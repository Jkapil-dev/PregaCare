import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';

class NotificationSharingSettingsPage extends StatefulWidget {
  const NotificationSharingSettingsPage({super.key});

  @override
  State<NotificationSharingSettingsPage> createState() => _NotificationSharingSettingsPageState();
}

class _NotificationSharingSettingsPageState extends State<NotificationSharingSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Default granular sharing settings toggles
  Map<String, bool> _sharingSettings = {
    'medicineReminders': true,
    'appointmentReminders': true,
    'vaccinationReminders': true,
    'emergencyAlerts': true,
    'babyUpdates': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uid = userProvider.uid;
    
    if (uid.isEmpty) return;

    try {
      final docSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('notification_settings')
          .doc('settings')
          .get();

      if (docSnap.exists) {
        final data = docSnap.data();
        final rawSharing = data?['sharingSettings'];
        if (rawSharing is Map) {
          setState(() {
            _sharingSettings = {
              'medicineReminders': rawSharing['medicineReminders'] == true,
              'appointmentReminders': rawSharing['appointmentReminders'] == true,
              'vaccinationReminders': rawSharing['vaccinationReminders'] == true,
              'emergencyAlerts': rawSharing['emergencyAlerts'] == true,
              'babyUpdates': rawSharing['babyUpdates'] == true,
            };
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading notification sharing settings: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    if (_isSaving) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uid = userProvider.uid;

    if (uid.isEmpty) return;

    setState(() {
      _sharingSettings[key] = value;
      _isSaving = true;
    });

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notification_settings')
          .doc('settings')
          .set({
        'sharingSettings': _sharingSettings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final connectionId = userProvider.linkedConnectionId;
      if (connectionId != null && connectionId.isNotEmpty) {
        await _db
            .collection('pregnancy_connections')
            .doc(connectionId)
            .collection('shared_reminders')
            .doc('settings')
            .set({
          'sharingSettings': _sharingSettings,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sharing preferences updated.'),
            backgroundColor: MaatriColors.teal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving notification sharing settings: $e');
      if (mounted) {
        setState(() {
          _sharingSettings[key] = !value; // Rollback
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preferences: $e'),
            backgroundColor: MaatriColors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isMother = userProvider.isMother;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Notification Sharing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MaatriColors.charcoal,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: MaatriColors.coral))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 24),
                    Text(
                      'Granular Sharing Settings',
                      style: MaatriTypography.titleMedium.copyWith(
                        color: MaatriColors.charcoal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable or disable what real-time push alerts and reminders are synchronized to your partner.',
                      style: TextStyle(fontSize: 12, color: MaatriColors.slate),
                    ),
                    const SizedBox(height: 16),
                    _buildToggleTile(
                      title: 'Medicine Reminders Sharing',
                      description: 'Sync your daily medication dose alerts with your partner.',
                      value: _sharingSettings['medicineReminders'] ?? true,
                      icon: Icons.medication_rounded,
                      iconColor: MaatriColors.teal,
                      enabled: isMother,
                      onChanged: (val) => _updateSetting('medicineReminders', val),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Appointment Reminders Sharing',
                      description: 'Sync prenatal consultation doctor appointments.',
                      value: _sharingSettings['appointmentReminders'] ?? true,
                      icon: Icons.calendar_month_rounded,
                      iconColor: MaatriColors.lavenderDark,
                      enabled: isMother,
                      onChanged: (val) => _updateSetting('appointmentReminders', val),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Vaccination Reminders Sharing',
                      description: 'Sync planned maternal immunizations.',
                      value: _sharingSettings['vaccinationReminders'] ?? true,
                      icon: Icons.shield_rounded,
                      iconColor: MaatriColors.goldenAmber,
                      enabled: isMother,
                      onChanged: (val) => _updateSetting('vaccinationReminders', val),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Emergency Alerts Sharing',
                      description: 'Alert partner instantly when SOS is triggered.',
                      value: _sharingSettings['emergencyAlerts'] ?? true,
                      icon: Icons.emergency_rounded,
                      iconColor: MaatriColors.danger,
                      enabled: isMother,
                      onChanged: (val) => _updateSetting('emergencyAlerts', val),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Baby Growth Updates Sharing',
                      description: 'Sync weekly development and growth milestone alerts.',
                      value: _sharingSettings['babyUpdates'] ?? true,
                      icon: Icons.child_care_rounded,
                      iconColor: Colors.pinkAccent,
                      enabled: isMother,
                      onChanged: (val) => _updateSetting('babyUpdates', val),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaatriColors.pureWhite,
        borderRadius: BorderRadius.circular(MaatriTheme.radiusLg),
        boxShadow: MaatriTheme.shadowSm,
        border: Border.all(color: MaatriColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MaatriColors.teal.withOpacity( 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: MaatriColors.teal, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner Notification Sync',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MaatriColors.charcoal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pregnancy is a shared journey. Turn on these triggers so your linked partner automatically schedules local reminders and receives priority emergency triggers alongside you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: MaatriColors.slate,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String description,
    required bool value,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MaatriColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: MaatriColors.slate),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: MaatriColors.teal,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
