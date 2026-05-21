import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(title: Row(children: [const Icon(Icons.warning_amber_rounded, color: MaatriColors.danger), const SizedBox(width: 8), const Text('Emergency')])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MaatriTheme.spacingMd),
        child: Column(children: [
          // SOS Button
          GestureDetector(
            onTap: () => _showSOSDialog(context),
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: MaatriColors.danger, boxShadow: [BoxShadow(color: MaatriColors.danger.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.emergency_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 4),
                Text('Tap for\nEmergency', textAlign: TextAlign.center, style: MaatriTypography.labelLarge.copyWith(color: Colors.white)),
              ]),
            ),
          ),
          const SizedBox(height: MaatriTheme.spacingLg),
          // Emergency contacts
          SectionHeader(title: 'Emergency Contacts', icon: Icons.phone_rounded, iconColor: MaatriColors.danger),
          const SizedBox(height: MaatriTheme.spacingSm),
          _ContactCard(name: 'Dr. Anya Sharma (OB-GYN)', phone: '+91 98765 43210'),
          const SizedBox(height: 8),
          _ContactCard(name: 'Rahul (Husband)', phone: '+91 98765 43211'),
          const SizedBox(height: 8),
          _ContactCard(name: 'Ambulance', phone: '108'),
          const SizedBox(height: MaatriTheme.spacingLg),
          // Nearby hospitals
          SectionHeader(title: 'Nearby Hospitals', icon: Icons.local_hospital_rounded, iconColor: MaatriColors.teal),
          const SizedBox(height: MaatriTheme.spacingSm),
          _HospitalCard(name: 'City Maternity Center', distance: '0.8 km'),
          const SizedBox(height: 8),
          _HospitalCard(name: 'Apollo Hospital', distance: '2.3 km'),
          const SizedBox(height: MaatriTheme.spacingLg),
          // Danger signs
          SectionHeader(title: 'Danger Signs', icon: Icons.warning_rounded, iconColor: MaatriColors.warningDark),
          const SizedBox(height: MaatriTheme.spacingSm),
          GlassCard(child: Column(children: [
            _DangerItem(text: 'Severe headache or vision changes', severity: MaatriColors.danger),
            _DangerItem(text: 'Vaginal bleeding', severity: MaatriColors.danger),
            _DangerItem(text: 'Sudden swelling (face/hands)', severity: MaatriColors.danger),
            _DangerItem(text: 'Severe abdominal pain', severity: MaatriColors.danger),
            _DangerItem(text: 'Reduced fetal movement', severity: MaatriColors.warningDark),
            _DangerItem(text: 'Persistent nausea/vomiting', severity: MaatriColors.warningDark),
            _DangerItem(text: 'High fever (>38°C)', severity: MaatriColors.warningDark),
          ])),
          const SizedBox(height: MaatriTheme.spacingLg),
          // Share location
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
            onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.teal),
            icon: const Icon(Icons.location_on_rounded), label: const Text('Share My Location'),
          )),
          const SizedBox(height: MaatriTheme.spacingXl),
        ]),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Emergency SOS'), content: const Text('Call emergency services now?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); launchUrl(Uri.parse('tel:108')); },
          style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger), child: const Text('Call Now')),
      ],
    ));
  }
}

class _ContactCard extends StatelessWidget {
  final String name, phone;
  const _ContactCard({required this.name, required this.phone});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: MaatriColors.dangerLight, shape: BoxShape.circle), child: const Icon(Icons.phone, color: MaatriColors.danger, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: MaatriTypography.titleSmall), Text(phone, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
      ])),
      Container(decoration: BoxDecoration(color: MaatriColors.success, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.phone, color: Colors.white, size: 20), onPressed: () => launchUrl(Uri.parse('tel:$phone')))),
    ]));
  }
}

class _HospitalCard extends StatelessWidget {
  final String name, distance;
  const _HospitalCard({required this.name, required this.distance});
  @override
  Widget build(BuildContext context) {
    return GlassCard(child: Row(children: [
      const Icon(Icons.local_hospital_rounded, color: MaatriColors.teal),
      const SizedBox(width: 12),
      Expanded(child: Text(name, style: MaatriTypography.titleSmall)),
      Text(distance, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
    ]));
  }
}

class _DangerItem extends StatelessWidget {
  final String text; final Color severity;
  const _DangerItem({required this.text, required this.severity});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      StatusDot(color: severity), const SizedBox(width: 10),
      Expanded(child: Text(text, style: MaatriTypography.bodyMedium)),
    ]));
  }
}
