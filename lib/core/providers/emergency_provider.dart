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
import '../utils/effective_uid.dart';
import 'user_provider.dart';

class EmergencyProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _emergencyStateSubscription;
  UserProvider? _userProvider;

  List<EmergencyContact> _contacts = [];
  MedicalEmergencyInfo _medicalInfo = const MedicalEmergencyInfo();
  List<Hospital> _savedHospitals = [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSosTriggered = false;
  Map<String, dynamic>? _connectionEmergencyState;
  Timer? _alarmVibrationTimer;

  List<EmergencyContact> get contacts => _contacts;
  MedicalEmergencyInfo get medicalInfo => _medicalInfo;
  List<Hospital> get savedHospitals => _savedHospitals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSosTriggered => _isSosTriggered;
  Map<String, dynamic>? get connectionEmergencyState => _connectionEmergencyState;

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

  void _listenToConnectionEmergencyState(String connectionId) {
    _emergencyStateSubscription?.cancel();
    _emergencyStateSubscription = _db
        .collection('pregnancy_connections')
        .doc(connectionId)
        .collection('emergency_state')
        .doc('current')
        .snapshots()
        .listen((docSnap) {
      if (docSnap.exists) {
        _connectionEmergencyState = docSnap.data();
        debugPrint('EmergencyProvider: Connection emergency state synchronized: $_connectionEmergencyState');
        _cacheConnectionEmergencyState();
        notifyListeners();
      } else {
        _connectionEmergencyState = null;
        _cacheConnectionEmergencyState();
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('EmergencyProvider: Connection emergency state subscription error: $e');
    });
  }

  void update(UserProvider userProvider) {
    final oldEffectiveUid = _userProvider == null ? null : (_userProvider!.isPartner ? _userProvider!.linkedMotherUid : _userProvider!.uid);
    final newEffectiveUid = userProvider.isPartner ? userProvider.linkedMotherUid : userProvider.uid;

    final oldHasPermission = _userProvider?.hasEmergencyPermission ?? false;
    final newHasPermission = userProvider.hasEmergencyPermission;

    final oldConnectionId = _userProvider?.linkedConnectionId;
    final newConnectionId = userProvider.linkedConnectionId;

    _userProvider = userProvider;

    if (oldEffectiveUid != newEffectiveUid || oldHasPermission != newHasPermission) {
      if (newHasPermission && newEffectiveUid != null && newEffectiveUid.isNotEmpty) {
        loadAllEmergencyData();
      } else {
        _contacts = [];
        _medicalInfo = const MedicalEmergencyInfo();
        _savedHospitals = [];
        notifyListeners();
      }
    }

    if (oldConnectionId != newConnectionId || (_emergencyStateSubscription == null && newConnectionId != null && newConnectionId.isNotEmpty)) {
      _emergencyStateSubscription?.cancel();
      _emergencyStateSubscription = null;
      if (newConnectionId != null && newConnectionId.isNotEmpty) {
        _listenToConnectionEmergencyState(newConnectionId);
      } else {
        _connectionEmergencyState = null;
        notifyListeners();
      }
    }
  }

  String get _userId {
    return EffectiveUidProvider.getEffectiveUid();
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

      // Load Connection Emergency State
      final connectionEmergencyJson = prefs.getString('mc_connection_emergency_state');
      if (connectionEmergencyJson != null) {
        _connectionEmergencyState = jsonDecode(connectionEmergencyJson) as Map<String, dynamic>?;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('EmergencyProvider offline cache read error: $e');
    }
  }

  Future<void> _cacheConnectionEmergencyState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_connectionEmergencyState != null) {
        await prefs.setString('mc_connection_emergency_state', jsonEncode(_connectionEmergencyState));
      } else {
        await prefs.remove('mc_connection_emergency_state');
      }
    } catch (e) {
      debugPrint('EmergencyProvider cache connection emergency state error: $e');
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
    final hasPermission = _userProvider?.hasEmergencyPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) {
      _contacts = [];
      _medicalInfo = const MedicalEmergencyInfo();
      _savedHospitals = [];
      notifyListeners();
      return;
    }

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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify emergency contacts.');
    }
    final hasPermission = _userProvider?.hasEmergencyPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify emergency contacts.');
    }
    final hasPermission = _userProvider?.hasEmergencyPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify medical info.');
    }
    final hasPermission = _userProvider?.hasEmergencyPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify saved hospitals.');
    }
    final hasPermission = _userProvider?.hasEmergencyPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

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
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can modify saved hospitals.');
    }
    final hasPermission = _userProvider?.hasEmergencyPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

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

  Future<void> updateEmergencyLocation(double lat, double lng) async {
    final uid = _userProvider?.isPartner == true ? _userProvider?.linkedMotherUid : _userProvider?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      await _db.collection('users').doc(uid).update({
        'sosLatitude': lat,
        'sosLongitude': lng,
      });
      debugPrint('SOS position updated in Firestore user doc for $uid');
    } catch (e) {
      debugPrint('Error updating SOS position in user doc: $e');
    }

    final connectionId = _userProvider?.linkedConnectionId;
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await _db
            .collection('pregnancy_connections')
            .doc(connectionId)
            .collection('emergency_state')
            .doc('current')
            .set({
          'location': GeoPoint(lat, lng),
          'latitude': lat,
          'longitude': lng,
          'mapsUrl': 'https://maps.google.com/?q=$lat,$lng',
          'locationTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Emergency position updated in connection $connectionId');
      } catch (e) {
        debugPrint('Error updating connection emergency position: $e');
      }
    }
  }

  Future<void> refreshSOSLocation(BuildContext context) async {
    final hasPermission = _userProvider?.hasEmergencyPermission ?? true;
    final uid = _userId;
    if (!hasPermission || uid.isEmpty) return;

    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final position = await locationProvider.fetchLocation(context);
      if (position != null) {
        await updateEmergencyLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Error refreshing SOS location: $e');
    }
  }

  Future<void> triggerSOSAlert(BuildContext context) async {
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can trigger SOS alerts.');
    }
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

    // 4. Fetch GPS and update Firestore Mother & Connection documents
    double? lat;
    double? lng;
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final position = await locationProvider.fetchLocation(context);
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (e) {
      debugPrint('Error getting location during SOS trigger: $e');
    }

    final uid = _userId;
    try {
      await _db.collection('users').doc(uid).update({
        'sosActive': true,
        'sosLatitude': lat,
        'sosLongitude': lng,
        'sosTriggeredAt': FieldValue.serverTimestamp(),
      });
      debugPrint('SOS state updated in Firestore for $uid');
    } catch (e) {
      debugPrint('Error updating SOS state in Firestore: $e');
    }

    // Write to connection emergency subcollection
    final connectionId = _userProvider?.linkedConnectionId;
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await _db
            .collection('pregnancy_connections')
            .doc(connectionId)
            .collection('emergency_state')
            .doc('current')
            .set({
          'active': true,
          'triggeredBy': 'mother',
          'triggeredAt': FieldValue.serverTimestamp(),
          'location': (lat != null && lng != null) ? GeoPoint(lat, lng) : null,
          'latitude': lat,
          'longitude': lng,
          'mapsUrl': (lat != null && lng != null) ? 'https://maps.google.com/?q=$lat,$lng' : null,
          'locationTimestamp': FieldValue.serverTimestamp(),
          'resolved': false,
          'emergencyLevel': 'critical',
        });
        debugPrint('Emergency state created in connection $connectionId');
      } catch (e) {
        debugPrint('Error setting connection emergency state: $e');
      }
    }

    // 5. Native Location Sharing
    if (lat != null && lng != null && context.mounted) {
      try {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        unawaited(locationProvider.shareLocation(context));
      } catch (e) {
        debugPrint('Error sharing location: $e');
      }
    }
  }

  Future<void> resolveEmergency() async {
    _isSosTriggered = false;
    _alarmVibrationTimer?.cancel();
    _alarmVibrationTimer = null;
    notifyListeners();

    final uid = _userProvider?.isPartner == true ? _userProvider?.linkedMotherUid : _userProvider?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await _db.collection('users').doc(uid).update({
          'sosActive': false,
          'sosLatitude': FieldValue.delete(),
          'sosLongitude': FieldValue.delete(),
          'sosTriggeredAt': FieldValue.delete(),
        });
        debugPrint('SOS state cleared in Firestore user doc for $uid');
      } catch (e) {
        debugPrint('Error clearing SOS state in Firestore user doc: $e');
      }
    }

    final connectionId = _userProvider?.linkedConnectionId;
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await _db
            .collection('pregnancy_connections')
            .doc(connectionId)
            .collection('emergency_state')
            .doc('current')
            .set({
          'active': false,
          'resolved': true,
          'resolvedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('Emergency resolved in connection $connectionId');
      } catch (e) {
        debugPrint('Error resolving connection emergency state: $e');
      }
    }
  }

  Future<void> cancelSOSAlert() async {
    if (_userProvider?.role == 'partner') {
      throw Exception('Only Mother accounts can cancel SOS alerts.');
    }
    await resolveEmergency();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emergencyStateSubscription?.cancel();
    _alarmVibrationTimer?.cancel();
    super.dispose();
  }
}
