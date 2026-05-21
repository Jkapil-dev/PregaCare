import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine.dart';
import 'notification_service.dart';

class MedicineStorageService {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  String get _keyMedicines => 'maatricare_medicines_v2_${_uid ?? "guest"}';

  /// Save single medicine, schedule notifications, and persist
  Future<void> saveMedicine(Medicine medicine) async {
    final medicines = await loadMedicines();
    
    // Cancel old notifications first if editing
    final existingIndex = medicines.indexWhere((m) => m.id == medicine.id);
    if (existingIndex != -1) {
      await _notificationService.cancelNotifications(medicines[existingIndex].notificationIds);
    }

    // Schedule new notifications if reminder is enabled
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

    if (existingIndex != -1) {
      medicines[existingIndex] = updatedMedicine;
    } else {
      medicines.insert(0, updatedMedicine);
    }

    await _saveToPrefs(medicines);
  }

  /// Update adherence logs and potentially dismiss notifications for today if marked taken
  Future<void> updateAdherence(String medicineId, String dateStr, String timeLabel, String status) async {
    final medicines = await loadMedicines();
    final index = medicines.indexWhere((m) => m.id == medicineId);
    if (index == -1) return;

    final medicine = medicines[index];
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
        debugPrint('Failed to cancel today\'s notification: $e');
      }
    }

    final updatedMedicine = medicine.copyWith(adherenceLogs: updatedLogs);
    medicines[index] = updatedMedicine;
    await _saveToPrefs(medicines);
  }

  /// Load all persisted medicines
  Future<List<Medicine>> loadMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyMedicines);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final list = jsonList.map((json) => Medicine.fromJson(json)).toList();
      return list.where((m) => !m.id.contains('mock')).toList();
    } catch (e) {
      debugPrint('Failed to load medicines: $e');
      return [];
    }
  }

  /// Delete a medicine and cancel its scheduled notifications
  Future<void> deleteMedicine(String id) async {
    final medicines = await loadMedicines();
    final index = medicines.indexWhere((m) => m.id == id);
    if (index != -1) {
      await _notificationService.cancelNotifications(medicines[index].notificationIds);
      medicines.removeAt(index);
      await _saveToPrefs(medicines);
    }
  }

  /// Persist to SharedPreferences
  Future<void> _saveToPrefs(List<Medicine> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(medicines.map((m) => m.toJson()).toList());
    await prefs.setString(_keyMedicines, jsonString);
  }
}
