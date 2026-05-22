import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/responsive_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('About Materna'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MaatriColors.charcoal,
      ),
      body: SafeArea(
        child: ResponsivePageWrapper(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // App Icon Container
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: MaatriColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: MaatriTheme.glowCoral,
                  ),
                  child: const Icon(
                    Icons.pregnant_woman_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Materna',
                  style: MaatriTypography.headlineMedium.copyWith(
                    color: MaatriColors.charcoal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Version 1.0.0 (Build 100)',
                  style: MaatriTypography.labelMedium.copyWith(
                    color: MaatriColors.mediumGray,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Description
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our Mission',
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Materna is built with love and care to assist expectant mothers throughout their pregnancy journey. Our goal is to provide healthcare-grade tracking, vital monitoring, clinical scheduling, AI-assisted guidance, and emotional support to ensure a healthy and happy experience for mother and baby.',
                        style: MaatriTypography.bodyMedium.copyWith(
                          color: MaatriColors.slate,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Legal / Attribution
              GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined, color: MaatriColors.coral),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Terms of Service...')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_outlined, color: MaatriColors.teal),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Privacy Policy...')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.gavel_outlined, color: MaatriColors.lavenderDark),
                      title: const Text('Third-Party Licenses'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'Materna',
                          applicationVersion: '1.0.0',
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Icon(Icons.pregnant_woman_rounded, color: MaatriColors.coral, size: 48),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Center(
                child: Text(
                  '© 2026 Materna Inc. All rights reserved.',
                  style: MaatriTypography.labelSmall.copyWith(
                    color: MaatriColors.mediumGray,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
}
