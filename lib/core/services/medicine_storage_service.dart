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
        mealTiming: 'Pre-meal',
        reminderEnabled: true,
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
        mealTiming: 'Post-meal',
        reminderEnabled: true,
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
        mealTiming: 'Post-meal',
        reminderEnabled: false,
      ),
    ];
  }
}
