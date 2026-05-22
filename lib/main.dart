import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/theme.dart';
import 'core/navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/medicine_provider.dart';
import 'core/providers/mood_provider.dart';
import 'core/providers/appointment_provider.dart';
import 'core/providers/record_provider.dart';
import 'core/providers/emergency_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/connection_provider.dart';
import 'core/providers/partner_provider.dart';
import 'core/providers/shared_pregnancy_provider.dart';
import 'core/providers/vaccination_provider.dart';
import 'core/providers/journal_provider.dart';
import 'core/providers/tracker_provider.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with support for local dev configurations
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, MedicineProvider>(
          create: (_) => MedicineProvider(),
          update: (_, userProvider, medicineProvider) =>
              (medicineProvider ?? MedicineProvider())..update(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, MoodProvider>(
          create: (_) => MoodProvider(),
          update: (_, userProvider, moodProvider) =>
              (moodProvider ?? MoodProvider())..update(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, AppointmentProvider>(
          create: (_) => AppointmentProvider(),
          update: (_, userProvider, appointmentProvider) =>
              (appointmentProvider ?? AppointmentProvider())..update(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, SharedPregnancyProvider>(
          create: (_) => SharedPregnancyProvider(),
          update: (_, userProvider, sharedPregnancyProvider) =>
              (sharedPregnancyProvider ?? SharedPregnancyProvider())..update(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, RecordProvider>(
          create: (_) => RecordProvider(),
          update: (_, userProvider, recordProvider) =>
              (recordProvider ?? RecordProvider())..update(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, EmergencyProvider>(
          create: (_) => EmergencyProvider(),
          update: (_, userProvider, emergencyProvider) =>
              (emergencyProvider ?? EmergencyProvider())..update(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, VaccinationProvider>(
          create: (_) => VaccinationProvider(),
          update: (_, userProvider, vaccinationProvider) =>
              (vaccinationProvider ?? VaccinationProvider())..update(userProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, JournalProvider>(
          create: (_) => JournalProvider(),
          update: (_, userProvider, journalProvider) =>
              (journalProvider ?? JournalProvider())..update(userProvider),
        ),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => PartnerProvider()),
      ],
      child: const MaatriCareApp(),
    ),
  );
}

/// Root application widget
class MaatriCareApp extends StatefulWidget {
  const MaatriCareApp({super.key});

  @override
  State<MaatriCareApp> createState() => _MaatriCareAppState();
}

class _MaatriCareAppState extends State<MaatriCareApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _router = createRouter(authProvider, userProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaatriCare',
      debugShowCheckedModeBanner: false,
      theme: MaatriTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
