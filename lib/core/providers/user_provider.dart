import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Centralized state provider for User Profile details fetched from Firestore.
class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  UserProvider() {
    _init();
  }

  // --- Getters ---
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isOnboardingCompleted {
    if (_profile == null) return false;
    return _profile!['onboardingCompleted'] == true;
  }

  String get uid => _profile?['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  String get displayName => _profile?['displayName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
  String get email => _profile?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';

  int get pregnancyWeek {
    final lmpStr = _profile?['lmpDate'];
    if (lmpStr != null) {
      final lmp = DateTime.tryParse(lmpStr);
      if (lmp != null) {
        final diffDays = DateTime.now().difference(lmp).inDays;
        final calcWeek = diffDays ~/ 7;
        return calcWeek >= 0 ? calcWeek : 0;
      }
    }
    return _profile?['pregnancyWeek'] ?? 0;
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
    final wt = _profile?['weight'];
    if (wt is num) return wt.toDouble();
    return 0.0;
  }

  String get dueDateString {
    final dateStr = _profile?['dueDate'];
    if (dateStr != null) {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        return "${dt.day}/${dt.month}/${dt.year}";
      }
    }
    return '';
  }

  // --- Health Vitals & History Getters ---
  String get bpSys => _profile?['bpSys']?.toString() ?? '120';
  String get bpDia => _profile?['bpDia']?.toString() ?? '80';

  List<String> get bpHistory {
    final list = _profile?['bpHistory'];
    if (list is List) {
      return List<String>.from(list);
    }
    return ['120/80 mmHg (Today)', '118/79 mmHg (2 days ago)'];
  }

  int get waterGlasses => _profile?['waterGlasses'] ?? 5;

  double get sleepHours {
    final sleep = _profile?['sleepHours'];
    if (sleep is num) return sleep.toDouble();
    return 7.5;
  }

  double get temperature {
    final temp = _profile?['temperature'];
    if (temp is num) return temp.toDouble();
    return 36.8;
  }

  Map<String, bool> get symptoms {
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
    final raw = _profile?['symptomsHistory'];
    if (raw is Map) {
      return Map<String, List<String>>.from(raw.map((k, v) => MapEntry(k.toString(), List<String>.from(v ?? []))));
    }
    final today = DateTime.now();
    String dayStr(int offset) {
      final d = today.subtract(Duration(days: offset));
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
    return {
      dayStr(0): ['Morning Sickness', 'Backache'],
      dayStr(1): ['Backache'],
      dayStr(2): ['Morning Sickness', 'Backache', 'Fatigue'],
      dayStr(3): ['Backache'],
      dayStr(4): ['Fatigue'],
      dayStr(5): ['Morning Sickness', 'Headache'],
      dayStr(6): ['Morning Sickness', 'Backache'],
    };
  }

  int get streak => _profile?['streak'] ?? 12;

  List<String> get kickLogs {
    final list = _profile?['kickLogs'];
    if (list is List) {
      return List<String>.from(list);
    }
    return ['10 kicks in 45 mins (Yesterday)', '8 kicks in 30 mins (2 days ago)'];
  }

  List<Map<String, dynamic>> get contractionLogs {
    final list = _profile?['contractionLogs'];
    if (list is List) {
      return List<Map<String, dynamic>>.from(list.map((item) => Map<String, dynamic>.from(item)));
    }
    return [];
  }

  /// Initialize Auth Listener to fetch user profile when authenticated
  void _init() {
    debugPrint('UserProvider: Initializing auth state listener');
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('UserProvider: User logged in (${user.uid}). Loading Firestore profile.');
        await fetchProfile(user.uid);
      } else {
        debugPrint('UserProvider: User logged out. Clearing profile.');
        _profile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Fetch Firestore document users/{uid}
  Future<void> fetchProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _profile = doc.data();
        debugPrint('UserProvider: Profile loaded. onboardingCompleted = $isOnboardingCompleted');
      } else {
        _profile = null;
        debugPrint('UserProvider: Profile document does not exist for $uid');
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('UserProvider fetchProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      updateData['uid'] = user.uid;
      updateData['email'] = user.email;
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      await fetchProfile(user.uid);
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
    final currentHistory = Map<String, dynamic>.from(_profile?['symptomsHistory'] ?? symptomsHistory);
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
    super.dispose();
  }
}
