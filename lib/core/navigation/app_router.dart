import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/onboarding/presentation/pages/pregnancy_setup_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/tracker/tracker_home/presentation/pages/tracker_home_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/knowledge_hub/presentation/pages/knowledge_hub_page.dart';
import '../../features/knowledge_hub/presentation/pages/knowledge_article_detail_page.dart';
import '../../features/knowledge_hub/presentation/pages/knowledge_category_page.dart';
import '../../features/knowledge_hub/presentation/pages/featured_articles_page.dart';
import '../../features/knowledge_hub/domain/models/knowledge_article.dart';
import '../../features/notifications/presentation/pages/notification_center_screen.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/emergency/presentation/pages/emergency_page.dart';
import '../../features/shared_journey/presentation/pages/shared_journey_page.dart';
import '../../features/timeline/presentation/pages/timeline_page.dart';
import '../../features/profile/presentation/pages/personal_info_page.dart';
import '../../features/profile/presentation/pages/pregnancy_profile_page.dart';
import '../../features/profile/presentation/pages/medical_info_page.dart';
import '../../features/profile/presentation/pages/notification_settings_page.dart';
import '../../features/profile/presentation/pages/privacy_security_page.dart';
import '../../features/profile/presentation/pages/app_preferences_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/about_page.dart';
import '../../features/profile/presentation/pages/partner_family_page.dart';
import '../../features/profile/presentation/pages/sharing_permissions_page.dart';
import '../../features/profile/presentation/pages/notification_sharing_settings_page.dart';
import '../../features/partner/presentation/pages/partner_support_page.dart';
import '../../features/partner/presentation/pages/baby_updates_page.dart';
import '../navigation/app_shell.dart';
import '../../../providers/auth_provider.dart';

import '../providers/user_provider.dart';

// Tracker sub-modules (Level 2 deep-link targets)
import '../../features/tracker/health_tracking/presentation/pages/health_tracking_page.dart';
import '../../features/tracker/baby_monitoring/presentation/pages/baby_monitoring_page.dart';
import '../../features/tracker/medication_care/presentation/pages/medication_care_page.dart';
import '../../features/tracker/emotional_wellness/presentation/pages/emotional_wellness_page.dart';
import '../../features/tracker/records_documents/presentation/pages/records_documents_page.dart';
import '../../features/tracker/insights_history/presentation/pages/insights_history_page.dart';

/// Application route paths
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const pregnancySetup = '/pregnancy-setup';
  static const home = '/home';
  static const tracking = '/tracking';
  static const knowledgeHub = '/knowledge';
  static const knowledgeCategory = '/knowledge/category';
  static const articleDetail = '/knowledge/article';
  static const featuredArticles = '/knowledge/featured';
  static const community = '/community';
  static const profile = '/profile';
  static const emergency = '/emergency';
  static const timeline = '/timeline';
  static const notifications = '/notifications';

  // Partner specific routes
  static const support = '/support';
  static const babyUpdates = '/baby-updates';
  static const safety = '/safety';
  static const sharedJourney = '/shared-journey';

  // Profile sub-pages routes
  static const personalInfo = '/profile/personal';
  static const pregnancyProfile = '/profile/pregnancy';
  static const medicalInfo = '/profile/medical';
  static const notificationSettings = '/profile/notifications';
  static const privacySecurity = '/profile/privacy';
  static const appPreferences = '/profile/preferences';
  static const helpSupport = '/profile/help';
  static const about = '/profile/about';
  static const partnerFamily = '/profile/partner-family';
  static const sharingPermissions = '/profile/partner-family/permissions';
  static const notificationSharingSettings = '/profile/partner-family/notifications';

  // Tracker sub-module routes (Level 2)
  static const healthTracking = '/tracker/health';
  static const babyMonitoring = '/tracker/baby';
  static const medicationCare = '/tracker/medication';
  static const emotionalWellness = '/tracker/emotional';
  static const recordsDocuments = '/tracker/records';
  static const insightsHistory = '/tracker/insights';
}

