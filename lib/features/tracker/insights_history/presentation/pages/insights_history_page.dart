import 'package:flutter/material.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';

class InsightsHistoryPage extends StatelessWidget {
  const InsightsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Insights & History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MaatriTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health & Bio Analytics', style: MaatriTypography.headlineMedium),
            const SizedBox(height: 4),
            Text('Intelligent insights driven by logged tracking data', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
            const SizedBox(height: MaatriTheme.spacingLg),

            // ── AI INSIGHTS CARD ──
            _buildAIInsights(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── MEDICATION ADHERENCE CARD ──
            _buildAdherenceCard(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── SYMPTOM FREQUENCY ──
            _buildSymptomFrequencyCard(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── MOOD ANALYTICS ──
            _buildMoodAnalyticsCard(),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: MaatriColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MaatriTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text('MaatriCare AI Engine', style: MaatriTypography.titleMedium.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"Your body weight trends show ideal, healthy progression for Week 24. However, you logged morning sickness twice this week. Consider drinking ginger tea and increasing water intake to 10 glasses to maintain optimal amniotic fluids."',
            style: MaatriTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.95), height: 1.4, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.tealLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_circle_rounded, color: MaatriColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Medication Adherence', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text('92%', style: MaatriTypography.headlineSmall.copyWith(color: MaatriColors.teal)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.92,
              minHeight: 10,
              backgroundColor: MaatriColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(MaatriColors.teal),
            ),
          ),
          const SizedBox(height: 8),
          Text('Excellent compliance! Scheduled intake has been extremely consistent over the last 14 days.', style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
        ],
      ),
    );
  }

  Widget _buildSymptomFrequencyCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.coralLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bar_chart_rounded, color: MaatriColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Logged Symptoms Frequency', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildSymptomBar('Morning Sickness', 4, MaatriColors.coral),
          _buildSymptomBar('Backache', 6, MaatriColors.goldenAmber),
          _buildSymptomBar('Fatigue', 2, MaatriColors.teal),
          _buildSymptomBar('Headache', 1, MaatriColors.lavenderDark),
        ],
      ),
    );
  }

  Widget _buildSymptomBar(String symptom, int daysCount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(symptom, style: MaatriTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              Text('$daysCount days/wk', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: daysCount / 7,
              minHeight: 6,
              backgroundColor: MaatriColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodAnalyticsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.lavenderLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.pie_chart_rounded, color: MaatriColors.lavenderDark, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Mood Breakdown', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodShare('😊 Happy', '50%'),
              _buildMoodShare('😌 Calm', '30%'),
              _buildMoodShare('😴 Tired', '20%'),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Mood profile indicates strong overall emotional stability.',
              style: TextStyle(color: MaatriColors.slate, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodShare(String mood, String share) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: MaatriColors.cloudGray, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(mood, style: MaatriTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(share, style: MaatriTypography.headlineSmall.copyWith(color: MaatriColors.lavenderDark, fontSize: 18)),
        ],
      ),
    );
  }
}
