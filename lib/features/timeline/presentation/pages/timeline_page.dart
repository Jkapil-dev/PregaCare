import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentWeek = userProvider.pregnancyWeek;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(title: const Text('Pregnancy Timeline'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context))),
      body: ListView.builder(padding: const EdgeInsets.all(16), itemCount: 40, itemBuilder: (c, i) {
        final week = i + 1;
        final isCurrent = week == currentWeek;
        final isPast = week < currentWeek;
        final trimester = week <= 12 ? 1 : week <= 27 ? 2 : 3;
        return _buildWeekItem(context, week, isCurrent, isPast, trimester);
      }),
    );
  }

  Widget _buildWeekItem(BuildContext ctx, int week, bool isCurrent, bool isPast, int trimester) {
    final sizes = ['Poppy seed','Sesame seed','Lentil','Blueberry','Raspberry','Cherry','Olive','Grape','Kumquat','Fig','Lime','Plum','Lemon','Nectarine','Apple','Avocado','Turnip','Onion','Mango','Banana','Carrot','Papaya','Grapefruit','Corn','Cauliflower','Lettuce','Eggplant','Squash','Cabbage','Coconut','Cucumber','Pineapple','Jicama','Butternut','Honeydew','Cantaloupe','Romaine','Winter melon','Pumpkin','Watermelon'];
    final size = week <= 40 ? sizes[week - 1] : 'Baby';
    final color = isCurrent ? MaatriColors.coral : isPast ? MaatriColors.teal : MaatriColors.lightGray;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Timeline line
      SizedBox(width: 40, child: Column(children: [
        Container(width: isCurrent ? 16 : 10, height: isCurrent ? 16 : 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: isCurrent ? [BoxShadow(color: MaatriColors.coral.withOpacity( 0.4), blurRadius: 8)] : null)),
        if (week < 40) Container(width: 2, height: 60, color: isPast ? MaatriColors.tealLight : MaatriColors.lightGray),
      ])),
      Expanded(child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isCurrent ? null : MaatriColors.pureWhite, gradient: isCurrent ? MaatriColors.primaryGradient : null, borderRadius: BorderRadius.circular(14), boxShadow: isCurrent ? MaatriTheme.glowCoral : MaatriTheme.shadowSm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Week $week', style: MaatriTypography.titleMedium.copyWith(color: isCurrent ? Colors.white : MaatriColors.charcoal, fontWeight: FontWeight.w700)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isCurrent ? Colors.white.withOpacity( 0.2) : MaatriColors.cloudGray, borderRadius: BorderRadius.circular(999)),
              child: Text('T$trimester', style: MaatriTypography.labelSmall.copyWith(color: isCurrent ? Colors.white : MaatriColors.slate))),
          ]),
          const SizedBox(height: 4),
          Text('Baby size: $size', style: MaatriTypography.bodySmall.copyWith(color: isCurrent ? Colors.white.withOpacity( 0.9) : MaatriColors.slate)),
          if (isCurrent) ...[const SizedBox(height: 4), Text('📍 You are here', style: MaatriTypography.labelMedium.copyWith(color: Colors.white))],
        ]),
      )),
    ]);
  }
}
