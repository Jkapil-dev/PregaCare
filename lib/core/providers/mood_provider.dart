import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MoodProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  List<Map<String, dynamic>> _moods = [];
  bool _isLoading = false;
  String? _errorMessage;

  MoodProvider() {
    _init();
  }

  List<Map<String, dynamic>> get moods => _moods;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get latestMood {
    if (_moods.isEmpty) return '—';
    // Sort to make sure we get the newest date
    final sorted = List<Map<String, dynamic>>.from(_moods);
    sorted.sort((a, b) {
      final aDate = a['date'] as String? ?? '';
      final bDate = b['date'] as String? ?? '';
      return bDate.compareTo(aDate); // descending
    });
    return sorted.first['mood'] as String? ?? '—';
  }

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      loadMoods();
    });
  }

  Future<void> loadMoods() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _moods = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .get();

      _moods = snapshot.docs.map((doc) => doc.data()).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MoodProvider loadMoods error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveMood(String moodString) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .doc(todayStr)
          .set({
        'date': todayStr,
        'mood': moodString,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadMoods();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('MoodProvider saveMood error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
