import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';
import 'package:maatricare/core/models/medicine.dart';
import 'package:maatricare/core/services/medicine_storage_service.dart';

class MedicationCarePage extends StatefulWidget {
  const MedicationCarePage({super.key});

  @override
  State<MedicationCarePage> createState() => _MedicationCarePageState();
}

class _MedicationCarePageState extends State<MedicationCarePage> {
  final MedicineStorageService _storageService = MedicineStorageService();
  List<Medicine> _meds = [];
  bool _isLoadingMeds = true;

  // Vaccines
  final List<_Vaccine> _vaccines = [
    _Vaccine('Tetanus Toxoid (TT-1)', 'Given at Week 16-20', true, '12 Mar 2026'),
    _Vaccine('Tetanus Toxoid (TT-2)', 'Given at Week 20-24', true, '18 Apr 2026'),
    _Vaccine('Tdap Booster', 'Given at Week 27-36', false, 'Pending'),
    _Vaccine('Influenza Vaccine', 'Given during Seasonality', false, 'Pending'),
  ];

  // Appointments
  final List<_Appointment> _appointments = [
    _Appointment('Obstetrician Follow-up', 'Dr. Anya Sharma', '28 May 2026', '10:30 AM'),
    _Appointment('Ultrasound Anomaly Scan', 'Fortis Imaging Lab', '04 Jun 2026', '02:00 PM'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    setState(() => _isLoadingMeds = true);
    final list = await _storageService.loadMedicines();
    setState(() {
      _meds = list;
      _isLoadingMeds = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Medication & Care'),
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
            Text('Prescriptions & Schedules', style: MaatriTypography.headlineMedium),
            const SizedBox(height: 4),
            Text('Keep your medication timing and checkups aligned', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
            const SizedBox(height: MaatriTheme.spacingLg),

            // ── MEDICINES LIST ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Medications', style: MaatriTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: MaatriColors.coral),
                  onPressed: () => _showMedDialog(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingMeds)
              const Center(child: CircularProgressIndicator())
            else if (_meds.isEmpty)
              Text('No medications logged yet.', style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate))
            else
              ..._meds.map((med) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  onTap: () => _showMedDialog(med),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: MaatriColors.coralLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.medication_rounded, color: MaatriColors.coral, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.medicineName, style: MaatriTypography.titleSmall),
                            Text('${med.dosage} · ${med.timeSchedule}', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                          ],
                        ),
                      ),
                      Icon(
                        med.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                        color: med.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              )),

            const SizedBox(height: MaatriTheme.spacingLg),

            // ── VACCINATION STATUS ──
            Text('Maternal Vaccinations', style: MaatriTypography.titleMedium),
            const SizedBox(height: 8),
            ..._vaccines.map((vac) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                child: Row(
                  children: [
                    Checkbox(
                      value: vac.taken,
                      activeColor: MaatriColors.teal,
                      onChanged: (val) {
                        setState(() {
                          vac.taken = val ?? false;
                          vac.date = vac.taken ? DateFormat('dd MMM yyyy').format(DateTime.now()) : 'Pending';
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vac.name, style: MaatriTypography.titleSmall),
                          Text(vac.notes, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                        ],
                      ),
                    ),
                    Text(vac.date, style: MaatriTypography.labelSmall.copyWith(color: vac.taken ? MaatriColors.success : MaatriColors.mediumGray, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )),

            const SizedBox(height: MaatriTheme.spacingLg),

            // ── UPCOMING APPOINTMENTS ──
            Text('Upcoming Consultations', style: MaatriTypography.titleMedium),
            const SizedBox(height: 8),
            ..._appointments.map((app) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: MaatriColors.tealLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.event_available_rounded, color: MaatriColors.teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.type, style: MaatriTypography.titleSmall),
                          Text(app.doctor, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(app.date, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.coral, fontWeight: FontWeight.bold)),
                        Text(app.time, style: MaatriTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  // ── MEDICINES DIALOG ──
  void _showMedDialog(Medicine? existingMed) {
    final isEditing = existingMed != null;
    final nameCtrl = TextEditingController(text: existingMed?.medicineName ?? '');
    final dosageCtrl = TextEditingController(text: existingMed?.dosage ?? '');
    final durationCtrl = TextEditingController(text: existingMed?.durationDays.toString() ?? '7');
    final notesCtrl = TextEditingController(text: existingMed?.notes ?? '');

    List<String> selectedTimes = existingMed != null ? List<String>.from(existingMed.selectedTimes) : ['Morning'];
    String mealTiming = existingMed?.mealTiming ?? 'Not Applicable';
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
                  TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Medicine name')),
                  const SizedBox(height: 12),
                  TextField(controller: dosageCtrl, decoration: const InputDecoration(hintText: 'Dosage')),
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
                            decoration: BoxDecoration(border: Border.all(color: MaatriColors.lightGray), borderRadius: BorderRadius.circular(12)),
                            child: Text(DateFormat('dd MMM yyyy').format(startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Days')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('End Date: ${DateFormat('dd MMM yyyy').format(calculatedEndDate)}', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.teal)),
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
                          onSelected: (checked) {
                            setS(() {
                              if (checked) {
                                selectedTimes.add(timeOption);
                              } else if (selectedTimes.length > 1) {
                                selectedTimes.remove(timeOption);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reminders Enabled', style: MaatriTypography.labelLarge),
                      Switch(value: reminderEnabled, onChanged: (v) => setS(() => reminderEnabled = v)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        final med = Medicine(
                          id: isEditing ? existingMed.id : UniqueKey().toString(),
                          medicineName: name,
                          dosage: dosageCtrl.text.trim(),
                          selectedTimes: selectedTimes,
                          startDate: startDate,
                          endDate: calculatedEndDate,
                          durationDays: duration,
                          notes: notesCtrl.text.trim(),
                          mealTiming: mealTiming,
                          reminderEnabled: reminderEnabled,
                        );

                        await _storageService.saveMedicine(med);
                        Navigator.pop(ctx);
                        _loadMeds();
                      },
                      child: const Text('Save Medication'),
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
}

class _Vaccine {
  final String name;
  final String notes;
  bool taken;
  String date;

  _Vaccine(this.name, this.notes, this.taken, this.date);
}

class _Appointment {
  final String type;
  final String doctor;
  final String date;
  final String time;

  _Appointment(this.type, this.doctor, this.date, this.time);
}
