import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';

/// Health tracking dashboard with category cards and trends
class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MaatriTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MaatriTheme.spacingSm),
              Text('Health Tracking', style: MaatriTypography.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Monitor your health and baby\'s wellness',
                style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
              ),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Tracking grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: MaatriTheme.spacingSm,
                crossAxisSpacing: MaatriTheme.spacingSm,
                childAspectRatio: 1.1,
                children: [
                  _TrackingCard(
                    title: 'Blood Pressure',
                    value: '120/80',
                    subtitle: 'Last: 2h ago',
                    icon: Icons.favorite_rounded,
                    color: MaatriColors.teal,
                    gradient: MaatriColors.tealGradient,
                    status: 'Normal',
                    statusColor: MaatriColors.success,
                  ),
                  _TrackingCard(
                    title: 'Weight',
                    value: '68 kg',
                    subtitle: 'Last: Today',
                    icon: Icons.monitor_weight_rounded,
                    color: MaatriColors.coral,
                    gradient: MaatriColors.primaryGradient,
                    status: 'On track',
                    statusColor: MaatriColors.success,
                  ),
                  _TrackingCard(
                    title: 'Mood',
                    value: '😊',
                    subtitle: 'Last: 1h ago',
                    icon: Icons.emoji_emotions_rounded,
                    color: MaatriColors.lavenderDark,
                    gradient: MaatriColors.lavenderGradient,
                    status: 'Happy',
                    statusColor: MaatriColors.success,
                    isEmoji: true,
                  ),
                  _TrackingCard(
                    title: 'Symptoms',
                    value: '2',
                    subtitle: 'Active today',
                    icon: Icons.checklist_rounded,
                    color: MaatriColors.goldenAmber,
                    status: 'Mild',
                    statusColor: MaatriColors.warning,
                  ),
                  _TrackingCard(
                    title: 'Kick Counter',
                    value: '12',
                    subtitle: 'Today\'s count',
                    icon: Icons.child_care_rounded,
                    color: MaatriColors.coral,
                    status: 'Active',
                    statusColor: MaatriColors.success,
                  ),
                  _TrackingCard(
                    title: 'Medications',
                    value: '2/3',
                    subtitle: 'Taken today',
                    icon: Icons.medication_rounded,
                    color: MaatriColors.teal,
                    status: 'Pending',
                    statusColor: MaatriColors.warning,
                  ),
                ],
              ),

              const SizedBox(height: MaatriTheme.spacingLg),

              // Contraction Timer button
              GlassCard(
                onTap: () {
                  // TODO: Contraction timer
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MaatriColors.coral.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                      ),
                      child: const Icon(Icons.timer_rounded, color: MaatriColors.coral, size: 28),
                    ),
                    const SizedBox(width: MaatriTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contraction Timer', style: MaatriTypography.titleMedium),
                          Text(
                            'Track contraction duration and frequency',
                            style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
                  ],
                ),
              ),

              const SizedBox(height: MaatriTheme.spacingLg),

              // Weekly trends
              SectionHeader(title: "This Week's Trends", icon: Icons.trending_up_rounded, iconColor: MaatriColors.teal),
              const SizedBox(height: MaatriTheme.spacingSm),
              GlassCard(
                padding: const EdgeInsets.all(MaatriTheme.spacingLg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendDot('Blood Pressure', MaatriColors.teal),
                        const SizedBox(width: MaatriTheme.spacingMd),
                        _buildLegendDot('Weight', MaatriColors.coral),
                      ],
                    ),
                    const SizedBox(height: MaatriTheme.spacingMd),
                    // Placeholder chart area
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: MaatriColors.cloudGray,
                        borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          'Trend chart will appear here',
                          style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.mediumGray),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MaatriTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: MaatriTypography.labelSmall),
      ],
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Gradient? gradient;
  final String status;
  final Color statusColor;
  final bool isEmoji;

  const _TrackingCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.gradient,
    required this.status,
    required this.statusColor,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;
    final textColor = hasGradient ? Colors.white : MaatriColors.charcoal;
    final subtextColor = hasGradient ? Colors.white.withValues(alpha: 0.8) : MaatriColors.slate;

    return Container(
      padding: const EdgeInsets.all(MaatriTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: gradient,
        color: hasGradient ? null : MaatriColors.pureWhite,
        borderRadius: BorderRadius.circular(MaatriTheme.radiusLg),
        boxShadow: MaatriTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: hasGradient ? Colors.white : color, size: 22),
              StatusDot(color: statusColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEmoji)
                Text(value, style: const TextStyle(fontSize: 28))
              else
                Text(value, style: MaatriTypography.statValue.copyWith(color: textColor)),
              Text(title, style: MaatriTypography.labelMedium.copyWith(color: textColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: MaatriTypography.labelSmall.copyWith(color: subtextColor)),
            ],
          ),
        ],
      ),
    );
  }
}
