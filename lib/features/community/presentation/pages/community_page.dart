import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/responsive_widgets.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(child: ResponsivePageWrapper(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Community', style: MaatriTypography.headlineLarge),
          const SizedBox(height: 4),
          Text('Connect with other mothers', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
        ])),
        // Trimester tabs
        ResponsiveChipBar(children: [
          _TabChip(label: 'All', isActive: true),
          _TabChip(label: 'Trimester 1', isActive: false),
          _TabChip(label: 'Trimester 2', isActive: false),
          _TabChip(label: 'Trimester 3', isActive: false),
        ]),
        const SizedBox(height: 16),
        Expanded(child: ListView(padding: const EdgeInsets.only(left: 16, right: 16, bottom: 88), children: [
          _PostCard(author: 'Anonymous Mom', badge: 'Week 24', text: 'Anyone else experiencing back pain during the second trimester? Looking for some relief tips! 🙏', replies: 12, likes: 34, time: '2h ago'),
          const SizedBox(height: 12),
          _PostCard(author: 'Priya M.', badge: 'Week 30', text: 'Just had my glucose test and everything came back normal! So relieved 😊', replies: 8, likes: 56, time: '4h ago'),
          const SizedBox(height: 12),
          _PostCard(author: 'Anonymous Mom', badge: 'Week 16', text: 'First-time mom here. What are the must-have items for the hospital bag?', replies: 23, likes: 41, time: '6h ago'),
        ])),
      ]))),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: MaatriColors.lavenderDark, child: const Icon(Icons.edit_rounded, color: Colors.white)),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label; final bool isActive;
  const _TabChip({required this.label, required this.isActive});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isActive ? MaatriColors.coral : MaatriColors.pureWhite, borderRadius: BorderRadius.circular(999), border: isActive ? null : Border.all(color: MaatriColors.lightGray)),
      child: Text(label, style: MaatriTypography.labelMedium.copyWith(color: isActive ? Colors.white : MaatriColors.slate)));
  }
}

class _PostCard extends StatelessWidget {
  final String author, badge, text, time; final int replies, likes;
  const _PostCard({required this.author, required this.badge, required this.text, required this.replies, required this.likes, required this.time});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(radius: 18, backgroundColor: MaatriColors.lavenderLight, child: const Icon(Icons.person_rounded, color: MaatriColors.lavenderDark, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ResponsiveText(author, style: MaatriTypography.titleSmall),
          ResponsiveText('$badge · $time', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
        ])),
        const Icon(Icons.more_horiz_rounded, color: MaatriColors.mediumGray),
      ]),
      const SizedBox(height: 10),
      Text(text, style: MaatriTypography.bodyMedium),
      const SizedBox(height: 10),
      ResponsiveActionRow(
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded, size: 18, color: MaatriColors.slate), const SizedBox(width: 4),
              Text('$likes', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 18, color: MaatriColors.slate), const SizedBox(width: 4),
              Text('$replies replies', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate)),
            ],
          ),
        ],
      ),
    ]));
  }
}
