import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav.dart';
import 'app_router.dart';
import '../theme/colors.dart';

/// Main app shell with bottom navigation and persistent SOS FAB
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.tracking)) return 1;
    if (location.startsWith(AppRoutes.aiAssistant)) return 2;
    if (location.startsWith(AppRoutes.community)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: MaatriBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => _onTabTap(context, index),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'sos_fab',
        onPressed: () => context.push(AppRoutes.emergency),
        backgroundColor: MaatriColors.danger,
        child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
    );
  }
}
