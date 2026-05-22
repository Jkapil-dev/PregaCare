import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/responsive_widgets.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MaatriColors.charcoal,
      ),
      body: SafeArea(
        child: ResponsivePageWrapper(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQ Search Header Placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: MaatriColors.tealGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: MaatriTheme.glowTeal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How can we help?',
                      style: MaatriTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search FAQs, articles...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // FAQ Section
              Text(
                'Frequently Asked Questions',
                style: MaatriTypography.titleMedium.copyWith(
                  color: MaatriColors.charcoal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ExpansionTile(
                title: Text('How does the Pregnancy Tracker calculate my due date?', style: MaatriTypography.titleSmall),
                leading: const Icon(Icons.help_outline_rounded, color: MaatriColors.coral),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'We calculate your due date using Naegele\'s rule: adding 280 days (40 weeks) to the first day of your Last Menstrual Period (LMP). You can modify your LMP date anytime under "Pregnancy Profile" to recalculate your weeks automatically.',
                      style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              
              ExpansionTile(
                title: Text('Is my medical data securely stored?', style: MaatriTypography.titleSmall),
                leading: const Icon(Icons.help_outline_rounded, color: MaatriColors.teal),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Yes! All clinical details, symptoms, vitals, and health documents are synced with enterprise-grade cloud security. Your personal medical records are accessible only to you through securely authenticated sessions.',
                      style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),

              ExpansionTile(
                title: Text('Can I export my medical report to show my doctor?', style: MaatriTypography.titleSmall),
                leading: const Icon(Icons.help_outline_rounded, color: MaatriColors.lavenderDark),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Absolutely! Go to the Records and Documents tracker tab to access all your uploaded reports, ultrasounds, and doctor prescription logs. You can open and download individual records as high-resolution images or PDFs.',
                      style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),

              ExpansionTile(
                title: Text('How do I log daily kicks or contractions?', style: MaatriTypography.titleSmall),
                leading: const Icon(Icons.help_outline_rounded, color: MaatriColors.goldenAmber),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Open the Tracking tab from bottom navigation, tap "Baby Monitoring", and select either the "Kick Counter" or "Contraction Timer" sub-modules to start active logging in real-time.',
                      style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact Support Card
              Text(
                'Still need help?',
                style: MaatriTypography.titleMedium.copyWith(
                  color: MaatriColors.charcoal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined, color: MaatriColors.teal, size: 28),
                      title: const Text('Email Support'),
                      subtitle: const Text('support@maatricare.com'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening mail client...'),
                            backgroundColor: MaatriColors.teal,
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.chat_bubble_outline_rounded, color: MaatriColors.coral, size: 28),
                      title: const Text('Live Chat (AI Assistant)'),
                      subtitle: const Text('Instant answers for pregnancy questions'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select AI Assistant tab in the main menu.'),
                            backgroundColor: MaatriColors.teal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}
}
