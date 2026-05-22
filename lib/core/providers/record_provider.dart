import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medical_record.dart';
import '../services/medical_record_storage_service.dart';
import '../utils/effective_uid.dart';
import 'user_provider.dart';

class RecordProvider extends ChangeNotifier {
  final MedicalRecordStorageService _storageService = MedicalRecordStorageService();
  StreamSubscription<User?>? _authSubscription;
  UserProvider? _userProvider;

  List<MedicalRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _cachedEffectiveUid;
  bool _cachedHasPermission = false;

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

  void update(UserProvider userProvider) {
    _userProvider = userProvider;

    final newEffectiveUid = userProvider.isPartner ? userProvider.linkedMotherUid : userProvider.uid;
    final newHasPermission = userProvider.hasTrackerPermission;

    if (_cachedEffectiveUid != newEffectiveUid || _cachedHasPermission != newHasPermission) {
      _cachedEffectiveUid = newEffectiveUid;
      _cachedHasPermission = newHasPermission;

      if (newHasPermission && newEffectiveUid != null && newEffectiveUid.isNotEmpty) {
        loadRecords();
      } else {
        _records = [];
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadRecords() async {
    final hasPermission = _userProvider?.hasTrackerPermission ?? true;
    final uid = EffectiveUidProvider.getEffectiveUid();
    if (!hasPermission || uid.isEmpty) {
      _records = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify medical records.');
    }
    final hasPermission = _userProvider?.hasTrackerPermission ?? true;
    if (!hasPermission) return;

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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify medical records.');
    }
    final hasPermission = _userProvider?.hasTrackerPermission ?? true;
    if (!hasPermission) return;

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
