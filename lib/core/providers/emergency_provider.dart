import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';
import '../models/medical_emergency_info.dart';
import '../models/hospital.dart';
import '../services/notification_service.dart';
import 'location_provider.dart';

class EmergencyProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  List<EmergencyContact> _contacts = [];
  MedicalEmergencyInfo _medicalInfo = const MedicalEmergencyInfo();
  List<Hospital> _savedHospitals = [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSosTriggered = false;
  Timer? _alarmVibrationTimer;

  List<EmergencyContact> get contacts => _contacts;
  MedicalEmergencyInfo get medicalInfo => _medicalInfo;
  List<Hospital> get savedHospitals => _savedHospitals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSosTriggered => _isSosTriggered;

  EmergencyProvider() {
    _init();
  }

  void _init() {
    // 1. Instantly load cached offline data from SharedPreferences first
    _loadCachedData();

    // 2. Setup auth listener for dynamic Firestore syncing
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        loadAllEmergencyData();
      } else {
        _contacts = [];
        _medicalInfo = const MedicalEmergencyInfo();
        _savedHospitals = [];
        notifyListeners();
      }
    });
  }

  String? get _userId {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  // ==========================================
  // OFFLINE CACHING ACTIONS
  // ==========================================

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Contacts
      final contactsJson = prefs.getString('mc_emergency_contacts');
      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        _contacts = decoded.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
      }

      // Load Medical Info
      final medicalJson = prefs.getString('mc_medical_emergency_info');
      if (medicalJson != null) {
        _medicalInfo = MedicalEmergencyInfo.fromJson(jsonDecode(medicalJson) as Map<String, dynamic>);
      }

      // Load Saved Hospitals
      final hospitalsJson = prefs.getString('mc_saved_hospitals');
      if (hospitalsJson != null) {
        final List<dynamic> decoded = jsonDecode(hospitalsJson);
        _savedHospitals = decoded.map((e) => Hospital.fromJson(e as Map<String, dynamic>)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('EmergencyProvider offline cache read error: $e');
    }
  }

  Future<void> _cacheContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _contacts.map((e) => e.toJson()).toList();
      await prefs.setString('mc_emergency_contacts', jsonEncode(list));
    } catch (e) {
      debugPrint('EmergencyProvider cache contacts error: $e');
    }
  }

  Future<void> _cacheMedicalInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mc_medical_emergency_info', jsonEncode(_medicalInfo.toJson()));
    } catch (e) {
      debugPrint('EmergencyProvider cache medical info error: $e');
    }
  }

  Future<void> _cacheHospitals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedHospitals.map((e) => e.toJson()).toList();
      await prefs.setString('mc_saved_hospitals', jsonEncode(list));
    } catch (e) {
      debugPrint('EmergencyProvider cache hospitals error: $e');
    }
  }

  // ==========================================
  // FIRESTORE SYNC SYNC ACTIONS
  // ==========================================

  Future<void> loadAllEmergencyData() async {
    final uid = _userId;
    if (uid == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load Contacts from Firestore
      final contactsSnap = await _db.collection('users').doc(uid).collection('emergency_contacts').get();
      _contacts = contactsSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return EmergencyContact.fromJson(data);
      }).toList();
      // Sort priority (1 primary first)
      _contacts.sort((a, b) => a.priority.compareTo(b.priority));
      await _cacheContacts();

      // Load Medical Emergency Info
      final medicalDoc = await _db.collection('users').doc(uid).collection('medical_emergency_info').doc('profile').get();
      if (medicalDoc.exists && medicalDoc.data() != null) {
        _medicalInfo = MedicalEmergencyInfo.fromJson(medicalDoc.data()!);
      } else {
        _medicalInfo = const MedicalEmergencyInfo();
      }
      await _cacheMedicalInfo();

      // Load Saved Hospitals
      final hospitalsSnap = await _db.collection('users').doc(uid).collection('saved_hospitals').get();
      _savedHospitals = hospitalsSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Hospital.fromJson(data);
      }).toList();
      await _cacheHospitals();

    } catch (e) {
      debugPrint('EmergencyProvider Firestore loading error: $e. Falling back to cached state.');
      _errorMessage = 'Failed to update from database. Viewing offline records.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // EMERGENCY CONTACT CRUD OPERATIONS
  // ==========================================

  Future<void> saveContact(EmergencyContact contact) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final docRef = _db.collection('users').doc(uid).collection('emergency_contacts').doc(contact.id.isEmpty ? null : contact.id);
      final finalContact = contact.copyWith(id: docRef.id);
      
      // Update Firestore
      await docRef.set(finalContact.toJson());

      // Update Local State
      final index = _contacts.indexWhere((c) => c.id == finalContact.id);
      if (index != -1) {
        _contacts[index] = finalContact;
      } else {
        _contacts.add(finalContact);
      }
      _contacts.sort((a, b) => a.priority.compareTo(b.priority));
      notifyListeners();

      // Cache locally
      await _cacheContacts();
    } catch (e) {
      debugPrint('EmergencyProvider saveContact error: $e');
      rethrow;
    }
  }

  Future<void> deleteContact(String contactId) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).collection('emergency_contacts').doc(contactId).delete();

      _contacts.removeWhere((c) => c.id == contactId);
      notifyListeners();

      await _cacheContacts();
    } catch (e) {
      debugPrint('EmergencyProvider deleteContact error: $e');
      rethrow;
    }
  }

  // ==========================================
  // MEDICAL EMERGENCY INFO ACTIONS
  // ==========================================

  Future<void> saveMedicalInfo(MedicalEmergencyInfo info) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).collection('medical_emergency_info').doc('profile').set(info.toJson());

      _medicalInfo = info;
      notifyListeners();

      await _cacheMedicalInfo();
    } catch (e) {
      debugPrint('EmergencyProvider saveMedicalInfo error: $e');
      rethrow;
    }
  }

  // ==========================================
  // HOSPITALS CRUD OPERATIONS
  // ==========================================

  Future<void> saveHospital(Hospital hospital) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final docRef = _db.collection('users').doc(uid).collection('saved_hospitals').doc(hospital.id.isEmpty ? null : hospital.id);
      final finalHospital = hospital.copyWith(id: docRef.id, isPreferred: true);

      await docRef.set(finalHospital.toJson());

      final index = _savedHospitals.indexWhere((h) => h.id == finalHospital.id);
      if (index != -1) {
        _savedHospitals[index] = finalHospital;
      } else {
        _savedHospitals.add(finalHospital);
      }
      notifyListeners();

      await _cacheHospitals();
    } catch (e) {
      debugPrint('EmergencyProvider saveHospital error: $e');
      rethrow;
    }
  }

  Future<void> deleteHospital(String hospitalId) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _db.collection('users').doc(uid).collection('saved_hospitals').doc(hospitalId).delete();

      _savedHospitals.removeWhere((h) => h.id == hospitalId);
      notifyListeners();

      await _cacheHospitals();
    } catch (e) {
      debugPrint('EmergencyProvider deleteHospital error: $e');
      rethrow;
    }
  }

  // ==========================================
  // SOS EMERGENCY ALARM ACTIONS
  // ==========================================

  Future<void> triggerSOSAlert(BuildContext context) async {
    if (_isSosTriggered) return;
    _isSosTriggered = true;
    notifyListeners();

    // 1. Show high-priority emergency notification
    try {
      final notificationService = NotificationService();
      await notificationService.showEmergencySOSNotification();
    } catch (e) {
      debugPrint('EmergencyProvider notification error: $e');
    }

    // 2. Start continuous vibration loop (periodic haptic feedback calls)
    _alarmVibrationTimer?.cancel();
    _alarmVibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      HapticFeedback.vibrate();
    });

    // 3. Automated dialing: Dial primary contact if exists, otherwise fallback to ambulance (108)
    String phoneNumberToDial = '108';
    if (_contacts.isNotEmpty) {
      phoneNumberToDial = _contacts.first.phone;
    }

    if (phoneNumberToDial.isNotEmpty) {
      try {
        final url = Uri.parse('tel:$phoneNumberToDial');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          debugPrint('Could not launch dialing url for: $phoneNumberToDial');
        }
      } catch (e) {
        debugPrint('Error launching dial url: $e');
      }
    }

    // 4. Gather GPS and trigger native location sharing
    if (context.mounted) {
      try {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        unawaited(locationProvider.shareLocation(context));
      } catch (e) {
        debugPrint('Error getting LocationProvider or sharing location: $e');
      }
    }
  }

  void cancelSOSAlert() {
    _isSosTriggered = false;
    _alarmVibrationTimer?.cancel();
    _alarmVibrationTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _alarmVibrationTimer?.cancel();
    super.dispose();
  }
}
