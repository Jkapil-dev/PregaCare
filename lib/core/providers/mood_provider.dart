import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/effective_uid.dart';
import 'user_provider.dart';

class MoodProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  UserProvider? _userProvider;

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

  void update(UserProvider userProvider) {
    final oldEffectiveUid = _userProvider == null ? null : (_userProvider!.isPartner ? _userProvider!.linkedMotherUid : _userProvider!.uid);
    final newEffectiveUid = userProvider.isPartner ? userProvider.linkedMotherUid : userProvider.uid;

    final oldHasPermission = _userProvider?.hasTrackerPermission ?? false;
    final newHasPermission = userProvider.hasTrackerPermission;

    _userProvider = userProvider;

    if (oldEffectiveUid != newEffectiveUid || oldHasPermission != newHasPermission) {
      if (newHasPermission && newEffectiveUid != null && newEffectiveUid.isNotEmpty) {
        loadMoods();
      } else {
        _moods = [];
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  String get _userId => EffectiveUidProvider.getEffectiveUid();

  Future<void> loadMoods() async {
    final hasPermission = _userProvider?.hasTrackerPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) {
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
          .doc(uid)
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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify moods.');
    }
    final hasPermission = _userProvider?.hasTrackerPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await _db
          .collection('users')
          .doc(uid)
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
