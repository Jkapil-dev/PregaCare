import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/models/medicine.dart';
import '../../../../core/services/medicine_storage_service.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});
  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final MedicineStorageService _storageService = MedicineStorageService();

  // Medicines List
  List<Medicine> _meds = [];

  // Health Notes
  final List<_Note> _notes = [
    _Note('Feeling slight dizziness in mornings', DateTime.now().subtract(const Duration(days: 1)), true),
    _Note('Ask doctor about vitamin D levels', DateTime.now().subtract(const Duration(days: 3)), true),
  ];
  final _noteCtrl = TextEditingController();

  // Weight
  final List<_WeightEntry> _weights = [
    _WeightEntry(12, 58.0), _WeightEntry(16, 60.5), _WeightEntry(20, 63.0), _WeightEntry(24, 66.0),
  ];

  // Mood
  final List<_MoodEntry> _moods = [
    _MoodEntry('Happy', '😊', DateTime.now()),
    _MoodEntry('Calm', '😌', DateTime.now().subtract(const Duration(days: 1))),
    _MoodEntry('Tired', '😴', DateTime.now().subtract(const Duration(days: 2))),
  ];

  // Documents
  final List<_Doc> _docs = [
    _Doc('Ultrasound Scan', 'May 10, 2026', Icons.image_rounded),
    _Doc('Blood Report', 'Apr 28, 2026', Icons.description_rounded),
  ];

  bool _docsExpanded = true;
  bool _isLoadingMeds = true;

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    setState(() => _isLoadingMeds = true);
    final medsList = await _storageService.loadMedicines();
    setState(() {
      _meds = medsList;
      _isLoadingMeds = false;
    });
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MaatriTheme.spacingMd),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: MaatriTheme.spacingSm),
            Text('Health Tracking', style: MaatriTypography.headlineLarge),
            const SizedBox(height: 4),
            Text('Monitor your health and baby\'s wellness', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),

            // ── MEDICATIONS ──
            const SizedBox(height: MaatriTheme.spacingLg),
            _sectionTitle('Medications', Icons.medication_rounded, MaatriColors.coral, onAdd: () => _showMedDialog(null)),

            // Upcoming strip
            const SizedBox(height: MaatriTheme.spacingSm),
            if (_isLoadingMeds)
              const Center(child: CircularProgressIndicator())
            else if (_meds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No active medications logged.', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
              )
            else ...[
              // Show next 2 upcoming medications that are active
              SizedBox(height: 100, child: ListView.separated(
                scrollDirection: Axis.horizontal, 
                itemCount: _meds.where((m) => m.isActive).take(2).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (c, i) {
                  final med = _meds.where((m) => m.isActive).toList()[i];
                  return Container(width: 220, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(gradient: MaatriColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [const Icon(Icons.medication_rounded, color: Colors.white, size: 18), const SizedBox(width: 6),
                        Expanded(child: Text(med.medicineName, overflow: TextOverflow.ellipsis, style: MaatriTypography.titleSmall.copyWith(color: Colors.white)))]),
                      Text('${med.dosage} · ${med.mealTiming}', style: MaatriTypography.labelSmall.copyWith(color: Colors.white70)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(med.selectedTimes.join(', '), style: MaatriTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('${med.remainingDays}d left', style: MaatriTypography.labelSmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ]),
                  );
                },
              )),

              // All meds list
              const SizedBox(height: MaatriTheme.spacingSm),
              ...List.generate(_meds.length, (i) {
                final med = _meds[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GlassCard(
                    onTap: () => _showMedDialog(med),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (med.isExpired ? MaatriColors.mediumGray.withValues(alpha: 0.12) : MaatriColors.coralLight.withValues(alpha: 0.12)), borderRadius: BorderRadius.circular(10)),
                        child: Icon(med.isExpired ? Icons.history_rounded : Icons.medication_rounded, color: med.isExpired ? MaatriColors.mediumGray : MaatriColors.coral, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          children: [
                            Text(med.medicineName, style: MaatriTypography.titleSmall),
                            if (med.dosage.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text('(${med.dosage})', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(med.timeSchedule, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.charcoal, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          med.isExpired
                              ? 'Schedule Expired'
                              : '${med.remainingDays} days remaining · ${med.mealTiming}',
                          style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate),
                        ),
                      ])),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                med.reminderEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                                size: 16,
                                color: med.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                med.reminderEnabled ? 'Active' : 'Off',
                                style: MaatriTypography.labelSmall.copyWith(
                                  color: med.reminderEnabled ? MaatriColors.teal : MaatriColors.mediumGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: MaatriColors.danger, size: 20),
                            onPressed: () => _confirmDeleteMed(med.id),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ]),
                  ),
                );
              }),
            ],

            // ── HEALTH NOTES ──
            const SizedBox(height: MaatriTheme.spacingLg),
            _sectionTitle('Health Notes', Icons.note_alt_rounded, MaatriColors.goldenAmber, onAdd: _showAddNoteDialog),
            const SizedBox(height: MaatriTheme.spacingSm),
            ...List.generate(_notes.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_notes[i].text, style: MaatriTypography.bodyMedium),
                  const SizedBox(height: 4),
                  Text(_formatDate(_notes[i].date), style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                ])),
                Column(children: [
                  GestureDetector(
                    onTap: () { setState(() => _notes[i].bookmarked = !_notes[i].bookmarked);
                      if (_notes[i].bookmarked) _showReminderPopup(); },
                    child: Icon(_notes[i].bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _notes[i].bookmarked ? MaatriColors.goldenAmber : MaatriColors.mediumGray, size: 22)),
                ]),
              ])),
            )),

            // ── WEIGHT TRACKING ──
            const SizedBox(height: MaatriTheme.spacingLg),
            _sectionTitle('Weight Tracking', Icons.monitor_weight_rounded, MaatriColors.teal, onAdd: _showAddWeightDialog),
            const SizedBox(height: MaatriTheme.spacingSm),
            // Weight graph
            GlassCard(padding: const EdgeInsets.all(MaatriTheme.spacingMd), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Weight Progression', style: MaatriTypography.labelLarge),
                Text('${_weights.last.kg} kg', style: MaatriTypography.titleMedium.copyWith(color: MaatriColors.teal)),
              ]),
              const SizedBox(height: 12),
              SizedBox(height: 120, child: CustomPaint(size: const Size(double.infinity, 120), painter: _WeightChartPainter(_weights))),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Week ${_weights.first.week}', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                Text('Week ${_weights.last.week}', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
              ]),
            ])),
            // Milestone entries
            const SizedBox(height: MaatriTheme.spacingSm),
            SizedBox(height: 50, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _weights.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (c, i) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: MaatriColors.pureWhite, borderRadius: BorderRadius.circular(12), boxShadow: MaatriTheme.shadowSm),
                child: Column(children: [
                  Text('Wk ${_weights[i].week}', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                  Text('${_weights[i].kg} kg', style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.teal)),
                ])))),

            // ── MOOD TRACKING ──
            const SizedBox(height: MaatriTheme.spacingLg),
            _sectionTitle('Mood Tracker', Icons.emoji_emotions_rounded, MaatriColors.lavenderDark, onAdd: _showMoodPicker),
            const SizedBox(height: MaatriTheme.spacingSm),
            SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _moods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (c, i) => Container(width: 90, padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: MaatriColors.lavenderGradient, borderRadius: BorderRadius.circular(14)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_moods[i].emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(_moods[i].label, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.lavenderDark)),
                ])))),

            // ── SCAN / DOCUMENTS ──
            const SizedBox(height: MaatriTheme.spacingLg),
            _sectionTitle('Scans & Documents', Icons.document_scanner_rounded, MaatriColors.info, onAdd: _showDocOptions),
            const SizedBox(height: MaatriTheme.spacingSm),
            GlassCard(child: Column(children: [
              GestureDetector(
                onTap: () => setState(() => _docsExpanded = !_docsExpanded),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${_docs.length} documents', style: MaatriTypography.titleSmall),
                  Icon(_docsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: MaatriColors.slate),
                ]),
              ),
              if (_docsExpanded) ...List.generate(_docs.length, (i) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: MaatriColors.cloudGray, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Icon(_docs[i].icon, color: MaatriColors.info, size: 28),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_docs[i].name, style: MaatriTypography.titleSmall),
                      Text(_docs[i].date, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
                  ])),
              )),
            ])),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color, {VoidCallback? onAdd}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: MaatriTypography.headlineSmall)]),
      if (onAdd != null) GestureDetector(onTap: onAdd, child: Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.add_rounded, color: color, size: 20))),
    ]);
  }

  String _formatDate(DateTime d) { final diff = DateTime.now().difference(d).inDays; return diff == 0 ? 'Today' : diff == 1 ? 'Yesterday' : '$diff days ago'; }

  // ── MEDICINES ADD / EDIT DIALOG ──
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEditing ? 'Edit Medicine' : 'Add Medicine', style: MaatriTypography.headlineSmall),
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: MaatriColors.danger),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDeleteMed(existingMed.id);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(hintText: 'Medicine name', prefixIcon: Icon(Icons.medication_rounded, color: MaatriColors.coral)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageCtrl,
                    decoration: const InputDecoration(hintText: 'Dosage (e.g. 500mg, 1 tablet)', prefixIcon: Icon(Icons.medical_services_outlined, color: MaatriColors.coral)),
                  ),
                  const SizedBox(height: 16),

                  // Start Date & Duration Row
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
                            if (date != null) {
                              setS(() => startDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: MaatriColors.lightGray),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: MaatriColors.slate),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(startDate),
                                    style: MaatriTypography.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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

                  // MULTIPLE TIME SELECTION
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
                              } else {
                                if (selectedTimes.length > 1) {
                                  selectedTimes.remove(timeOption);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please keep at least one scheduled time.')),
                                  );
                                }
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Meal Timing selection
                  Text('Meal Timing', style: MaatriTypography.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Pre-meal', 'Post-meal', 'Not Applicable'].map((m) =>
                      ChoiceChip(
                        label: Text(m), 
                        selected: mealTiming == m, 
                        selectedColor: MaatriColors.tealLight.withValues(alpha: 0.4),
                        onSelected: (_) => setS(() => mealTiming = m),
                      ),
                    ).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Reminder Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: MaatriColors.teal),
                          const SizedBox(width: 8),
                          Text('Enable Reminders', style: MaatriTypography.labelLarge),
                        ],
                      ),
                      Switch(
                        value: reminderEnabled,
                        activeColor: MaatriColors.teal,
                        onChanged: (val) => setS(() => reminderEnabled = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(hintText: 'Additional notes (optional)', prefixIcon: Icon(Icons.description_outlined, color: MaatriColors.slate)),
                  ),
                  const SizedBox(height: 24),

                  // SAVE / ADD CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final dosage = dosageCtrl.text.trim();
                        final duration = int.tryParse(durationCtrl.text) ?? 0;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Medicine name cannot be empty.'), backgroundColor: MaatriColors.danger),
                          );
                          return;
                        }

                        if (selectedTimes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least one timing.'), backgroundColor: MaatriColors.danger),
                          );
                          return;
                        }

                        if (duration <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid duration.'), backgroundColor: MaatriColors.danger),
                          );
                          return;
                        }

                        final newMed = Medicine(
                          id: isEditing ? existingMed.id : UniqueKey().toString(),
                          medicineName: name,
                          dosage: dosage,
                          selectedTimes: selectedTimes,
                          startDate: startDate,
                          endDate: calculatedEndDate,
                          durationDays: duration,
                          notes: notesCtrl.text.trim(),
                          mealTiming: mealTiming,
                          reminderEnabled: reminderEnabled,
                          notificationIds: isEditing ? existingMed.notificationIds : const [],
                        );

                        await _storageService.saveMedicine(newMed);
                        Navigator.pop(ctx);
                        _loadMeds();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Medication updated! ✓' : 'Medication added successfully! ✓'),
                            backgroundColor: MaatriColors.success,
                            behavior: SnackBarBehavior.floating,
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
              await _storageService.deleteMedicine(id);
              _loadMeds();
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

  // ── HEALTH NOTES DIALOGS ──
  void _showAddNoteDialog() {
    _noteCtrl.clear();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Health Note', style: MaatriTypography.headlineSmall),
          const SizedBox(height: 16),
          TextField(controller: _noteCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Write your health note...')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: () { if (_noteCtrl.text.isNotEmpty) { setState(() => _notes.insert(0, _Note(_noteCtrl.text, DateTime.now(), false))); Navigator.pop(ctx); } },
            child: const Text('Save Note'))),
        ]),
      ),
    );
  }

  void _showReminderPopup() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [const Icon(Icons.notifications_active_rounded, color: MaatriColors.goldenAmber), const SizedBox(width: 8), const Text('Set Reminder')]),
      content: const Text('Remind me later to consult with the doctor about this note?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Not Now')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Reminder set! ✓'), backgroundColor: MaatriColors.success, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); },
          child: const Text('Set Reminder')),
      ],
    ));
  }

  void _showAddWeightDialog() {
    final wCtrl = TextEditingController();
    final weekCtrl = TextEditingController(text: '${_weights.last.week + 4}');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Log Weight', style: MaatriTypography.headlineSmall),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: weekCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Week', suffixText: 'wk'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: wCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Weight', suffixText: 'kg'))),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: () { final w = double.tryParse(wCtrl.text); final wk = int.tryParse(weekCtrl.text);
              if (w != null && wk != null) { setState(() => _weights.add(_WeightEntry(wk, w))); Navigator.pop(ctx); } },
            child: const Text('Save Weight'))),
        ]),
      ),
    );
  }

  void _showMoodPicker() {
    final moods = [('Happy', '😊'), ('Calm', '😌'), ('Tired', '😴'), ('Emotional', '🥺'), ('Stressed', '😰'), ('Excited', '🤩')];
    showModalBottomSheet(context: context, backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('How are you feeling?', style: MaatriTypography.headlineSmall),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: moods.map((m) => GestureDetector(
            onTap: () { setState(() => _moods.insert(0, _MoodEntry(m.$1, m.$2, DateTime.now()))); Navigator.pop(ctx); },
            child: Container(width: 90, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: MaatriColors.lavenderLight, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [Text(m.$2, style: const TextStyle(fontSize: 32)), const SizedBox(height: 4),
                Text(m.$1, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.lavenderDark))])))).toList()),
        ])),
    );
  }

  void _showDocOptions() {
    showModalBottomSheet(context: context, backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Document', style: MaatriTypography.headlineSmall),
          const SizedBox(height: 16),
          ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: MaatriColors.coralLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.camera_alt_rounded, color: MaatriColors.coral)),
            title: const Text('Take Photo'), subtitle: const Text('Capture with camera'),
            onTap: () async { Navigator.pop(ctx); final img = await ImagePicker().pickImage(source: ImageSource.camera);
              if (img != null) setState(() => _docs.insert(0, _Doc(img.name, 'Today', Icons.image_rounded))); }),
          const Divider(),
          ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: MaatriColors.tealLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.upload_file_rounded, color: MaatriColors.teal)),
            title: const Text('Upload File'), subtitle: const Text('Choose from device'),
            onTap: () async { Navigator.pop(ctx); final img = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (img != null) setState(() => _docs.insert(0, _Doc(img.name, 'Today', Icons.description_rounded))); }),
        ])),
    );
  }
}

// ── Data Models ──
class _Note { String text; DateTime date; bool bookmarked; _Note(this.text, this.date, this.bookmarked); }
class _WeightEntry { int week; double kg; _WeightEntry(this.week, this.kg); }
class _MoodEntry { String label, emoji; DateTime date; _MoodEntry(this.label, this.emoji, this.date); }
class _Doc { String name, date; IconData icon; _Doc(this.name, this.date, this.icon); }

// ── Weight Chart Painter ──
class _WeightChartPainter extends CustomPainter {
  final List<_WeightEntry> data;
  _WeightChartPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minW = data.map((e) => e.kg).reduce((a, b) => a < b ? a : b) - 2;
    final maxW = data.map((e) => e.kg).reduce((a, b) => a > b ? a : b) + 2;
    final paint = Paint()..color = MaatriColors.teal..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = MaatriColors.teal;
    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [MaatriColors.teal.withValues(alpha: 0.3), MaatriColors.teal.withValues(alpha: 0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i].kg - minW) / (maxW - minW)) * size.height;
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    fillPath.lineTo(size.width, size.height); fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
