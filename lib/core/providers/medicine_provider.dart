import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<User?>? _authSubscription;

  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _errorMessage;

  MedicineProvider() {
    _init();
  }

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get adherenceRate {
    int totalScheduled = 0;
    int totalTaken = 0;
    for (final med in _medicines) {
      for (final dateLogs in med.adherenceLogs.values) {
        for (final status in dateLogs.values) {
          totalScheduled++;
          if (status == 'Taken') {
            totalTaken++;
          }
        }
      }
    }
    if (totalScheduled == 0) return 1.0;
    return totalTaken / totalScheduled;
  }

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        loadMedicines();
      } else {
        _medicines = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Helper to get the active user ID or fallback to guest session
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'default_user_id';
  }

  /// Load medicines from Firestore
  Future<void> loadMedicines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _firestoreService.getMedicines(_userId);
      _medicines = list;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MedicineProvider loadMedicines error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add or update a medicine and coordinate reminders
  Future<void> saveMedicine(Medicine medicine) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Manage notifications first (Cancel existing)
      final existingIndex = _medicines.indexWhere((m) => m.id == medicine.id);
      if (existingIndex != -1) {
        await _notificationService.cancelNotifications(_medicines[existingIndex].notificationIds);
      }

      // 2. Schedule new ones if enabled and not expired
      List<int> notificationIds = [];
      if (medicine.reminderEnabled && !medicine.isExpired) {
        notificationIds = await _notificationService.scheduleMedicineReminders(
          id: medicine.id,
          name: medicine.medicineName,
          dosage: medicine.dosage,
          times: medicine.selectedTimes,
          startDate: medicine.startDate,
          endDate: medicine.endDate,
          durationDays: medicine.durationDays,
        );
      }

      final updatedMedicine = medicine.copyWith(notificationIds: notificationIds);

      // 3. Save to Firestore
      await _firestoreService.saveMedicine(_userId, updatedMedicine);

      // 4. Update local state
      if (existingIndex != -1) {
        _medicines[existingIndex] = updatedMedicine;
      } else {
        _medicines.insert(0, updatedMedicine);
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MedicineProvider saveMedicine error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a medicine and cancel scheduled reminders
  Future<void> deleteMedicine(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _medicines.indexWhere((m) => m.id == id);
      if (index != -1) {
        // 1. Cancel notifications
        await _notificationService.cancelNotifications(_medicines[index].notificationIds);
        
        // 2. Delete from Firestore
        await _firestoreService.deleteMedicine(_userId, id);

        // 3. Update local list
        _medicines.removeAt(index);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MedicineProvider deleteMedicine error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update adherence logs and handle daily reminder dismissals if marked taken
  Future<void> updateAdherence(
    String medicineId,
    String dateStr,
    String timeLabel,
    String status,
  ) async {
    final index = _medicines.indexWhere((m) => m.id == medicineId);
    if (index == -1) return;

    final medicine = _medicines[index];
    final updatedLogs = Map<String, Map<String, String>>.from(medicine.adherenceLogs);
    if (!updatedLogs.containsKey(dateStr)) {
      updatedLogs[dateStr] = {};
    }
    
    final dayLogs = Map<String, String>.from(updatedLogs[dateStr]!);
    dayLogs[timeLabel] = status;
    updatedLogs[dateStr] = dayLogs;

    // If marked taken, cancel today's specific daily notification to dismiss it
    if (status == 'Taken') {
      try {
        final uniqueId = (medicine.id.hashCode + timeLabel.hashCode).abs() % 100000;
        final now = DateTime.now();
        final todayZero = DateTime(now.year, now.month, now.day);
        final startZero = DateTime(medicine.startDate.year, medicine.startDate.month, medicine.startDate.day);
        final dayOffset = todayZero.difference(startZero).inDays;

        if (dayOffset >= 0 && dayOffset < medicine.durationDays) {
          final todayNotificationId = uniqueId + dayOffset;
          await _notificationService.cancelNotifications([todayNotificationId]);
        }
      } catch (e) {
        debugPrint('MedicineProvider failed to cancel today\'s notification: $e');
      }
    }

    final updatedMedicine = medicine.copyWith(adherenceLogs: updatedLogs);
    
    // Optimistic local state update for snappy UI feel
    _medicines[index] = updatedMedicine;
    notifyListeners();

    try {
      // Save changes to Firestore
      await _firestoreService.updateAdherence(_userId, medicineId, updatedLogs);
    } catch (e) {
      debugPrint('MedicineProvider updateAdherence remote save error: $e');
      // Rollback on failure if necessary, but typically keep local optimistic state
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
