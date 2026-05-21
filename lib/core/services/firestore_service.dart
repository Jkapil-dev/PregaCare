import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/medicine.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all medicines for a specific userId
  Future<List<Medicine>> getMedicines(String userId) async {
    try {
      debugPrint('FirestoreService: Loading medicines for user $userId');
      final querySnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure the doc ID is copied to model ID
        data['id'] = doc.id;
        return Medicine.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('FirestoreService Error in getMedicines: $e');
      rethrow;
    }
  }

  /// Save or update a medicine document
  Future<void> saveMedicine(String userId, Medicine medicine) async {
    try {
      debugPrint('FirestoreService: Saving medicine ${medicine.id} for user $userId');
      
      final data = medicine.toJson();
      data['userId'] = userId;
      
      // Store dates as ISO strings in the document, which match the Medicine.toJson()
      // format and parse perfectly in _parseDateTime
      await _db
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc(medicine.id)
          .set(data);
      
      debugPrint('FirestoreService: Successfully saved medicine ${medicine.id}');
    } catch (e) {
      debugPrint('FirestoreService Error in saveMedicine: $e');
      rethrow;
    }
  }

  /// Delete a medicine document
  Future<void> deleteMedicine(String userId, String id) async {
    try {
      debugPrint('FirestoreService: Deleting medicine $id for user $userId');
      await _db
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc(id)
          .delete();
      debugPrint('FirestoreService: Successfully deleted medicine $id');
    } catch (e) {
      debugPrint('FirestoreService Error in deleteMedicine: $e');
      rethrow;
    }
  }

  /// Update adherence logs for a specific medicine document
  Future<void> updateAdherence(
    String userId,
    String medicineId,
    Map<String, Map<String, String>> adherenceLogs,
  ) async {
    try {
      debugPrint('FirestoreService: Updating adherence for medicine $medicineId');
      await _db
          .collection('users')
          .doc(userId)
          .collection('medicines')
          .doc(medicineId)
          .update({
        'adherenceLogs': adherenceLogs,
      });
      debugPrint('FirestoreService: Successfully updated adherence');
    } catch (e) {
      debugPrint('FirestoreService Error in updateAdherence: $e');
      rethrow;
    }
  }
}
