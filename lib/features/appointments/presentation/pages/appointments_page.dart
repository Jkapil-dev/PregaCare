import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(title: const Text('Appointments'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available_outlined, size: 64, color: MaatriColors.mediumGray.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'No appointments scheduled.',
                style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.charcoal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Use the Medication & Care module to schedule your antenatal consultations.',
                style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
