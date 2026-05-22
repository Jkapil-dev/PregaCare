import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for Firebase Authentication and initial user database records.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Expose user authentication state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Get the currently authenticated user (null if signed out)
  User? get currentUser => _auth.currentUser;

  /// Sign up a new user with email and password, creating their Firestore document.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    String? displayName,
  }) async {
    try {
      debugPrint('AuthService: Registering new user with email: $email, role: $role');
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        // Update display name in Firebase Auth
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
          await user.reload();
        }

        // Create the corresponding document in Firestore: users/{uid}
        await _createFirestoreUserDocument(user, role: role, displayName: displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException during signup: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: General error during signup: $e');
      rethrow;
    }
  }

  /// Sign in an existing user with email and password, ensuring Firestore profile document exists.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Logging in user: $email');
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        // Verify Firestore profile exists; create it if missing for some reason
        await _ensureFirestoreUserDocumentExists(user);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException during login: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: General error during login: $e');
      rethrow;
    }
  }

  /// Sign out the current user.
  Future<void> logout() async {
    try {
      debugPrint('AuthService: Signing out user: ${currentUser?.email}');
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService: Error during logout: $e');
      rethrow;
    }
  }

  /// Helper to create a user's Firestore document at users/{uid}
  Future<void> _createFirestoreUserDocument(User user, {required String role, String? displayName}) async {
    final docRef = _db.collection('users').doc(user.uid);
    
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName ?? user.displayName ?? '',
      'role': role,
      'linkedConnectionId': '',
      'linkedPartnerUid': '',
      'linkedMotherUid': '',
      'onboardingCompleted': role == 'partner',
      'createdAt': FieldValue.serverTimestamp(),
      'pregnancyWeek': 0,
      'trimester': 1,
    };

    debugPrint('AuthService: Creating Firestore document at users/${user.uid} with role: $role');
    await docRef.set(userData, SetOptions(merge: true));
  }

  /// Helper to ensure the Firestore document exists, creating it if it doesn't.
  Future<void> _ensureFirestoreUserDocumentExists(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      debugPrint('AuthService: Firestore document users/${user.uid} missing. Re-creating with default role "mother".');
      await _createFirestoreUserDocument(user, role: 'mother');
    } else {
      final data = docSnapshot.data();
      if (data == null || !data.containsKey('role') || data['role'] == null || (data['role'] as String).isEmpty) {
        debugPrint('AuthService: Firestore document users/${user.uid} exists but missing "role". Merging "mother" role.');
        await docRef.set({
          'role': 'mother',
          'linkedConnectionId': data?['linkedConnectionId'] ?? '',
          'linkedPartnerUid': data?['linkedPartnerUid'] ?? '',
          'linkedMotherUid': data?['linkedMotherUid'] ?? '',
          'onboardingCompleted': data?['onboardingCompleted'] ?? false,
        }, SetOptions(merge: true));
      }
    }
  }
}
