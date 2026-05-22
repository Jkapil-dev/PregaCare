import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/effective_uid.dart';
import 'user_provider.dart';

class MedicineProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<User?>? _authSubscription;
  UserProvider? _userProvider;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _medicinesSubscription;

  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _cachedEffectiveUid;
  bool _cachedHasPermission = false;
  bool _cachedSharingAllowed = true;

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
      if (user == null) {
        _unsubscribe();
        _medicines = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void update(UserProvider userProvider) {
    _userProvider = userProvider;

    final newEffectiveUid = userProvider.isPartner ? userProvider.linkedMotherUid : userProvider.uid;
    final newHasPermission = userProvider.hasMedicinesPermission;
    final newSharingAllowed = userProvider.motherNotificationSettings?['sharingSettings']?['medicineReminders'] ?? true;

    if (_cachedEffectiveUid != newEffectiveUid || _cachedHasPermission != newHasPermission) {
      _cachedEffectiveUid = newEffectiveUid;
      _cachedHasPermission = newHasPermission;

      if (newHasPermission && newEffectiveUid != null && newEffectiveUid.isNotEmpty) {
        loadMedicines();
      } else {
        _unsubscribe();
        _medicines = [];
        _isLoading = false;
        notifyListeners();
      }
    } else if (userProvider.isPartner && _cachedSharingAllowed != newSharingAllowed) {
      _cachedSharingAllowed = newSharingAllowed;
      _syncLocalNotifications();
    }
  }

  /// Helper to get the active user ID
  String get _userId {
    return EffectiveUidProvider.getEffectiveUid();
  }

  void _unsubscribe() {
    _medicinesSubscription?.cancel();
    _medicinesSubscription = null;
  }

  Future<void> _syncLocalNotifications() async {
    if (_userProvider?.isPartner != true) return;

    // 1. Cancel all current notification IDs
    final List<int> idsToCancel = [];
    for (final med in _medicines) {
      idsToCancel.addAll(med.notificationIds);
    }
    if (idsToCancel.isNotEmpty) {
      await _notificationService.cancelNotifications(idsToCancel);
    }

    // 2. Check if sharing is allowed and permissions exist
    final sharingAllowed = _userProvider?.motherNotificationSettings?['sharingSettings']?['medicineReminders'] ?? true;
    final hasPermission = _userProvider?.hasMedicinesPermission ?? false;

    if (sharingAllowed && hasPermission) {
      // 3. Re-schedule upcoming active medicine reminders
      for (final med in _medicines) {
        if (med.reminderEnabled && !med.isExpired) {
          debugPrint('MedicineProvider: Partner scheduling reminders for ${med.medicineName}');
          await _notificationService.scheduleMedicineReminders(
            id: med.id,
            name: med.medicineName,
            dosage: med.dosage,
            times: med.selectedTimes,
            startDate: med.startDate,
            endDate: med.endDate,
            durationDays: med.durationDays,
          );
        }
      }
    }
  }

  /// Load medicines from Firestore in real-time
  Future<void> loadMedicines() async {
    final hasPermission = _userProvider?.hasMedicinesPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) {
      _unsubscribe();
      _medicines = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _unsubscribe();

    final bool isPartner = _userProvider?.isPartner ?? false;
    final String? connectionId = _userProvider?.linkedConnectionId;
    Query<Map<String, dynamic>> medicinesCollection;
    if (isPartner && connectionId != null && connectionId.isNotEmpty) {
      medicinesCollection = FirebaseFirestore.instance
          .collection('pregnancy_connections')
          .doc(connectionId)
          .collection('shared_medicines')
          .orderBy('createdAt', descending: true);
    } else {
      medicinesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .orderBy('createdAt', descending: true);
    }

    _medicinesSubscription = medicinesCollection.snapshots().listen((snapshot) {
      _medicines = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Medicine.fromJson(data);
      }).toList();

      // If this is the mother, defensively replicate to shared collection
      if (!(_userProvider?.isPartner ?? false) && connectionId != null && connectionId.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final med in _medicines) {
          final docRef = FirebaseFirestore.instance
              .collection('pregnancy_connections')
              .doc(connectionId)
              .collection('shared_medicines')
              .doc(med.id);
          batch.set(docRef, med.toJson(), SetOptions(merge: true));
        }
        batch.commit().catchError((e) => debugPrint('MedicineProvider: Replication error $e'));
      }

      _medicines = _medicines.where((m) => !m.id.contains('mock')).toList();
      _isLoading = false;
      _errorMessage = null;

      // Sync local notifications for Partner
      _syncLocalNotifications();

      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('MedicineProvider stream error: $e');
    });
  }

  /// Add or update a medicine and coordinate reminders
  Future<void> saveMedicine(Medicine medicine) async {
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify medicines.');
    }
    final hasPermission = _userProvider?.hasMedicinesPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

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

      // 3. Save to mother collection
      await _firestoreService.saveMedicine(uid, updatedMedicine);

      // 4. Replicate to shared collection if mother has a connection
      if (!(_userProvider?.isPartner ?? false)) {
        final connectionId = _userProvider?.linkedConnectionId;
        if (connectionId != null && connectionId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('pregnancy_connections')
              .doc(connectionId)
              .collection('shared_medicines')
              .doc(updatedMedicine.id)
              .set(updatedMedicine.toJson(), SetOptions(merge: true));
        }
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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify medicines.');
    }
    final hasPermission = _userProvider?.hasMedicinesPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final index = _medicines.indexWhere((m) => m.id == id);
      if (index != -1) {
        // 1. Cancel notifications
        await _notificationService.cancelNotifications(_medicines[index].notificationIds);
        
        // 2. Delete from mother collection
        await _firestoreService.deleteMedicine(uid, id);
        // 3. Delete from shared collection if mother
        if (!(_userProvider?.isPartner ?? false)) {
          final connectionId = _userProvider?.linkedConnectionId;
          if (connectionId != null && connectionId.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('pregnancy_connections')
                .doc(connectionId)
                .collection('shared_medicines')
                .doc(id)
                .delete();
          }
        }
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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify medicines.');
    }
    final hasPermission = _userProvider?.hasMedicinesPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

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
      // Save changes to mother collection
      await _firestoreService.updateAdherence(uid, medicineId, updatedLogs);
      
      // Replicate adherence updates to shared collection if mother
      if (!(_userProvider?.isPartner ?? false)) {
        final connectionId = _userProvider?.linkedConnectionId;
        if (connectionId != null && connectionId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('pregnancy_connections')
              .doc(connectionId)
              .collection('shared_medicines')
              .doc(medicineId)
              .update({'adherenceLogs': updatedLogs});
        }
      }
    } catch (e) {
      debugPrint('MedicineProvider updateAdherence remote save error: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _unsubscribe();
    super.dispose();
  }
}
