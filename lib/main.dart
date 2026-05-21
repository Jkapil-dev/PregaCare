import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/theme.dart';
import 'core/navigation/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MaatriCareApp());
}

/// Root application widget
class MaatriCareApp extends StatelessWidget {
  const MaatriCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaatriCare',
      debugShowCheckedModeBanner: false,
      theme: MaatriTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
