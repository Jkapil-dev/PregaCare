import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Centralized state provider for User Profile details fetched from Firestore.
class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  UserProvider() {
    _init();
  }

  // --- Getters ---
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isOnboardingCompleted {
    if (_profile == null) return false;
    return _profile!['onboardingCompleted'] == true;
  }

  String get uid => _profile?['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  String get displayName => _profile?['displayName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
  String get email => _profile?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';

  int get pregnancyWeek {
    final lmpStr = _profile?['lmpDate'];
    if (lmpStr != null) {
      final lmp = DateTime.tryParse(lmpStr);
      if (lmp != null) {
        final diffDays = DateTime.now().difference(lmp).inDays;
        final calcWeek = diffDays ~/ 7;
        return calcWeek >= 0 ? calcWeek : 0;
      }
    }
    return _profile?['pregnancyWeek'] ?? 0;
  }

  int get trimester {
    final week = pregnancyWeek;
    if (week <= 13) return 1;
    if (week <= 26) return 2;
    return 3;
  }

  double get progress {
    final week = pregnancyWeek;
    if (week <= 0) return 0.0;
    if (week >= 40) return 1.0;
    return week / 40.0;
  }

  String get babySize {
    final week = pregnancyWeek;
    if (week <= 4) return 'Poppy seed 🔴';
    if (week <= 8) return 'Raspberry 🍓';
    if (week <= 12) return 'Lime 🍋';
    if (week <= 16) return 'Avocado 🥑';
    if (week <= 20) return 'Banana 🍌';
    if (week <= 24) return 'Corn on the cob 🌽';
    if (week <= 28) return 'Eggplant 🍆';
    if (week <= 32) return 'Squash 🍊';
    if (week <= 36) return 'Honeydew melon 🍈';
    return 'Watermelon 🍉';
  }

  double get weight {
    final wt = _profile?['weight'];
    if (wt is num) return wt.toDouble();
    return 0.0;
  }

  String get dueDateString {
    final dateStr = _profile?['dueDate'];
    if (dateStr != null) {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        return "${dt.day}/${dt.month}/${dt.year}";
      }
    }
    return '';
  }

  /// Initialize Auth Listener to fetch user profile when authenticated
  void _init() {
    debugPrint('UserProvider: Initializing auth state listener');
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('UserProvider: User logged in (${user.uid}). Loading Firestore profile.');
        await fetchProfile(user.uid);
      } else {
        debugPrint('UserProvider: User logged out. Clearing profile.');
        _profile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Fetch Firestore document users/{uid}
  Future<void> fetchProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _profile = doc.data();
        debugPrint('UserProvider: Profile loaded. onboardingCompleted = $isOnboardingCompleted');
      } else {
        _profile = null;
        debugPrint('UserProvider: Profile document does not exist for $uid');
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('UserProvider fetchProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save or Update Firestore profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'No authenticated user found.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updateData = Map<String, dynamic>.from(data);
      updateData['uid'] = user.uid;
      updateData['email'] = user.email;
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      await fetchProfile(user.uid);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('UserProvider updateProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload the profile manually
  Future<void> refreshProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await fetchProfile(user.uid);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
