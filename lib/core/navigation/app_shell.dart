import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'bottom_nav.dart';
import 'app_router.dart';
import '../widgets/sos_floating_button.dart';
import '../widgets/emergency_overlay.dart';
import '../providers/user_provider.dart';

/// Main app shell with bottom navigation and persistent SOS FAB
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final location = GoRouterState.of(context).uri.path;
    final isPartner = userProvider.role == 'partner';

    if (isPartner) {
      if (location.startsWith(AppRoutes.home)) return 0;
      if (location.startsWith(AppRoutes.support)) return 1;
      if (location.startsWith(AppRoutes.babyUpdates)) return 2;
      if (location.startsWith(AppRoutes.safety)) return 3;
      if (location.startsWith(AppRoutes.profile)) return 4;
    } else {
      if (location.startsWith(AppRoutes.home)) return 0;
      if (location.startsWith(AppRoutes.tracking)) return 1;
      if (location.startsWith(AppRoutes.aiAssistant)) return 2;
      if (location.startsWith(AppRoutes.community)) return 3;
      if (location.startsWith(AppRoutes.profile)) return 4;
    }
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPartner = userProvider.role == 'partner';

    if (isPartner) {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
          break;
        case 1:
          context.go(AppRoutes.support);
          break;
        case 2:
          context.go(AppRoutes.babyUpdates);
          break;
        case 3:
          context.go(AppRoutes.safety);
          break;
        case 4:
          context.go(AppRoutes.profile);
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
          break;
        case 1:
          context.go(AppRoutes.tracking);
          break;
        case 2:
          context.go(AppRoutes.aiAssistant);
          break;
        case 3:
          context.go(AppRoutes.community);
          break;
        case 4:
          context.go(AppRoutes.profile);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Stack(
      children: [
        Scaffold(
          body: child,
          bottomNavigationBar: MaatriBottomNav(
            currentIndex: currentIndex,
            onTap: (index) => _onTabTap(context, index),
          ),
          floatingActionButton: const SOSFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
        ),
        
        // Full screen critical emergency overlay
        const EmergencyOverlay(),
      ],
    );
  }
}

