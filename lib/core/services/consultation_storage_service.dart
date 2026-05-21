import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/consultation.dart';
import 'notification_service.dart';

class ConsultationStorageService {
  static const String _keyConsultations = 'maatricare_consultations_v1';
  final NotificationService _notificationService = NotificationService();

  /// Save single consultation record, schedule notification, and persist
  Future<void> saveConsultation(Consultation con) async {
    final list = await loadConsultations();
    
    // Cancel old notifications first if editing
    final existingIndex = list.indexWhere((c) => c.id == con.id);
    if (existingIndex != -1) {
      await _notificationService.cancelNotifications([list[existingIndex].notificationId]);
    }

    // Schedule new notification if reminder is enabled and status is upcoming
    if (con.reminderEnabled && con.consultationStatus == 'Upcoming') {
      await _notificationService.scheduleConsultationReminder(con);
    }

    if (existingIndex != -1) {
      list[existingIndex] = con;
    } else {
      list.insert(0, con);
    }

    await _saveToPrefs(list);
  }

  /// Load all persisted consultations
  Future<List<Consultation>> loadConsultations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyConsultations);
      if (jsonString == null) {
        return _getMockConsultations();
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Consultation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to load consultations: $e');
      return _getMockConsultations();
    }
  }

  /// Delete a consultation and cancel its scheduled notification
  Future<void> deleteConsultation(String id) async {
    final list = await loadConsultations();
    final index = list.indexWhere((c) => c.id == id);
    if (index != -1) {
      await _notificationService.cancelNotifications([list[index].notificationId]);
      list.removeAt(index);
      await _saveToPrefs(list);
    }
  }

  /// Persist to SharedPreferences
  Future<void> _saveToPrefs(List<Consultation> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list.map((c) => c.toJson()).toList());
    await prefs.setString(_keyConsultations, jsonString);
  }

  /// Default doctor followups preloaded
  List<Consultation> _getMockConsultations() {
    final today = DateTime.now();
    return [
      Consultation(
        id: 'con_1',
        doctorName: 'Dr. Anya Sharma',
        specialization: 'Gynaecologist & Obstetrician',
        hospitalOrClinic: 'Apollo Maternal Wing',
        appointmentDate: today.add(const Duration(days: 7)),
        appointmentTime: '10:30 AM',
        notes: 'Monthly Routine Prenatal Follow-up',
        reminderEnabled: true,
        consultationStatus: 'Upcoming',
      ),
      Consultation(
        id: 'con_2',
        doctorName: 'Dr. Rahul Mehta',
        specialization: 'Fetal Radiologist',
        hospitalOrClinic: 'Fortis Imaging Lab',
        appointmentDate: today.add(const Duration(days: 14)),
        appointmentTime: '02:00 PM',
        notes: 'Second Trimester Growth & Anomaly Scan',
        reminderEnabled: true,
        consultationStatus: 'Upcoming',
      ),
      Consultation(
        id: 'con_3',
        doctorName: 'Dr. Sonia Gupta',
        specialization: 'Maternal Nutritionist',
        hospitalOrClinic: 'City Health Center',
        appointmentDate: today.subtract(const Duration(days: 5)),
        appointmentTime: '11:00 AM',
        notes: 'Discussion on iron-rich meal options',
        reminderEnabled: false,
        consultationStatus: 'Completed',
      ),
    ];
  }
}