/// Helper class to make GoRouter react to Firebase Auth Stream changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Create GoRouter configuration dynamically
GoRouter createRouter(AuthProvider authProvider, UserProvider userProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: Listenable.merge([authProvider, userProvider]),
    redirect: (context, state) {
      final user = authProvider.user;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;

      // Allowed public paths
      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isAuth = location == AppRoutes.auth;

      // 1. Let SplashPage handle the stable startup animation and transition
      if (isSplash) return null;

      // 2. Wait if the providers are fetching initial data
      if (authProvider.isLoading || userProvider.isLoading) {
        return null;
      }

      // 3. If not logged in, redirect any protected route access to /auth
      if (!isLoggedIn) {
        if (!isOnboarding && !isAuth) {
          debugPrint('GoRouter Redirect: Unauthenticated access to $location. Redirecting to /auth');
          return AppRoutes.auth;
        }
        return null;
      }

      // 4. User is logged in but profile document is missing (e.g. failed fetch or deleted document)
      if (userProvider.profile == null) {
        if (location != AppRoutes.home) {
          debugPrint('GoRouter Redirect: Profile missing for $location. Redirecting to /home for security audit.');
          return AppRoutes.home;
        }
        return null;
      }

      // 5. If user is on public landing pages or auth pages
      if (isOnboarding || isAuth) {
        if (userProvider.isOnboardingCompleted) {
          debugPrint('GoRouter Redirect: Onboarding complete. Routing to /home');
          return AppRoutes.home;
        } else {
          debugPrint('GoRouter Redirect: Onboarding incomplete. Routing to /pregnancy-setup');
          return AppRoutes.pregnancySetup;
        }
      }

      // 6. Protect onboarding setup route if already completed onboarding
      if (location == AppRoutes.pregnancySetup && userProvider.isOnboardingCompleted) {
        debugPrint('GoRouter Redirect: Onboarding already complete. Routing to /home');
        return AppRoutes.home;
      }

      // Role-based safety checks
      final isPartner = userProvider.role == 'partner';
      final isMother = userProvider.role == 'mother';

      if (isPartner) {
        // Partners should not access mother-only sections
        final isMotherRoute = location == AppRoutes.pregnancyProfile ||
            location == AppRoutes.medicalInfo ||
            location == AppRoutes.sharingPermissions ||
            location == AppRoutes.notificationSharingSettings ||
            location == AppRoutes.community ||
            location == AppRoutes.pregnancySetup;

        if (isMotherRoute) {
          debugPrint('GoRouter Redirect: Partner tried to access mother-only route $location. Redirecting to /home');
          return AppRoutes.home;
        }

        // If partner lacks emergency permission, protect emergency routes
        if (!userProvider.hasEmergencyPermission) {
          if (location == AppRoutes.emergency || location == AppRoutes.safety) {
            debugPrint('GoRouter Redirect: Partner lacks emergency permission. Redirecting to /home');
            return AppRoutes.home;
          }
        }
      }

      if (isMother) {
        // Mothers should not access partner-only sections
        final isPartnerRoute = location == AppRoutes.support ||
            location == AppRoutes.babyUpdates ||
            location == AppRoutes.safety;

        if (isPartnerRoute) {
          debugPrint('GoRouter Redirect: Mother tried to access partner route $location. Redirecting to /home');
          return AppRoutes.home;
        }
      }

      return null;
    },
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
            path: AppRoutes.knowledgeHub,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: KnowledgeHubPage(),
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
          GoRoute(
            path: AppRoutes.support,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PartnerSupportPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.babyUpdates,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BabyUpdatesPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.safety,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EmergencyPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.sharedJourney,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SharedJourneyPage(),
            ),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: AppRoutes.articleDetail,
        builder: (context, state) {
          final article = state.extra as KnowledgeArticle?;
          if (article == null) {
            // Fallback if no article provided
            return const Scaffold(body: Center(child: Text('Article not found')));
          }
          return KnowledgeArticleDetailPage(article: article);
        },
      ),
      GoRoute(
        path: AppRoutes.knowledgeCategory,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title = extra['category'] as String? ?? 'General';
          final icon = extra['icon'] as IconData? ?? Icons.library_books_rounded;
          final color = extra['color'] as Color? ?? Colors.teal;
          
          return KnowledgeCategoryPage(
            categoryTitle: title,
            categoryIcon: icon,
            categoryColor: color,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.featuredArticles,
        builder: (context, state) => const FeaturedArticlesPage(),
      ),
      GoRoute(
        path: AppRoutes.emergency,
        builder: (context, state) => const EmergencyPage(),
      ),
      GoRoute(
        path: AppRoutes.timeline,
        builder: (context, state) => const TimelinePage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationCenterScreen(),
      ),

      // Tracker sub-module deep-link routes (Level 2 — pushed on top of shell)
      GoRoute(
        path: AppRoutes.healthTracking,
        builder: (context, state) => const HealthTrackingPage(),
      ),
      GoRoute(
        path: AppRoutes.babyMonitoring,
        builder: (context, state) => const BabyMonitoringPage(),
      ),
      GoRoute(
        path: AppRoutes.medicationCare,
        builder: (context, state) => const MedicationCarePage(),
      ),
      GoRoute(
        path: AppRoutes.emotionalWellness,
        builder: (context, state) => const EmotionalWellnessPage(),
      ),
      GoRoute(
        path: AppRoutes.recordsDocuments,
        builder: (context, state) => const RecordsDocumentsPage(),
      ),
      GoRoute(
        path: AppRoutes.insightsHistory,
        builder: (context, state) => const InsightsHistoryPage(),
      ),
      // Profile sub-pages deep-link routes (Level 2)
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (context, state) => const PersonalInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.pregnancyProfile,
        builder: (context, state) => const PregnancyProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.medicalInfo,
        builder: (context, state) => const MedicalInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.privacySecurity,
        builder: (context, state) => const PrivacySecurityPage(),
      ),
      GoRoute(
        path: AppRoutes.appPreferences,
        builder: (context, state) => const AppPreferencesPage(),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.partnerFamily,
        builder: (context, state) => const PartnerFamilyPage(),
      ),
      GoRoute(
        path: AppRoutes.sharingPermissions,
        builder: (context, state) => const SharingPermissionsPage(),
      ),
      GoRoute(
        path: AppRoutes.notificationSharingSettings,
        builder: (context, state) => const NotificationSharingSettingsPage(),
      ),
    ],
  );
}
