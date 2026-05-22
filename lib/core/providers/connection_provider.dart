import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/effective_uid.dart';

class ConnectionProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _generateInviteCode() {
    final rand = math.Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final codeChars = List.generate(6, (index) => chars[rand.nextInt(chars.length)]);
    return 'MAT-${codeChars.join()}';
  }

  /// Create a pending invitation code for a mother
  Future<String> createInvitation(String motherUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if mother already has an active connection
      final existingActive = await _db
          .collection('pregnancy_connections')
          .where('motherUid', isEqualTo: motherUid)
          .where('status', isEqualTo: 'active')
          .where('active', isEqualTo: true)
          .get();

      if (existingActive.docs.isNotEmpty) {
        throw Exception('You already have an active partner connection.');
      }

      // Check if mother already has a pending connection, and if so, revoke it first
      final existingPending = await _db
          .collection('pregnancy_connections')
          .where('motherUid', isEqualTo: motherUid)
          .where('status', isEqualTo: 'pending')
          .where('active', isEqualTo: true)
          .get();

      final batchCleanup = _db.batch();
      for (var doc in existingPending.docs) {
        batchCleanup.update(doc.reference, {
          'status': 'disconnected',
          'active': false,
        });
      }
      await batchCleanup.commit();

      final code = _generateInviteCode();
      final docRef = _db.collection('pregnancy_connections').doc();
      final connectionData = {
        'id': docRef.id,
        'motherUid': motherUid,
        'partnerUid': '',
        'connectionCode': code,
        'status': 'pending',
        'permissions': {
          'viewTracker': true,
          'viewEmergency': true,
          'viewReminders': true,
          'viewNotifications': true,
          'appointments': true,
          'medicines': true,
          'reminders': true,
          'babyUpdates': true,
          'emergencyAlerts': true,
        },
        'linkedUsers': [motherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      };

      final batchCreate = _db.batch();
      batchCreate.set(docRef, connectionData);

      // Also update Mother's user profile with the linkedConnectionId so she can listen to it
      batchCreate.update(_db.collection('users').doc(motherUid), {
        'linkedConnectionId': docRef.id,
      });

      await batchCreate.commit();
      return code;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Join an invitation using an invite code
  Future<void> joinConnection(String code, String partnerUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the pending connection with the code
      final query = await _db
          .collection('pregnancy_connections')
          .where('connectionCode', isEqualTo: code.trim().toUpperCase())
          .where('status', isEqualTo: 'pending')
          .where('active', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Invalid or expired invitation code.');
      }

      final connectionDoc = query.docs.first;
      final connectionId = connectionDoc.id;
      final motherUid = connectionDoc.data()['motherUid'] as String;

      if (motherUid == partnerUid) {
        throw Exception('You cannot link to your own account.');
      }

      // Check if partner is already linked to another connection
      final partnerActive = await _db
          .collection('pregnancy_connections')
          .where('partnerUid', isEqualTo: partnerUid)
          .where('status', isEqualTo: 'active')
          .where('active', isEqualTo: true)
          .get();

      if (partnerActive.docs.isNotEmpty) {
        throw Exception('You are already linked to a pregnancy connection. Please disconnect first.');
      }

      final batch = _db.batch();

      // 1. Update Connection status
      batch.update(connectionDoc.reference, {
        'partnerUid': partnerUid,
        'status': 'active',
        'linkedUsers': [motherUid, partnerUid],
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Partner profile
      batch.update(_db.collection('users').doc(partnerUid), {
        'role': 'partner',
        'linkedMotherUid': motherUid,
        'linkedConnectionId': connectionId,
        'onboardingCompleted': true,
      });

      // 3. Update Mother profile
      batch.update(_db.collection('users').doc(motherUid), {
        'linkedPartnerUid': partnerUid,
      });

      await batch.commit();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Revoke a pending invitation
  Future<void> revokeInvitation(String motherUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pendingDocs = await _db
          .collection('pregnancy_connections')
          .where('motherUid', isEqualTo: motherUid)
          .where('status', isEqualTo: 'pending')
          .where('active', isEqualTo: true)
          .get();

      final batch = _db.batch();

      for (var doc in pendingDocs.docs) {
        batch.update(doc.reference, {
          'status': 'disconnected',
          'active': false,
        });
      }

      // Clear the connection ID on mother's profile
      batch.update(_db.collection('users').doc(motherUid), {
        'linkedConnectionId': FieldValue.delete(),
        'linkedPartnerUid': FieldValue.delete(),
      });

      await batch.commit();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Disconnect an active connection
  Future<void> disconnect({
    required String connectionId,
    required String motherUid,
    required String partnerUid,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = _db.batch();

      // 1. Update connection document
      batch.update(_db.collection('pregnancy_connections').doc(connectionId), {
        'status': 'disconnected',
        'active': false,
        'disconnectedAt': FieldValue.serverTimestamp(),
      });

      // 2. Reset mother user fields
      batch.update(_db.collection('users').doc(motherUid), {
        'linkedPartnerUid': FieldValue.delete(),
        'linkedConnectionId': FieldValue.delete(),
      });

      // 3. Reset partner user fields
      batch.update(_db.collection('users').doc(partnerUid), {
        'role': 'mother', // resets partner back to mother role (independent view)
        'linkedMotherUid': FieldValue.delete(),
        'linkedConnectionId': FieldValue.delete(),
      });

      await batch.commit();

      // Clear EffectiveUidProvider cache
      EffectiveUidProvider.clearCache();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
