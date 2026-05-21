import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/providers/user_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final displayName = userProvider.displayName.isNotEmpty
        ? userProvider.displayName
        : (userProvider.email.isNotEmpty ? userProvider.email.split('@')[0] : 'Guest User');

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        const SizedBox(height: 16),
        // Profile header
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: MaatriColors.primaryGradient, borderRadius: BorderRadius.circular(20), boxShadow: MaatriTheme.glowCoral),
          child: Column(children: [
            CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.2), child: const Icon(Icons.person_rounded, color: Colors.white, size: 44)),
            const SizedBox(height: 12),
            Text(displayName, style: MaatriTypography.headlineMedium.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              _getPregnancySubtitle(userProvider.pregnancyWeek, userProvider.dueDateString),
              style: MaatriTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _StatBadge(label: 'BP Logs', value: '24'),
              const SizedBox(width: 16),
              _StatBadge(label: 'ANC Visits', value: '5'),
              const SizedBox(width: 16),
              _StatBadge(label: 'Streak', value: '12d'),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        // Menu items
        _MenuItem(icon: Icons.medical_information_rounded, title: 'Medical Profile', subtitle: 'Health conditions & allergies', color: MaatriColors.teal),
        const SizedBox(height: 8),
        _MenuItem(icon: Icons.folder_rounded, title: 'Medical Records', subtitle: 'Ultrasounds, labs, prescriptions', color: MaatriColors.coral),
        const SizedBox(height: 8),
        _MenuItem(icon: Icons.calendar_month_rounded, title: 'Appointments', subtitle: 'Upcoming & past visits', color: MaatriColors.lavenderDark),
        const SizedBox(height: 8),
        _MenuItem(icon: Icons.emergency_rounded, title: 'Emergency Contacts', subtitle: 'Quick dial contacts', color: MaatriColors.danger),
        const SizedBox(height: 8),
        _MenuItem(icon: Icons.notifications_rounded, title: 'Notification Settings', subtitle: 'Reminders & alerts', color: MaatriColors.goldenAmber),
        const SizedBox(height: 8),
        _MenuItem(icon: Icons.language_rounded, title: 'Language', subtitle: 'English', color: MaatriColors.info),
        const SizedBox(height: 8),
        _MenuItem(icon: Icons.privacy_tip_rounded, title: 'Privacy & Data', subtitle: 'Export, delete account', color: MaatriColors.slate),
        const SizedBox(height: 8),
        _MenuItem(icon: Icons.help_outline_rounded, title: 'Help & Support', subtitle: 'FAQs, contact us', color: MaatriColors.teal),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () async {
            await authProvider.logout();
          },
          child: Text('Sign Out', style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.danger)),
        ),
        const SizedBox(height: 8),
        Text('MaatriCare v1.0.0', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.mediumGray)),
        const SizedBox(height: 24),
      ]))),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  const _StatBadge({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Text(value, style: MaatriTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)), Text(label, style: MaatriTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.8)))]));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Color color;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(onTap: () {}, child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: MaatriTypography.titleSmall), Text(subtitle, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate))])),
      const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
    ]));
  }
}
