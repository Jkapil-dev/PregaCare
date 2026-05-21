import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import 'notification_service.dart';

class MedicineStorageService {
  static const String _keyMedicines = 'maatricare_medicines_v2';
  final NotificationService _notificationService = NotificationService();

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
        return _getMockMedicines();
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Medicine.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to load medicines: $e');
      return _getMockMedicines();
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

  /// Default mock medicines to ensure visual completeness out-of-the-box
  List<Medicine> _getMockMedicines() {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    return [
      Medicine(
        id: 'mock_1',
        medicineName: 'Folic Acid',
        dosage: '400mcg',
        selectedTimes: ['Morning'],
        startDate: today,
        endDate: today.add(const Duration(days: 30)),
        durationDays: 30,
        notes: 'Take before meal',
        mealType: 'Before Meal',
        reminderEnabled: true,
        adherenceLogs: {
          todayStr: {'Morning': 'Taken'}
        },
      ),
      Medicine(
        id: 'mock_2',
        medicineName: 'Iron Supplement',
        dosage: '100mg',
        selectedTimes: ['Morning', 'Night'],
        startDate: today,
        endDate: today.add(const Duration(days: 14)),
        durationDays: 14,
        notes: 'With orange juice for absorption',
        mealType: 'After Meal',
        reminderEnabled: true,
        adherenceLogs: {
          todayStr: {'Morning': 'Taken', 'Night': 'Pending'}
        },
      ),
      Medicine(
        id: 'mock_3',
        medicineName: 'Calcium',
        dosage: '500mg',
        selectedTimes: ['Afternoon', 'Night'],
        startDate: today,
        endDate: today.add(const Duration(days: 20)),
        durationDays: 20,
        notes: 'Do not take together with Iron',
        mealType: 'With Meal',
        reminderEnabled: false,
        adherenceLogs: {
          todayStr: {'Afternoon': 'Pending', 'Night': 'Pending'}
        },
      ),
    ];
  }
}
