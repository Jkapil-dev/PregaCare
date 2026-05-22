import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/consultation.dart';
import 'notification_service.dart';

import '../utils/effective_uid.dart';

class ConsultationStorageService {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => EffectiveUidProvider.getEffectiveUid();
  String get _keyConsultations => 'maatricare_consultations_v1_${_uid ?? "guest"}';

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

    // Update SharedPreferences cache first
    await _saveToPrefs(list);

    // Save to Firestore if authenticated
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('ConsultationStorageService: Syncing consultation ${con.id} to Firestore under users/$uid/appointments');
        await _db
            .collection('users')
            .doc(uid)
            .collection('appointments')
            .doc(con.id)
            .set(con.toJson());
      } catch (e) {
        debugPrint('ConsultationStorageService: Firestore sync error: $e');
      }
    }
  }

  /// Load all persisted consultations
  Future<List<Consultation>> loadConsultations() async {
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('ConsultationStorageService: Fetching appointments from Firestore under users/$uid/appointments');
        final snapshot = await _db
            .collection('users')
            .doc(uid)
            .collection('appointments')
            .get();

        final list = snapshot.docs
            .map((doc) => Consultation.fromJson(doc.data()))
            .toList();
        
        final filteredList = list.where((c) => !['con_1', 'con_2', 'con_3'].contains(c.id)).toList();
        
        // Sync local SharedPreferences cache
        await _saveToPrefs(filteredList);
        return filteredList;
      } catch (e) {
        debugPrint('ConsultationStorageService: Failed to fetch appointments from Firestore, falling back to local cache: $e');
      }
    }

    // Fallback/offline/unauthenticated local load
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyConsultations);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final list = jsonList.map((json) => Consultation.fromJson(json)).toList();
      return list.where((c) => !['con_1', 'con_2', 'con_3'].contains(c.id)).toList();
    } catch (e) {
      debugPrint('Failed to load consultations from prefs: $e');
      return [];
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

      final uid = _uid;
      if (uid != null) {
        try {
          debugPrint('ConsultationStorageService: Deleting appointment $id from Firestore');
          await _db
              .collection('users')
              .doc(uid)
              .collection('appointments')
              .doc(id)
              .delete();
        } catch (e) {
          debugPrint('ConsultationStorageService: Firestore delete error: $e');
        }
      }
    }
  }

  /// Persist to SharedPreferences
  Future<void> _saveToPrefs(List<Consultation> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list.map((c) => c.toJson()).toList());
    await prefs.setString(_keyConsultations, jsonString);
  }
}
