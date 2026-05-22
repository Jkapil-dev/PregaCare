import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';

// Providers
import 'package:maatricare/core/providers/user_provider.dart';
import 'package:maatricare/core/providers/medicine_provider.dart';
import 'package:maatricare/core/providers/mood_provider.dart';
import 'package:maatricare/core/providers/journal_provider.dart';
import 'package:maatricare/core/providers/record_provider.dart';
import 'package:maatricare/core/providers/appointment_provider.dart';

// Sections Sub-pages
import 'package:maatricare/features/tracker/health_tracking/presentation/pages/health_tracking_page.dart';
import 'package:maatricare/features/tracker/baby_monitoring/presentation/pages/baby_monitoring_page.dart';
import 'package:maatricare/features/tracker/medication_care/presentation/pages/medication_care_page.dart';
import 'package:maatricare/features/tracker/emotional_wellness/presentation/pages/emotional_wellness_page.dart';
import 'package:maatricare/features/tracker/records_documents/presentation/pages/records_documents_page.dart';
import 'package:maatricare/features/tracker/insights_history/presentation/pages/insights_history_page.dart';

class TrackerHomePage extends StatelessWidget {
  const TrackerHomePage({super.key});

  void _navigateTo(BuildContext context, Widget targetScreen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final medicineProvider = context.watch<MedicineProvider>();
    final moodProvider = context.watch<MoodProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final recordProvider = context.watch<RecordProvider>();
    final apptProvider = context.watch<AppointmentProvider>();

    final now = DateTime.now();
    final upcomingCount = apptProvider.appointments
        .where((c) => c.consultationStatus == 'Upcoming' && c.appointmentDate.isAfter(now.subtract(const Duration(days: 1))))
        .length;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MaatriTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MaatriTheme.spacingSm),
              Text('Tracker Hub', style: MaatriTypography.displaySmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('A centralized, medical-grade maternal health hub', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
              const SizedBox(height: MaatriTheme.spacingLg),

              // ── 1. HEALTH TRACKING ──
              _buildHubCard(
                context,
                title: 'Health Tracking',
                subtitle: 'Vitals & Daily Biometrics',
                summaryText: 'Weight: ${userProvider.weight > 0 ? '${userProvider.weight.toStringAsFixed(1)} kg' : 'Not set'} · Click to log vitals',
                icon: Icons.monitor_weight_rounded,
                color: MaatriColors.coral,
                onTap: () => _navigateTo(context, const HealthTrackingPage()),
              ),
              const SizedBox(height: MaatriTheme.spacingSm),

              // ── 2. BABY MONITORING ──
              _buildHubCard(
                context,
                title: 'Baby Monitoring',
                subtitle: 'Growth & Movement Logs',
                summaryText: 'Goal: 10 kicks · Currently Week ${userProvider.pregnancyWeek} (${userProvider.babySize})',
                icon: Icons.child_care_rounded,
                color: MaatriColors.teal,
                onTap: () => _navigateTo(context, const BabyMonitoringPage()),
              ),
              const SizedBox(height: MaatriTheme.spacingSm),

              // ── 3. MEDICATION & CARE ──
              _buildHubCard(
                context,
                title: 'Medication & Care',
                subtitle: 'Schedules & Doctor Appointments',
                summaryText: () {
                  final medCount = medicineProvider.medicines.length;
                  final medSummary = medCount > 0 ? '$medCount active medicine${medCount > 1 ? 's' : ''}' : 'No active medicines';
                  final apptText = upcomingCount > 0
                      ? '$upcomingCount upcoming visit${upcomingCount > 1 ? 's' : ''}'
                      : 'No visits scheduled';
                  return '$medSummary · $apptText';
                }(),
                icon: Icons.medication_rounded,
                color: MaatriColors.goldenAmber,
                onTap: () => _navigateTo(context, const MedicationCarePage()),
              ),
              const SizedBox(height: MaatriTheme.spacingSm),

              // ── 4. EMOTIONAL WELLNESS ──
              _buildHubCard(
                context,
                title: 'Emotional Wellness',
                subtitle: 'Moods, Journal & Reflections',
                summaryText: () {
                  final latestMood = moodProvider.latestMood;
                  final moodText = latestMood == '—' ? 'No mood logged today' : 'Mood today: $latestMood';
                  final journalCount = journalProvider.journals.length;
                  final journalSummary = journalCount > 0 ? '$journalCount journal entry${journalCount > 1 ? 'ies' : 'y'}' : 'No journal entries';
                  return '$moodText · $journalSummary';
                }(),
                icon: Icons.self_improvement_rounded,
                color: MaatriColors.lavenderDark,
                onTap: () => _navigateTo(context, const EmotionalWellnessPage()),
              ),
              const SizedBox(height: MaatriTheme.spacingSm),

              // ── 5. RECORDS & DOCUMENTS ──
              _buildHubCard(
                context,
                title: 'Records & Documents',
                subtitle: 'Ultrasounds, Reports & Prescriptions',
                summaryText: () {
                  final recordCount = recordProvider.records.length;
                  final recordSummary = recordCount > 0 ? '$recordCount file${recordCount > 1 ? 's' : ''} secured' : 'No documents secured';
                  return '$recordSummary · Click to view documents';
                }(),
                icon: Icons.folder_open_rounded,
                color: MaatriColors.info,
                onTap: () => _navigateTo(context, const RecordsDocumentsPage()),
              ),
              const SizedBox(height: MaatriTheme.spacingSm),

              // ── 6. INSIGHTS & HISTORY ──
              _buildHubCard(
                context,
                title: 'Insights & History',
                subtitle: 'Biometric Analytics & Adherence Trends',
                summaryText: 'Pregnancy Week ${userProvider.pregnancyWeek} insights and history trends',
                icon: Icons.trending_up_rounded,
                color: MaatriColors.success,
                onTap: () => _navigateTo(context, const InsightsHistoryPage()),
              ),
              const SizedBox(height: MaatriTheme.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String summaryText,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity( 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                  const SizedBox(height: 4),
                  Text(
                    summaryText,
                    style: MaatriTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity( 0.8), size: 16),
          ],
        ),
      ),
    );
  }
}
