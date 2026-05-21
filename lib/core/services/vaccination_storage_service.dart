import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vaccination.dart';
import 'notification_service.dart';

class VaccinationStorageService {
  static const String _keyVaccinations = 'maatricare_vaccinations_v1';
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

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

    // Update SharedPreferences cache first
    await _saveToPrefs(list);

    // Save to Firestore if authenticated
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('VaccinationStorageService: Syncing vaccination ${vac.id} to Firestore under users/$uid/vaccinations');
        await _db
            .collection('users')
            .doc(uid)
            .collection('vaccinations')
            .doc(vac.id)
            .set(vac.toJson());
      } catch (e) {
        debugPrint('VaccinationStorageService: Firestore sync error: $e');
      }
    }
  }

  /// Load all persisted vaccinations
  Future<List<Vaccination>> loadVaccinations() async {
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('VaccinationStorageService: Fetching vaccinations from Firestore under users/$uid/vaccinations');
        final snapshot = await _db
            .collection('users')
            .doc(uid)
            .collection('vaccinations')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs
              .map((doc) => Vaccination.fromJson(doc.data()))
              .toList();
          
          // Sync local SharedPreferences cache
          await _saveToPrefs(list);
          return list;
        }
      } catch (e) {
        debugPrint('VaccinationStorageService: Failed to fetch vaccinations from Firestore, falling back to local cache: $e');
      }
    }

    // Fallback/offline/unauthenticated local load
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyVaccinations);
      if (jsonString == null) {
        return _getMockVaccinations();
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Vaccination.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to load vaccinations from prefs: $e');
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

      final uid = _uid;
      if (uid != null) {
        try {
          debugPrint('VaccinationStorageService: Deleting vaccination $id from Firestore');
          await _db
              .collection('users')
              .doc(uid)
              .collection('vaccinations')
              .doc(id)
              .delete();
        } catch (e) {
          debugPrint('VaccinationStorageService: Firestore delete error: $e');
        }
      }
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
