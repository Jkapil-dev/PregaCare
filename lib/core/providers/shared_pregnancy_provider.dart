import 'dart:async';
import 'package:flutter/material.dart';
import 'user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_milestone.dart';
import '../models/shared_memory.dart';

class SharedPregnancyProvider extends ChangeNotifier {
  UserProvider? _userProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<SharedMilestone> _sharedMilestones = [];
  List<SharedMemory> _sharedMemories = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _milestonesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _memoriesSubscription;
  String? _cachedConnectionId;

  void update(UserProvider userProvider) {
    _userProvider = userProvider;
    final newConnectionId = userProvider.linkedConnectionId;
    if (_cachedConnectionId != newConnectionId) {
      _cachedConnectionId = newConnectionId;
      _listenToSharedMilestones();
      _listenToSharedMemories();
    }
    notifyListeners();
  }

  // ==========================================
  // PERMISSION PROXIES
  // ==========================================
  bool get hasAppointmentsPermission => _userProvider?.hasAppointmentsPermission ?? false;
  bool get hasMedicinesPermission => _userProvider?.hasMedicinesPermission ?? false;
  bool get hasRemindersPermission => _userProvider?.hasRemindersPermission ?? false;
  bool get hasBabyUpdatesPermission => _userProvider?.hasBabyUpdatesPermission ?? false;
  bool get hasEmergencyAlertsPermission => _userProvider?.hasEmergencyAlertsPermission ?? false;

  // ==========================================
  // PREGNANCY PROGRESS
  // ==========================================
  int get pregnancyWeek => _userProvider?.pregnancyWeek ?? 0;
  int get trimester => _userProvider?.trimester ?? 1;
  String get dueDateString => _userProvider?.dueDateString ?? '';
  double get progress => _userProvider?.progress ?? 0.0;

  // ==========================================
  // BABY DEVELOPMENT
  // ==========================================
  String get babySize => _userProvider?.babySize ?? '';
  Map<String, String>? get weeklyDevelopmentStats => _userProvider?.weeklyDevelopmentStats;

