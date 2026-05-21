import 'package:flutter/material.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';

class EmotionalWellnessPage extends StatefulWidget {
  const EmotionalWellnessPage({super.key});

  @override
  State<EmotionalWellnessPage> createState() => _EmotionalWellnessPageState();
}

class _EmotionalWellnessPageState extends State<EmotionalWellnessPage> {
  // Mood history
  final List<String> _moodHistory = ['😊 Happy (Today)', '😌 Calm (Yesterday)', '😴 Tired (2 days ago)'];

  // Journal entries
  final List<_JournalEntry> _journalEntries = [
    _JournalEntry('Felt the first strong kick today! Such a magical feeling. Sharing this moment with Rahul was beautiful.', 'May 20, 2026'),
    _JournalEntry('Bit of anxiety about the anomaly scan next week, but practicing daily breathing exercises is keeping me centered.', 'May 18, 2026'),
  ];

  // Daily reflection prompt answers
  String _smileReason = '';
  String _bodyFeeling = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Emotional Wellness'),
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
            Text('Mind & Mood Soother', style: MaatriTypography.headlineMedium),
            const SizedBox(height: 4),
            Text('Nurture your mental and emotional state through pregnancy', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
            const SizedBox(height: MaatriTheme.spacingLg),

            // ── MOOD TRACKER CARD ──
            _buildMoodPickerCard(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── DAILY REFLECTION PROMPTS ──
            _buildReflectionsCard(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── JOURNAL SECTION ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pregnancy Journal & Notes', style: MaatriTypography.titleMedium),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: MaatriColors.coral),
                  onPressed: _showAddJournalDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._journalEntries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.book_rounded, color: MaatriColors.coral, size: 18),
                        Text(entry.date, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(entry.content, style: MaatriTypography.bodyMedium),
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

  Widget _buildMoodPickerCard() {
    final moodOptions = [('Happy', '😊'), ('Calm', '😌'), ('Tired', '😴'), ('Anxious', '😰'), ('Excited', '🤩')];
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
                child: const Icon(Icons.emoji_emotions_rounded, color: MaatriColors.lavenderDark, size: 20),
              ),
              const SizedBox(width: 10),
              Text('How are you feeling?', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moodOptions.map((mood) => GestureDetector(
              onTap: () {
                setState(() {
                  _moodHistory.insert(0, '${mood.$2} ${mood.$1} (Just Now)');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mood recorded: ${mood.$1}!'), backgroundColor: MaatriColors.success),
                );
              },
              child: Column(
                children: [
                  Text(mood.$2, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(mood.$1, style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
                ],
              ),
            )).toList(),
          ),
          if (_moodHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Text('Recent Reflections:', style: MaatriTypography.labelMedium),
            const SizedBox(height: 4),
            ..._moodHistory.take(2).map((log) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.done_rounded, color: MaatriColors.success, size: 14),
                  const SizedBox(width: 6),
                  Text(log, style: MaatriTypography.bodySmall),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildReflectionsCard() {
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
                child: const Icon(Icons.self_improvement_rounded, color: MaatriColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Daily Reflection', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Text('What made you smile today?', style: MaatriTypography.labelMedium),
          const SizedBox(height: 6),
          TextField(
            decoration: const InputDecoration(hintText: 'Share a happy moment...'),
            onChanged: (v) => _smileReason = v,
          ),
          const SizedBox(height: 12),
          Text('How is your body feeling?', style: MaatriTypography.labelMedium),
          const SizedBox(height: 6),
          TextField(
            decoration: const InputDecoration(hintText: 'e.g., energized, a bit heavy...'),
            onChanged: (v) => _bodyFeeling = v,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reflection saved! ✓'), backgroundColor: MaatriColors.success),
                );
              },
              child: const Text('Save Reflection'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddJournalDialog() {
    final contentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MaatriColors.pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Journal Entry', style: MaatriTypography.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Pour your heart out, mom...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final text = contentCtrl.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _journalEntries.insert(0, _JournalEntry(text, 'Today'));
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntry {
  final String content;
  final String date;

  _JournalEntry(this.content, this.date);
}
