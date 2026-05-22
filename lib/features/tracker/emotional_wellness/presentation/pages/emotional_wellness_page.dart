import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';
import 'package:maatricare/core/widgets/responsive_widgets.dart';

// Models
import 'package:maatricare/core/models/journal_entry.dart';
import 'package:maatricare/core/providers/journal_provider.dart';
import 'package:maatricare/core/providers/mood_provider.dart';

class EmotionalWellnessPage extends StatefulWidget {
  const EmotionalWellnessPage({super.key});

  @override
  State<EmotionalWellnessPage> createState() => _EmotionalWellnessPageState();
}

class _EmotionalWellnessPageState extends State<EmotionalWellnessPage> {
  bool _filterBookmarkedOnly = false;

  // Reflection states (persisted in memory for simple session tracking)
  String _smileReason = '';
  String _bodyFeeling = '';

  final List<(String, String)> _moodOptions = [
    ('Happy', '😊'),
    ('Calm', '😌'),
    ('Emotional', '😢'),
    ('Anxious', '😰'),
    ('Excited', '🤍'),
    ('Tired', '😴'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false).loadJournals();
      Provider.of<MoodProvider>(context, listen: false).loadMoods();
    });
  }

  /// Check if today's entry already exists
  JournalEntry? _getTodayEntry(List<JournalEntry> journals) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final matches = journals.where((j) => j.date == todayStr);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final journals = journalProvider.journals;
    final isLoading = journalProvider.isLoading || moodProvider.isLoading;

    // Filter journals if toggled
    final filteredJournals = _filterBookmarkedOnly
        ? journals.where((j) => j.isBookmarked).toList()
        : journals;

    final todayEntry = _getTodayEntry(journals);

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Emotional Wellness'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsivePageWrapper(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(MaatriTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mind & Mood Soother', style: MaatriTypography.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Nurture your mental and emotional state through pregnancy', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // ── MOOD TRACKER CARD ──
                  _buildMoodPickerCard(todayEntry),
                  const SizedBox(height: MaatriTheme.spacingMd),

                  // ── DAILY REFLECTION PROMPTS ──
                  _buildReflectionsCard(),
                  const SizedBox(height: MaatriTheme.spacingMd),

                  // ── JOURNAL HEADER ──
                  ResponsiveActionRow(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      ResponsiveText('Pregnancy Journal & Notes', style: MaatriTypography.titleMedium),
                      FilterChip(
                        label: Row(
                          children: [
                            Icon(
                              _filterBookmarkedOnly ? Icons.star_rounded : Icons.star_outline_rounded, 
                              size: 16, 
                              color: _filterBookmarkedOnly ? Colors.amber : MaatriColors.slate,
                            ),
                            const SizedBox(width: 4),
                            const Text('Bookmarks'),
                          ],
                        ),
                        selected: _filterBookmarkedOnly,
                        selectedColor: MaatriColors.coralLight.withOpacity( 0.3),
                        onSelected: (val) {
                          setState(() {
                            _filterBookmarkedOnly = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── TODAY'S JOURNAL EMPTY STATE ──
                  if (todayEntry == null) ...[
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.edit_calendar_rounded, size: 40, color: MaatriColors.coral),
                            const SizedBox(height: 10),
                            Text(
                              "No journal entry for today.",
                              style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.charcoal),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Start writing today's thoughts.",
                              style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── TODAY'S DIALOG ENTRY BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        todayEntry != null ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: MaatriColors.coral,
                      ),
                      label: Text(
                        todayEntry != null ? 'Edit Today\'s Journal Entry' : 'Write Today\'s Journal Entry',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: MaatriColors.coral),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: MaatriColors.coral, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openJournalEditor(todayEntry),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── JOURNAL TIMELINE ──
                  if (filteredJournals.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.book_outlined, size: 48, color: MaatriColors.mediumGray.withOpacity( 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              _filterBookmarkedOnly ? 'No bookmarked memories yet.' : 'Write your first journal entry above!',
                              style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    ...filteredJournals.map((entry) => _buildTimelineCard(entry)),
                  ],
                  const SizedBox(height: MaatriTheme.spacingXxl),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildMoodPickerCard(JournalEntry? todayEntry) {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final journalsList = Provider.of<JournalProvider>(context).journals;

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
              Text('How are you feeling today?', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveActionRow(
            alignment: WrapAlignment.spaceAround,
            children: _moodOptions.map((mood) {
              final isTodayMood = todayEntry?.mood == '${mood.$2} ${mood.$1}';
              return GestureDetector(
                onTap: () async {
                  final moodString = '${mood.$2} ${mood.$1}';
                  await moodProvider.saveMood(moodString);

                  if (todayEntry != null) {
                    final updated = todayEntry.copyWith(mood: moodString);
                    await journalProvider.saveJournal(updated);
                  } else {
                    final now = DateTime.now();
                    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                    final newEntry = JournalEntry(
                      id: UniqueKey().toString(),
                      date: todayStr,
                      content: '',
                      mood: moodString,
                    );
                    await journalProvider.saveJournal(newEntry);
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Today\'s mood set to ${mood.$1}! 😊'),
                        backgroundColor: MaatriColors.success,
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: isTodayMood ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isTodayMood ? MaatriColors.coralLight.withOpacity( 0.3) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(mood.$2, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mood.$1,
                      style: MaatriTypography.labelSmall.copyWith(
                        color: isTodayMood ? MaatriColors.coral : MaatriColors.slate,
                        fontWeight: isTodayMood ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (journalsList.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Text('Recent Reflections Timeline:', style: MaatriTypography.labelMedium),
            const SizedBox(height: 6),
            ...journalsList.take(2).map((log) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.done_rounded, color: MaatriColors.success, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${log.displayDate}: ${log.mood} ${log.title.isNotEmpty ? "· " + log.title : ""}',
                    style: MaatriTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                  ),
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
                decoration: BoxDecoration(color: MaatriColors.tealLight.withOpacity( 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.self_improvement_rounded, color: MaatriColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Daily Reflection Prompts', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Text('What made you smile today?', style: MaatriTypography.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: _smileReason),
            decoration: const InputDecoration(hintText: 'Share a happy moment...'),
            onChanged: (v) => _smileReason = v,
          ),
          const SizedBox(height: 12),
          Text('How is your body feeling today?', style: MaatriTypography.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: _bodyFeeling),
            decoration: const InputDecoration(hintText: 'e.g., energized, a bit heavy...'),
            onChanged: (v) => _bodyFeeling = v,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reflection response saved successfully! ✓'), backgroundColor: MaatriColors.success),
                );
              },
              child: const Text('Save Reflections'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(JournalEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.mood.split(' ').first, 
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.mood.split(' ').skip(1).join(' '), 
                  style: MaatriTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.charcoal),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await Provider.of<JournalProvider>(context, listen: false).toggleBookmark(entry.id);
                  },
                  child: Icon(
                    entry.isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: entry.isBookmarked ? Colors.amber : MaatriColors.mediumGray,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openJournalEditor(entry),
                  child: const Icon(Icons.edit_outlined, color: MaatriColors.teal, size: 20),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDeleteJournal(entry.id),
                  child: const Icon(Icons.delete_outline_rounded, color: MaatriColors.danger, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.displayDate,
              style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate),
            ),
            if (entry.title.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.title,
                style: MaatriTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              entry.content.isEmpty ? 'Empty reflection entry. Tap edit to write!' : entry.content,
              style: MaatriTypography.bodyMedium.copyWith(
                color: entry.content.isEmpty ? MaatriColors.slate.withOpacity( 0.6) : MaatriColors.charcoal,
                fontStyle: entry.content.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            if (entry.isBookmarked) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: MaatriColors.coral, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '⭐ Bookmarked Memory', 
                    style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.coral, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── JOURNAL EDITOR BOTTOM SHEET ───────────────────────────────────────────
  void _openJournalEditor(JournalEntry? existingEntry) {
    final isEditing = existingEntry != null;
    final titleCtrl = TextEditingController(text: existingEntry?.title ?? '');
    final contentCtrl = TextEditingController(text: existingEntry?.content ?? '');
    
    // Choose pre-selected mood
    String selectedMood = existingEntry?.mood ?? '😊 Happy';
    bool isBookmarked = existingEntry?.isBookmarked ?? false;

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
                Text(
                  isEditing ? 'Reflect & Edit Journal' : 'Write Today\'s Reflection', 
                  style: MaatriTypography.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Entry Title (optional)',
                    prefixIcon: Icon(Icons.bookmark_outline_rounded, color: MaatriColors.coral),
                  ),
                ),
                const SizedBox(height: 16),

                // Mood selector chips
                Text('Daily Mood Selection', style: MaatriTypography.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _moodOptions.map((mood) {
                    final itemString = '${mood.$2} ${mood.$1}';
                    final active = selectedMood == itemString;
                    return ChoiceChip(
                      label: Text('${mood.$2} ${mood.$1}'),
                      selected: active,
                      selectedColor: MaatriColors.coralLight.withOpacity( 0.4),
                      onSelected: (_) => setS(() => selectedMood = itemString),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Content body
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Pour your heart out, mom... how are you and baby doing?',
                  ),
                ),
                const SizedBox(height: 16),

                // Bookmark toggle
                ResponsiveActionRow(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ResponsiveText('Bookmark as Memory', style: MaatriTypography.labelLarge),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isBookmarked ? Colors.amber : MaatriColors.mediumGray,
                        size: 28,
                      ),
                      onPressed: () => setS(() => isBookmarked = !isBookmarked),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final content = contentCtrl.text.trim();
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please write some content to save.'), backgroundColor: MaatriColors.danger),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                      final entry = JournalEntry(
                        id: isEditing ? existingEntry.id : UniqueKey().toString(),
                        date: isEditing ? existingEntry.date : todayStr,
                        title: titleCtrl.text.trim(),
                        content: content,
                        mood: selectedMood,
                        isBookmarked: isBookmarked,
                      );

                      await Provider.of<JournalProvider>(context, listen: false).saveJournal(entry);
                      await Provider.of<MoodProvider>(context, listen: false).loadMoods();
                      if (context.mounted) {
                        Navigator.pop(ctx);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Journal entry updated! ✓' : 'Daily journal entry saved! ✓'),
                          backgroundColor: MaatriColors.success,
                        ),
                      );
                    },
                    child: Text(isEditing ? 'Update Journal' : 'Save Journal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteJournal(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Journal Entry?'),
        content: const Text('Are you sure you want to permanently delete this daily journal entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<JournalProvider>(context, listen: false).deleteJournal(id);
              await Provider.of<MoodProvider>(context, listen: false).loadMoods();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Journal entry deleted.'), backgroundColor: MaatriColors.charcoal, behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
