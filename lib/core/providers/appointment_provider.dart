import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/consultation.dart';
import '../services/consultation_storage_service.dart';
import '../services/notification_service.dart';
import 'user_provider.dart';

class AppointmentProvider extends ChangeNotifier {
  final ConsultationStorageService _storageService = ConsultationStorageService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _appointmentsSubscription;
  UserProvider? _userProvider;

  List<Consultation> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  AppointmentProvider() {
    _init();
  }

  List<Consultation> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Consultation? get nextAppointment {
    if (_appointments.isEmpty) return null;
    final now = DateTime.now();
    
    // Filter to only upcoming consultations, and sort them chronologically (earliest first)
    final upcoming = _appointments
        .where((c) => c.consultationStatus == 'Upcoming' && c.appointmentDate.isAfter(now.subtract(const Duration(days: 1))))
        .toList();
        
    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) {
      final comp = a.appointmentDate.compareTo(b.appointmentDate);
      if (comp != 0) return comp;
      return a.appointmentTime.compareTo(b.appointmentTime);
    });

    return upcoming.first;
  }

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _unsubscribe();
        _appointments = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void update(UserProvider userProvider) {
    final oldEffectiveUid = _userProvider == null ? null : (_userProvider!.isPartner ? _userProvider!.linkedMotherUid : _userProvider!.uid);
    final newEffectiveUid = userProvider.isPartner ? userProvider.linkedMotherUid : userProvider.uid;

    final oldHasPermission = _userProvider?.hasAppointmentsPermission ?? false;
    final newHasPermission = userProvider.hasAppointmentsPermission;

    final oldSharingAllowed = _userProvider?.motherNotificationSettings?['sharingSettings']?['appointmentReminders'] ?? true;
    final newSharingAllowed = userProvider.motherNotificationSettings?['sharingSettings']?['appointmentReminders'] ?? true;

    _userProvider = userProvider;

    if (oldEffectiveUid != newEffectiveUid || oldHasPermission != newHasPermission) {
      if (newHasPermission && newEffectiveUid != null && newEffectiveUid.isNotEmpty) {
        _subscribeToAppointments(newEffectiveUid);
      } else {
        _unsubscribe();
        _appointments = [];
        _isLoading = false;
        notifyListeners();
      }
    } else if (userProvider.isPartner && oldSharingAllowed != newSharingAllowed) {
      _syncLocalNotifications();
    }
  }

  Future<void> _syncLocalNotifications() async {
    if (_userProvider?.isPartner != true) return;

    // 1. Cancel all current appointment notification IDs
    final List<int> idsToCancel = _appointments.map((c) => c.notificationId).toList();
    if (idsToCancel.isNotEmpty) {
      await _notificationService.cancelNotifications(idsToCancel);
    }

    // 2. Check if sharing is allowed and permissions exist
    final sharingAllowed = _userProvider?.motherNotificationSettings?['sharingSettings']?['appointmentReminders'] ?? true;
    final hasPermission = _userProvider?.hasAppointmentsPermission ?? false;

    if (sharingAllowed && hasPermission) {
      final now = DateTime.now();
      // 3. Re-schedule upcoming appointments
      for (final con in _appointments) {
        if (con.reminderEnabled && con.consultationStatus == 'Upcoming' && con.appointmentDate.isAfter(now)) {
          debugPrint('AppointmentProvider: Partner scheduling reminder for appointment with ${con.doctorName}');
          await _notificationService.scheduleConsultationReminder(con);
        }
      }
    }
  }

  void _subscribeToAppointments(String targetUid) {
    _unsubscribe();
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final appointmentsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('appointments');

    _appointmentsSubscription = appointmentsCollection.snapshots().listen((snapshot) {
      _appointments = snapshot.docs.map((doc) => Consultation.fromJson(doc.data())).toList();
      _appointments = _appointments.where((c) => !['con_1', 'con_2', 'con_3'].contains(c.id)).toList();
      _isLoading = false;
      _errorMessage = null;

      // Sync local notifications for Partner
      _syncLocalNotifications();

      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('AppointmentProvider stream error: $e');
    });
  }

  void _unsubscribe() {
    _appointmentsSubscription?.cancel();
    _appointmentsSubscription = null;
  }

  Future<void> loadAppointments() async {
    final uid = _userProvider?.isPartner == true ? _userProvider?.linkedMotherUid : _userProvider?.uid;
    if (uid != null && uid.isNotEmpty && (_userProvider?.hasAppointmentsPermission ?? true)) {
      _subscribeToAppointments(uid);
    }
  }

  Future<void> saveAppointment(Consultation appointment) async {
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify appointments.');
    }
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.saveConsultation(appointment);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AppointmentProvider saveAppointment error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAppointment(String id) async {
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify appointments.');
    }
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.deleteConsultation(id);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AppointmentProvider deleteAppointment error: $e');
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
