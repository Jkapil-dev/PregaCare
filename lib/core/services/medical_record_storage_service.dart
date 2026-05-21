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
        return _getMockRecords();
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final list = jsonList.map((json) => MedicalRecord.fromJson(json)).toList();
      list.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return list;
    } catch (e) {
      debugPrint('Failed to load medical records from prefs: $e');
      return _getMockRecords();
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

  /// Default mock records so the UI looks populated out-of-the-box
  List<MedicalRecord> _getMockRecords() {
    final today = DateTime.now();
    return [
      MedicalRecord(
        id: 'rec_1',
        fileName: 'Anomaly_Ultrasound_Scan.jpg',
        fileType: 'image',
        category: 'Ultrasounds',
        uploadDate: today.subtract(const Duration(days: 2)),
        filePath: '', // Mock: no actual file
        notes: 'Second trimester anomaly scan — all clear',
      ),
      MedicalRecord(
        id: 'rec_2',
        fileName: 'First_Trimester_Scan.jpg',
        fileType: 'image',
        category: 'Ultrasounds',
        uploadDate: today.subtract(const Duration(days: 90)),
        filePath: '',
        notes: 'Week 12 viability scan',
      ),
      MedicalRecord(
        id: 'rec_3',
        fileName: 'CBC_Report.pdf',
        fileType: 'pdf',
        category: 'Lab Reports',
        uploadDate: today.subtract(const Duration(days: 30)),
        filePath: '',
        notes: 'Complete Blood Count — results within normal range',
      ),
      MedicalRecord(
        id: 'rec_4',
        fileName: 'GTT_Report.pdf',
        fileType: 'pdf',
        category: 'Lab Reports',
        uploadDate: today.subtract(const Duration(days: 35)),
        filePath: '',
        notes: 'Glucose Tolerance Test — no gestational diabetes detected',
      ),
      MedicalRecord(
        id: 'rec_5',
        fileName: 'Dr_Sharma_Prescription.jpg',
        fileType: 'image',
        category: 'Prescriptions',
        uploadDate: today.subtract(const Duration(days: 15)),
        filePath: '',
        notes: 'OBGYN visit prescription for iron and calcium',
      ),
    ];
  }
}
