import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';
import 'package:maatricare/core/providers/user_provider.dart';
import 'package:maatricare/core/providers/medicine_provider.dart';
import 'package:maatricare/core/providers/mood_provider.dart';

class InsightsHistoryPage extends StatelessWidget {
  const InsightsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);

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
            _buildAIInsights(userProvider),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── MEDICATION ADHERENCE CARD ──
            _buildAdherenceCard(medProvider),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── SYMPTOM FREQUENCY ──
            _buildSymptomFrequencyCard(userProvider),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── MOOD ANALYTICS ──
            _buildMoodAnalyticsCard(moodProvider),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsights(UserProvider userProvider) {
    final week = userProvider.pregnancyWeek;
    final water = userProvider.waterGlasses;
    final symptomsMap = userProvider.symptoms;
    final activeSymptoms = symptomsMap.entries.where((e) => e.value).map((e) => e.key).toList();
    
    String symptomStr = '';
    if (activeSymptoms.isEmpty) {
      symptomStr = 'You have logged no symptoms today, which is excellent.';
    } else {
      symptomStr = 'You have logged some symptoms today: ${activeSymptoms.join(", ")}.';
    }

    String advice = '';
    if (water < 8) {
      advice = 'Your daily water intake is $water glasses, which is below the target. Hydration is crucial for amniotic fluid levels; try to drink at least 8-10 glasses.';
    } else {
      advice = 'Great job staying hydrated with $water glasses of water today!';
    }

    final fullInsight = '"For Week $week, $symptomStr $advice"';

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
            fullInsight,
            style: MaatriTypography.bodyMedium.copyWith(color: Colors.white.withOpacity( 0.95), height: 1.4, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard(MedicineProvider medProvider) {
    final rate = medProvider.adherenceRate;
    final percentStr = '${(rate * 100).toStringAsFixed(0)}%';
    
    String textAdvice = 'Excellent compliance! Scheduled intake has been extremely consistent.';
    if (rate < 0.6) {
      textAdvice = 'Adherence is low. Try setting up reminders on your medications to stay on track.';
    } else if (rate < 0.85) {
      textAdvice = 'Good compliance, but try to take all scheduled doses consistently.';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.tealLight.withOpacity( 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_circle_rounded, color: MaatriColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Medication Adherence', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text(percentStr, style: MaatriTypography.headlineSmall.copyWith(color: MaatriColors.teal)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: MaatriColors.lightGray,
              valueColor: const AlwaysStoppedAnimation<Color>(MaatriColors.teal),
            ),
          ),
          const SizedBox(height: 8),
          Text(textAdvice, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
        ],
      ),
    );
  }

  Widget _buildSymptomFrequencyCard(UserProvider userProvider) {
    final history = userProvider.symptomsHistory;
    final last7Days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: i));
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    });

    final Map<String, int> symptomCounts = {
      'Morning Sickness': 0,
      'Backache': 0,
      'Fatigue': 0,
      'Headache': 0,
      'Swollen Ankles': 0,
    };

    for (final dateStr in last7Days) {
      final list = history[dateStr];
      if (list != null) {
        for (final symptom in list) {
          if (symptomCounts.containsKey(symptom)) {
            symptomCounts[symptom] = symptomCounts[symptom]! + 1;
          }
        }
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.coralLight.withOpacity( 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bar_chart_rounded, color: MaatriColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Logged Symptoms Frequency', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          _buildSymptomBar('Morning Sickness', symptomCounts['Morning Sickness']!, MaatriColors.coral),
          _buildSymptomBar('Backache', symptomCounts['Backache']!, MaatriColors.goldenAmber),
          _buildSymptomBar('Fatigue', symptomCounts['Fatigue']!, MaatriColors.teal),
          _buildSymptomBar('Headache', symptomCounts['Headache']!, MaatriColors.lavenderDark),
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

  Widget _buildMoodAnalyticsCard(MoodProvider moodProvider) {
    final moods = moodProvider.moods;
    final totalCount = moods.length;
    final Map<String, int> counts = {};
    for (final m in moods) {
      final moodStr = m['mood'] as String?;
      if (moodStr != null) {
        counts[moodStr] = (counts[moodStr] ?? 0) + 1;
      }
    }
    final divisor = totalCount == 0 ? 1 : totalCount;

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
          if (totalCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No moods logged yet',
                  style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                ),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: sorted.take(3).map((e) {
                final pct = ((e.value / divisor) * 100).toStringAsFixed(0);
                return _buildMoodShare(e.key, '$pct%');
              }).toList(),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Mood profile indicates healthy emotional patterns.',
                style: const TextStyle(color: MaatriColors.slate, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          ],
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
