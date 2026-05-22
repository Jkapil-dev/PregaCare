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

  String? _cachedEffectiveUid;
  bool _cachedHasPermission = false;
  bool _cachedSharingAllowed = true;

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
    _userProvider = userProvider;

    final newEffectiveUid = userProvider.isPartner ? userProvider.linkedMotherUid : userProvider.uid;
    final newHasPermission = userProvider.hasAppointmentsPermission;
    final newSharingAllowed = userProvider.motherNotificationSettings?['sharingSettings']?['appointmentReminders'] ?? true;

    if (_cachedEffectiveUid != newEffectiveUid || _cachedHasPermission != newHasPermission) {
      _cachedEffectiveUid = newEffectiveUid;
      _cachedHasPermission = newHasPermission;

      if (newHasPermission && newEffectiveUid != null && newEffectiveUid.isNotEmpty) {
        _subscribeToAppointments(newEffectiveUid);
      } else {
        _unsubscribe();
        _appointments = [];
        _isLoading = false;
        notifyListeners();
      }
    } else if (userProvider.isPartner && _cachedSharingAllowed != newSharingAllowed) {
      _cachedSharingAllowed = newSharingAllowed;
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

    final bool isPartner = _userProvider?.isPartner ?? false;
    final String? connectionId = _userProvider?.linkedConnectionId;
    Query<Map<String, dynamic>> appointmentsCollection;

    if (isPartner && connectionId != null && connectionId.isNotEmpty) {
      appointmentsCollection = FirebaseFirestore.instance
          .collection('pregnancy_connections')
          .doc(connectionId)
          .collection('shared_appointments');
    } else {
      appointmentsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .collection('appointments');
    }

    _appointmentsSubscription = appointmentsCollection.snapshots().listen((snapshot) {
      _appointments = snapshot.docs.map((doc) => Consultation.fromJson(doc.data())).toList();

      // Defensively replicate to shared collection if Mother
      if (!isPartner && connectionId != null && connectionId.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final con in _appointments) {
          final docRef = FirebaseFirestore.instance
              .collection('pregnancy_connections')
              .doc(connectionId)
              .collection('shared_appointments')
              .doc(con.id);
          batch.set(docRef, con.toJson(), SetOptions(merge: true));
        }
        batch.commit().catchError((e) => debugPrint('AppointmentProvider: Replication error $e'));
      }

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
    if (uid != null && uid.isNotEmpty) {
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

      // Replicate to shared collection if Mother has connection
      final connectionId = _userProvider?.linkedConnectionId;
      if (connectionId != null && connectionId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('pregnancy_connections')
            .doc(connectionId)
            .collection('shared_appointments')
            .doc(appointment.id)
            .set(appointment.toJson(), SetOptions(merge: true));
      }
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

      // Delete from shared collection if Mother has connection
      final connectionId = _userProvider?.linkedConnectionId;
      if (connectionId != null && connectionId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('pregnancy_connections')
            .doc(connectionId)
            .collection('shared_appointments')
            .doc(id)
            .delete();
      }
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
