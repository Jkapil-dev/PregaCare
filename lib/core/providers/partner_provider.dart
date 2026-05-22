import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PartnerProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _partnerProfile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get partnerProfile => _partnerProfile;

  /// Load display details for the linked partner (Name, Email, etc.)
  Future<Map<String, dynamic>?> loadPartnerProfile(String partnerUid) async {
    _isLoading = true;
    _errorMessage = null;
    _partnerProfile = null;
    notifyListeners();

    try {
      final doc = await _db.collection('users').doc(partnerUid).get();
      if (doc.exists) {
        _partnerProfile = doc.data();
        notifyListeners();
        return _partnerProfile;
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('PartnerProvider: error loading partner profile: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update granular permissions in Firestore (called by Mother)
  Future<void> updatePermissions(String connectionId, Map<String, bool> permissions) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.collection('pregnancy_connections').doc(connectionId).update({
        'permissions': permissions,
      });
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('PartnerProvider: error updating permissions: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
