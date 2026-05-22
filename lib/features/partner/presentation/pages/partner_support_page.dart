import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/medicine_provider.dart';
import '../../../../core/providers/appointment_provider.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:go_router/go_router.dart';

class PartnerSupportPage extends StatefulWidget {
  const PartnerSupportPage({super.key});

  @override
  State<PartnerSupportPage> createState() => _PartnerSupportPageState();
}

class _PartnerSupportPageState extends State<PartnerSupportPage> {
  // Local daily support checklist
  final Map<int, List<String>> _trimesterTasks = {
    1: [
      'Prepare a light, anti-nausea meal or snack.',
      'Refill her water bottle and ensure she drinks 8+ glasses.',
      'Encourage a 15-minute relaxation or power nap.',
      'Research early pregnancy milestones together.',
    ],
    2: [
      'Offer a gentle back or foot massage.',
      'Plan or discuss the nursery and baby registry ideas.',
      'Go on a peaceful evening walk together.',
      'Ensure she is taking her iron and calcium supplements.',
    ],
    3: [
      'Pack or check the hospital bag essentials.',
      'Review and practice breathing/labor exercises.',
      'Double-check that all emergency contacts are updated.',
      'Help her with shoes or lifting any items.',
    ]
  };

  final Map<String, bool> _completedTasks = {};

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);
    final apptProvider = Provider.of<AppointmentProvider>(context);

    final trimester = userProvider.trimester;
    final tasks = _trimesterTasks[trimester] ?? _trimesterTasks[2]!;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MaatriTheme.spacingMd),
              _buildHeader(userProvider),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Trimester Support Tips
              SectionHeader(
                title: 'Companion Checklist (Trimester $trimester)',
                icon: Icons.assignment_turned_in_rounded,
                iconColor: MaatriColors.teal,
              ),
              const SizedBox(height: MaatriTheme.spacingSm),
              _buildCompanionChecklist(tasks),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Shared Medication Reminders
              SectionHeader(
                title: 'Medication Reminders',
                icon: Icons.medication_rounded,
                iconColor: MaatriColors.coral,
              ),
              const SizedBox(height: MaatriTheme.spacingSm),
              _buildMedicationReminders(userProvider, medProvider),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Shared Appointments
              SectionHeader(
                title: 'Upcoming Appointments',
                icon: Icons.calendar_today_rounded,
                iconColor: MaatriColors.lavenderDark,
              ),
              const SizedBox(height: MaatriTheme.spacingSm),
              _buildAppointments(userProvider, apptProvider),
              const SizedBox(height: MaatriTheme.spacingLg),

              // Emergency quick contacts
              SectionHeader(
                title: 'Safety & Emergency Contacts',
                icon: Icons.shield_outlined,
                iconColor: MaatriColors.danger,
              ),
              const SizedBox(height: MaatriTheme.spacingSm),
              _buildEmergencyCard(userProvider),
              const SizedBox(height: MaatriTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserProvider userProvider) {
    final motherName = userProvider.motherProfile?['displayName'] ?? 'Mama';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Hub',
          style: MaatriTypography.headlineLarge.copyWith(color: MaatriColors.charcoal),
        ),
        const SizedBox(height: 4),
        Text(
          'Helping you care for $motherName during Week ${userProvider.pregnancyWeek}.',
          style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
        ),
      ],
    );
  }

  Widget _buildCompanionChecklist(List<String> tasks) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: MaatriTheme.spacingSm, horizontal: MaatriTheme.spacingMd),
      child: Column(
        children: tasks.map((task) {
          final isCompleted = _completedTasks[task] ?? false;
          return CheckboxListTile(
            title: Text(
              task,
              style: MaatriTypography.bodyMedium.copyWith(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? MaatriColors.slate : MaatriColors.charcoal,
              ),
            ),
            activeColor: MaatriColors.teal,
            value: isCompleted,
            onChanged: (val) {
              setState(() {
                _completedTasks[task] = val ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicationReminders(UserProvider user, MedicineProvider provider) {
    if (!user.isLinked) {
      return const _LockedFeatureCard(message: 'Link your account to view shared pregnancy reminders.');
    }
    if (!user.hasMedicinesPermission || !user.hasRemindersPermission) {
      return const _LockedFeatureCard(message: 'Medication reminders permission is currently disabled by the Mother.');
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

    return GlassCard(
      padding: const EdgeInsets.all(MaatriTheme.spacingMd),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activeMeds.length,
        separatorBuilder: (_, __) => const Divider(color: MaatriColors.lightGray),
        itemBuilder: (context, index) {
          final med = activeMeds[index];
          final timesList = med.selectedTimes.join(', ');
          
          // Adherence status check for today
          final todayLogs = med.adherenceLogs[todayStr] ?? {};
          final isTaken = todayLogs.values.any((status) => status == 'Taken');

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.medication_rounded,
                  color: isTaken ? MaatriColors.successDark : MaatriColors.coral,
                  size: 26,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTaken ? MaatriColors.successLight : MaatriColors.warningLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isTaken ? 'Taken' : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
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
    );
  }

  Widget _buildAppointments(UserProvider user, AppointmentProvider provider) {
    if (!user.isLinked) {
      return const _LockedFeatureCard(message: 'Link your account to view shared appointments.');
    }
    if (!user.hasAppointmentsPermission) {
      return const _LockedFeatureCard(message: 'Appointment details permission is currently disabled by the Mother.');
    }

    final next = provider.nextAppointment;
    if (next == null) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No upcoming appointments scheduled.',
              style: TextStyle(color: MaatriColors.slate),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MaatriColors.lavenderLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services_rounded, color: MaatriColors.lavenderDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${next.doctorName}', style: MaatriTypography.titleSmall),
                    Text(next.specialization, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: MaatriColors.mediumGray),
              const SizedBox(width: 6),
              Text(
                '${next.appointmentDate.day}/${next.appointmentDate.month}/${next.appointmentDate.year} at ${next.appointmentTime}',
                style: MaatriTypography.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: MaatriColors.mediumGray),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  next.hospitalOrClinic,
                  style: MaatriTypography.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(UserProvider user) {
    if (!user.isLinked) {
      return const _LockedFeatureCard(message: 'Link your account to view safety details.');
    }
    if (!user.hasEmergencyAlertsPermission) {
      return const _LockedFeatureCard(message: 'Emergency safety info permission is currently disabled.');
    }

    final doctor = user.doctorName;
    final hospital = user.hospitalName;
    final emergencyPhone = user.emergencyContactPhone;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doctor.isNotEmpty) ...[
            _buildInfoRow(Icons.person_pin_rounded, 'OB-GYN Doctor', 'Dr. $doctor'),
            const SizedBox(height: 8),
          ],
          if (hospital.isNotEmpty) ...[
            _buildInfoRow(Icons.local_hospital_rounded, 'Preferred Hospital', hospital),
            const SizedBox(height: 8),
          ],
          if (emergencyPhone.isNotEmpty) ...[
            _buildInfoRow(Icons.phone_in_talk_rounded, 'SOS Contact', emergencyPhone),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.emergency),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaatriColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                ),
              ),
              icon: const Icon(Icons.shield_outlined, color: Colors.white),
              label: const Text('OPEN EMERGENCY CENTER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: MaatriColors.mediumGray),
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
      backgroundColor: Colors.grey.withOpacity( 0.05),
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
