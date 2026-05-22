import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

import '../utils/effective_uid.dart';

class JournalStorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => EffectiveUidProvider.getEffectiveUid();
  String get _keyJournal => 'maatricare_journals_v1_${_uid ?? "guest"}';

  /// Save or Update a journal entry (One Day = One Journal Entry constraint)
  Future<void> saveJournalEntry(JournalEntry entry) async {
    final list = await loadJournalEntries();
    
    // Find if an entry for the exact same date already exists
    final existingIndex = list.indexWhere((item) => item.date == entry.date);
    
    final updatedEntry = entry.copyWith(updatedAt: DateTime.now());

    if (existingIndex != -1) {
      list[existingIndex] = updatedEntry;
    } else {
      list.insert(0, updatedEntry);
    }

    // Always update SharedPreferences cache first
    await _saveToPrefs(list);

    // Save to Firestore if authenticated
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('JournalStorageService: Syncing journal entry to Firestore under users/$uid/journals');
        // 1. Save journal entry to subcollection users/{uid}/journals
        await _db
            .collection('users')
            .doc(uid)
            .collection('journals')
            .doc(updatedEntry.id)
            .set(updatedEntry.toJson());

        // 2. Also log daily mood in users/{uid}/moods/{date}
        if (updatedEntry.mood.isNotEmpty) {
          await _db
              .collection('users')
              .doc(uid)
              .collection('moods')
              .doc(updatedEntry.date)
              .set({
            'date': updatedEntry.date,
            'mood': updatedEntry.mood,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('JournalStorageService: Firestore sync error: $e');
      }
    }
  }

  /// Load all persisted journal entries, sorted chronologically (newest first)
  Future<List<JournalEntry>> loadJournalEntries() async {
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('JournalStorageService: Fetching journal entries from Firestore under users/$uid/journals');
        final snapshot = await _db
            .collection('users')
            .doc(uid)
            .collection('journals')
            .get();

        final list = snapshot.docs
            .map((doc) => JournalEntry.fromJson(doc.data()))
            .toList();
        
        final filteredList = list.where((j) => !['journal_1', 'journal_2', 'journal_3'].contains(j.id)).toList();
        filteredList.sort((a, b) => b.date.compareTo(a.date));
        
        // Sync local SharedPreferences cache
        await _saveToPrefs(filteredList);
        return filteredList;
      } catch (e) {
        debugPrint('JournalStorageService: Failed to fetch journals from Firestore, falling back to local cache: $e');
      }
    }

    // Fallback/offline/unauthenticated local load
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyJournal);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final list = jsonList.map((json) => JournalEntry.fromJson(json)).toList();
      
      final filteredList = list.where((j) => !['journal_1', 'journal_2', 'journal_3'].contains(j.id)).toList();
      
      // Sort newest first
      filteredList.sort((a, b) => b.date.compareTo(a.date));
      return filteredList;
    } catch (e) {
      debugPrint('Failed to load journals from prefs: $e');
      return [];
    }
  }

  /// Delete a journal entry
  Future<void> deleteJournalEntry(String id) async {
    final list = await loadJournalEntries();
    final index = list.indexWhere((item) => item.id == id);
    if (index != -1) {
      final entry = list[index];
      list.removeAt(index);
      await _saveToPrefs(list);

      final uid = _uid;
      if (uid != null) {
        try {
          debugPrint('JournalStorageService: Deleting journal entry $id from Firestore');
          await _db
              .collection('users')
              .doc(uid)
              .collection('journals')
              .doc(id)
              .delete();

          // Also delete the corresponding mood log for that date if applicable
          await _db
              .collection('users')
              .doc(uid)
              .collection('moods')
              .doc(entry.date)
              .delete();
        } catch (e) {
          debugPrint('JournalStorageService: Firestore delete error: $e');
        }
      }
    }
  }

  /// Toggle bookmark status of a specific entry
  Future<void> toggleBookmark(String id) async {
    final list = await loadJournalEntries();
    final index = list.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updated = list[index].copyWith(
        isBookmarked: !list[index].isBookmarked,
        updatedAt: DateTime.now(),
      );
      list[index] = updated;
      await _saveToPrefs(list);

      final uid = _uid;
      if (uid != null) {
        try {
          debugPrint('JournalStorageService: Syncing bookmark toggle to Firestore');
          await _db
              .collection('users')
              .doc(uid)
              .collection('journals')
              .doc(id)
              .set(updated.toJson());
        } catch (e) {
          debugPrint('JournalStorageService: Firestore bookmark sync error: $e');
        }
      }
    }
  }

  /// Persist to SharedPreferences
  Future<void> _saveToPrefs(List<JournalEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list.map((item) => item.toJson()).toList());
    await prefs.setString(_keyJournal, jsonString);
  }
}
