import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/responsive_widgets.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/appointment_provider.dart';
import '../../../../core/widgets/responsive_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _getPregnancySubtitle(int week, String dueDateStr) {
    String subText = 'Week $week';
    if (dueDateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dueDateStr);
        final formatted = DateFormat('MMMM yyyy').format(date);
        subText += ' · Due $formatted';
      } catch (_) {
        subText += ' · Due $dueDateStr';
      }
    }
    return subText;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final apptProvider = context.watch<AppointmentProvider>();
    
    final displayName = userProvider.displayName.isNotEmpty
        ? userProvider.displayName
        : (userProvider.email.isNotEmpty ? userProvider.email.split('@')[0] : 'Guest User');

    final initials = _getInitials(displayName);

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: ResponsivePageWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Profile header card with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: MaatriColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: MaatriTheme.glowCoral,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(
                        initials,
                        style: MaatriTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveText(
                      displayName,
                      style: MaatriTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    ResponsiveText(
                      _getPregnancySubtitle(userProvider.pregnancyWeek, userProvider.dueDateString),
                      style: MaatriTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.95)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ResponsiveActionRow(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _StatBadge(label: 'BP Logs', value: '${userProvider.bpHistory.length}'),
                        _StatBadge(label: 'ANC Visits', value: '${apptProvider.appointments.length}'),
                        _StatBadge(label: 'Streak', value: '${userProvider.streak}d'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu items structured to match target architecture
              _MenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Personal Info',
                subtitle: 'Display name, phone number, age & height',
                color: MaatriColors.teal,
                route: AppRoutes.personalInfo,
              ),
              const SizedBox(height: 8),
              if (!userProvider.isPartner) ...[
                _MenuItem(
                  icon: Icons.child_care_rounded,
                  title: 'Pregnancy Profile',
                  subtitle: 'LMP, due date, blood group, doctor & hospital',
                  color: MaatriColors.coral,
                  route: AppRoutes.pregnancyProfile,
                ),
                const SizedBox(height: 8),
                _MenuItem(
                  icon: Icons.medical_information_rounded,
                  title: 'Medical Profile',
                  subtitle: 'Allergies, conditions, meds & emergency contacts',
                  color: MaatriColors.lavenderDark,
                  route: AppRoutes.medicalInfo,
                ),
                const SizedBox(height: 8),
              ],
              _MenuItem(
                icon: Icons.people_outline_rounded,
                title: 'Partner & Family Mode',
                subtitle: 'Invite partner, link accounts, manage access permissions',
                color: MaatriColors.coral,
                route: AppRoutes.partnerFamily,
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.notifications_rounded,
                title: 'Notification Settings',
                subtitle: 'Customize daily reminders & alerts',
                color: MaatriColors.goldenAmber,
                route: AppRoutes.notificationSettings,
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy & Security',
                subtitle: 'Reset password, log out, delete account',
                color: MaatriColors.slate,
                route: AppRoutes.privacySecurity,
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.settings_suggest_rounded,
                title: 'App Preferences',
                subtitle: 'Language & measurement units settings',
                color: MaatriColors.info,
                route: AppRoutes.appPreferences,
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Frequently asked questions & contact channel',
                color: MaatriColors.teal,
                route: AppRoutes.helpSupport,
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.info_outline_rounded,
                title: 'About Materna',
                subtitle: 'Version details, terms, licenses',
                color: MaatriColors.coral,
                route: AppRoutes.about,
              ),
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out?'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(color: MaatriColors.slate)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign Out', style: TextStyle(color: MaatriColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await authProvider.logout();
                  }
                },
                child: Text(
                  'Sign Out',
                  style: MaatriTypography.labelLarge.copyWith(
                    color: MaatriColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Materna v1.0.0', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.mediumGray)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  const _StatBadge({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity( 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: MaatriTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: MaatriTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity( 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final String route;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () {
        context.push(route);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity( 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(title, style: MaatriTypography.titleSmall),
                const SizedBox(height: 2),
                ResponsiveText(
                  subtitle,
                  style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
        ],
      ),
    );
  }
}
