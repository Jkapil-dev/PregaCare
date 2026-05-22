import 'package:firebase_auth/firebase_auth.dart';

/// A memory-cached utility class to resolve the target UID for pregnancy-related Firestore queries.
/// If the current user is a linked partner, this redirects queries to the mother's UID.
class EffectiveUidProvider {
  static String? _cachedUid;

  /// Update the active redirect target UID.
  static void update(String uid) {
    _cachedUid = uid;
  }

  /// Clear the cache (called on logout, connection state updates, etc.)
  static void clearCache() {
    _cachedUid = null;
  }

  /// Retrieve the current effective UID synchronously.
  static String getEffectiveUid() {
    if (_cachedUid != null && _cachedUid!.isNotEmpty) {
      return _cachedUid!;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  /// Retrieve the current effective UID asynchronously (for compatibility with async storage callers).
  static Future<String> getEffectiveUidAsync() async {
    return getEffectiveUid();
  }
}
