import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/consultation.dart';
import '../services/consultation_storage_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final ConsultationStorageService _storageService = ConsultationStorageService();
  StreamSubscription<User?>? _authSubscription;

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
      loadAppointments();
    });
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _appointments = await _storageService.loadConsultations();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AppointmentProvider loadAppointments error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAppointment(Consultation appointment) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.saveConsultation(appointment);
      await loadAppointments();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('AppointmentProvider saveAppointment error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAppointment(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.deleteConsultation(id);
      await loadAppointments();
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
    super.dispose();
  }
}