  // ==========================================
  // HEALTHCARE SUMMARIES / EMERGENCY
  // ==========================================
  String get bloodGroup => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.bloodGroup ?? '') : '';
  String get doctorName => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.doctorName ?? '') : '';
  String get hospitalName => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.hospitalName ?? '') : '';
  String get emergencyContactName => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.emergencyContactName ?? '') : '';
  String get emergencyContactPhone => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.emergencyContactPhone ?? '') : '';
  List<String> get allergies => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.allergies ?? []) : [];
  List<String> get conditions => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.conditions ?? []) : [];
  String get healthNotes => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.healthNotes ?? '') : '';

  // ==========================================
  // MOTHER DISPLAY NAME PROXY
  // ==========================================
  String get motherDisplayName => _userProvider?.motherProfile?['displayName'] ?? 'Mama';

  // ==========================================
  // DUE DATE COUNTDOWN
  // ==========================================
  int get daysUntilDueDate {
    final dateStr = dueDateString;
    if (dateStr.isEmpty) {
      // Fallback: estimate from pregnancy week (40 weeks - current week) * 7
      final week = pregnancyWeek;
      if (week <= 0) return -1;
      return ((40 - week) * 7).clamp(0, 280);
    }
    // Parse DD/MM/YYYY format
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final dueDate = DateTime(year, month, day);
        final remaining = dueDate.difference(DateTime.now()).inDays;
        return remaining >= 0 ? remaining : 0;
      }
    } catch (_) {}
    return -1;
  }

  // ==========================================
  // WEEKLY DEVELOPMENT NARRATIVE
  // ==========================================
  String get weeklyDevelopmentNarrative {
    final week = pregnancyWeek.clamp(1, 40);
    return _weeklyNarratives[week] ?? _weeklyNarratives[24]!;
  }

  // ==========================================
  // WEEKLY SUPPORT TIPS (computed)
  // ==========================================
  List<Map<String, String>> get weeklySupportTips {
    final week = pregnancyWeek.clamp(1, 40);
    return _weeklySupportTips[week] ?? _weeklySupportTips[24]!;
  }

  // ==========================================
  // DAILY HELP SUGGESTIONS (context-aware)
  // ==========================================
  List<Map<String, String>> get dailyHelpSuggestions {
    final week = pregnancyWeek.clamp(1, 40);
    final hour = DateTime.now().hour;
    final tri = trimester;

    final List<Map<String, String>> suggestions = [];

    // Time-aware suggestion
    if (hour < 12) {
      suggestions.add({
        'icon': 'free_breakfast',
        'title': 'Prepare a nourishing breakfast',
        'desc': 'A warm, protein-rich breakfast helps sustain her energy through the morning.',
      });
    } else if (hour < 17) {
      suggestions.add({
        'icon': 'water_drop',
        'title': 'Remind her to hydrate',
        'desc': 'Afternoon dehydration is common. Bring her a fresh glass of water or herbal tea.',
      });
    } else {
      suggestions.add({
        'icon': 'directions_walk',
        'title': 'Suggest an evening walk',
        'desc': 'A calm 15-minute walk together improves circulation and eases end-of-day stress.',
      });
    }

    // Week-specific suggestions
    if (week <= 13) {
      suggestions.add({
        'icon': 'local_cafe',
        'title': 'Help with nausea relief',
        'desc': 'Keep ginger tea, crackers, or peppermint candies within easy reach.',
      });
      suggestions.add({
        'icon': 'bedtime',
        'title': 'Encourage extra rest',
        'desc': 'First trimester fatigue is intense. Handle a chore so she can nap.',
      });
    } else if (week <= 26) {
      suggestions.add({
        'icon': 'self_improvement',
        'title': 'Offer a gentle massage',
        'desc': 'Lower back and feet carry growing pressure. A 10-minute massage works wonders.',
      });
      suggestions.add({
        'icon': 'restaurant',
        'title': 'Prepare a balanced meal',
        'desc': 'Include iron-rich foods, leafy greens, and lean proteins for growing baby.',
      });
    } else {
      suggestions.add({
        'icon': 'luggage',
        'title': 'Review the hospital bag',
        'desc': 'Ensure essentials are packed: documents, clothes, snacks, and comfort items.',
      });
      suggestions.add({
        'icon': 'air',
        'title': 'Practice breathing together',
        'desc': 'Spend 5 minutes practicing deep breathing techniques for labor preparation.',
      });
    }

    // Trimester-specific addition
    if (tri == 1) {
      suggestions.add({
        'icon': 'menu_book',
        'title': 'Read about early milestones',
        'desc': 'Learning about fetal development together creates shared excitement and bonding.',
      });
    } else if (tri == 2) {
      suggestions.add({
        'icon': 'calendar_today',
        'title': 'Review upcoming appointments',
        'desc': 'Check if any prenatal visits or scans are approaching this week.',
      });
    } else {
      suggestions.add({
        'icon': 'phone_in_talk',
        'title': 'Update emergency contacts',
        'desc': 'Verify that all emergency numbers and hospital routes are current and accessible.',
      });
    }

    return suggestions;
  }

  // ==========================================
  // SHARED MILESTONES (achieved vs upcoming)
  // ==========================================
  // Existing static shared milestones for UI display
  List<Map<String, dynamic>> get sharedMilestones {
    final week = pregnancyWeek;
    final List<Map<String, dynamic>> result = [];
    for (final entry in _pregnancyMilestones.entries) {
      result.add({
        'week': entry.key,
        'title': entry.value['title']!,
        'emoji': entry.value['emoji']!,
        'achieved': week >= entry.key,
      });
    }
    return result;
  }

  // Real-time shared milestones from Firestore
  List<SharedMilestone> get sharedMilestonesList => _sharedMilestones;


  void _listenToSharedMilestones() {
    _milestonesSubscription?.cancel();
    _milestonesSubscription = null;

    final connectionId = _userProvider?.linkedConnectionId;
    if (connectionId == null || connectionId.isEmpty) {
      _sharedMilestones = [];
      return;
    }
    
    _milestonesSubscription = _firestore
        .collection('pregnancy_connections')
        .doc(connectionId)
        .collection('shared_milestones')
        .snapshots()
        .listen((snapshot) {
      _sharedMilestones = snapshot.docs
          .map((doc) => SharedMilestone.fromDocument(doc))
          .toList();
      notifyListeners();
    });
  }

  // Real-time shared memories from Firestore
  List<SharedMemory> get sharedMemories => _sharedMemories;

  void _listenToSharedMemories() {
    _memoriesSubscription?.cancel();
    _memoriesSubscription = null;

    final connectionId = _userProvider?.linkedConnectionId;
    if (connectionId == null || connectionId.isEmpty) {
      _sharedMemories = [];
      return;
    }
    
    _memoriesSubscription = _firestore
        .collection('pregnancy_connections')
        .doc(connectionId)
        .collection('shared_memories')
        .snapshots()
        .listen((snapshot) {
      _sharedMemories = snapshot.docs
          .map((doc) => SharedMemory.fromDocument(doc))
          .toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _milestonesSubscription?.cancel();
    _memoriesSubscription?.cancel();
    super.dispose();
  }

  // Helper to add a new shared memory (photo, note, etc.)
  Future<void> addSharedMemory(SharedMemory memory) async {
    final uid = _userProvider?.uid;
    final connectionId = _userProvider?.linkedConnectionId;
    if (uid == null || connectionId == null || connectionId.isEmpty) return;
    
    await _firestore
        .collection('pregnancy_connections')
        .doc(connectionId)
        .collection('shared_memories')
        .add({
      'motherId': uid,
      'type': memory.type,
      'content': memory.content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  // ==========================================
  // PARTNER WEEK TIPS (for BabyUpdatesPage)
  // ==========================================
  List<String> partnerWeekTips(int week) {
    final clamped = week.clamp(1, 40);
    return _partnerWeekTips[clamped] ?? _partnerWeekTips[24]!;
  }

  // ==========================================
  // DAILY AFFIRMATIONS
  // ==========================================
  String get dailyAffirmation {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _dailyAffirmations.length;
    return _dailyAffirmations[index];
  }

  // ==========================================
  // STATIC DATA: WEEKLY NARRATIVES
  // ==========================================
  static const Map<int, String> _weeklyNarratives = {
    1: "The miracle begins! A single fertilized cell is dividing rapidly, carrying the full blueprint of your future baby. It's a time of invisible but extraordinary transformation.",
    2: "The tiny blastocyst is making its home in the uterine wall. The placenta — baby's lifeline for the next 9 months — is beginning to form.",
    3: "Your baby is now called an embryo! Though smaller than a grain of rice, the foundations for the heart, brain, and spinal cord are being laid down.",
    4: "The neural tube is forming, which will become the brain and spine. The heart begins its very first beats this week — a truly magical moment.",
    5: "Tiny buds are appearing that will become arms and legs. The face is starting to take shape with spots for the eyes and mouth.",
    6: "The heart is beating steadily now, pumping blood through a tiny body. Facial features are becoming more defined each day.",
    7: "Baby's brain is growing rapidly, generating about 100 new cells every minute. Small hands and feet are starting to form with webbed fingers.",
    8: "All major organs are now in place! Baby can make tiny spontaneous movements, though they're too small for you to feel yet.",
    9: "Baby has graduated from embryo to fetus! All essential body parts exist now and will continue growing and maturing over the coming months.",
    10: "Bones and cartilage are forming. Baby's vital organs are beginning to function. The tiny tail has disappeared, and baby looks more human each day.",
    11: "Baby can now open and close their fists! Tooth buds are forming under the gums, and hair follicles are developing.",
    12: "Reflexes are developing — baby can curl toes and make sucking movements. The digestive system is practicing contractions for future meals.",
    13: "Baby's fingerprints are forming, making them completely unique. Vocal cords are developing, preparing for that incredible first cry.",
    14: "Welcome to the second trimester! Baby can now make facial expressions like squinting and frowning. The body is growing faster than the head.",
    15: "Baby can sense light through closed eyelids and may respond to bright lights outside the womb. Legs are now longer than arms.",
    16: "Baby's skeletal system continues to develop from cartilage to bone. The circulatory and urinary systems are fully functional.",
    17: "Fat is starting to form under baby's skin, which will help regulate body temperature after birth. Baby is developing the ability to hear.",
    18: "Baby can hear sounds now! Your voice, heartbeat, and even music can reach those tiny ears. Many parents feel the first kicks around this time.",
    19: "Baby is covered in a waxy coating called vernix caseosa that protects delicate skin. The brain is designating areas for smell, taste, hearing, vision, and touch.",
    20: "You're halfway there! Baby is swallowing more now and producing meconium. The anatomy scan this week gives a wonderful peek at your growing baby.",
    21: "Baby's movements are becoming more coordinated. They can now suck their thumb! Eyebrows and eyelids are fully formed.",
    22: "Baby looks like a tiny newborn now. Their senses of touch and taste are developing. Fingernails have grown to the tips of tiny fingers.",
    23: "Baby can hear your voice clearly and may respond with kicks! Lungs are developing the structures needed to breathe air after birth.",
    24: "Baby's face is fully formed with eyelashes, eyebrows, and hair. The inner ear is developing balance, so baby can sense right-side up from upside down.",
    25: "Baby is gaining weight and their skin is becoming less translucent. They may startle at loud noises and respond to your familiar voice.",
    26: "Baby's eyes are opening for the first time! They can see light and shadow. The brain is developing rapid neural connections.",
    27: "Welcome to the third trimester! Baby can now open and close their eyes, sleep and wake at regular intervals, and maybe even suck fingers.",
    28: "Baby's brain is adding billions of neurons. They can dream during REM sleep! Lungs are maturing and preparing for the first breath.",
    29: "Baby is getting stronger, and those kicks and stretches are more forceful now. Bones are fully developed but still soft and pliable.",
    30: "Baby's brain is developing grooves and indentations, increasing surface area for growing intelligence. Red blood cells form in bone marrow now.",
    31: "Baby's five senses are fully operational! They can process information, track light, and perceive all sorts of signals from the outside world.",
    32: "Baby is practicing breathing movements. Toenails are visible, and baby has settled into more regular sleep-wake patterns.",
    33: "Baby's bones are hardening (except the skull, which stays soft for delivery). Immune system antibodies are being passed from mother to baby.",
    34: "Baby's lungs are nearly mature. The protective vernix coating is getting thicker. Baby may be settling into a head-down position.",
    35: "Baby's kidneys are fully developed, and the liver can process some waste products. Fat continues accumulating for temperature regulation.",
    36: "Baby has shed most of their lanugo (fine body hair). They're gaining about an ounce per day! The digestive system is fully mature.",
    37: "Congratulations — baby is now early term! All organ systems are functional. Baby is practicing breathing, sucking, and gripping.",
    38: "Baby has a firm grasp and their organs are ready for life outside the womb. The brain and lungs continue to mature until birth.",
    39: "Baby is considered full term! They're adding fat layers and perfecting their breathing. All systems are go for the big arrival.",
    40: "Your due date is here! Baby is fully prepared for birth. Their head will mold during delivery to fit through the birth canal safely.",
  };

  // ==========================================
  // STATIC DATA: WEEKLY SUPPORT TIPS
  // ==========================================
  static const Map<int, List<Map<String, String>>> _weeklySupportTips = {
    1: [
      {'title': 'Celebrate Together', 'desc': 'This is an exciting time. Share the joy and start dreaming about your future together.', 'icon': 'celebration'},
      {'title': 'Start a Prenatal Vitamin Routine', 'desc': 'Help her remember to take folic acid and prenatal vitamins daily.', 'icon': 'medication'},
      {'title': 'Research Together', 'desc': 'Read about the first weeks of pregnancy together to feel informed and connected.', 'icon': 'menu_book'},
      {'title': 'Emotional Availability', 'desc': 'Early pregnancy can bring mixed emotions. Be present, patient, and supportive.', 'icon': 'favorite'},
    ],
    2: [
      {'title': 'Morning Sickness Prep', 'desc': 'Stock up on ginger tea, crackers, and bland snacks that may ease nausea.', 'icon': 'local_cafe'},
      {'title': 'Attend the First Appointment', 'desc': 'Offer to go to the first prenatal checkup together for shared experience.', 'icon': 'medical_services'},
      {'title': 'Keep Communication Open', 'desc': 'Ask how she\'s feeling. Sometimes just listening means everything.', 'icon': 'chat'},
      {'title': 'Healthy Lifestyle Adjustments', 'desc': 'Reduce alcohol or caffeine at home to create a supportive environment.', 'icon': 'spa'},
    ],
    3: [
      {'title': 'Handle Morning Nausea', 'desc': 'Keep dry toast or crackers near the bed for early morning relief.', 'icon': 'bakery_dining'},
      {'title': 'Be Patient with Fatigue', 'desc': 'She may need more sleep than usual. Encourage rest without judgment.', 'icon': 'bedtime'},
      {'title': 'Share Household Tasks', 'desc': 'Take over chores that involve strong smells or heavy lifting.', 'icon': 'cleaning_services'},
      {'title': 'Plan Nutrition Together', 'desc': 'Explore healthy pregnancy recipes and cook nourishing meals.', 'icon': 'restaurant'},
    ],
    4: [
      {'title': 'Heart is Beating', 'desc': 'Baby\'s heart starts beating this week. Share the wonder of this milestone.', 'icon': 'favorite'},
      {'title': 'Avoid Strong Odors', 'desc': 'Heightened sense of smell can trigger nausea. Minimize cooking strong-smelling foods.', 'icon': 'air'},
      {'title': 'Offer Comfort', 'desc': 'Bloating and cramping are common. A warm compress can help ease discomfort.', 'icon': 'spa'},
      {'title': 'Stay Positive Together', 'desc': 'Early weeks can be anxious. Focus on the excitement of what\'s growing.', 'icon': 'sentiment_satisfied'},
    ],
    5: [
      {'title': 'Manage Food Aversions', 'desc': 'Be flexible with meals. What she loved last week might make her queasy now.', 'icon': 'restaurant'},
      {'title': 'Small, Frequent Meals', 'desc': 'Help prepare 5-6 small meals instead of 3 large ones to prevent nausea.', 'icon': 'lunch_dining'},
      {'title': 'Gentle Encouragement', 'desc': 'Remind her that nausea usually improves after the first trimester.', 'icon': 'emoji_emotions'},
      {'title': 'Reduce Her Stress', 'desc': 'Handle errands or tasks that might add unnecessary stress.', 'icon': 'self_improvement'},
    ],
    6: [
      {'title': 'First Heartbeat Scan', 'desc': 'The heartbeat may be visible on ultrasound soon. Plan to attend together.', 'icon': 'monitor_heart'},
      {'title': 'Hydration Partner', 'desc': 'Keep her water bottle filled and nearby. Dehydration worsens nausea.', 'icon': 'water_drop'},
      {'title': 'Evening Wind-Down', 'desc': 'Help create a relaxing bedtime routine — dimmed lights, no screens, calm music.', 'icon': 'nightlight'},
      {'title': 'Avoid Toxins', 'desc': 'Ensure cleaning products at home are pregnancy-safe and well-ventilated.', 'icon': 'health_and_safety'},
    ],
    7: [
      {'title': 'Gentle Exercise Together', 'desc': 'A short, slow walk together helps circulation and mood.', 'icon': 'directions_walk'},
      {'title': 'Emotional Support', 'desc': 'Mood swings are normal. Don\'t take them personally — hormones are powerful.', 'icon': 'psychology'},
      {'title': 'Prenatal Class Research', 'desc': 'Start looking into prenatal classes or workshops you can attend together.', 'icon': 'school'},
      {'title': 'Document the Journey', 'desc': 'Consider starting a pregnancy journal or photo diary together.', 'icon': 'photo_camera'},
    ],
    8: [
      {'title': 'All Organs Forming', 'desc': 'Every major organ is now in place. Be extra supportive during this critical period.', 'icon': 'child_care'},
      {'title': 'Wardrobe Comfort', 'desc': 'She may need looser clothing soon. Offer to shop for comfortable maternity basics.', 'icon': 'checkroom'},
      {'title': 'Dental Health', 'desc': 'Pregnancy hormones affect gums. Remind her about dental checkups.', 'icon': 'dentistry'},
      {'title': 'Limit Caffeine Together', 'desc': 'Switch to decaf or herbal tea as a shared gesture of support.', 'icon': 'coffee'},
    ],
    9: [
      {'title': 'Embryo to Fetus', 'desc': 'Baby is officially a fetus now! Celebrate this transition together.', 'icon': 'celebration'},
      {'title': 'Iron-Rich Foods', 'desc': 'Help prepare meals rich in iron: spinach, beans, lean red meat.', 'icon': 'restaurant'},
      {'title': 'Belly Moisturizing', 'desc': 'Offer to apply stretch mark cream or oil — it\'s a bonding moment too.', 'icon': 'spa'},
      {'title': 'Share the News?', 'desc': 'Discuss together when and how you\'d like to share the pregnancy news.', 'icon': 'share'},
    ],
    10: [
      {'title': 'Bones Forming', 'desc': 'Baby\'s bones are developing. Ensure calcium-rich foods are part of daily diet.', 'icon': 'fitness_center'},
      {'title': 'Attend Prenatal Visits', 'desc': 'Your presence at checkups means more than you realize.', 'icon': 'medical_services'},
      {'title': 'Create a Support Network', 'desc': 'Connect with other expecting parents or support groups.', 'icon': 'groups'},
      {'title': 'Patience with Fatigue', 'desc': 'Extreme tiredness peaks around now. Let her rest without guilt.', 'icon': 'hotel'},
    ],
    11: [
      {'title': 'Baby Can Move', 'desc': 'Baby is making tiny movements! Though too small to feel, they\'re active.', 'icon': 'child_care'},
      {'title': 'Healthy Snack Station', 'desc': 'Set up a snack station with fruits, nuts, and yogurt for easy access.', 'icon': 'lunch_dining'},
      {'title': 'Nausea May Ease Soon', 'desc': 'Encourage her — many women feel improvement in the coming weeks.', 'icon': 'trending_up'},
      {'title': 'Prenatal Screening', 'desc': 'Discuss any upcoming screening tests together to reduce anxiety.', 'icon': 'biotech'},
    ],
    12: [
      {'title': 'End of First Trimester', 'desc': 'Almost past the first hurdle! The risk of complications drops significantly.', 'icon': 'celebration'},
      {'title': 'Energy May Return', 'desc': 'She might start feeling more energetic. Plan a gentle outing together.', 'icon': 'wb_sunny'},
      {'title': 'Nuchal Scan', 'desc': 'The NT scan often happens around now. Attend together for support.', 'icon': 'medical_services'},
      {'title': 'Start Planning', 'desc': 'Begin gentle conversations about nursery ideas or name brainstorming.', 'icon': 'design_services'},
    ],
    13: [
      {'title': 'Welcome to Trimester 2', 'desc': 'The "golden trimester" begins! Energy returns and nausea often fades.', 'icon': 'auto_awesome'},
      {'title': 'Celebrate the Milestone', 'desc': 'Mark this transition with something special — a dinner or a small gift.', 'icon': 'card_giftcard'},
      {'title': 'Resume Gentle Exercise', 'desc': 'As energy returns, walking or prenatal yoga together feels wonderful.', 'icon': 'self_improvement'},
      {'title': 'Fingerprints Forming', 'desc': 'Baby is developing unique fingerprints — truly one of a kind.', 'icon': 'fingerprint'},
    ],
    14: [
      {'title': 'Facial Expressions', 'desc': 'Baby can squint and frown! Their personality is already developing.', 'icon': 'face'},
      {'title': 'Active Together', 'desc': 'This is a great time for couples\' activities — walks, swimming, or gentle hikes.', 'icon': 'hiking'},
      {'title': 'Bump Watch', 'desc': 'A noticeable bump may be appearing. Be genuinely excited and complimentary.', 'icon': 'favorite'},
      {'title': 'Calcium Boost', 'desc': 'Baby\'s bones are hardening. Dairy, fortified foods, and leafy greens help.', 'icon': 'eco'},
    ],
    15: [
      {'title': 'Baby Senses Light', 'desc': 'Baby can detect light through the womb. Share this amazing fact!', 'icon': 'light_mode'},
      {'title': 'Pregnancy Photos', 'desc': 'Start a weekly bump photo series — you\'ll treasure these memories.', 'icon': 'photo_camera'},
      {'title': 'Meal Prep Together', 'desc': 'Batch-cook healthy meals for the week to make nutrition easier.', 'icon': 'restaurant'},
      {'title': 'Back Support', 'desc': 'As the belly grows, back pain may start. Offer cushions and massages.', 'icon': 'airline_seat_recline_normal'},
    ],
    16: [
      {'title': 'Growing Skeleton', 'desc': 'Baby\'s skeletal system is strengthening. Support with calcium-rich diet.', 'icon': 'fitness_center'},
      {'title': 'Maternity Wardrobe', 'desc': 'She may need more comfortable clothing. A shopping trip together can be fun.', 'icon': 'checkroom'},
      {'title': 'Feel the Connection', 'desc': 'Talk to the baby — they can sense vibrations and warmth.', 'icon': 'record_voice_over'},
      {'title': 'Plan the Nursery', 'desc': 'Start discussing nursery layout, colors, and themes together.', 'icon': 'design_services'},
    ],
    17: [
      {'title': 'Baby Hears Sounds', 'desc': 'Baby is developing hearing! Speak, sing, or play music gently.', 'icon': 'music_note'},
      {'title': 'Skin Changes', 'desc': 'Stretch marks may appear. Apply moisturizer together as a caring ritual.', 'icon': 'spa'},
      {'title': 'Balanced Diet Focus', 'desc': 'Help ensure meals include proteins, healthy fats, and complex carbs.', 'icon': 'restaurant'},
      {'title': 'Register for Classes', 'desc': 'Sign up for birthing or parenting classes — they fill up fast!', 'icon': 'school'},
    ],
    18: [
      {'title': 'First Kicks!', 'desc': 'You might feel baby kick for the first time! Place your hand on her belly.', 'icon': 'child_care'},
      {'title': 'Anatomy Scan Coming', 'desc': 'The mid-pregnancy scan is approaching. Plan to attend together.', 'icon': 'medical_services'},
      {'title': 'Sleep Position Support', 'desc': 'Side sleeping becomes more comfortable now. A pregnancy pillow helps.', 'icon': 'bedtime'},
      {'title': 'Stay Active Together', 'desc': 'Swimming, walking, or prenatal yoga are excellent for both of you.', 'icon': 'pool'},
    ],
    19: [
      {'title': 'Vernix Coating', 'desc': 'Baby is developing a protective wax coating. Nature\'s own skincare!', 'icon': 'spa'},
      {'title': 'Gender Reveal?', 'desc': 'If you choose to learn the sex, the anatomy scan may reveal it.', 'icon': 'cake'},
      {'title': 'Leg Cramp Relief', 'desc': 'Nighttime leg cramps are common. Help with gentle stretching before bed.', 'icon': 'accessibility_new'},
      {'title': 'Stay Hydrated', 'desc': 'Dehydration can cause cramps and headaches. Keep water accessible.', 'icon': 'water_drop'},
    ],
    20: [
      {'title': 'Halfway Point!', 'desc': 'Celebrate — you\'re halfway through this incredible journey together!', 'icon': 'celebration'},
      {'title': 'Anatomy Scan Day', 'desc': 'This detailed scan checks baby\'s development. Be there for support.', 'icon': 'medical_services'},
      {'title': 'Baby Registry', 'desc': 'Start thinking about essential items you\'ll need for the baby.', 'icon': 'shopping_cart'},
      {'title': 'Emotional Check-In', 'desc': 'Ask her how she\'s really feeling. The halfway mark brings mixed emotions.', 'icon': 'psychology'},
    ],
    21: [
      {'title': 'Coordinated Movements', 'desc': 'Baby\'s movements are becoming more purposeful. Feel those kicks together!', 'icon': 'child_care'},
      {'title': 'Nursery Shopping', 'desc': 'Start browsing cribs, car seats, and other essentials together.', 'icon': 'shopping_cart'},
      {'title': 'Date Night', 'desc': 'Plan a relaxing date — a movie, dinner, or a sunset walk.', 'icon': 'dinner_dining'},
      {'title': 'Iron Supplements', 'desc': 'Anemia risk increases. Help track iron supplement intake.', 'icon': 'medication'},
    ],
    22: [
      {'title': 'Baby Looks Like a Newborn', 'desc': 'Features are fully formed. Those tiny fingernails have reached the fingertips!', 'icon': 'child_care'},
      {'title': 'Comfortable Footwear', 'desc': 'Swelling feet may need bigger, supportive shoes. Help her find comfortable ones.', 'icon': 'hiking'},
      {'title': 'Birth Plan Discussion', 'desc': 'Start gentle conversations about birth preferences and wishes.', 'icon': 'edit_note'},
      {'title': 'Posture Support', 'desc': 'Growing belly shifts center of gravity. Be mindful of her balance.', 'icon': 'accessibility_new'},
    ],
    23: [
      {'title': 'Baby Hears Your Voice', 'desc': 'Baby recognizes familiar voices now. Read stories or talk to the bump!', 'icon': 'record_voice_over'},
      {'title': 'Glucose Test Prep', 'desc': 'The gestational diabetes screening is coming up. Encourage healthy eating.', 'icon': 'science'},
      {'title': 'Breathing Exercises', 'desc': 'Start practicing relaxation breathing together for labor preparation.', 'icon': 'air'},
      {'title': 'Swelling Management', 'desc': 'Elevate her legs when resting. Light ankle circles help reduce swelling.', 'icon': 'spa'},
    ],
    24: [
      {'title': 'Baby\'s Face is Complete', 'desc': 'Eyelashes, eyebrows, and hair are all in place. A beautiful little person!', 'icon': 'face'},
      {'title': 'Encourage Hydration', 'desc': 'She needs 10+ glasses of water daily. Be her hydration reminder.', 'icon': 'water_drop'},
      {'title': 'Watch for Swelling', 'desc': 'Some swelling is normal, but sudden or severe swelling needs medical attention.', 'icon': 'health_and_safety'},
      {'title': 'Rest and Comfort', 'desc': 'Help create a comfortable resting spot with pillows and blankets.', 'icon': 'weekend'},
      {'title': 'Emotional Support', 'desc': 'Third trimester anxieties may begin. Listen without trying to fix everything.', 'icon': 'favorite'},
    ],
    25: [
      {'title': 'Baby Responds to Sound', 'desc': 'Baby may startle at loud noises and calm to your voice. So precious!', 'icon': 'hearing'},
      {'title': 'Back Pain Relief', 'desc': 'Offer warm compresses or gentle back rubs to ease growing discomfort.', 'icon': 'spa'},
      {'title': 'Childbirth Classes', 'desc': 'If you haven\'t started, now is a great time to begin classes together.', 'icon': 'school'},
      {'title': 'Balanced Meals', 'desc': 'DHA-rich foods (salmon, walnuts) support baby\'s rapid brain development.', 'icon': 'restaurant'},
    ],
    26: [
      {'title': 'Baby Opens Eyes', 'desc': 'For the first time, those tiny eyes are opening. They can see light and shadow!', 'icon': 'visibility'},
      {'title': 'Hospital Pre-Registration', 'desc': 'Pre-register at the hospital to avoid paperwork during labor.', 'icon': 'local_hospital'},
      {'title': 'Car Seat Research', 'desc': 'Research and purchase a car seat. Practice installation together.', 'icon': 'directions_car'},
      {'title': 'Sleep Challenges', 'desc': 'Sleeping gets harder. Extra pillows and a consistent bedtime routine help.', 'icon': 'nightlight'},
    ],
    27: [
      {'title': 'Third Trimester Begins', 'desc': 'The final stretch! Baby is opening and closing eyes, sleeping, and dreaming.', 'icon': 'auto_awesome'},
      {'title': 'Perineal Massage Info', 'desc': 'Discuss perineal massage preparation for birth with your healthcare provider.', 'icon': 'medical_services'},
      {'title': 'Final Nursery Setup', 'desc': 'Time to assemble the crib, wash baby clothes, and organize the nursery.', 'icon': 'crib'},
      {'title': 'Reduce Physical Strain', 'desc': 'Handle heavy lifting, bending, and physically demanding tasks for her.', 'icon': 'fitness_center'},
    ],
    28: [
      {'title': 'Baby Dreams!', 'desc': 'Baby experiences REM sleep and may be dreaming. What a wonderful thought!', 'icon': 'nightlight'},
      {'title': 'Kick Count Awareness', 'desc': 'Learn about kick counting together. 10 movements in 2 hours is healthy.', 'icon': 'timer'},
      {'title': 'Rhogam Shot', 'desc': 'If blood type is Rh-negative, the Rhogam injection may be needed now.', 'icon': 'vaccines'},
      {'title': 'Stress Reduction', 'desc': 'Practice meditation or calming exercises together before bed.', 'icon': 'self_improvement'},
    ],
    29: [
      {'title': 'Stronger Kicks', 'desc': 'Baby is getting more powerful! Those kicks and stretches are unmistakable.', 'icon': 'child_care'},
      {'title': 'Hospital Bag Start', 'desc': 'Begin packing the hospital bag with essentials for both of you.', 'icon': 'luggage'},
      {'title': 'Comfort Positions', 'desc': 'Help her find comfortable sitting and sleeping positions as the belly grows.', 'icon': 'airline_seat_recline_normal'},
      {'title': 'Frequent Meals', 'desc': 'Stomach space is decreasing. Help prepare smaller, more frequent meals.', 'icon': 'lunch_dining'},
    ],
    30: [
      {'title': 'Brain Growth Surge', 'desc': 'Baby\'s brain surface area is increasing rapidly with new grooves and folds.', 'icon': 'psychology'},
      {'title': 'Swelling Check', 'desc': 'Monitor for unusual swelling. Keep her feet elevated when sitting.', 'icon': 'health_and_safety'},
      {'title': 'Birth Plan Finalize', 'desc': 'Review and finalize the birth plan together. Discuss preferences clearly.', 'icon': 'edit_note'},
      {'title': 'Emotional Reassurance', 'desc': 'Third-trimester anxiety is common. Reassure her that she\'s doing beautifully.', 'icon': 'favorite'},
    ],
    31: [
      {'title': 'Five Senses Active', 'desc': 'All five of baby\'s senses are now fully functional. They perceive the world!', 'icon': 'psychology'},
      {'title': 'Pediatrician Research', 'desc': 'Start researching and selecting a pediatrician for after birth.', 'icon': 'medical_services'},
      {'title': 'Heartburn Help', 'desc': 'Heartburn intensifies. Help with small meals and avoiding spicy food before bed.', 'icon': 'restaurant'},
      {'title': 'Positive Affirmations', 'desc': 'Tell her she\'s strong, beautiful, and doing something extraordinary.', 'icon': 'favorite'},
    ],
    32: [
      {'title': 'Breathing Practice', 'desc': 'Baby is practicing breathing movements. Practice your breathing techniques too!', 'icon': 'air'},
      {'title': 'Final Shopping List', 'desc': 'Review the baby essentials list. Diapers, wipes, bottles — is everything ready?', 'icon': 'checklist'},
      {'title': 'Comfortable Space', 'desc': 'Create a comfortable recovery area at home for after the birth.', 'icon': 'weekend'},
      {'title': 'Regular Movement Check', 'desc': 'Continue monitoring baby\'s movements daily. Report any significant changes.', 'icon': 'timer'},
    ],
    33: [
      {'title': 'Immune System Transfer', 'desc': 'Antibodies are passing from mother to baby, building their immune defense.', 'icon': 'shield'},
      {'title': 'TDAP Vaccine', 'desc': 'The TDAP vaccine is often recommended around now. Discuss with your doctor.', 'icon': 'vaccines'},
      {'title': 'Install Car Seat', 'desc': 'Install the car seat and have it inspected. Many fire stations offer free checks.', 'icon': 'directions_car'},
      {'title': 'Be Her Advocate', 'desc': 'At appointments, help her voice concerns. Write down questions beforehand.', 'icon': 'record_voice_over'},
    ],
    34: [
      {'title': 'Lungs Nearly Mature', 'desc': 'Baby\'s lungs are almost ready for the outside world. Every day counts!', 'icon': 'air'},
      {'title': 'Freeze Meals', 'desc': 'Prepare and freeze meals now so you have food ready during postpartum recovery.', 'icon': 'kitchen'},
      {'title': 'Hospital Route', 'desc': 'Practice the drive to the hospital. Know alternate routes and parking.', 'icon': 'directions_car'},
      {'title': 'Labor Signs Education', 'desc': 'Learn the signs of labor together: contractions, water breaking, mucus plug.', 'icon': 'school'},
    ],
    35: [
      {'title': 'Baby Gaining Weight', 'desc': 'Baby gains about half a pound per week now. Growing plump and healthy!', 'icon': 'trending_up'},
      {'title': 'Complete Hospital Bag', 'desc': 'Finalize packing: charger, snacks, comfortable clothes, toiletries, documents.', 'icon': 'luggage'},
      {'title': 'Support Network Ready', 'desc': 'Confirm who will help after birth: family, friends, postpartum support.', 'icon': 'groups'},
      {'title': 'Gentle Daily Walks', 'desc': 'Short walks help with positioning and can encourage labor when the time comes.', 'icon': 'directions_walk'},
    ],
    36: [
      {'title': 'Baby Drops Lower', 'desc': 'Baby may descend into the pelvis (lightening). Breathing gets easier for her.', 'icon': 'child_care'},
      {'title': 'Weekly Checkups Begin', 'desc': 'Weekly prenatal appointments usually start now. Attend as many as possible.', 'icon': 'medical_services'},
      {'title': 'Recovery Supplies', 'desc': 'Prepare postpartum recovery supplies: pads, nursing bras, nipple cream.', 'icon': 'shopping_cart'},
      {'title': 'Patience and Calm', 'desc': 'She may be uncomfortable and anxious. Patience is your greatest gift now.', 'icon': 'spa'},
    ],
    37: [
      {'title': 'Early Term!', 'desc': 'Baby is considered early term. All systems are functional and maturing.', 'icon': 'celebration'},
      {'title': 'Know the Signs', 'desc': 'Real contractions are regular and intensifying. Time them carefully.', 'icon': 'timer'},
      {'title': 'Stay Close', 'desc': 'Try to stay nearby and keep your phone charged and accessible.', 'icon': 'phone_android'},
      {'title': 'Emotional Presence', 'desc': 'These final weeks are intense. Hold her hand, literally and figuratively.', 'icon': 'favorite'},
    ],
    38: [
      {'title': 'Ready for Birth', 'desc': 'Baby has a firm grasp and is fully developed. The countdown is real!', 'icon': 'child_care'},
      {'title': 'Review Birth Plan', 'desc': 'Go over the birth plan one more time. Discuss any last-minute changes.', 'icon': 'edit_note'},
      {'title': 'Rest Together', 'desc': 'Both of you need rest. Sleep when possible — things will get busy soon!', 'icon': 'bedtime'},
      {'title': 'Capture the Moment', 'desc': 'Take final belly photos together. These are memories you\'ll cherish forever.', 'icon': 'photo_camera'},
    ],
    39: [
      {'title': 'Full Term!', 'desc': 'Baby is considered full term. They\'re perfectly ready to meet you both!', 'icon': 'auto_awesome'},
      {'title': 'Stay Calm and Ready', 'desc': 'Keep the car fueled, bag packed, and phones charged at all times.', 'icon': 'directions_car'},
      {'title': 'Comfort and Care', 'desc': 'Help with anything that makes her more comfortable: feet rubs, cool drinks, company.', 'icon': 'spa'},
      {'title': 'You\'re Almost Parents', 'desc': 'Take a quiet moment together to reflect on this journey and the love ahead.', 'icon': 'favorite'},
    ],
    40: [
      {'title': 'Due Date!', 'desc': 'Today is the estimated due date. Baby will come when they\'re ready!', 'icon': 'celebration'},
      {'title': 'Patience is Key', 'desc': 'Only 5% of babies arrive on their due date. Stay patient and trust the process.', 'icon': 'hourglass_bottom'},
      {'title': 'Walk and Movement', 'desc': 'Gentle walks and movement can encourage labor naturally.', 'icon': 'directions_walk'},
      {'title': 'Be Her Rock', 'desc': 'She may feel frustrated or anxious. Your calm presence is her anchor.', 'icon': 'favorite'},
      {'title': 'Contact Your Doctor', 'desc': 'If past 40 weeks, discuss induction options with your healthcare provider.', 'icon': 'medical_services'},
    ],
  };

  // ==========================================
  // STATIC DATA: PREGNANCY MILESTONES
  // ==========================================
  static const Map<int, Map<String, String>> _pregnancyMilestones = {
    4: {'title': 'First Heartbeat', 'emoji': '💓'},
    8: {'title': 'All Organs Formed', 'emoji': '🌱'},
    10: {'title': 'Heartbeat Audible', 'emoji': '🔊'},
    12: {'title': 'First Trimester Complete', 'emoji': '🎉'},
    13: {'title': 'Fingerprints Forming', 'emoji': '🖐️'},
    16: {'title': 'Baby Can Move', 'emoji': '🤸'},
    18: {'title': 'First Kicks Felt', 'emoji': '🦶'},
    20: {'title': 'Halfway There!', 'emoji': '🎊'},
    22: {'title': 'Fingernails Complete', 'emoji': '✨'},
    24: {'title': 'Face Fully Formed', 'emoji': '👶'},
    26: {'title': 'Eyes Open', 'emoji': '👀'},
    27: {'title': 'Third Trimester Begins', 'emoji': '🌟'},
    28: {'title': 'Baby Can Dream', 'emoji': '💭'},
    30: {'title': 'Brain Growth Surge', 'emoji': '🧠'},
    32: {'title': 'Breathing Practice', 'emoji': '🌬️'},
    34: {'title': 'Lungs Nearly Mature', 'emoji': '🫁'},
    36: {'title': 'Weekly Checkups Begin', 'emoji': '🏥'},
    37: {'title': 'Early Term Reached', 'emoji': '🎈'},
    39: {'title': 'Full Term!', 'emoji': '🎀'},
    40: {'title': 'Due Date!', 'emoji': '🍼'},
  };

  // ==========================================
  // STATIC DATA: PARTNER WEEK TIPS
  // ==========================================
  static const Map<int, List<String>> _partnerWeekTips = {
    1: ['This is the very beginning — small gestures of excitement go a long way.', 'Start taking prenatal vitamins together as a couple ritual.'],
    2: ['Morning sickness may not have started yet, but stock up on nausea remedies.', 'Be flexible with plans — early pregnancy fatigue can be unpredictable.'],
    3: ['She may not look different yet, but her body is working incredibly hard.', 'Offer to handle cooking if strong smells are triggering nausea.'],
    4: ['The heart starts beating this week — share the wonder of this milestone.', 'Keep healthy snacks readily available for sudden hunger.'],
    5: ['Food aversions are real. Don\'t take it personally if she can\'t eat your cooking.', 'Small, frequent meals work better than three big ones right now.'],
    6: ['The first ultrasound may be coming — plan to attend together.', 'Keep her water bottle filled. Hydration helps with nausea.'],
    7: ['Her energy levels may be at their lowest. Handle extra chores without being asked.', 'A short walk together can boost both your moods.'],
    8: ['All major organs are forming — this is a critical growth period.', 'Consider starting a pregnancy photo journal together.'],
    9: ['Baby is now called a fetus! Celebrate this transition.', 'Offer to apply moisturizer or stretch mark cream — it\'s bonding time.'],
    10: ['Attend prenatal appointments. Your presence means more than you think.', 'Baby\'s bones are developing. Calcium-rich foods are important now.'],
    11: ['Nausea often starts improving soon — encourage her to hang in there.', 'Stock the snack drawer with healthy, easy-to-grab options.'],
    12: ['The first trimester is almost over. Energy often returns in trimester 2.', 'The nuchal scan may be scheduled now. Be present for support.'],
    13: ['Welcome to trimester 2! The "golden period" of pregnancy begins.', 'Energy typically returns — plan gentle activities together.'],
    14: ['Baby can make facial expressions now. How amazing is that?', 'As the bump becomes visible, be genuinely excited and complimentary.'],
    15: ['Baby can sense light through closed eyelids now.', 'Start weekly bump photos to capture this beautiful journey.'],
    16: ['Baby\'s skeletal system is developing. Support with calcium-rich meals.', 'Begin nursery conversations — colors, themes, furniture.'],
    17: ['Baby can hear sounds now! Play music or talk to the belly.', 'Stretch marks may appear — offer to help with skin care routines.'],
    18: ['This is often when the first kicks are felt. Be ready with your hand on her belly!', 'The anatomy scan is approaching. Plan to attend together.'],
    19: ['Leg cramps may start bothering her at night. Gentle stretching before bed helps.', 'Keep water accessible — dehydration worsens cramps.'],
    20: ['Halfway point! Celebrate this incredible milestone together.', 'Start thinking about baby essentials and creating a registry.'],
    21: ['Baby\'s movements are more coordinated. Feel those purposeful kicks!', 'Plan a relaxing date night before life gets busier.'],
    22: ['Baby looks like a miniature newborn now. So close to meeting them!', 'Growing belly shifts her center of gravity. Be mindful of balance.'],
    23: ['Baby can hear your voice clearly. Reading or singing is wonderful bonding.', 'Start discussing birth preferences and creating a birth plan.'],
    24: ['Her belly is getting heavier. Offer support when she sits or stands.', 'Watch for unusual swelling — it could indicate complications.'],
    25: ['Baby may startle at loud noises and calm to your voice. Beautiful!', 'DHA-rich foods support baby\'s rapid brain development.'],
    26: ['Baby\'s eyes are opening for the first time! They can see light.', 'Consider pre-registering at the hospital to save time later.'],
    27: ['Third trimester begins! Baby is sleeping, waking, and dreaming.', 'Take over more household responsibilities as she tires more easily.'],
    28: ['Baby is dreaming during sleep. What could they be dreaming about?', 'Learn about kick counting — 10 movements in 2 hours is healthy.'],
    29: ['Baby\'s kicks are stronger. Enjoy feeling those little punches!', 'Start packing the hospital bag with essentials for both of you.'],
    30: ['Baby\'s brain is developing rapidly. Every interaction matters.', 'Monitor for unusual swelling and keep her feet elevated.'],
    31: ['All five senses are fully operational. Baby perceives the world!', 'Research pediatricians together and choose one before birth.'],
    32: ['Baby is practicing breathing. You should practice your techniques too!', 'Ensure all baby essentials are ready: diapers, wipes, bottles.'],
    33: ['Antibodies are transferring from mother to baby. Nature is amazing.', 'Install the car seat now and have it professionally inspected.'],
    34: ['Baby\'s lungs are almost ready. The finish line is in sight!', 'Prepare and freeze meals for the postpartum period.'],
    35: ['Baby gains about half a pound per week now. Growing beautifully!', 'Finalize the hospital bag and keep it by the door.'],
    36: ['Baby may drop lower into the pelvis. Breathing gets easier for her.', 'Weekly checkups begin. Try to attend every one.'],
    37: ['Baby is early term! All systems are go for arrival.', 'Stay close, keep your phone charged, and know the route to the hospital.'],
    38: ['Baby is fully developed and has a strong grasp. Almost time!', 'Review the birth plan together one final time.'],
    39: ['Full term! Baby is ready to meet you both whenever they choose.', 'Take a quiet moment together — your life is about to change beautifully.'],
    40: ['Due date! Only 5% arrive on schedule, so stay patient.', 'Your calm presence is her greatest support right now.'],
  };

  // ==========================================
  // STATIC DATA: DAILY AFFIRMATIONS
  // ==========================================
  static const List<String> _dailyAffirmations = [
    'Small gestures of care carry enormous weight during this journey.',
    'Your presence is the most powerful gift you can offer.',
    'Every kind word and gentle action strengthens your bond.',
    'Being a supportive partner is one of the most meaningful roles you\'ll ever play.',
    'She doesn\'t need you to fix everything — just to be there.',
    'Your patience today builds trust that lasts a lifetime.',
    'A warm meal, a listening ear, a gentle hand — these are acts of love.',
    'This journey is transforming both of you. Embrace it together.',
    'The way you show up now shapes the parent you\'ll become.',
    'Love is in the details: a filled water glass, a shoulder to lean on.',
    'You are part of something extraordinary. Don\'t underestimate your role.',
    'Asking "How are you feeling?" never gets old during pregnancy.',
    'Your calm energy is her safe harbor in moments of uncertainty.',
    'Every day you choose to be present is a day well spent.',
    'The best partners don\'t have all the answers — they just stay close.',
    'Celebrate every small victory together. Each one matters.',
    'Your willingness to learn and grow shows incredible love.',
    'Remember: you\'re not just supporting her. You\'re building a family.',
    'Tenderness costs nothing but means everything.',
    'She sees your effort, even when she doesn\'t say it.',
    'Today is a good day to tell her she\'s doing something amazing.',
    'A 5-minute check-in can transform her entire day.',
    'You don\'t need grand gestures. Consistency is what matters most.',
    'Your involvement now creates the foundation for lifelong partnership.',
    'Rest when she rests. You\'ll need your energy too.',
    'Sometimes the most supportive thing is sitting together in silence.',
    'Every week brings new milestones. Celebrate them together.',
    'She chose you to share this journey with. Honor that trust.',
    'Your gentle words are medicine for the soul.',
    'The love you give now multiplies when baby arrives.',
    'Be proud of yourself too. Being a great partner takes real effort.',
  ];
}
