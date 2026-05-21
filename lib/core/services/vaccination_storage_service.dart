import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vaccination.dart';
import 'notification_service.dart';

class VaccinationStorageService {
  static const String _keyVaccinations = 'maatricare_vaccinations_v1';
  final NotificationService _notificationService = NotificationService();

  /// Save single vaccination record, schedule notification, and persist
  Future<void> saveVaccination(Vaccination vac) async {
    final list = await loadVaccinations();
    
    // Cancel old notifications first if editing
    final existingIndex = list.indexWhere((v) => v.id == vac.id);
    if (existingIndex != -1) {
      await _notificationService.cancelNotifications([list[existingIndex].notificationId]);
    }

    // Schedule new notification if reminder is enabled and status is not completed
    if (vac.reminderEnabled && vac.vaccinationStatus == 'Upcoming') {
      await _notificationService.scheduleVaccineReminder(vac);
    }

    if (existingIndex != -1) {
      list[existingIndex] = vac;
    } else {
      list.insert(0, vac);
    }

    await _saveToPrefs(list);
  }

  /// Load all persisted vaccinations
  Future<List<Vaccination>> loadVaccinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyVaccinations);
      if (jsonString == null) {
        return _getMockVaccinations();
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Vaccination.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to load vaccinations: $e');
      return _getMockVaccinations();
    }
  }

  /// Delete a vaccination and cancel its scheduled notification
  Future<void> deleteVaccination(String id) async {
    final list = await loadVaccinations();
    final index = list.indexWhere((v) => v.id == id);
    if (index != -1) {
      await _notificationService.cancelNotifications([list[index].notificationId]);
      list.removeAt(index);
      await _saveToPrefs(list);
    }
  }

  /// Persist to SharedPreferences
  Future<void> _saveToPrefs(List<Vaccination> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list.map((v) => v.toJson()).toList());
    await prefs.setString(_keyVaccinations, jsonString);
  }

  /// Prenatal immunisation schedule (TT-1, TT-2, Tdap, Influenza)
  List<Vaccination> _getMockVaccinations() {
    final today = DateTime.now();
    return [
      Vaccination(
        id: 'vac_1',
        vaccineName: 'Tetanus Toxoid (TT-1)',
        doseNumber: 'Dose 1',
        scheduledDate: today.subtract(const Duration(days: 45)),
        hospitalOrClinic: 'Apollo Maternal Wing',
        doctorName: 'Dr. Anya Sharma',
        notes: 'First prenatal immunization Dose',
        reminderEnabled: true,
        vaccinationStatus: 'Completed',
      ),
      Vaccination(
        id: 'vac_2',
        vaccineName: 'Tetanus Toxoid (TT-2)',
        doseNumber: 'Dose 2',
        scheduledDate: today.subtract(const Duration(days: 10)),
        hospitalOrClinic: 'Apollo Maternal Wing',
        doctorName: 'Dr. Anya Sharma',
        notes: 'Booster Dose booster scheduled 4 weeks post-Dose 1',
        reminderEnabled: true,
        vaccinationStatus: 'Completed',
      ),
      Vaccination(
        id: 'vac_3',
        vaccineName: 'Tdap Booster',
        doseNumber: 'Dose 1',
        scheduledDate: today.add(const Duration(days: 15)),
        hospitalOrClinic: 'Fortis Clinic',
        doctorName: 'Dr. Rahul Mehta',
        notes: 'Protects baby from whooping cough post-birth',
        reminderEnabled: true,
        vaccinationStatus: 'Upcoming',
      ),
      Vaccination(
        id: 'vac_4',
        vaccineName: 'Influenza Vaccine',
        doseNumber: 'Single Dose',
        scheduledDate: today.add(const Duration(days: 30)),
        hospitalOrClinic: 'City Health Center',
        doctorName: 'Dr. Sonia Gupta',
        notes: 'Highly recommended during season shifts',
        reminderEnabled: false,
        vaccinationStatus: 'Upcoming',
      ),
    ];
  }
}
