import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';

class JournalStorageService {
  static const String _keyJournal = 'maatricare_journals_v1';

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

    await _saveToPrefs(list);
  }

  /// Load all persisted journal entries, sorted chronologically (newest first)
  Future<List<JournalEntry>> loadJournalEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyJournal);
      if (jsonString == null) {
        return _getMockJournals();
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final list = jsonList.map((json) => JournalEntry.fromJson(json)).toList();
      
      // Sort newest first
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      debugPrint('Failed to load journals: $e');
      return _getMockJournals();
    }
  }

  /// Delete a journal entry
  Future<void> deleteJournalEntry(String id) async {
    final list = await loadJournalEntries();
    final index = list.indexWhere((item) => item.id == id);
    if (index != -1) {
      list.removeAt(index);
      await _saveToPrefs(list);
    }
  }

  /// Toggle bookmark status of a specific entry
  Future<void> toggleBookmark(String id) async {
    final list = await loadJournalEntries();
    final index = list.indexWhere((item) => item.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(
        isBookmarked: !list[index].isBookmarked,
        updatedAt: DateTime.now(),
      );
      await _saveToPrefs(list);
    }
  }

  /// Persist to SharedPreferences
  Future<void> _saveToPrefs(List<JournalEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list.map((item) => item.toJson()).toList());
    await prefs.setString(_keyJournal, jsonString);
  }

  /// Default mock journal reflections
  List<JournalEntry> _getMockJournals() {
    final today = DateTime.now();
    
    final dateToday = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final yesterday = today.subtract(const Duration(days: 1));
    final dateYesterday = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final dateTwoDaysAgo = "${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}";

    return [
      JournalEntry(
        id: 'journal_1',
        date: dateToday,
        title: 'Baby Kicked Today',
        content: 'Felt the first strong kick today! Such a magical feeling. Sharing this moment with Rahul was beautiful.',
        mood: '😊 Happy',
        isBookmarked: true,
      ),
      JournalEntry(
        id: 'journal_2',
        date: dateYesterday,
        title: 'Breathing Center',
        content: 'Bit of anxiety about the anomaly scan next week, but practicing daily breathing exercises is keeping me centered.',
        mood: '😌 Calm',
        isBookmarked: false,
      ),
      JournalEntry(
        id: 'journal_3',
        date: dateTwoDaysAgo,
        title: 'Feeling Sleepy',
        content: 'Felt exhausted today after a short walk. Took a nice 2-hour afternoon nap.',
        mood: '😴 Tired',
        isBookmarked: false,
      ),
    ];
  }
}
