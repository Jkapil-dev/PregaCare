import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/onboarding/presentation/pages/pregnancy_setup_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/tracker/tracker_home/presentation/pages/tracker_home_page.dart';
import '../../features/ai_assistant/presentation/pages/ai_chat_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/emergency/presentation/pages/emergency_page.dart';
import '../../features/timeline/presentation/pages/timeline_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../navigation/app_shell.dart';

/// Application route paths
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const pregnancySetup = '/pregnancy-setup';
  static const home = '/home';
  static const tracking = '/tracking';
  static const aiAssistant = '/ai';
  static const community = '/community';
  static const profile = '/profile';
  static const emergency = '/emergency';
  static const timeline = '/timeline';
  static const appointments = '/appointments';
}

/// GoRouter configuration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: AppRoutes.pregnancySetup,
      builder: (context, state) => const PregnancySetupPage(),
    ),

    // Main app shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.tracking,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TrackerHomePage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.aiAssistant,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AiChatPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.community,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CommunityPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),

    // Full-screen routes (no bottom nav)
    GoRoute(
      path: AppRoutes.emergency,
      builder: (context, state) => const EmergencyPage(),
    ),
    GoRoute(
      path: AppRoutes.timeline,
      builder: (context, state) => const TimelinePage(),
    ),
    GoRoute(
      path: AppRoutes.appointments,
      builder: (context, state) => const AppointmentsPage(),
    ),
  ],
);
