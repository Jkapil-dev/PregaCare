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
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Vaccination.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to load vaccinations from prefs: $e');
      return [];
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
}
