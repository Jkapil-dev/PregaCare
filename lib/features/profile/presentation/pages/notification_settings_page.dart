import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isSaving = false;

  Future<void> _toggleSetting(String key, bool currentValue) async {
    final userProvider = context.read<UserProvider>();
    final currentSettings = Map<String, bool>.from(userProvider.notificationSettings);
    
    currentSettings[key] = !currentValue;

    setState(() => _isSaving = true);
    try {
      await userProvider.updateProfile({
        'notificationSettings': currentSettings,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getFriendlyName(key)} updated!'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: MaatriColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification settings: $e'),
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

  String _getFriendlyName(String key) {
    switch (key) {
      case 'medicineReminders':
        return 'Medicine Reminders';
      case 'appointmentReminders':
        return 'Appointment Reminders';
      case 'vaccinationReminders':
        return 'Vaccination Reminders';
      case 'moodReminders':
        return 'Emotional Wellness Reminders';
      case 'hydrationReminders':
        return 'Hydration / Water Reminders';
      default:
        return 'Notification';
    }
  }

  String _getDescription(String key) {
    switch (key) {
      case 'medicineReminders':
        return 'Get alerts when it is time to take your maternal vitamins and medicines.';
      case 'appointmentReminders':
        return 'Get reminders before your scheduled OB-Gyn and clinic visits.';
      case 'vaccinationReminders':
        return 'Stay on track with important maternal vaccines like Tdap and Influenza.';
      case 'moodReminders':
        return 'Receive occasional gentle prompts to log your mood and check emotional health.';
      case 'hydrationReminders':
        return 'Get helpful reminders to drink water throughout the day for maternal health.';
      default:
        return '';
    }
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'medicineReminders':
        return Icons.medication_rounded;
      case 'appointmentReminders':
        return Icons.calendar_today_rounded;
      case 'vaccinationReminders':
        return Icons.vaccines_rounded;
      case 'moodReminders':
        return Icons.favorite_rounded;
      case 'hydrationReminders':
        return Icons.local_drink_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String key) {
    switch (key) {
      case 'medicineReminders':
        return MaatriColors.teal;
      case 'appointmentReminders':
        return MaatriColors.lavenderDark;
      case 'vaccinationReminders':
        return MaatriColors.coral;
      case 'moodReminders':
        return Colors.pinkAccent;
      case 'hydrationReminders':
        return Colors.blue;
      default:
        return MaatriColors.charcoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final settings = userProvider.notificationSettings;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Notification Settings'),
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
                    'Daily Reminders',
                    style: MaatriTypography.titleMedium.copyWith(
                      color: MaatriColors.charcoal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize reminders to help you maintain a healthy pregnancy schedule.',
                    style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                  ),
                  const SizedBox(height: 16),
                  
                  ...settings.keys.map((key) {
                    final isEnabled = settings[key] == true;
                    final friendlyName = _getFriendlyName(key);
                    final description = _getDescription(key);
                    final icon = _getIcon(key);
                    final color = _getColor(key);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(friendlyName, style: MaatriTypography.titleSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: MaatriTypography.bodySmall.copyWith(
                                      color: MaatriColors.slate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              activeThumbColor: MaatriColors.coral,
                              value: isEnabled,
                              onChanged: _isSaving ? null : (_) => _toggleSetting(key, isEnabled),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
