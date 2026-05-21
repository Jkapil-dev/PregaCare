import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';

class AppPreferencesPage extends StatefulWidget {
  const AppPreferencesPage({super.key});

  @override
  State<AppPreferencesPage> createState() => _AppPreferencesPageState();
}

class _AppPreferencesPageState extends State<AppPreferencesPage> {
  bool _isSaving = false;

  Future<void> _updatePreference(String key, dynamic val) async {
    final userProvider = context.read<UserProvider>();
    final currentPrefs = Map<String, dynamic>.from(userProvider.preferences);
    
    currentPrefs[key] = val;

    setState(() => _isSaving = true);
    try {
      await userProvider.updateProfile({
        'preferences': currentPrefs,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences updated!'),
            duration: Duration(milliseconds: 600),
            backgroundColor: MaatriColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preference: $e'),
            backgroundColor: MaatriColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final prefs = userProvider.preferences;
    final isDarkMode = prefs['darkMode'] == true;
    final language = prefs['language']?.toString() ?? 'English';
    final units = prefs['units']?.toString() ?? 'Metric';

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('App Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MaatriColors.charcoal,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Settings',
                    style: MaatriTypography.titleMedium.copyWith(
                      color: MaatriColors.charcoal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize MaatriCare display language, units, and appearance theme.',
                    style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                  ),
                  const SizedBox(height: 16),

                  GlassCard(
                    child: Column(
                      children: [
                        // Dark Mode Toggle
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.dark_mode_outlined, color: Colors.deepPurple),
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Coming Soon (Beta preview)'),
                          trailing: Switch(
                          activeThumbColor: MaatriColors.coral,
                            value: isDarkMode,
                            onChanged: _isSaving ? null : (val) => _updatePreference('darkMode', val),
                          ),
                        ),
                        const Divider(),

                        // Language Selector
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MaatriColors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.translate_rounded, color: MaatriColors.teal),
                          ),
                          title: const Text('Language'),
                          subtitle: Text('Current language: $language'),
                          trailing: DropdownButton<String>(
                            value: language,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: MaatriColors.mediumGray),
                            items: const [
                              DropdownMenuItem(value: 'English', child: Text('English')),
                              DropdownMenuItem(value: 'Español', child: Text('Español')),
                              DropdownMenuItem(value: 'Hindi', child: Text('Hindi (हिन्दी)')),
                              DropdownMenuItem(value: 'Français', child: Text('Français')),
                            ],
                            onChanged: _isSaving
                                ? null
                                : (val) {
                                    if (val != null) {
                                      _updatePreference('language', val);
                                    }
                                  },
                          ),
                        ),
                        const Divider(),

                        // Units Preference
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MaatriColors.coral.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.straighten_rounded, color: MaatriColors.coral),
                          ),
                          title: const Text('Measurement Units'),
                          subtitle: Text('Weight/Height format: $units'),
                          trailing: DropdownButton<String>(
                            value: units,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: MaatriColors.mediumGray),
                            items: const [
                              DropdownMenuItem(value: 'Metric', child: Text('Metric (kg, cm)')),
                              DropdownMenuItem(value: 'Imperial', child: Text('Imperial (lbs, ft)')),
                            ],
                            onChanged: _isSaving
                                ? null
                                : (val) {
                                    if (val != null) {
                                      _updatePreference('units', val);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isSaving)
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(color: MaatriColors.coral),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
