import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medical_record.dart';

class MedicalRecordStorageService {
  static const String _keyRecords = 'maatricare_medical_records_v1';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Copies the picked file into the app's documents directory for persistent local storage.
  /// Returns the saved file path. On web, returns the original path as-is.
  Future<String> saveFileLocally(String sourcePath, String fileName) async {
    if (kIsWeb) return sourcePath; // Web: no local file copy needed

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordsDir = Directory(p.join(appDir.path, 'maatricare_records'));
      if (!recordsDir.existsSync()) {
        recordsDir.createSync(recursive: true);
      }
      // Avoid filename collisions by prepending timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeFileName = '${timestamp}_$fileName';
      final destPath = p.join(recordsDir.path, safeFileName);
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Failed to copy file locally: $e');
      return sourcePath; // Fallback: use original
    }
  }

  /// Save a new record or update an existing one
  Future<void> saveRecord(MedicalRecord record) async {
    final list = await loadRecords();
    final existingIndex = list.indexWhere((r) => r.id == record.id);
    if (existingIndex != -1) {
      list[existingIndex] = record;
    } else {
      list.insert(0, record);
    }
    
    // Update SharedPreferences cache first
    await _saveToPrefs(list);

    // Save to Firestore if authenticated
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('MedicalRecordStorageService: Syncing medical record ${record.id} to Firestore under users/$uid/records');
        await _db
            .collection('users')
            .doc(uid)
            .collection('records')
            .doc(record.id)
            .set(record.toJson());
      } catch (e) {
        debugPrint('MedicalRecordStorageService: Firestore sync error: $e');
      }
    }
  }

  /// Load all persisted medical records, sorted newest first
  Future<List<MedicalRecord>> loadRecords() async {
    final uid = _uid;
    if (uid != null) {
      try {
        debugPrint('MedicalRecordStorageService: Fetching records from Firestore under users/$uid/records');
        final snapshot = await _db
            .collection('users')
            .doc(uid)
            .collection('records')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs
              .map((doc) => MedicalRecord.fromJson(doc.data()))
              .toList();
          list.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
          
          // Sync local SharedPreferences cache
          await _saveToPrefs(list);
          return list;
        }
      } catch (e) {
        debugPrint('MedicalRecordStorageService: Failed to fetch records from Firestore, falling back to local cache: $e');
      }
    }

    // Fallback/offline/unauthenticated local load
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyRecords);
      if (jsonString == null) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final list = jsonList.map((json) => MedicalRecord.fromJson(json)).toList();
      list.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return list;
    } catch (e) {
      debugPrint('Failed to load medical records from prefs: $e');
      return [];
    }
  }

  /// Delete a record and optionally delete its local file copy
  Future<void> deleteRecord(String id) async {
    final list = await loadRecords();
    final index = list.indexWhere((r) => r.id == id);
    if (index != -1) {
      // Try deleting local file
      if (!kIsWeb) {
        try {
          final file = File(list[index].filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Could not delete local file: $e');
        }
      }
      list.removeAt(index);
      await _saveToPrefs(list);

      final uid = _uid;
      if (uid != null) {
        try {
          debugPrint('MedicalRecordStorageService: Deleting record $id from Firestore');
          await _db
              .collection('users')
              .doc(uid)
              .collection('records')
              .doc(id)
              .delete();
        } catch (e) {
          debugPrint('MedicalRecordStorageService: Firestore delete error: $e');
        }
      }
    }
  }

  /// Persist to SharedPreferences
  Future<void> _saveToPrefs(List<MedicalRecord> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(list.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRecords, jsonString);
  }
}
