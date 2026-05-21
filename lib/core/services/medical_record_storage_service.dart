import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/medical_record.dart';

class MedicalRecordStorageService {
  static const String _keyRecords = 'maatricare_medical_records_v1';

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
    await _saveToPrefs(list);
  }

  /// Load all persisted medical records, sorted newest first
  Future<List<MedicalRecord>> loadRecords() async {
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
      debugPrint('Failed to load medical records: $e');
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
