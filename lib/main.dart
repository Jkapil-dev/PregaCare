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
import 'core/providers/journal_provider.dart';
import 'core/providers/appointment_provider.dart';
import 'core/providers/record_provider.dart';
import 'core/providers/emergency_provider.dart';
import 'core/providers/location_provider.dart';
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
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => RecordProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
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
