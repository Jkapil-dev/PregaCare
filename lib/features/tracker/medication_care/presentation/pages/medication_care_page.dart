import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';

// Models
import 'package:maatricare/core/models/medicine.dart';
import 'package:maatricare/core/models/vaccination.dart';
import 'package:maatricare/core/models/consultation.dart';

// Services
import 'package:maatricare/core/services/medicine_storage_service.dart';
import 'package:maatricare/core/services/vaccination_storage_service.dart';
import 'package:maatricare/core/services/consultation_storage_service.dart';

class MedicationCarePage extends StatefulWidget {
  const MedicationCarePage({super.key});

  @override
  State<MedicationCarePage> createState() => _MedicationCarePageState();
}

class _MedicationCarePageState extends State<MedicationCarePage> {
  final MedicineStorageService _medicineService = MedicineStorageService();
  final VaccinationStorageService _vaccineService = VaccinationStorageService();
  final ConsultationStorageService _consultationService = ConsultationStorageService();

  List<Medicine> _meds = [];
  List<Vaccination> _vaccines = [];
  List<Consultation> _consultations = [];

  bool _isLoading = true;
  int _activeTab = 0; // 0 = Medicines, 1 = Vaccinations, 2 = Consultations

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final medsList = await _medicineService.loadMedicines();
    final vacList = await _vaccineService.loadVaccinations();
    final conList = await _consultationService.loadConsultations();

