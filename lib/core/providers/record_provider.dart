import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medical_record.dart';
import '../services/medical_record_storage_service.dart';

class RecordProvider extends ChangeNotifier {
  final MedicalRecordStorageService _storageService = MedicalRecordStorageService();
  StreamSubscription<User?>? _authSubscription;

  List<MedicalRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  RecordProvider() {
    _init();
  }

  List<MedicalRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      loadRecords();
    });
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _storageService.loadRecords();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('RecordProvider loadRecords error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveRecord(MedicalRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.saveRecord(record);
      await loadRecords();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('RecordProvider saveRecord error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.deleteRecord(id);
      await loadRecords();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('RecordProvider deleteRecord error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> saveFileLocally(String sourcePath, String fileName) async {
    return await _storageService.saveFileLocally(sourcePath, fileName);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
