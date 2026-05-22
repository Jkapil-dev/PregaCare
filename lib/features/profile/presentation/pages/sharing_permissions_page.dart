import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/partner_provider.dart';

class SharingPermissionsPage extends StatefulWidget {
  const SharingPermissionsPage({super.key});

  @override
  State<SharingPermissionsPage> createState() => _SharingPermissionsPageState();
}

class _SharingPermissionsPageState extends State<SharingPermissionsPage> {
  bool _isProcessing = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? MaatriColors.danger : MaatriColors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleTogglePermission(
    String connectionId,
    Map<String, bool> currentPermissions,
    String key,
    bool value,
  ) async {
    setState(() => _isProcessing = true);
    
    // 1. Copy the existing permissions map
    final updatedPermissions = Map<String, bool>.from(currentPermissions);
    
    // 2. Set the newly toggled granular key
    updatedPermissions[key] = value;
    
    // 3. Compute legacy keys for Firestore rules and backward compatibility
    final medicines = updatedPermissions['medicines'] == true;
    final babyUpdates = updatedPermissions['babyUpdates'] == true;
    final appointments = updatedPermissions['appointments'] == true;
    final reminders = updatedPermissions['reminders'] == true;
    final emergencyAlerts = updatedPermissions['emergencyAlerts'] == true;

    updatedPermissions['viewTracker'] = medicines || babyUpdates;
    updatedPermissions['viewEmergency'] = emergencyAlerts;
    updatedPermissions['viewReminders'] = appointments || reminders;
    updatedPermissions['viewNotifications'] = reminders;

    try {
      await context.read<PartnerProvider>().updatePermissions(connectionId, updatedPermissions);
      _showSnackBar('Sharing settings updated.');
    } catch (e) {
      _showSnackBar('Failed to update permission: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final connectionId = userProvider.linkedConnectionId ?? '';
    final permissionsMap = userProvider.permissions;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Sharing Permissions'),
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
                  Container(
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
                            color: MaatriColors.coral.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.security_rounded, color: MaatriColors.coral, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are in Control',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: MaatriColors.charcoal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Mother remains the primary owner. Change these settings at any time to grant or revoke access.',
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
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Shared Features',
                    style: MaatriTypography.titleMedium.copyWith(
                      color: MaatriColors.charcoal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPermissionSwitchTile(
                    title: 'Appointments Sharing',
                    description: 'Share upcoming prenatal checkups and doctor visits.',
                    icon: Icons.calendar_month_rounded,
                    iconColor: MaatriColors.lavenderDark,
                    value: permissionsMap['appointments'] ?? permissionsMap['viewReminders'] ?? false,
                    onChanged: (val) => _handleTogglePermission(connectionId, permissionsMap, 'appointments', val),
                  ),
                  _buildPermissionSwitchTile(
                    title: 'Medicine Sharing',
                    description: 'Allow partner to view your medicines checklist and dosage.',
                    icon: Icons.medication_rounded,
                    iconColor: MaatriColors.teal,
                    value: permissionsMap['medicines'] ?? permissionsMap['viewTracker'] ?? false,
                    onChanged: (val) => _handleTogglePermission(connectionId, permissionsMap, 'medicines', val),
                  ),
                  _buildPermissionSwitchTile(
                    title: 'Medicine & Care Reminders',
                    description: 'Partner can view when you need to take medicines or log vitals.',
                    icon: Icons.alarm_rounded,
                    iconColor: MaatriColors.goldenAmber,
                    value: permissionsMap['reminders'] ?? permissionsMap['viewReminders'] ?? false,
                    onChanged: (val) => _handleTogglePermission(connectionId, permissionsMap, 'reminders', val),
                  ),
                  _buildPermissionSwitchTile(
                    title: 'Baby Growth Updates',
                    description: 'Share weekly baby development stages, size/weight stats, and description.',
                    icon: Icons.child_care_rounded,
                    iconColor: Colors.pinkAccent,
                    value: permissionsMap['babyUpdates'] ?? permissionsMap['viewTracker'] ?? false,
                    onChanged: (val) => _handleTogglePermission(connectionId, permissionsMap, 'babyUpdates', val),
                  ),
                  _buildPermissionSwitchTile(
                    title: 'Emergency Alerts & Status',
                    description: 'Share medical records, allergies, hospital pref, emergency logs, and status details.',
                    icon: Icons.emergency_rounded,
                    iconColor: MaatriColors.danger,
                    value: permissionsMap['emergencyAlerts'] ?? permissionsMap['viewEmergency'] ?? false,
                    onChanged: (val) => _handleTogglePermission(connectionId, permissionsMap, 'emergencyAlerts', val),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
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

  Widget _buildPermissionSwitchTile({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MaatriColors.slate,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch(
              activeThumbColor: MaatriColors.coral,
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