    setState(() {
      _meds = medsList;
      _vaccines = vacList;
      _consultations = conList;
      _isLoading = false;
    });
  }

  /// Calculates dynamic total adherence rate across all saved medicines
  double _calculateOverallAdherence() {
    int totalTaken = 0;
    int totalMissed = 0;
    for (final med in _meds) {
      med.adherenceLogs.forEach((date, statusMap) {
        statusMap.forEach((time, status) {
          if (status == 'Taken') totalTaken++;
          if (status == 'Missed') totalMissed++;
        });
      });
    }
    final loggedCount = totalTaken + totalMissed;
    if (loggedCount == 0) return 100.0;
    return (totalTaken / loggedCount) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final overallAdherence = _calculateOverallAdherence();

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Medication & Care'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(MaatriTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Antenatal Care Suite', style: MaatriTypography.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Schedules, immunizations, and clinical appointments', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // ── ADHERENCE DASHBOARD ──
                  _buildAdherenceDashboard(overallAdherence),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // ── Premium Tab Switcher ──
                  _buildPremiumTabSwitcher(),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // ── ACTIVE CONTENT PANEL ──
                  if (_activeTab == 0) ...[
                    _buildMedicinesSection(todayStr),
                  ] else if (_activeTab == 1) ...[
                    _buildVaccinationsSection(),
                  ] else ...[
                    _buildConsultationsSection(),
                  ],
                  const SizedBox(height: MaatriTheme.spacingXxl),
                ],
              ),
            ),
    );
  }

  Widget _buildAdherenceDashboard(double overallAdherence) {
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
              const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text('Care analytics', style: MaatriTypography.titleMedium.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medication Adherence', style: MaatriTypography.headlineMedium.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Continuous schedules protect maternal health', style: MaatriTypography.bodySmall.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${overallAdherence.toStringAsFixed(0)}%',
                  style: MaatriTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MaatriColors.cloudGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSingleTab(0, 'Meds', Icons.medication_rounded),
          _buildSingleTab(1, 'Vaccines', Icons.shield_rounded),
          _buildSingleTab(2, 'ANC Appts', Icons.event_available_rounded),
        ],
      ),
    );
  }

  Widget _buildSingleTab(int index, String label, IconData icon) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? MaatriColors.pureWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? MaatriTheme.shadowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? MaatriColors.coral : MaatriColors.slate, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: MaatriTypography.labelMedium.copyWith(
                  color: active ? MaatriColors.charcoal : MaatriColors.slate,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1. MEDICINES SUB-MODULE ───────────────────────────────────────────────
  Widget _buildMedicinesSection(String todayStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Medications', style: MaatriTypography.titleMedium),
            ElevatedButton.icon(
              onPressed: () => _showMedDialog(null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Med'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaatriColors.coral,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_meds.isEmpty) ...[
          _buildEmptyPlaceholder('No medications logged.', Icons.medication_outlined),
        ] else ...[
          ..._meds.map((med) => _buildMedicineCard(med, todayStr)),
        ]
      ],
    );
  }

  Widget _buildMedicineCard(Medicine med, String todayStr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: med.isExpired 
                        ? MaatriColors.mediumGray.withValues(alpha: 0.12)
                        : MaatriColors.coralLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    med.isExpired ? Icons.history_rounded : Icons.medication_rounded, 
                    color: med.isExpired ? MaatriColors.mediumGray : MaatriColors.coral, 
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              med.medicineName, 
                              style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showMedDialog(med),
                            child: const Icon(Icons.edit_outlined, color: MaatriColors.teal, size: 20),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _confirmDeleteMed(med.id),
                            child: const Icon(Icons.delete_outline_rounded, color: MaatriColors.danger, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${med.dosage} · ${med.mealType}', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                      const SizedBox(height: 4),
                      Text(
                        med.isExpired 
                            ? 'Schedule Completed' 
                            : '${med.remainingDays} days remaining', 
                        style: MaatriTypography.labelSmall.copyWith(
                          color: med.isExpired ? MaatriColors.mediumGray : MaatriColors.teal, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            med.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                            size: 14,
                            color: med.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            med.reminderEnabled ? '🔔 Reminder Active' : 'Reminders Disabled',
                            style: MaatriTypography.labelSmall.copyWith(color: med.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('Intake Tracker Status:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.charcoal)),
            const SizedBox(height: 8),
            
            // Interactive taken check buttons
            ...med.selectedTimes.map((timeLabel) {
              final status = med.adherenceLogs[todayStr]?[timeLabel] ?? 'Pending';
              
              IconData statusIcon = Icons.check_box_outline_blank_rounded;
              Color statusColor = MaatriColors.slate;
              if (status == 'Taken') {
                statusIcon = Icons.check_box_rounded;
                statusColor = MaatriColors.success;
              } else if (status == 'Missed') {
                statusIcon = Icons.disabled_by_default_rounded;
                statusColor = MaatriColors.danger;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$timeLabel $status', 
                        style: MaatriTypography.bodyMedium.copyWith(
                          color: statusColor,
                          fontWeight: status == 'Pending' ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        InkWell(
                          onTap: () async {
                            await _medicineService.updateAdherence(med.id, todayStr, timeLabel, 'Taken');
                            _loadAllData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Taken' ? MaatriColors.success.withValues(alpha: 0.15) : Colors.transparent,
                              border: Border.all(color: MaatriColors.success),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Taken', style: TextStyle(color: MaatriColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await _medicineService.updateAdherence(med.id, todayStr, timeLabel, 'Missed');
                            _loadAllData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Missed' ? MaatriColors.danger.withValues(alpha: 0.15) : Colors.transparent,
                              border: Border.all(color: MaatriColors.danger),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Missed', style: TextStyle(color: MaatriColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await _medicineService.updateAdherence(med.id, todayStr, timeLabel, 'Pending');
                            _loadAllData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Pending' ? MaatriColors.mediumGray.withValues(alpha: 0.15) : Colors.transparent,
                              border: Border.all(color: MaatriColors.mediumGray),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Reset', style: TextStyle(color: MaatriColors.mediumGray, fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── 2. VACCINATIONS SUB-MODULE ────────────────────────────────────────────
  Widget _buildVaccinationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Maternal Immunizations', style: MaatriTypography.titleMedium),
            ElevatedButton.icon(
              onPressed: () => _showVaccineDialog(null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Vaccine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaatriColors.coral,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_vaccines.isEmpty) ...[
          _buildEmptyPlaceholder('No immunization records logged.', Icons.shield_outlined),
        ] else ...[
          ..._vaccines.map((vac) => _buildVaccinationCard(vac)),
        ]
      ],
    );
  }

  Widget _buildVaccinationCard(Vaccination vac) {
    Color statusColor;
    IconData statusIcon;

    if (vac.vaccinationStatus == 'Completed') {
      statusColor = MaatriColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (vac.vaccinationStatus == 'Missed') {
      statusColor = MaatriColors.danger;
      statusIcon = Icons.cancel_rounded;
    } else if (vac.isOverdue) {
      statusColor = MaatriColors.danger;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = MaatriColors.goldenAmber;
      statusIcon = Icons.schedule_rounded;
    }

    final displayStatus = vac.isOverdue ? 'Overdue' : vac.vaccinationStatus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vac.vaccineName,
                              style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showVaccineDialog(vac),
                            child: const Icon(Icons.edit_outlined, color: MaatriColors.teal, size: 20),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _confirmDeleteVaccine(vac.id),
                            child: const Icon(Icons.delete_outline_rounded, color: MaatriColors.danger, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(vac.doseNumber, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled: ${DateFormat('dd MMM yyyy').format(vac.scheduledDate)}',
                        style: MaatriTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (vac.hospitalOrClinic.isNotEmpty || vac.doctorName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${vac.hospitalOrClinic} ${vac.doctorName.isNotEmpty ? "· " + vac.doctorName : ""}',
                          style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate, fontSize: 11),
                        ),
                      ],
                      if (vac.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MaatriColors.cloudGray,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vac.notes,
                            style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.charcoal, fontStyle: FontStyle.italic, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayStatus,
                    style: MaatriTypography.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      vac.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                      size: 14,
                      color: vac.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vac.reminderEnabled ? 'Reminder Active' : 'Off',
                      style: MaatriTypography.labelSmall.copyWith(color: vac.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. CONSULTATIONS SUB-MODULE ───────────────────────────────────────────
  Widget _buildConsultationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Antenatal Consultations', style: MaatriTypography.titleMedium),
            ElevatedButton.icon(
              onPressed: () => _showConsultationDialog(null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaatriColors.coral,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_consultations.isEmpty) ...[
          _buildEmptyPlaceholder('No consultations scheduled.', Icons.event_available_outlined),
        ] else ...[
          ..._consultations.map((con) => _buildConsultationCard(con)),
        ]
      ],
    );
  }

  Widget _buildConsultationCard(Consultation con) {
    Color statusColor;
    IconData statusIcon;

    if (con.consultationStatus == 'Completed') {
      statusColor = MaatriColors.success;
      statusIcon = Icons.done_all_rounded;
    } else if (con.consultationStatus == 'Cancelled') {
      statusColor = MaatriColors.mediumGray;
      statusIcon = Icons.close_rounded;
    } else if (con.consultationStatus == 'Missed') {
      statusColor = MaatriColors.danger;
      statusIcon = Icons.event_busy_rounded;
    } else {
      statusColor = MaatriColors.teal;
      statusIcon = Icons.event_available_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              con.doctorName,
                              style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showConsultationDialog(con),
                            child: const Icon(Icons.edit_outlined, color: MaatriColors.teal, size: 20),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _confirmDeleteConsultation(con.id),
                            child: const Icon(Icons.delete_outline_rounded, color: MaatriColors.danger, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(con.specialization, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(con.appointmentDate)} · ${con.appointmentTime}',
                        style: MaatriTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: MaatriColors.coral),
                      ),
                      if (con.hospitalOrClinic.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(con.hospitalOrClinic, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate, fontSize: 11)),
                      ],
                      if (con.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MaatriColors.cloudGray,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            con.notes,
                            style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.charcoal, fontStyle: FontStyle.italic, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    con.consultationStatus,
                    style: MaatriTypography.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      con.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                      size: 14,
                      color: con.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      con.reminderEnabled ? '🔔 Reminder Active' : 'Off',
                      style: MaatriTypography.labelSmall.copyWith(color: con.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. COMMON HELPERS ─────────────────────────────────────────────────────
  Widget _buildEmptyPlaceholder(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: MaatriColors.mediumGray.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message, style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
          ],
        ),
      ),
    );
  }

  // ─── 5. DIALOGS & SAVE CONTROLLERS ─────────────────────────────────────────

  // ── Medicine Dialog Editor
  void _showMedDialog(Medicine? existingMed) {
    final isEditing = existingMed != null;
    final nameCtrl = TextEditingController(text: existingMed?.medicineName ?? '');
    final dosageCtrl = TextEditingController(text: existingMed?.dosage ?? '');
    final durationCtrl = TextEditingController(text: existingMed?.durationDays.toString() ?? '7');
    final notesCtrl = TextEditingController(text: existingMed?.notes ?? '');

    List<String> selectedTimes = existingMed != null ? List<String>.from(existingMed.selectedTimes) : ['Morning'];
    String mealType = existingMed?.mealType ?? 'After Meal';
    DateTime startDate = existingMed?.startDate ?? DateTime.now();
    bool reminderEnabled = existingMed?.reminderEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final duration = int.tryParse(durationCtrl.text) ?? 1;
          final calculatedEndDate = startDate.add(Duration(days: duration > 0 ? duration - 1 : 0));

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Edit Medicine' : 'Add Medicine', style: MaatriTypography.headlineSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl, 
                    decoration: const InputDecoration(
                      hintText: 'Medicine name',
                      prefixIcon: Icon(Icons.medication_rounded, color: MaatriColors.coral),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageCtrl, 
                    decoration: const InputDecoration(
                      hintText: 'Dosage (e.g. 1 Tablet, 500mg)',
                      prefixIcon: Icon(Icons.medical_services_outlined, color: MaatriColors.coral),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (date != null) setS(() => startDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: MaatriColors.lightGray),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: MaatriColors.slate),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd MMM yyyy').format(startDate)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: durationCtrl, 
                          keyboardType: TextInputType.number, 
                          decoration: const InputDecoration(hintText: 'Days', suffixText: 'days'),
                          onChanged: (_) => setS(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active until: ${DateFormat('dd MMM yyyy').format(calculatedEndDate)}', 
                    style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.teal, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Text('Scheduled Times', style: MaatriTypography.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Morning', 'Afternoon', 'Night'].map((timeOption) {
                      final isSelected = selectedTimes.contains(timeOption);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(timeOption),
                          selected: isSelected,
                          selectedColor: MaatriColors.coralLight.withValues(alpha: 0.4),
                          checkmarkColor: MaatriColors.coral,
                          onSelected: (checked) {
                            setS(() {
                              if (checked) {
                                selectedTimes.add(timeOption);
                              } else if (selectedTimes.length > 1) {
                                selectedTimes.remove(timeOption);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('At least one scheduled timing must be active.')),
                                );
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Text('Meal Relation Type', style: MaatriTypography.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Before Meal', 'After Meal', 'With Meal', 'Empty Stomach'].map((m) =>
                      ChoiceChip(
                        label: Text(m), 
                        selected: mealType == m, 
                        selectedColor: MaatriColors.tealLight.withValues(alpha: 0.4),
                        onSelected: (_) => setS(() => mealType = m),
                      ),
                    ).toList(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reminders Enabled', style: MaatriTypography.labelLarge),
                      Switch(
                        value: reminderEnabled, 
                        activeColor: MaatriColors.teal,
                        onChanged: (v) => setS(() => reminderEnabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: notesCtrl, 
                    decoration: const InputDecoration(
                      hintText: 'Additional notes (optional)',
                      prefixIcon: Icon(Icons.description_outlined, color: MaatriColors.slate),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final duration = int.tryParse(durationCtrl.text) ?? 0;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a medicine name.'), backgroundColor: MaatriColors.danger),
                          );
                          return;
                        }

                        if (duration <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid duration of days.'), backgroundColor: MaatriColors.danger),
                          );
                          return;
                        }

                        final med = Medicine(
                          id: isEditing ? existingMed.id : UniqueKey().toString(),
                          medicineName: name,
                          dosage: dosageCtrl.text.trim(),
                          selectedTimes: selectedTimes,
                          mealType: mealType,
                          startDate: startDate,
                          endDate: calculatedEndDate,
                          durationDays: duration,
                          notes: notesCtrl.text.trim(),
                          reminderEnabled: reminderEnabled,
                          adherenceLogs: isEditing ? existingMed.adherenceLogs : const {},
                        );

                        await _medicineService.saveMedicine(med);
                        Navigator.pop(ctx);
                        _loadAllData();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Medicine updated successfully! ✓' : 'Medicine saved successfully! ✓'),
                            backgroundColor: MaatriColors.success,
                          ),
                        );
                      },
                      child: Text(isEditing ? 'Update Medicine' : 'Add Medicine'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Vaccination Dialog Editor
  void _showVaccineDialog(Vaccination? existingVac) {
    final isEditing = existingVac != null;
    final nameCtrl = TextEditingController(text: existingVac?.vaccineName ?? '');
    final doseCtrl = TextEditingController(text: existingVac?.doseNumber ?? 'Dose 1');
    final clinicCtrl = TextEditingController(text: existingVac?.hospitalOrClinic ?? '');
    final docCtrl = TextEditingController(text: existingVac?.doctorName ?? '');
    final notesCtrl = TextEditingController(text: existingVac?.notes ?? '');

    DateTime scheduledDate = existingVac?.scheduledDate ?? DateTime.now().add(const Duration(days: 7));
    String status = existingVac?.vaccinationStatus ?? 'Upcoming';
    bool reminderEnabled = existingVac?.reminderEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Edit Vaccination' : 'Add Vaccination', style: MaatriTypography.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Vaccine name (e.g. TT Vaccine, Tdap)',
                    prefixIcon: Icon(Icons.shield_rounded, color: MaatriColors.coral),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doseCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Dose Number (e.g. Dose 1, Booster)',
                    prefixIcon: Icon(Icons.numbers_rounded, color: MaatriColors.coral),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: scheduledDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setS(() => scheduledDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: MaatriColors.lightGray),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: MaatriColors.slate),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd MMM yyyy').format(scheduledDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: clinicCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Hospital or Clinic Name',
                    prefixIcon: Icon(Icons.local_hospital_outlined, color: MaatriColors.slate),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: docCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Consultant Doctor Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: MaatriColors.slate),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Vaccination Status', style: MaatriTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Upcoming', 'Completed', 'Missed'].map((s) =>
                    ChoiceChip(
                      label: Text(s),
                      selected: status == s,
                      selectedColor: MaatriColors.tealLight.withValues(alpha: 0.4),
                      onSelected: (_) => setS(() => status = s),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reminder Alert 1 Day Before', style: MaatriTypography.labelLarge),
                    Switch(
                      value: reminderEnabled,
                      activeColor: MaatriColors.teal,
                      onChanged: (v) => setS(() => reminderEnabled = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Additional notes or requirements',
                    prefixIcon: Icon(Icons.description_outlined, color: MaatriColors.slate),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a vaccine name.'), backgroundColor: MaatriColors.danger),
                        );
                        return;
                      }

                      final vac = Vaccination(
                        id: isEditing ? existingVac.id : UniqueKey().toString(),
                        vaccineName: name,
                        doseNumber: doseCtrl.text.trim(),
                        scheduledDate: scheduledDate,
                        hospitalOrClinic: clinicCtrl.text.trim(),
                        doctorName: docCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                        reminderEnabled: reminderEnabled,
                        vaccinationStatus: status,
                      );

                      await _vaccineService.saveVaccination(vac);
                      Navigator.pop(ctx);
                      _loadAllData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Vaccination schedule updated! ✓' : 'Vaccination saved! ✓'),
                          backgroundColor: MaatriColors.success,
                        ),
                      );
                    },
                    child: Text(isEditing ? 'Update Immunization' : 'Save Immunization'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Consultation Dialog Editor
  void _showConsultationDialog(Consultation? existingCon) {
    final isEditing = existingCon != null;
    final docCtrl = TextEditingController(text: existingCon?.doctorName ?? '');
    final specCtrl = TextEditingController(text: existingCon?.specialization ?? 'Gynecologist');
    final clinicCtrl = TextEditingController(text: existingCon?.hospitalOrClinic ?? '');
    final timeCtrl = TextEditingController(text: existingCon?.appointmentTime ?? '10:30 AM');
    final notesCtrl = TextEditingController(text: existingCon?.notes ?? '');

    DateTime appointmentDate = existingCon?.appointmentDate ?? DateTime.now().add(const Duration(days: 3));
    String status = existingCon?.consultationStatus ?? 'Upcoming';
    bool reminderEnabled = existingCon?.reminderEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Edit ANC Appointment' : 'Add ANC Appointment', style: MaatriTypography.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: docCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Doctor Name (e.g. Dr. Anya Sharma)',
                    prefixIcon: Icon(Icons.person_pin_rounded, color: MaatriColors.coral),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Specialization (e.g. Gynecologist)',
                    prefixIcon: Icon(Icons.badge_rounded, color: MaatriColors.coral),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: appointmentDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setS(() => appointmentDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: MaatriColors.lightGray),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: MaatriColors.slate),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd MMM yyyy').format(appointmentDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Time (e.g. 10:30 AM)',
                          suffixIcon: Icon(Icons.access_time_rounded, size: 16, color: MaatriColors.slate),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: clinicCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Hospital or Clinic Location',
                    prefixIcon: Icon(Icons.local_hospital_outlined, color: MaatriColors.slate),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Consultation Status', style: MaatriTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Upcoming', 'Completed', 'Cancelled'].map((s) =>
                    ChoiceChip(
                      label: Text(s),
                      selected: status == s,
                      selectedColor: MaatriColors.tealLight.withValues(alpha: 0.4),
                      onSelected: (_) => setS(() => status = s),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reminder Alert 1 Day Before', style: MaatriTypography.labelLarge),
                    Switch(
                      value: reminderEnabled,
                      activeColor: MaatriColors.teal,
                      onChanged: (v) => setS(() => reminderEnabled = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Additional notes (e.g. carry blood report)',
                    prefixIcon: Icon(Icons.description_outlined, color: MaatriColors.slate),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final doc = docCtrl.text.trim();
                      if (doc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a doctor name.'), backgroundColor: MaatriColors.danger),
                        );
                        return;
                      }

                      final con = Consultation(
                        id: isEditing ? existingCon.id : UniqueKey().toString(),
                        doctorName: doc,
                        specialization: specCtrl.text.trim(),
                        hospitalOrClinic: clinicCtrl.text.trim(),
                        appointmentDate: appointmentDate,
                        appointmentTime: timeCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                        reminderEnabled: reminderEnabled,
                        consultationStatus: status,
                      );

                      await _consultationService.saveConsultation(con);
                      Navigator.pop(ctx);
                      _loadAllData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'ANC Appointment details updated! ✓' : 'ANC Appointment saved! ✓'),
                          backgroundColor: MaatriColors.success,
                        ),
                      );
                    },
                    child: Text(isEditing ? 'Update Appointment' : 'Save Appointment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Medicines Delete Confirmation
  void _confirmDeleteMed(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Medicine?'),
        content: const Text('Are you sure you want to delete this medicine? All scheduled reminders will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _medicineService.deleteMedicine(id);
              _loadAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medication removed.'), backgroundColor: MaatriColors.charcoal, behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Vaccination Delete Confirmation
  void _confirmDeleteVaccine(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Immunization?'),
        content: const Text('Are you sure you want to remove this vaccination schedule? Scheduled alerts will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _vaccineService.deleteVaccination(id);
              _loadAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Immunization record deleted.'), backgroundColor: MaatriColors.charcoal, behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Consultation Delete Confirmation
  void _confirmDeleteConsultation(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Appointment?'),
        content: const Text('Are you sure you want to delete this ANC follow-up checkup? Scheduled reminders will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _consultationService.deleteConsultation(id);
              _loadAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Consultation appointment removed.'), backgroundColor: MaatriColors.charcoal, behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
