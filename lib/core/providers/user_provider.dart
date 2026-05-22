import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/effective_uid.dart';
import '../services/notification_service.dart';

/// Centralized state provider for User Profile details fetched from Firestore.
class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _motherDocSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _connectionDocSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _motherNotificationSettingsSubscription;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _motherProfile;
  Map<String, dynamic>? _connectionData;
  Map<String, dynamic>? _motherNotificationSettings;
  bool _isLoading = true;
  bool _hasFetched = false;
  String? _errorMessage;
  Timer? _partnerSosVibrationTimer;

  UserProvider() {
    _init();
  }

  // --- Getters ---
  Map<String, dynamic>? get profile => _profile;
  Map<String, dynamic>? get motherProfile => _motherProfile;
  Map<String, dynamic>? get motherNotificationSettings => _motherNotificationSettings;
  bool get isLoading {
    final hasUser = FirebaseAuth.instance.currentUser != null;
    if (hasUser && !_hasFetched) {
      return true;
    }
    return _isLoading;
  }
  String? get errorMessage => _errorMessage;

  bool get isOnboardingCompleted {
    if (_profile == null) return false;
    return _profile!['onboardingCompleted'] == true;
  }

  String get uid => _profile?['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  String get displayName => _profile?['displayName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
  String get email => _profile?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';

  // --- Personal Info Getters ---
  String get phoneNumber => _profile?['phoneNumber'] ?? '';
  int get age {
    final a = _profile?['age'];
    if (a is int) return a;
    return 0;
  }
  double get height {
    final h = _profile?['height'];
    if (h is num) return h.toDouble();
    return 0.0;
  }

  // --- Partner Role & Linking Getters ---
  String get role => _profile?['role'] ?? '';
  bool get isPartner => role == 'partner';
  bool get isMother => role == 'mother';
  bool get isLinked => _profile?['linkedConnectionId'] != null && (_profile?['linkedConnectionId'] as String).isNotEmpty;
  String? get linkedPartnerUid => _profile?['linkedPartnerUid'] as String?;
  String? get linkedMotherUid => _profile?['linkedMotherUid'] as String?;
  String? get linkedConnectionId => _profile?['linkedConnectionId'] as String?;
  Map<String, dynamic>? get connectionData => _connectionData;

  Map<String, bool> get permissions {
    if (_connectionData == null) return {};
    final raw = _connectionData!['permissions'];
    if (raw is Map) {
      return Map<String, bool>.from(raw.map((k, v) => MapEntry(k.toString(), v == true)));
    }
    return {};
  }

  bool get hasTrackerPermission {
    if (isMother) return true;
    return permissions['viewTracker'] ?? false;
  }

  bool get hasEmergencyPermission {
    if (isMother) return true;
    return permissions['viewEmergency'] ?? false;
  }

  bool get hasRemindersPermission {
    if (isMother) return true;
    return permissions['reminders'] ?? permissions['viewReminders'] ?? false;
  }

  bool get hasNotificationsPermission {
    if (isMother) return true;
    return permissions['viewNotifications'] ?? false;
  }

  bool get hasAppointmentsPermission {
    if (isMother) return true;
    return permissions['appointments'] ?? permissions['viewReminders'] ?? false;
  }

  bool get hasMedicinesPermission {
    if (isMother) return true;
    return permissions['medicines'] ?? permissions['viewTracker'] ?? false;
  }

  bool get hasBabyUpdatesPermission {
    if (isMother) return true;
    return permissions['babyUpdates'] ?? permissions['viewTracker'] ?? false;
  }

  bool get hasEmergencyAlertsPermission {
    if (isMother) return true;
    return permissions['emergencyAlerts'] ?? permissions['viewEmergency'] ?? false;
  }

  Map<String, dynamic>? get _pregnancyProfileMap => (isPartner && _motherProfile != null) ? _motherProfile : _profile;

  // --- Pregnancy Profile Getters ---
  String get bloodGroup => _pregnancyProfileMap?['bloodGroup'] ?? '';
  String get doctorName => _pregnancyProfileMap?['doctorName'] ?? '';
  String get hospitalName => _pregnancyProfileMap?['hospitalName'] ?? '';
  String get lmpDateString => _pregnancyProfileMap?['lmpDate'] ?? '';
  bool get isFirstPregnancy => _pregnancyProfileMap?['isFirstPregnancy'] ?? true;
  int get pregnancyNumber => _pregnancyProfileMap?['pregnancyNumber'] ?? 1;

  // --- Medical Info Getters ---
  List<String> get allergies {
    if (!hasEmergencyPermission) return [];
    final list = _pregnancyProfileMap?['allergies'];
    if (list is List) return List<String>.from(list);
    return [];
  }
  List<String> get conditions {
    if (!hasEmergencyPermission) return [];
    final list = _pregnancyProfileMap?['conditions'];
    if (list is List) return List<String>.from(list);
    return [];
  }
  String get emergencyContactName {
    if (!hasEmergencyPermission) return '';
    return _pregnancyProfileMap?['emergencyContactName'] ?? '';
  }
  String get emergencyContactPhone {
    if (!hasEmergencyPermission) return '';
    return _pregnancyProfileMap?['emergencyContactPhone'] ?? '';
  }
  String get medications {
    if (!hasTrackerPermission) return '';
    return _pregnancyProfileMap?['medications'] ?? '';
  }
  String get healthNotes {
    if (!hasEmergencyPermission) return '';
    return _pregnancyProfileMap?['healthNotes'] ?? '';
  }

  // --- Settings Getters ---
  Map<String, bool> get notificationSettings {
    final raw = _profile?['notificationSettings'];
    if (raw is Map) {
      return Map<String, bool>.from(raw.map((k, v) => MapEntry(k.toString(), v == true)));
    }
    return {
      'medicineReminders': true,
      'appointmentReminders': true,
      'vaccinationReminders': true,
      'moodReminders': false,
      'hydrationReminders': false,
    };
  }
  Map<String, dynamic> get preferences {
    final raw = _profile?['preferences'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'darkMode': false, 'language': 'English', 'units': 'Metric'};
  }

  int get pregnancyWeek {
    final lmpStr = _pregnancyProfileMap?['lmpDate'];
    if (lmpStr != null) {
      final lmp = DateTime.tryParse(lmpStr);
      if (lmp != null) {
        final diffDays = DateTime.now().difference(lmp).inDays;
        final calcWeek = diffDays ~/ 7;
        return calcWeek >= 0 ? calcWeek : 0;
      }
    }
    return _pregnancyProfileMap?['pregnancyWeek'] ?? 0;
  }

  int get trimester {
    final week = pregnancyWeek;
    if (week <= 13) return 1;
    if (week <= 26) return 2;
    return 3;
  }

  double get progress {
    final week = pregnancyWeek;
    if (week <= 0) return 0.0;
    if (week >= 40) return 1.0;
    return week / 40.0;
  }

  static Map<int, Map<String, String>> get weeklyDevelopment => _weeklyDevelopment;

  static const Map<int, Map<String, String>> _weeklyDevelopment = {
    1: {
      'size': 'Poppy seed 🔴',
      'weight': '0.1g',
      'length': '0.1cm',
      'description': 'Your pregnancy journey begins! Fertilization and early cell division are underway.',
    },
    2: {
      'size': 'Sesame seed 🔴',
      'weight': '0.1g',
      'length': '0.2cm',
      'description': 'The blastocyst is implanting in the uterine wall. Early placenta cells are forming.',
    },
    3: {
      'size': 'Lentil 🫘',
      'weight': '0.2g',
      'length': '0.3cm',
      'description': 'The embryo is forming three distinct cell layers that will develop into organs and tissues.',
    },
    4: {
      'size': 'Blueberry 🫐',
      'weight': '0.5g',
      'length': '0.4cm',
      'description': 'The heart begins to beat and early blood vessels are starting to form.',
    },
    5: {
      'size': 'Raspberry 🍓',
      'weight': '0.8g',
      'length': '0.6cm',
      'description': 'Neural tube is closing. Arm and leg buds are starting to become visible.',
    },
    6: {
      'size': 'Cherry 🍒',
      'weight': '1g',
      'length': '1.2cm',
      'description': 'Heart beats faster now. Tiny fingers and toes are starting to web and form.',
    },
    7: {
      'size': 'Olive 🫒',
      'weight': '1.5g',
      'length': '1.6cm',
      'description': 'Baby is starting to move, although you cannot feel it. Internal organs are shaping.',
    },
    8: {
      'size': 'Grape 🍇',
      'weight': '2g',
      'length': '2.3cm',
      'description': 'The tail has disappeared. Joints like elbows and wrists are beginning to bend.',
    },
    9: {
      'size': 'Kumquat 🍊',
      'weight': '4g',
      'length': '3.1cm',
      'description': 'Baby is now a fetus! Internal organs like kidneys, liver, and intestines are working.',
    },
    10: {
      'size': 'Fig 🫓',
      'weight': '7g',
      'length': '4.1cm',
      'description': 'Skin is translucent and baby can swallow. Fingerprints are beginning to form.',
    },
    11: {
      'size': 'Lime 🍋',
      'weight': '14g',
      'length': '5.4cm',
      'description': 'Genitalia are developing. Hair follicles and fingernails are beginning to form.',
    },
    12: {
      'size': 'Plum 🫐',
      'weight': '23g',
      'length': '7.4cm',
      'description': 'First trimester ends! Baby is fully formed from head to toe and starts kicking.',
    },
    13: {
      'size': 'Lemon 🍋',
      'weight': '43g',
      'length': '8.7cm',
      'description': 'Vocal cords and teeth buds are forming. Baby can make sucking faces now.',
    },
    14: {
      'size': 'Nectarine 🍑',
      'weight': '70g',
      'length': '10.1cm',
      'description': 'Baby can make facial expressions and is starting to grow fine lanugo hair.',
    },
    15: {
      'size': 'Apple 🍎',
      'weight': '100g',
      'length': '11.6cm',
      'description': 'Skeleton is transitioning from cartilage to bone. Hearing is starting to develop.',
    },
    16: {
      'size': 'Avocado 🥑',
      'weight': '140g',
      'length': '13cm',
      'description': 'Eyes and ears are in their final positions. You might feel first fluttery movements.',
    },
    17: {
      'size': 'Turnip 🧅',
      'weight': '190g',
      'length': '14.2cm',
      'description': 'Adipose (fat) tissue is depositing under the skin. Baby is practicing breathing.',
    },
    18: {
      'size': 'Onion 🧅',
      'weight': '240g',
      'length': '15.3cm',
      'description': 'Myelin is coating nerve fibers. Baby can hear your heartbeat and loud voices.',
    },
    19: {
      'size': 'Mango 🥭',
      'weight': '300g',
      'length': '16.4cm',
      'description': 'Sensory development peaks. Vernix caseosa coats skin to protect it from fluid.',
    },
    20: {
      'size': 'Banana 🍌',
      'weight': '360g',
      'length': '26.7cm',
      'description': 'Halfway mark! Movement is stronger and more regular. Digestive system is active.',
    },
    21: {
      'size': 'Carrot 🥕',
      'weight': '430g',
      'length': '27.8cm',
      'description': 'Taste buds are functional. Baby can swallow amniotic fluid and taste flavors.',
    },
    22: {
      'size': 'Papaya 🥭',
      'weight': '500g',
      'length': '28.9cm',
      'description': 'Eyelashes and eyebrows are well-formed. Lung capillaries are beginning to grow.',
    },
    23: {
      'size': 'Grapefruit 🍊',
      'weight': '550g',
      'length': '29.5cm',
      'description': 'Inner ear is fully developed, and baby starts recognizing familiar outside sounds.',
    },
    24: {
      'size': 'Corn on the cob 🌽',
      'weight': '600g',
      'length': '30cm',
      'description': 'Senses are developing rapidly! Real lung surfactant is beginning to form.',
    },
    25: {
      'size': 'Cauliflower 🥦',
      'weight': '660g',
      'length': '34.6cm',
      'description': 'Skin is becoming less wrinkled as baby gains more fat stores under the skin.',
    },
    26: {
      'size': 'Lettuce 🥬',
      'weight': '760g',
      'length': '35.6cm',
      'description': 'Eyes open for the first time! Baby can blink and respond to light changes.',
    },
    27: {
      'size': 'Eggplant 🍆',
      'weight': '875g',
      'length': '36.6cm',
      'description': 'Second trimester ends. Lungs and nervous system are continuing to mature rapidly.',
    },
    28: {
      'size': 'Squash 🍊',
      'weight': '1.0kg',
      'length': '37.6cm',
      'description': 'Third trimester starts! Eyes can blink and lungs can breathe air in/out.',
    },
    29: {
      'size': 'Cabbage 🥬',
      'weight': '1.2kg',
      'length': '38.6cm',
      'description': 'Muscles and organs are expanding. Brain is regulating body temperature.',
    },
    30: {
      'size': 'Coconut 🥥',
      'weight': '1.3kg',
      'length': '39.9cm',
      'description': 'Bone marrow is now entirely responsible for producing red blood cells.',
    },
    31: {
      'size': 'Cucumber 🥒',
      'weight': '1.5kg',
      'length': '41.1cm',
      'description': 'Reproductive system is developing further. Sleep-wake cycles are established.',
    },
    32: {
      'size': 'Pineapple 🍍',
      'weight': '1.7kg',
      'length': '42.4cm',
      'description': 'Nails are fully formed and bones are hardening. Baby is gaining weight fast.',
    },
    33: {
      'size': 'Jicama 🥔',
      'weight': '1.9kg',
      'length': '43.7cm',
      'description': 'Immune system is getting maternal antibodies. Lungs are nearly mature.',
    },
    34: {
      'size': 'Butternut squash 🍊',
      'weight': '2.1kg',
      'length': '45cm',
      'description': 'Fat layers are building up, and baby is rounding out to stay warm after birth.',
    },
    35: {
      'size': 'Honeydew melon 🍈',
      'weight': '2.4kg',
      'length': '46.2cm',
      'description': 'Kidneys and liver are fully functional. Most physical systems are ready.',
    },
    36: {
      'size': 'Cantaloupe 🍈',
      'weight': '2.6kg',
      'length': '47.4cm',
      'description': 'Baby is dropping down into the pelvis, which may relieve upper abdomen pressure.',
    },
    37: {
      'size': 'Romaine lettuce 🥬',
      'weight': '2.9kg',
      'length': '48.6cm',
      'description': 'Early term! Lungs and brain are fully functional, but continue to mature.',
    },
    38: {
      'size': 'Winter melon 🍈',
      'weight': '3.1kg',
      'length': '49.8cm',
      'description': 'Baby has shed most lanugo hair and is ready to survive outside the womb.',
    },
    39: {
      'size': 'Pumpkin 🎃',
      'weight': '3.3kg',
      'length': '50.7cm',
      'description': 'Full term! Skin is smooth and plump. Baby is waiting for the sign to arrive.',
    },
    40: {
      'size': 'Watermelon 🍉',
      'weight': '3.5kg',
      'length': '51.2cm',
      'description': 'Ready for birth! Welcome to the world, little one.',
    },
  };

  Map<String, String> get weeklyDevelopmentStats {
    final week = pregnancyWeek;
    final index = week.clamp(1, 40);
    return _weeklyDevelopment[index] ?? _weeklyDevelopment[24]!;
  }

  String get babySize => weeklyDevelopmentStats['size'] ?? 'Watermelon 🍉';

  double get weight {
    if (!hasTrackerPermission) return 0.0;
    final wt = _pregnancyProfileMap?['weight'];
    if (wt is num) return wt.toDouble();
    return 0.0;
  }

  String get dueDateString {
    final dateStr = _pregnancyProfileMap?['dueDate'];
    if (dateStr != null) {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        return "${dt.day}/${dt.month}/${dt.year}";
      }
    }
    return '';
  }

  // --- Health Vitals & History Getters ---
  String get bpSys {
    if (!hasTrackerPermission) return '';
    return _pregnancyProfileMap?['bpSys']?.toString() ?? '';
  }
  String get bpDia {
    if (!hasTrackerPermission) return '';
    return _pregnancyProfileMap?['bpDia']?.toString() ?? '';
  }

  List<String> get bpHistory {
    if (!hasTrackerPermission) return [];
    final list = _pregnancyProfileMap?['bpHistory'];
    if (list is List) {
      return List<String>.from(list);
    }
    return [];
  }

  int get waterGlasses {
    if (!hasTrackerPermission) return 0;
    return _pregnancyProfileMap?['waterGlasses'] ?? 0;
  }

  double get sleepHours {
    if (!hasTrackerPermission) return 0.0;
    final sleep = _pregnancyProfileMap?['sleepHours'];
    if (sleep is num) return sleep.toDouble();
    return 0.0;
  }

  double get temperature {
    if (!hasTrackerPermission) return 0.0;
    final temp = _pregnancyProfileMap?['temperature'];
    if (temp is num) return temp.toDouble();
    return 0.0;
  }

  Map<String, bool> get symptoms {
    if (!hasTrackerPermission) return {};
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final history = symptomsHistory;
    final todayList = history[todayStr] ?? [];
    final standardSymptoms = ['Morning Sickness', 'Fatigue', 'Backache', 'Headache', 'Swollen Ankles'];
    return {
      for (final s in standardSymptoms) s: todayList.contains(s),
    };
  }

  Map<String, List<String>> get symptomsHistory {
    if (!hasTrackerPermission) return {};
    final raw = _pregnancyProfileMap?['symptomsHistory'];
    if (raw is Map) {
      return Map<String, List<String>>.from(raw.map((k, v) => MapEntry(k.toString(), List<String>.from(v ?? []))));
    }
    return {};
  }

  int get streak {
    if (!hasTrackerPermission) return 0;
    return _pregnancyProfileMap?['streak'] ?? 0;
  }

  List<String> get kickLogs {
    if (!hasTrackerPermission) return [];
    final list = _pregnancyProfileMap?['kickLogs'];
    if (list is List) {
      return List<String>.from(list);
    }
    return [];
  }

  List<Map<String, dynamic>> get contractionLogs {
    if (!hasTrackerPermission) return [];
    final list = _pregnancyProfileMap?['contractionLogs'];
    if (list is List) {
      return List<Map<String, dynamic>>.from(list.map((item) => Map<String, dynamic>.from(item)));
    }
    return [];
  }

  String get profileTargetUid => (isPartner && linkedMotherUid != null) ? linkedMotherUid! : uid;

  /// Initialize Auth Listener to fetch user profile when authenticated
  void _init() {
    debugPrint('UserProvider: Initializing auth state listener');
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('UserProvider: User logged in (${user.uid}). Loading Firestore profile.');
        await fetchProfile(user.uid);
      } else {
        debugPrint('UserProvider: User logged out. Clearing profile.');
        await _cancelSubscriptions();
        _profile = null;
        _hasFetched = false;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Cancel all active Firestore snapshot listeners
  Future<void> _cancelSubscriptions() async {
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;
    await _cancelMotherSubscription();
    await _cancelConnectionSubscription();
    await _motherNotificationSettingsSubscription?.cancel();
    _motherNotificationSettingsSubscription = null;
    _motherNotificationSettings = null;
    _partnerSosVibrationTimer?.cancel();
    _partnerSosVibrationTimer = null;
  }

  Future<void> _cancelMotherSubscription() async {
    await _motherDocSubscription?.cancel();
    _motherDocSubscription = null;
    _motherProfile = null;
  }

  Future<void> _cancelConnectionSubscription() async {
    await _connectionDocSubscription?.cancel();
    _connectionDocSubscription = null;
    _connectionData = null;
  }

  void _listenToMotherProfile(String connectionId) {
    if (_motherDocSubscription != null) return;
    _motherDocSubscription = _db
        .collection('pregnancy_connections')
        .doc(connectionId)
        .collection('shared_state')
        .doc('current')
        .snapshots()
        .listen((docSnap) {
      if (docSnap.exists) {
        final data = docSnap.data();
        final oldSosActive = _motherProfile?['sosActive'] == true;
        _motherProfile = data;
        debugPrint('UserProvider: Replicated Mother profile updated from shared_state');

        final newSosActive = data?['sosActive'] == true;
        if (newSosActive != oldSosActive) {
          _handleMotherSosStateChange(newSosActive, data);
        }

        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('UserProvider: Mother profile listen error: $e');
    });
  }

  void _listenToConnection(String connectionId) {
    if (_connectionDocSubscription != null) return;
    _connectionDocSubscription = _db.collection('pregnancy_connections').doc(connectionId).snapshots().listen((docSnap) {
      if (docSnap.exists) {
        _connectionData = docSnap.data();
        debugPrint('UserProvider: Connection data updated');
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('UserProvider: Connection listen error: $e');
    });
  }

  void _listenToMotherNotificationSettings(String connectionId) {
    _motherNotificationSettingsSubscription?.cancel();
    _motherNotificationSettingsSubscription = _db
        .collection('pregnancy_connections')
        .doc(connectionId)
        .collection('shared_reminders')
        .doc('settings')
        .snapshots()
        .listen((docSnap) {
      if (docSnap.exists) {
        _motherNotificationSettings = docSnap.data();
        debugPrint('UserProvider: Replicated Mother notification settings updated: $_motherNotificationSettings');
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('UserProvider: Mother notification settings listen error: $e');
    });
  }

  void _handleMotherSosStateChange(bool active, Map<String, dynamic>? data) {
    _partnerSosVibrationTimer?.cancel();
    _partnerSosVibrationTimer = null;

    if (active) {
      final emergencySharingAllowed = _motherNotificationSettings?['sharingSettings']?['emergencyAlerts'] ?? true;
      if (emergencySharingAllowed && hasEmergencyAlertsPermission) {
        unawaited(NotificationService().showEmergencySOSNotification());
        
        _partnerSosVibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          HapticFeedback.vibrate();
        });
        debugPrint('UserProvider: Triggered SOS siren/haptics loop on Partner device');
      }
    } else {
      debugPrint('UserProvider: SOS deactivated. Stopped haptics on Partner device');
    }
  }

  /// Fetch Firestore document users/{uid}
  Future<void> fetchProfile(String uid) async {
    _isLoading = true;
    _hasFetched = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cancelSubscriptions();

      _userDocSubscription = _db.collection('users').doc(uid).snapshots().listen((docSnap) async {
        if (docSnap.exists) {
          _profile = docSnap.data();
          debugPrint('UserProvider: Profile loaded/updated. onboardingCompleted = $isOnboardingCompleted, role = $role');

          // Sync FCM device token safely in background
          unawaited(NotificationService().syncDeviceToken(uid));

          final motherUid = _profile?['linkedMotherUid'] as String?;
          final connectionId = _profile?['linkedConnectionId'] as String?;

          if (role == 'partner' && connectionId != null && connectionId.isNotEmpty) {
            EffectiveUidProvider.update(motherUid ?? '');
            _listenToMotherProfile(connectionId);
            _listenToMotherNotificationSettings(connectionId);
          } else {
            EffectiveUidProvider.update(uid);
            await _cancelMotherSubscription();
            await _motherNotificationSettingsSubscription?.cancel();
            _motherNotificationSettingsSubscription = null;
            _motherNotificationSettings = null;
          }

          if (role == 'mother' && connectionId != null && connectionId.isNotEmpty) {
            // Replicate mother profile defensively
            final motherProfileData = _profile;
            if (motherProfileData != null) {
              unawaited(_db
                  .collection('pregnancy_connections')
                  .doc(connectionId)
                  .collection('shared_state')
                  .doc('current')
                  .set(motherProfileData, SetOptions(merge: true))
                  .then((_) => debugPrint('UserProvider: Mother profile replicated to shared_state'))
                  .catchError((e) => debugPrint('UserProvider: Mother profile replication failed: $e')));
            }

            // Fetch and replicate notification settings
            unawaited(_db
                .collection('users')
                .doc(uid)
                .collection('notification_settings')
                .doc('settings')
                .get()
                .then((settingsSnap) {
                  if (settingsSnap.exists && settingsSnap.data() != null) {
                    return _db
                        .collection('pregnancy_connections')
                        .doc(connectionId)
                        .collection('shared_reminders')
                        .doc('settings')
                        .set(settingsSnap.data()!, SetOptions(merge: true))
                        .then((_) => debugPrint('UserProvider: Mother notification settings replicated to shared_reminders'));
                  }
                })
                .catchError((e) => debugPrint('UserProvider: Mother notification settings replication failed: $e')));
          }

          if (connectionId != null && connectionId.isNotEmpty) {
            _listenToConnection(connectionId);
          } else {
            await _cancelConnectionSubscription();
          }
        } else {
          _profile = null;
          await _cancelSubscriptions();
          debugPrint('UserProvider: Profile document does not exist for $uid');
        }
        _hasFetched = true;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }, onError: (e) {
        _hasFetched = true;
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _hasFetched = true;
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('UserProvider fetchProfile error: $e');
    }
  }

  /// Save or Update Firestore profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'No authenticated user found.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updateData = Map<String, dynamic>.from(data);
      if (role == 'partner') {
        final personalData = <String, dynamic>{};
        final pregnancyData = <String, dynamic>{};
        const personalKeys = {
          'uid',
          'email',
          'displayName',
          'phoneNumber',
          'age',
          'height',
          'role',
          'onboardingCompleted',
          'linkedPartnerUid',
          'linkedMotherUid',
          'linkedConnectionId',
          'preferences',
          'notificationSettings',
        };
        updateData.forEach((key, value) {
          if (personalKeys.contains(key)) {
            personalData[key] = value;
          } else {
            pregnancyData[key] = value;
          }
        });

        if (pregnancyData.isNotEmpty) {
          throw Exception('Partners are not authorized to modify pregnancy/maternal data.');
        }

        if (personalData.isNotEmpty) {
          personalData['updatedAt'] = FieldValue.serverTimestamp();
          await _db.collection('users').doc(user.uid).set(personalData, SetOptions(merge: true));
        }
      } else {
        final targetUid = profileTargetUid;
        if (targetUid == user.uid) {
          updateData['uid'] = user.uid;
          updateData['email'] = user.email;
        }
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        await _db.collection('users').doc(targetUid).set(updateData, SetOptions(merge: true));
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('UserProvider updateProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWaterGlasses(int glasses) async {
    await updateProfile({'waterGlasses': glasses});
  }

  Future<void> updateSleepHours(double hours) async {
    await updateProfile({'sleepHours': hours});
  }

  Future<void> updateTemperature(double temp) async {
    await updateProfile({'temperature': temp});
  }

  Future<void> updateSymptom(String symptom, bool value) async {
    final currentHistory = Map<String, dynamic>.from(_pregnancyProfileMap?['symptomsHistory'] ?? symptomsHistory);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayList = List<String>.from(currentHistory[todayStr] ?? []);
    if (value) {
      if (!todayList.contains(symptom)) {
        todayList.add(symptom);
      }
    } else {
      todayList.remove(symptom);
    }
    currentHistory[todayStr] = todayList;
    await updateProfile({'symptomsHistory': currentHistory});
  }

  Future<void> addBPLog(String sys, String dia) async {
    final currentHistory = List<String>.from(bpHistory);
    currentHistory.insert(0, '$sys/$dia mmHg (Just Now)');
    await updateProfile({
      'bpSys': sys,
      'bpDia': dia,
      'bpHistory': currentHistory,
    });
  }

  Future<void> addKickLog(String log) async {
    final currentLogs = List<String>.from(kickLogs);
    currentLogs.insert(0, log);
    await updateProfile({'kickLogs': currentLogs});
  }

  Future<void> addContractionLog(int durationSeconds, String startTimeStr, String frequency) async {
    final currentLogs = List<Map<String, dynamic>>.from(contractionLogs);
    currentLogs.insert(0, {
      'durationSeconds': durationSeconds,
      'startTime': startTimeStr,
      'frequency': frequency,
    });
    await updateProfile({'contractionLogs': currentLogs});
  }

  /// Reload the profile manually
  Future<void> refreshProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await fetchProfile(user.uid);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    _motherDocSubscription?.cancel();
    _connectionDocSubscription?.cancel();
    _motherNotificationSettingsSubscription?.cancel();
    _partnerSosVibrationTimer?.cancel();
    super.dispose();
  }
}
