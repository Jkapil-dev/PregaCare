import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../../../core/providers/shared_pregnancy_provider.dart';


/// Home Dashboard - the main hub of MaatriCare
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isPartner = userProvider.role == 'partner';

    if (isPartner) {
      return _buildPartnerDashboard(context, userProvider);
    } else {
      return _buildMotherDashboard(context, userProvider);
    }
  }

  // ==========================================
  // MOTHER DASHBOARD MODE
  // ==========================================
  Widget _buildMotherDashboard(BuildContext context, UserProvider userProvider) {
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

  // ==========================================
  // PARTNER DASHBOARD MODE
  // ==========================================
  Widget _buildPartnerDashboard(BuildContext context, UserProvider userProvider) {
    final apptProvider = Provider.of<AppointmentProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);
    final sharedPregnancy = Provider.of<SharedPregnancyProvider>(context);

    final trimester = sharedPregnancy.trimester;
    final displayName = userProvider.displayName.isNotEmpty ? userProvider.displayName : 'Partner';
    final motherName = userProvider.motherProfile?['displayName'] ?? 'Mama';

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MaatriTheme.spacingMd),
              _buildPartnerSosBanner(context, userProvider, motherName),
              _buildPartnerGreeting(context, displayName, motherName),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildPartnerWeekCard(context, userProvider, sharedPregnancy),
              const SizedBox(height: MaatriTheme.spacingMd),
              _buildPartnerAppointmentCard(context, userProvider, apptProvider.nextAppointment),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildPartnerMedicineReminders(context, userProvider, medProvider),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildPartnerSupportSuggestions(context, trimester),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildPartnerEmergencyStatus(context, userProvider),
              const SizedBox(height: MaatriTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerSosBanner(BuildContext context, UserProvider userProvider, String motherName) {
    final motherProfile = userProvider.motherProfile;
    final sosActive = motherProfile?['sosActive'] == true;
    final emergencySharingAllowed = userProvider.motherNotificationSettings?['sharingSettings']?['emergencyAlerts'] ?? true;
    final hasPermission = userProvider.hasEmergencyAlertsPermission;

    if (!sosActive || !emergencySharingAllowed || !hasPermission) {
      return const SizedBox.shrink();
    }

    final triggeredAt = motherProfile?['sosTriggeredAt'];
    String timeStr = '';
    if (triggeredAt != null) {
      if (triggeredAt is Timestamp) {
        timeStr = DateFormat('hh:mm a').format(triggeredAt.toDate());
      } else {
        timeStr = triggeredAt.toString();
      }
    }

    final lat = motherProfile?['sosLatitude'];
    final lng = motherProfile?['sosLongitude'];
    final phone = motherProfile?['phoneNumber'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: MaatriTheme.spacingLg),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE57373), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: MaatriTheme.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL SOS ALERT',
                          style: MaatriTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            'Active since $timeStr',
                            style: MaatriTypography.labelSmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$motherName triggered an emergency alert. Reach out immediately or use maps directions below.',
                style: MaatriTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (phone.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse('tel:$phone');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: Text(
                          'CALL NOW',
                          style: MaatriTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (lat != null && lng != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD32F2F),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 16),
                        label: Text(
                          'DIRECTIONS',
                          style: MaatriTypography.labelMedium.copyWith(
                            color: const Color(0xFFD32F2F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerGreeting(BuildContext context, String partnerName, String motherName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting,', style: MaatriTypography.bodyLarge.copyWith(color: MaatriColors.slate)),
          Text(partnerName, style: MaatriTypography.headlineLarge.copyWith(color: MaatriColors.charcoal)),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: MaatriColors.teal, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Companion to $motherName', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.tealDark)),
            ],
          ),
        ]),
        Stack(children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined), color: MaatriColors.charcoal),
          Positioned(right: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: MaatriColors.coral, shape: BoxShape.circle))),
        ]),
      ],
    );
  }

  Widget _buildPartnerWeekCard(BuildContext context, UserProvider user, SharedPregnancyProvider sharedPregnancy) {
    final currentWeek = sharedPregnancy.pregnancyWeek;
    final trimester = sharedPregnancy.trimester;
    final progress = sharedPregnancy.progress;
    final stats = sharedPregnancy.weeklyDevelopmentStats ?? {};
    final babySize = sharedPregnancy.babySize;
    final babyWeight = stats['weight'] ?? '—';
    final babyLength = stats['length'] ?? '—';
    final babyDesc = stats['description'] ?? 'Your baby is growing and developing beautifully today!';
    final hasBabyUpdates = sharedPregnancy.hasBabyUpdatesPermission;

    return PrimaryCard(
      onTap: () => context.push(AppRoutes.timeline),
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Week $currentWeek', style: MaatriTypography.weekCounter.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Trimester $trimester', style: MaatriTypography.titleMedium.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              ProgressRing(
                progress: progress,
                size: 70,
                child: Text('${(progress * 100).toInt()}%', style: MaatriTypography.labelLarge.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: MaatriTheme.spacingMd),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: MaatriTheme.spacingMd),
          if (hasBabyUpdates) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Baby\'s Size', style: MaatriTypography.bodySmall.copyWith(color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(babySize, style: MaatriTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                const SizedBox(width: MaatriTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Weight', style: MaatriTypography.bodySmall.copyWith(color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(babyWeight, style: MaatriTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white24),
                const SizedBox(width: MaatriTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Length', style: MaatriTypography.bodySmall.copyWith(color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(babyLength, style: MaatriTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MaatriTheme.spacingMd),
            Text(
              babyDesc,
              style: MaatriTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85), fontStyle: FontStyle.italic),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Baby growth updates are currently hidden by mother.',
                    style: MaatriTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerAppointmentCard(BuildContext context, UserProvider user, Consultation? nextAppt) {
    if (!user.isLinked) {
      return const _LockedFeatureCard(message: 'Link your account to view appointments.');
    }
    if (!user.hasAppointmentsPermission) {
      return const _LockedFeatureCard(message: 'Appointment sharing is currently disabled.');
    }

    final String doctorNameText = nextAppt != null ? nextAppt.doctorName : 'No Upcoming Consultations';
    final String subtitleText = nextAppt != null ? _getAppointmentSub(nextAppt) : 'Schedule your check-up';

    return GlassCard(
      onTap: nextAppt != null ? () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MaatriTheme.radiusLg)),
            title: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: MaatriColors.teal),
                const SizedBox(width: 8),
                Expanded(child: Text('Appointment Details', style: MaatriTypography.headlineSmall)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OB-GYN / Doctor:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.slate)),
                Text('Dr. ${nextAppt.doctorName}', style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Specialization:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.slate)),
                Text(nextAppt.specialization, style: MaatriTypography.bodyMedium),
                const SizedBox(height: 8),
                Text('Date & Time:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.slate)),
                Text('${nextAppt.appointmentDate.day}/${nextAppt.appointmentDate.month}/${nextAppt.appointmentDate.year} at ${nextAppt.appointmentTime}', style: MaatriTypography.bodyMedium),
                const SizedBox(height: 8),
                Text('Hospital / Clinic:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.slate)),
                Text(nextAppt.hospitalOrClinic, style: MaatriTypography.bodyMedium),
                if (nextAppt.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.slate)),
                  Text(nextAppt.notes, style: MaatriTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: MaatriColors.charcoal)),
              ),
            ],
          ),
        );
      } : null,
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
        if (nextAppt != null) const Icon(Icons.info_outline_rounded, color: MaatriColors.mediumGray),
      ]),
    );
  }

  Widget _buildPartnerMedicineReminders(BuildContext context, UserProvider user, MedicineProvider provider) {
    if (!user.isLinked) {
      return const _LockedFeatureCard(message: 'Link your account to view shared reminders.');
    }
    if (!user.hasMedicinesPermission) {
      return const _LockedFeatureCard(message: 'Medication reminders permission is currently disabled.');
    }

    final activeMeds = provider.medicines.where((m) => !m.isExpired).toList();

    if (activeMeds.isEmpty) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No active medications listed for today.',
              style: TextStyle(color: MaatriColors.slate),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Shared Medication Reminders',
          icon: Icons.medication_rounded,
          iconColor: MaatriColors.coral,
        ),
        const SizedBox(height: MaatriTheme.spacingSm),
        GlassCard(
          padding: const EdgeInsets.all(MaatriTheme.spacingMd),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeMeds.length.clamp(0, 3),
            separatorBuilder: (_, __) => const Divider(color: MaatriColors.lightGray),
            itemBuilder: (context, index) {
              final med = activeMeds[index];
              final timesList = med.selectedTimes.join(', ');
              final todayLogs = med.adherenceLogs[todayStr] ?? {};
              final isTaken = todayLogs.values.any((status) => status == 'Taken');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.medication_rounded,
                      color: isTaken ? MaatriColors.successDark : MaatriColors.coral,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.medicineName, style: MaatriTypography.titleSmall),
                          Text(
                            'Dosage: ${med.dosage} · Times: $timesList',
                            style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isTaken ? MaatriColors.successLight : MaatriColors.warningLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isTaken ? 'Taken' : 'Pending',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isTaken ? MaatriColors.successDark : MaatriColors.warningDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerSupportSuggestions(BuildContext context, int trimester) {
    final Map<int, List<Map<String, String>>> recommendations = {
      1: [
        {'title': 'Morning Sickness Help', 'desc': 'Keep dry crackers near the bed for early morning sickness, and prepare ginger tea.'},
        {'title': 'Offer Extra Rest', 'desc': 'First trimester fatigue is intense. Handle chore responsibilities to let her nap.'},
      ],
      2: [
        {'title': 'Gentle Massage', 'desc': 'Offer a lower back or foot massage to relieve pregnancy aches and growing pressure.'},
        {'title': 'Active Walk', 'desc': 'Take a relaxing 20-minute walk together in the evening for blood circulation.'},
      ],
      3: [
        {'title': 'Hospital Bag Prep', 'desc': 'Ensure the hospital bag is fully packed and placed in an accessible spot.'},
        {'title': 'Breathing Exercises', 'desc': 'Help her practice breathing techniques and labor support postures.'},
      ],
    };

    final list = recommendations[trimester] ?? recommendations[2]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Daily Care Suggestions',
          icon: Icons.favorite_border_rounded,
          iconColor: MaatriColors.coral,
        ),
        const SizedBox(height: MaatriTheme.spacingSm),
        ...list.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GlassCard(
              padding: const EdgeInsets.all(MaatriTheme.spacingMd),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MaatriColors.coral.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, color: MaatriColors.coral, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']!, style: MaatriTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(item['desc']!, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPartnerEmergencyStatus(BuildContext context, UserProvider user) {
    if (!user.isLinked) {
      return const _LockedFeatureCard(message: 'Link your account to view emergency profiles.');
    }
    if (!user.hasEmergencyAlertsPermission) {
      return const _LockedFeatureCard(message: 'Emergency safety info permission is currently disabled.');
    }

    final doctor = user.doctorName;
    final hospital = user.hospitalName;
    final blood = user.bloodGroup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Safety Overview',
          icon: Icons.shield_outlined,
          iconColor: MaatriColors.danger,
        ),
        const SizedBox(height: MaatriTheme.spacingSm),
        GlassCard(
          padding: const EdgeInsets.all(MaatriTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blood.isNotEmpty) ...[
                _buildPartnerInfoRow(Icons.bloodtype_rounded, 'Blood Group', blood),
                const SizedBox(height: 8),
              ],
              if (doctor.isNotEmpty) ...[
                _buildPartnerInfoRow(Icons.person_pin_rounded, 'OB-GYN Doctor', 'Dr. $doctor'),
                const SizedBox(height: 8),
              ],
              if (hospital.isNotEmpty) ...[
                _buildPartnerInfoRow(Icons.local_hospital_rounded, 'Preferred Hospital', hospital),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.safety);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaatriColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                  label: const Text('OPEN EMERGENCY CENTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: MaatriColors.mediumGray),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: MaatriTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.darkGray),
        ),
        Expanded(
          child: Text(value, style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.charcoal)),
        )
      ],
    );
  }
}

class _LockedFeatureCard extends StatelessWidget {
  final String message;
  const _LockedFeatureCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: Colors.grey.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MaatriTheme.spacingMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: MaatriColors.cloudGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: MaatriColors.mediumGray, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: MaatriTypography.bodyMedium.copyWith(
                  color: MaatriColors.slate,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
