import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/navigation/app_router.dart';

/// Home Dashboard - the main hub of MaatriCare
import 'package:provider/provider.dart';
import '../../../../core/models/consultation.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/appointment_provider.dart';
import '../../../../core/providers/medicine_provider.dart';
import '../../../../core/providers/mood_provider.dart';
import '../../../../core/providers/journal_provider.dart';

/// Home Dashboard - the main hub of MaatriCare
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final journalProvider = Provider.of<JournalProvider>(context);

    final currentWeek = userProvider.pregnancyWeek;
    final trimester = userProvider.trimester;
    final progress = userProvider.progress;
    final babySize = userProvider.babySize;
    final displayName = userProvider.displayName.isNotEmpty ? userProvider.displayName : 'Mama';

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MaatriTheme.spacingMd),
              _buildGreeting(context, displayName),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildWeekCard(context, currentWeek, trimester, progress, babySize),
              const SizedBox(height: MaatriTheme.spacingMd),
              _buildAppointmentCard(context, apptProvider.nextAppointment),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildQuickActions(context, trimester),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildDailyInsight(context, userProvider),
              const SizedBox(height: MaatriTheme.spacingMd),
              _buildAIRecommendation(context, userProvider),
              const SizedBox(height: MaatriTheme.spacingMd),
              _buildWeeklySummary(context, medProvider, userProvider, moodProvider, journalProvider),
              const SizedBox(height: MaatriTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String displayName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting,', style: MaatriTypography.bodyLarge.copyWith(color: MaatriColors.slate)),
          Text(displayName, style: MaatriTypography.headlineLarge.copyWith(color: MaatriColors.charcoal)),
        ]),
        Row(children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded), color: MaatriColors.charcoal),
          Stack(children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined), color: MaatriColors.charcoal),
            Positioned(right: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: MaatriColors.coral, shape: BoxShape.circle))),
          ]),
        ]),
      ],
    );
  }

  Widget _buildWeekCard(BuildContext context, int week, int trimester, double progress, String babySize) {
    return PrimaryCard(
      onTap: () => context.push(AppRoutes.timeline),
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Week $week', style: MaatriTypography.weekCounter.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Trimester $trimester', style: MaatriTypography.titleMedium.copyWith(color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: MaatriTheme.spacingSm),
          Text('Baby is the size of a', style: MaatriTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
          Text(babySize, style: MaatriTypography.titleLarge.copyWith(color: Colors.white)),
        ])),
        ProgressRing(progress: progress, size: 70, child: Text('${(progress * 100).toInt()}%', style: MaatriTypography.labelLarge.copyWith(color: Colors.white))),
      ]),
    );
  }

  /// Appointment card → navigates to Tracker → Medication & Care (Consultations tab)
  Widget _buildAppointmentCard(BuildContext context, Consultation? nextAppt) {
    final String doctorNameText = nextAppt != null ? nextAppt.doctorName : 'No Upcoming Consultations';
    final String subtitleText = nextAppt != null ? _getAppointmentSub(nextAppt) : 'Schedule your check-up';

    return GlassCard(
      onTap: () => context.push(AppRoutes.medicationCare),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: MaatriColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(MaatriTheme.radiusMd)),
          child: const Icon(Icons.calendar_today_rounded, color: MaatriColors.teal, size: 22),
        ),
        const SizedBox(width: MaatriTheme.spacingMd),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Next Appointment', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.slate)),
          Text('$doctorNameText · $subtitleText', style: MaatriTypography.titleMedium),
        ])),
        const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
      ]),
    );
  }

  String _getAppointmentSub(Consultation appt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final apptDate = DateTime(appt.appointmentDate.year, appt.appointmentDate.month, appt.appointmentDate.day);
    final diffDays = apptDate.difference(today).inDays;

    final timeStr = appt.appointmentTime.isNotEmpty ? " at ${appt.appointmentTime}" : "";
    if (diffDays == 0) return 'Today$timeStr';
    if (diffDays == 1) return 'Tomorrow$timeStr';
    if (diffDays > 1) return 'in $diffDays days';
    if (diffDays < 0) return 'Passed';
    return appt.specialization;
  }

  /// Quick action shortcuts with trimester-aware health/baby card
  Widget _buildQuickActions(BuildContext context, int trimester) {
    // Dynamic trimester-based card
    final bool isThirdTrimester = trimester == 3;
    final String healthLabel = isThirdTrimester ? 'Baby Health' : 'Mother Health';
    final IconData healthIcon = isThirdTrimester ? Icons.child_care_rounded : Icons.monitor_weight_rounded;
    final String healthRoute = isThirdTrimester ? AppRoutes.babyMonitoring : AppRoutes.healthTracking;

    return Row(children: [
      Expanded(child: QuickActionTile(
        icon: Icons.medication_rounded, label: 'Medications', color: MaatriColors.coral,
        onTap: () => context.push(AppRoutes.medicationCare),
      )),
      const SizedBox(width: MaatriTheme.spacingSm),
      Expanded(child: QuickActionTile(
        icon: healthIcon, label: healthLabel, color: MaatriColors.teal,
        onTap: () => context.push(healthRoute),
      )),
      const SizedBox(width: MaatriTheme.spacingSm),
      Expanded(child: QuickActionTile(
        icon: Icons.edit_note_rounded, label: 'Journal', color: MaatriColors.goldenAmber,
        onTap: () => context.push(AppRoutes.emotionalWellness),
      )),
      const SizedBox(width: MaatriTheme.spacingSm),
      Expanded(child: QuickActionTile(
        icon: Icons.document_scanner_rounded, label: 'Records', color: MaatriColors.lavenderDark,
        onTap: () => context.push(AppRoutes.recordsDocuments),
      )),
    ]);
  }

  Widget _buildDailyInsight(BuildContext context, UserProvider userProvider) {
    final stats = userProvider.weeklyDevelopmentStats;
    final desc = stats['description'] ?? 'Your baby is growing and developing beautifully today!';
    return GlassCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: MaatriColors.goldenAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(MaatriTheme.radiusMd)),
          child: const Icon(Icons.lightbulb_rounded, color: MaatriColors.goldenAmber, size: 22),
        ),
        const SizedBox(width: MaatriTheme.spacingMd),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Today's Insight", style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.charcoal)),
          const SizedBox(height: 4),
          Text(desc, style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
        ])),
      ]),
    );
  }

  Widget _buildAIRecommendation(BuildContext context, UserProvider userProvider) {
    final week = userProvider.pregnancyWeek;
    String recommendation = 'Ensure you are drinking at least 8-10 glasses of water daily.';
    if (week <= 12) {
      recommendation = 'Ensure you take your prenatal vitamins containing folic acid, and focus on rest.';
    } else if (week <= 27) {
      recommendation = 'Monitor your blood pressure daily and stay hydrated with at least 8-10 glasses of water.';
    } else {
      recommendation = 'Count your baby\'s kicks daily on the Baby Monitoring page and watch for signs of contractions.';
    }

    return GlassCard(
      onTap: () => context.go(AppRoutes.aiAssistant),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: MaatriColors.lavender.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(MaatriTheme.radiusMd)),
          child: const Icon(Icons.auto_awesome_rounded, color: MaatriColors.lavenderDark, size: 22),
        ),
        const SizedBox(width: MaatriTheme.spacingMd),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Recommends', style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.charcoal)),
          const SizedBox(height: 4),
          Text(recommendation, style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
      ]),
    );
  }

  Widget _buildWeeklySummary(BuildContext context, MedicineProvider medProvider, UserProvider userProvider, MoodProvider moodProvider, JournalProvider journalProvider) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    int totalMedsToday = 0;
    int takenMedsToday = 0;
    for (final med in medProvider.medicines) {
      if (med.isExpired) continue;
      final todayDateOnly = DateTime(now.year, now.month, now.day);
      final startOnly = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      final endOnly = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
      if (todayDateOnly.isBefore(startOnly) || todayDateOnly.isAfter(endOnly)) continue;

      for (final time in med.selectedTimes) {
        totalMedsToday++;
        final status = med.adherenceLogs[todayStr]?[time] ?? 'Pending';
        if (status == 'Taken') {
          takenMedsToday++;
        }
      }
    }
    final medsText = (totalMedsToday == 0 && medProvider.medicines.isEmpty)
        ? '—'
        : (totalMedsToday > 0 ? '$takenMedsToday/$totalMedsToday' : '0/$totalMedsToday');

    final weightText = userProvider.weight > 0 ? '${userProvider.weight.toStringAsFixed(1)} kg' : '0.0 kg';
    final moodEmoji = moodProvider.latestMood == '—' ? '—' : moodProvider.latestMood.split(' ').first;
    final notesText = '${journalProvider.journals.length}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: "This Week's Summary", icon: Icons.analytics_outlined),
      const SizedBox(height: MaatriTheme.spacingSm),
      GlassCard(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildSummaryItem('Meds', medsText, MaatriColors.coral, Icons.medication_rounded),
          _buildSummaryItem('Weight', weightText, MaatriColors.teal, Icons.monitor_weight_rounded),
          _buildSummaryItem('Mood', moodEmoji, MaatriColors.goldenAmber, null),
          _buildSummaryItem('Notes', notesText, MaatriColors.lavenderDark, Icons.note_alt_rounded),
        ]),
      ),
    ]);
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData? icon) {
    return Column(children: [
      if (icon != null) Icon(icon, color: color, size: 24) else Text(value, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      if (icon != null) Text(value, style: MaatriTypography.titleSmall.copyWith(color: MaatriColors.charcoal)),
      Text(label, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
    ]);
  }
}
