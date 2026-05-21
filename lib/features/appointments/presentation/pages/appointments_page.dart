import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(title: const Text('Appointments'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context))),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add_rounded)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Upcoming', style: MaatriTypography.headlineSmall),
        const SizedBox(height: 12),
        _AppointmentCard(title: 'ANC Visit - Dr. Shah', date: 'May 24, 2026', time: '10:00 AM', type: 'ANC', color: MaatriColors.teal),
        const SizedBox(height: 8),
        _AppointmentCard(title: 'Glucose Test', date: 'May 28, 2026', time: '9:00 AM', type: 'Lab', color: MaatriColors.goldenAmber),
        const SizedBox(height: 8),
        _AppointmentCard(title: 'Tetanus Vaccination', date: 'Jun 5, 2026', time: '11:00 AM', type: 'Vaccine', color: MaatriColors.lavenderDark),
        const SizedBox(height: MaatriTheme.spacingLg),
        Text('Past', style: MaatriTypography.headlineSmall),
        const SizedBox(height: 12),
        _AppointmentCard(title: 'ANC Visit - Dr. Shah', date: 'May 10, 2026', time: '10:00 AM', type: 'ANC', color: MaatriColors.mediumGray, isPast: true),
        const SizedBox(height: 8),
        _AppointmentCard(title: 'Ultrasound Scan', date: 'Apr 28, 2026', time: '2:00 PM', type: 'Scan', color: MaatriColors.mediumGray, isPast: true),
      ]),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String title, date, time, type;
  final Color color;
  final bool isPast;
  const _AppointmentCard({required this.title, required this.date, required this.time, required this.type, required this.color, this.isPast = false});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(children: [
        Container(width: 4, height: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: MaatriTypography.titleSmall.copyWith(color: isPast ? MaatriColors.mediumGray : MaatriColors.charcoal)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: isPast ? MaatriColors.mediumGray : MaatriColors.slate),
            const SizedBox(width: 4),
            Text('$date · $time', style: MaatriTypography.bodySmall.copyWith(color: isPast ? MaatriColors.mediumGray : MaatriColors.slate)),
          ]),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
          child: Text(type, style: MaatriTypography.labelSmall.copyWith(color: color))),
      ]),
    );
  }
}
