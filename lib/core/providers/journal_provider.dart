import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/journal_storage_service.dart';

class JournalProvider extends ChangeNotifier {
  final JournalStorageService _storageService = JournalStorageService();
  StreamSubscription<User?>? _authSubscription;

  List<JournalEntry> _journals = [];
  bool _isLoading = false;
  String? _errorMessage;

  JournalProvider() {
    _init();
  }

  List<JournalEntry> get journals => _journals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      loadJournals();
    });
  }

  Future<void> loadJournals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _journals = await _storageService.loadJournalEntries();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JournalProvider loadJournals error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveJournal(JournalEntry entry) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.saveJournalEntry(entry);
      await loadJournals();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JournalProvider saveJournal error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteJournal(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.deleteJournalEntry(id);
      await loadJournals();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JournalProvider deleteJournal error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String id) async {
    try {
      await _storageService.toggleBookmark(id);
      await loadJournals();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('JournalProvider toggleBookmark error: $e');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
