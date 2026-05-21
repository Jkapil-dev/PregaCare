import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/navigation/app_router.dart';

/// Home Dashboard - the main hub of MaatriCare
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Mock data
  int get _currentWeek => 24;
  int get _trimester => 2;
  double get _progress => 24 / 40;
  String get _babySize => '🌽 Corn on the cob';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MaatriTheme.spacingMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MaatriTheme.spacingMd),

              // Greeting header
              _buildGreeting(context),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Week tracker card
              _buildWeekCard(context),
              const SizedBox(height: MaatriTheme.spacingMd),

              // Appointment card
              _buildAppointmentCard(context),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Quick actions
              _buildQuickActions(context),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Daily insight
              _buildDailyInsight(context),
              const SizedBox(height: MaatriTheme.spacingMd),

              // AI recommendation
              _buildAIRecommendation(context),
              const SizedBox(height: MaatriTheme.spacingMd),

              // Weekly summary
              _buildWeeklySummary(context),
              const SizedBox(height: MaatriTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: MaatriTypography.bodyLarge.copyWith(
                color: MaatriColors.slate,
              ),
            ),
            Text(
              'Priya',
              style: MaatriTypography.headlineLarge.copyWith(
                color: MaatriColors.charcoal,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                // TODO: Global search
              },
              icon: const Icon(Icons.search_rounded),
              color: MaatriColors.charcoal,
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Notifications
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  color: MaatriColors.charcoal,
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: MaatriColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekCard(BuildContext context) {
    return PrimaryCard(
      onTap: () => context.push(AppRoutes.timeline),
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week $_currentWeek',
                  style: MaatriTypography.weekCounter.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trimester $_trimester',
                  style: MaatriTypography.titleMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: MaatriTheme.spacingSm),
                Text(
                  'Baby is the size of a',
                  style: MaatriTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  _babySize,
                  style: MaatriTypography.titleLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ProgressRing(
            progress: _progress,
            size: 70,
            child: Text(
              '${(_progress * 100).toInt()}%',
              style: MaatriTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context) {
    return GlassCard(
      onTap: () => context.push(AppRoutes.appointments),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaatriColors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: MaatriColors.teal,
              size: 22,
            ),
          ),
          const SizedBox(width: MaatriTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Appointment',
                  style: MaatriTypography.labelMedium.copyWith(
                    color: MaatriColors.slate,
                  ),
                ),
                Text(
                  'Dr. Shah · 3 days',
                  style: MaatriTypography.titleMedium,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: MaatriColors.mediumGray,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickActionTile(
            icon: Icons.medication_rounded,
            label: 'Medications',
            color: MaatriColors.coral,
            onTap: () => context.go(AppRoutes.tracking),
          ),
        ),
        const SizedBox(width: MaatriTheme.spacingSm),
        Expanded(
          child: QuickActionTile(
            icon: Icons.monitor_weight_rounded,
            label: 'Weight',
            color: MaatriColors.teal,
            onTap: () => context.go(AppRoutes.tracking),
          ),
        ),
        const SizedBox(width: MaatriTheme.spacingSm),
        Expanded(
          child: QuickActionTile(
            icon: Icons.edit_note_rounded,
            label: 'Notes',
            color: MaatriColors.goldenAmber,
            onTap: () => context.go(AppRoutes.tracking),
          ),
        ),
        const SizedBox(width: MaatriTheme.spacingSm),
        Expanded(
          child: QuickActionTile(
            icon: Icons.document_scanner_rounded,
            label: 'Scan',
            color: MaatriColors.lavenderDark,
            onTap: () => context.go(AppRoutes.tracking),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyInsight(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaatriColors.goldenAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: MaatriColors.goldenAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: MaatriTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Insight",
                  style: MaatriTypography.labelLarge.copyWith(
                    color: MaatriColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your baby can now hear sounds from outside the womb. Try playing gentle music or reading aloud! 🎵',
                  style: MaatriTypography.bodyMedium.copyWith(
                    color: MaatriColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendation(BuildContext context) {
    return GlassCard(
      onTap: () => context.go(AppRoutes.aiAssistant),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MaatriColors.lavender.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: MaatriColors.lavenderDark,
              size: 22,
            ),
          ),
          const SizedBox(width: MaatriTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Recommends',
                  style: MaatriTypography.labelLarge.copyWith(
                    color: MaatriColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consider adding iron-rich foods like spinach and lentils to your diet this week.',
                  style: MaatriTypography.bodyMedium.copyWith(
                    color: MaatriColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: MaatriColors.mediumGray,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "This Week's Summary",
          icon: Icons.analytics_outlined,
        ),
        const SizedBox(height: MaatriTheme.spacingSm),
        GlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Meds', '2/3', MaatriColors.coral, Icons.medication_rounded),
              _buildSummaryItem('Weight', '68 kg', MaatriColors.teal, Icons.monitor_weight_rounded),
              _buildSummaryItem('Mood', '😊', MaatriColors.goldenAmber, null),
              _buildSummaryItem('Notes', '3', MaatriColors.lavenderDark, Icons.note_alt_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData? icon,
  ) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: color, size: 24)
        else
          Text(value, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        if (icon != null)
          Text(
            value,
            style: MaatriTypography.titleSmall.copyWith(
              color: MaatriColors.charcoal,
            ),
          ),
        Text(
          label,
          style: MaatriTypography.labelSmall.copyWith(
            color: MaatriColors.slate,
          ),
        ),
      ],
    );
  }
}
