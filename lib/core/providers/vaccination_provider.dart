import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/vaccination.dart';
import '../services/notification_service.dart';
import '../utils/effective_uid.dart';
import 'user_provider.dart';

class VaccinationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _vaccinationsSubscription;
  UserProvider? _userProvider;

  List<Vaccination> _vaccines = [];
  bool _isLoading = false;
  String? _errorMessage;

  VaccinationProvider() {
    _init();
  }

  List<Vaccination> get vaccines => _vaccines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _unsubscribe();
        _vaccines = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void update(UserProvider userProvider) {
    final oldEffectiveUid = _userProvider == null ? null : (_userProvider!.isPartner ? _userProvider!.linkedMotherUid : _userProvider!.uid);
    final newEffectiveUid = userProvider.isPartner ? userProvider.linkedMotherUid : userProvider.uid;

    final oldHasPermission = _userProvider?.hasTrackerPermission ?? false;
    final newHasPermission = userProvider.hasTrackerPermission;

    // Track old sharing allowed settings
    final oldSharingAllowed = _userProvider?.motherNotificationSettings?['sharingSettings']?['vaccinationReminders'] ?? true;
    final newSharingAllowed = userProvider.motherNotificationSettings?['sharingSettings']?['vaccinationReminders'] ?? true;

    _userProvider = userProvider;

    if (oldEffectiveUid != newEffectiveUid || oldHasPermission != newHasPermission) {
      if (newHasPermission && newEffectiveUid != null && newEffectiveUid.isNotEmpty) {
        _subscribeToVaccinations(newEffectiveUid);
      } else {
        _unsubscribe();
        _vaccines = [];
        _isLoading = false;
        notifyListeners();
      }
    } else if (userProvider.isPartner && oldSharingAllowed != newSharingAllowed) {
      // If sharing preference changed, trigger sync!
      _syncLocalNotifications();
    }
  }

  void _subscribeToVaccinations(String targetUid) {
    _unsubscribe();
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final vaccinationsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('vaccinations');

    _vaccinationsSubscription = vaccinationsCollection.snapshots().listen((snapshot) {
      _vaccines = snapshot.docs.map((doc) => Vaccination.fromJson(doc.data())).toList();
      _vaccines = _vaccines.where((v) => !['vac_1', 'vac_2', 'vac_3', 'vac_4'].contains(v.id)).toList();
      _isLoading = false;
      _errorMessage = null;

      // Sync local notifications for Partner
      _syncLocalNotifications();

      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('VaccinationProvider stream error: $e');
    });
  }

  void _unsubscribe() {
    _vaccinationsSubscription?.cancel();
    _vaccinationsSubscription = null;
  }

  Future<void> loadVaccinations() async {
    final uid = _userProvider?.isPartner == true ? _userProvider?.linkedMotherUid : _userProvider?.uid;
    if (uid != null && uid.isNotEmpty && (_userProvider?.hasTrackerPermission ?? true)) {
      _subscribeToVaccinations(uid);
    }
  }

  Future<void> _syncLocalNotifications() async {
    if (_userProvider?.isPartner != true) return;

    // 1. Cancel all current vaccination notification IDs
    final List<int> idsToCancel = _vaccines.map((v) => v.notificationId).toList();
    if (idsToCancel.isNotEmpty) {
      await _notificationService.cancelNotifications(idsToCancel);
    }

    // 2. Check if sharing is allowed and permissions exist
    final sharingAllowed = _userProvider?.motherNotificationSettings?['sharingSettings']?['vaccinationReminders'] ?? true;
    final hasPermission = _userProvider?.hasTrackerPermission ?? false;

    if (sharingAllowed && hasPermission) {
      final now = DateTime.now();
      // 3. Re-schedule upcoming vaccinations
      for (final vac in _vaccines) {
        if (vac.reminderEnabled && vac.vaccinationStatus == 'Upcoming' && vac.scheduledDate.isAfter(now)) {
          debugPrint('VaccinationProvider: Partner scheduling reminder for vaccination ${vac.vaccineName}');
          await _notificationService.scheduleVaccineReminder(vac);
        }
      }
    }
  }

  Future<void> saveVaccination(Vaccination vac) async {
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify vaccinations.');
    }
    _isLoading = true;
    notifyListeners();

    try {
      // Manage notifications for Mother
      final existingIndex = _vaccines.indexWhere((v) => v.id == vac.id);
      if (existingIndex != -1) {
        await _notificationService.cancelNotifications([_vaccines[existingIndex].notificationId]);
      }

      if (vac.reminderEnabled && vac.vaccinationStatus == 'Upcoming') {
        await _notificationService.scheduleVaccineReminder(vac);
      }

      final uid = _userProvider?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('vaccinations')
            .doc(vac.id)
            .set(vac.toJson());
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VaccinationProvider saveVaccination error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVaccination(String id) async {
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify vaccinations.');
    }
    _isLoading = true;
    notifyListeners();

    try {
      final index = _vaccines.indexWhere((v) => v.id == id);
      if (index != -1) {
        await _notificationService.cancelNotifications([_vaccines[index].notificationId]);
        
        final uid = _userProvider?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('vaccinations')
              .doc(id)
              .delete();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VaccinationProvider deleteVaccination error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _unsubscribe();
    super.dispose();
  }
}
