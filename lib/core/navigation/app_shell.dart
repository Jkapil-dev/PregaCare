import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'bottom_nav.dart';
import 'app_router.dart';
import '../widgets/sos_floating_button.dart';
import '../widgets/emergency_overlay.dart';
import '../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

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
      if (location.startsWith(AppRoutes.tracking)) return 1;
      if (location.startsWith(AppRoutes.knowledgeHub)) return 2;
      if (location.startsWith(AppRoutes.profile)) return 3;
    } else {
      if (location.startsWith(AppRoutes.home)) return 0;
      if (location.startsWith(AppRoutes.tracking)) return 1;
      if (location.startsWith(AppRoutes.knowledgeHub)) return 2;
      if (location.startsWith(AppRoutes.profile)) return 3;
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
          context.go(AppRoutes.tracking);
          break;
        case 2:
          context.go(AppRoutes.knowledgeHub);
          break;
        case 3:
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
          context.go(AppRoutes.knowledgeHub);
          break;
        case 3:
          context.go(AppRoutes.profile);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final hasAuthMismatch = userProvider.profile != null && userProvider.uid != firebaseUser.uid;
      final isProfileMissing = userProvider.profile == null && !userProvider.isLoading;
      final hasInvalidRole = userProvider.profile != null && 
          userProvider.role != 'mother' && 
          userProvider.role != 'partner';

      if (userProvider.isLoading) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF8F0), // MaatriColors.warmCream
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(color: Color(0xFFE8736C)), // MaatriColors.coral
                SizedBox(height: 16),
                Text(
                  'Loading your secure profile...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280), // MaatriColors.slate
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (hasAuthMismatch || isProfileMissing || hasInvalidRole) {
        String diagnosticMessage = 'An unknown authentication error has occurred.';
        if (hasAuthMismatch) {
          diagnosticMessage = 'Session mismatch detected. Your local user state does not align with your Firebase Authentication credential.';
        } else if (isProfileMissing) {
          diagnosticMessage = 'Your maternal healthcare profile could not be retrieved from the cloud database. Please verify your internet connection.';
        } else if (hasInvalidRole) {
          diagnosticMessage = 'Invalid or unrecognized user account role (${userProvider.role}). Only Mother or Partner configurations are supported.';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFFF8F0), // MaatriColors.warmCream
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.security,
                        color: Color(0xFFEF4444), // MaatriColors.danger
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Security & Profile Guard',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D3A), // MaatriColors.charcoal
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        diagnosticMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280), // MaatriColors.slate
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final authProvider = context.read<AuthProvider>();
                                await authProvider.logout();
                              },
                              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE8736C)),
                              label: const Text('Sign Out'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE8736C),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFFE8736C), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await userProvider.refreshProfile();
                              },
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5BBFBA), // MaatriColors.teal
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

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

