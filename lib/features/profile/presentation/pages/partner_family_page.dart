import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/connection_provider.dart';
import '../../../../core/providers/partner_provider.dart';
import '../../../../core/widgets/responsive_widgets.dart';

class PartnerFamilyPage extends StatefulWidget {
  const PartnerFamilyPage({super.key});

  @override
  State<PartnerFamilyPage> createState() => _PartnerFamilyPageState();
}

class _PartnerFamilyPageState extends State<PartnerFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  String? _loadedPartnerUid;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    final partnerUid = userProvider.linkedPartnerUid;
    if (partnerUid != null && partnerUid != _loadedPartnerUid) {
      _loadedPartnerUid = partnerUid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PartnerProvider>().loadPartnerProfile(partnerUid);
        }
      });
    } else if (partnerUid == null) {
      _loadedPartnerUid = null;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? MaatriColors.danger : MaatriColors.teal,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleGenerateCode(String motherUid) async {
    setState(() => _isProcessing = true);
    try {
      await context.read<ConnectionProvider>().createInvitation(motherUid);
      _showSnackBar('Invitation code generated successfully!');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleJoinConnection(String partnerUid) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isProcessing = true);
    final code = _codeController.text.trim().toUpperCase();
    try {
      await context.read<ConnectionProvider>().joinConnection(code, partnerUid);
      _showSnackBar('Successfully linked to pregnancy!');
      _codeController.clear();
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRevokeInvitation(String motherUid) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invitation?'),
        content: const Text('Are you sure you want to revoke this invitation code? The code will become invalid immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: MaatriColors.slate)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke', style: TextStyle(color: MaatriColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      await connectionProvider.revokeInvitation(motherUid);
      _showSnackBar('Invitation code revoked.');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDisconnect({
    required String connectionId,
    required String motherUid,
    required String partnerUid,
    required bool isMotherView,
  }) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMotherView ? 'Disconnect Partner?' : 'Disconnect Pregnancy?'),
        content: Text(isMotherView 
          ? 'Are you sure you want to disconnect your partner? They will lose access to your pregnancy data immediately.'
          : 'Are you sure you want to disconnect from this pregnancy? You will lose access to all shared metrics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: MaatriColors.slate)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect', style: TextStyle(color: MaatriColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      await connectionProvider.disconnect(
        connectionId: connectionId,
        motherUid: motherUid,
        partnerUid: partnerUid,
      );
      _showSnackBar('Accounts disconnected successfully.');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final partnerProvider = context.watch<PartnerProvider>();
    final connectionProvider = context.watch<ConnectionProvider>();

    final isMainLoading = userProvider.isLoading && userProvider.profile == null;
    final isPageLocked = _isProcessing || connectionProvider.isLoading || partnerProvider.isLoading;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Partner & Family Mode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MaatriColors.charcoal,
      ),
      body: SafeArea(
        child: ResponsivePageWrapper(
          child: Stack(
          children: [
            if (isMainLoading)
              const Center(child: CircularProgressIndicator(color: MaatriColors.coral))
            else
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroSection(),
                    const SizedBox(height: 20),
                    if (!userProvider.isLinked)
                      _buildUnlinkedView(userProvider)
                    else
                      _buildLinkedView(userProvider, partnerProvider),
                  ],
                ),
              ),
            if (isPageLocked)
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(color: MaatriColors.coral),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildIntroSection() {
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
              color: MaatriColors.coral.withOpacity( 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_rounded, color: MaatriColors.coral, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregnancy is Collaborative',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MaatriColors.charcoal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Invite a partner or family member to track milestones, view medical reminders, and stay informed on pregnancy progress together.',
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

  Widget _buildUnlinkedView(UserProvider userProvider) {
    return Column(
      children: [
        // Mother Card Option
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MaatriColors.coral.withOpacity( 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.child_care_rounded, color: MaatriColors.coral, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'I am a Mother',
                    style: MaatriTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: MaatriColors.charcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Generate a secure, single-use invite code. Provide this code to your husband, partner, or caregiver so they can connect and sync updates with you.',
                style: TextStyle(fontSize: 13, color: MaatriColors.slate, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaatriColors.coral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                    ),
                  ),
                  onPressed: () => _handleGenerateCode(userProvider.uid),
                  child: const Text('Generate Invite Code', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Partner Card Option
        GlassCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MaatriColors.teal.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite_border_rounded, color: MaatriColors.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'I am a Partner / Caregiver',
                      style: MaatriTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: MaatriColors.charcoal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter the invite code generated by the mother to sync with their account. Note: This will set your profile role to partner and sync their pregnancy timeline.',
                  style: TextStyle(fontSize: 13, color: MaatriColors.slate, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Invite Code (e.g. MAT-XXXXXX)',
                    hintText: 'MAT-',
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a connection code';
                    }
                    if (!value.trim().toUpperCase().startsWith('MAT-')) {
                      return 'Code must start with MAT-';
                    }
                    if (value.trim().length < 8) {
                      return 'Code is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaatriColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                      ),
                    ),
                    onPressed: () => _handleJoinConnection(userProvider.uid),
                    child: const Text('Join Pregnancy Connection', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedView(UserProvider userProvider, PartnerProvider partnerProvider) {
    final status = userProvider.connectionData?['status'] ?? 'pending';

    if (status == 'pending') {
      final code = userProvider.connectionData?['connectionCode'] ?? '';
      return _buildPendingMotherView(userProvider.uid, code);
    }

    // Otherwise, status is active
    if (userProvider.isMother) {
      return _buildActiveMotherView(userProvider, partnerProvider);
    } else {
      return _buildActivePartnerView(userProvider);
    }
  }

  Widget _buildPendingMotherView(String motherUid, String code) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: MaatriColors.goldenAmber, size: 48),
          const SizedBox(height: 12),
          Text(
            'Waiting for Partner',
            style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share this code with your partner. Once they enter it, your accounts will be securely linked.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: MaatriColors.slate, height: 1.4),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: MaatriColors.softRose,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MaatriColors.coralLight.withOpacity( 0.5)),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: MaatriColors.coralDark,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MaatriColors.charcoal,
                  side: const BorderSide(color: MaatriColors.mediumGray),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  _showSnackBar('Invite code copied to clipboard!');
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MaatriColors.charcoal,
                  side: const BorderSide(color: MaatriColors.mediumGray),
                ),
                onPressed: () {
                  Share.share('Join my pregnancy journey on MaatriCare! Use my secure connection code: $code');
                },
              ),
            ],
          ),
          const Divider(height: 40),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: MaatriColors.danger,
              ),
              onPressed: () => _handleRevokeInvitation(motherUid),
              child: const Text(
                'Cancel Invitation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMotherView(UserProvider userProvider, PartnerProvider partnerProvider) {
    final partnerUid = userProvider.linkedPartnerUid ?? '';
    final connectionId = userProvider.linkedConnectionId ?? '';
    final pProfile = partnerProvider.partnerProfile;

    final partnerName = pProfile?['displayName'] ?? 'Linked Partner';
    final partnerEmail = pProfile?['email'] ?? '';
    final initials = _getInitials(partnerName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connected Partner Header Card
        GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: MaatriColors.teal.withOpacity( 0.15),
                child: Text(
                  initials,
                  style: MaatriTypography.titleMedium.copyWith(
                    color: MaatriColors.tealDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (partnerEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        partnerEmail,
                        style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        StatusDot(color: MaatriColors.success, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'Connected Partner',
                          style: TextStyle(
                            fontSize: 12,
                            color: MaatriColors.successDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Permissions Section Title
        Text(
          'Sharing Permissions',
          style: MaatriTypography.titleMedium.copyWith(
            color: MaatriColors.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage what pregnancy progress and medical logs are shared with your partner.',
          style: TextStyle(fontSize: 12, color: MaatriColors.slate),
        ),
        const SizedBox(height: 12),

        GlassCard(
          onTap: () {
            context.push(AppRoutes.sharingPermissions);
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MaatriColors.coral.withOpacity( 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share_rounded, color: MaatriColors.coral, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Sharing Permissions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: MaatriColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Appointments, medicines, reminders, etc.',
                      style: TextStyle(fontSize: 12, color: MaatriColors.slate),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
            ],
          ),
        ),

        const SizedBox(height: 12),

        GlassCard(
          onTap: () {
            context.push(AppRoutes.notificationSharingSettings);
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MaatriColors.teal.withOpacity( 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: MaatriColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Sharing Settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: MaatriColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Toggle partner synchronized notification alerts',
                      style: TextStyle(fontSize: 12, color: MaatriColors.slate),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
            ],
          ),
        ),

        const SizedBox(height: 32),
        
        // Disconnect Partner Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: MaatriColors.danger,
              side: const BorderSide(color: MaatriColors.danger, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
              ),
            ),
            onPressed: () => _handleDisconnect(
              connectionId: connectionId,
              motherUid: userProvider.uid,
              partnerUid: partnerUid,
              isMotherView: true,
            ),
            child: const Text(
              'Disconnect Partner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActivePartnerView(UserProvider userProvider) {
    final motherProfile = userProvider.motherProfile;
    final connectionId = userProvider.linkedConnectionId ?? '';
    final motherUid = userProvider.linkedMotherUid ?? '';

    final motherName = motherProfile?['displayName'] ?? 'Pregnancy Owner';
    final motherEmail = motherProfile?['email'] ?? '';
    final initials = _getInitials(motherName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connected Mother Header Card
        GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: MaatriColors.coral.withOpacity( 0.15),
                child: Text(
                  initials,
                  style: MaatriTypography.titleMedium.copyWith(
                    color: MaatriColors.coralDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motherName,
                      style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (motherEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        motherEmail,
                        style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        StatusDot(color: MaatriColors.success, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'Linked to Pregnancy',
                          style: TextStyle(
                            fontSize: 12,
                            color: MaatriColors.successDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Permissions Granted Section
        Text(
          'Your Access Permissions',
          style: MaatriTypography.titleMedium.copyWith(
            color: MaatriColors.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'The mother controls these settings. These cards show what shared pregnancy data is visible to you.',
          style: TextStyle(fontSize: 12, color: MaatriColors.slate),
        ),
        const SizedBox(height: 16),

        _buildPermissionIndicatorTile(
          title: 'Appointments Access',
          granted: userProvider.hasAppointmentsPermission,
          icon: Icons.calendar_month_rounded,
          iconColor: MaatriColors.lavenderDark,
        ),
        const SizedBox(height: 10),
        _buildPermissionIndicatorTile(
          title: 'Medicines Access',
          granted: userProvider.hasMedicinesPermission,
          icon: Icons.medication_rounded,
          iconColor: MaatriColors.teal,
        ),
        const SizedBox(height: 10),
        _buildPermissionIndicatorTile(
          title: 'Medicine & Care Reminders Access',
          granted: userProvider.hasRemindersPermission,
          icon: Icons.alarm_rounded,
          iconColor: MaatriColors.goldenAmber,
        ),
        const SizedBox(height: 10),
        _buildPermissionIndicatorTile(
          title: 'Baby Growth Updates Access',
          granted: userProvider.hasBabyUpdatesPermission,
          icon: Icons.child_care_rounded,
          iconColor: Colors.pinkAccent,
        ),
        const SizedBox(height: 10),
        _buildPermissionIndicatorTile(
          title: 'Emergency Alerts & Status Access',
          granted: userProvider.hasEmergencyAlertsPermission,
          icon: Icons.emergency_rounded,
          iconColor: MaatriColors.danger,
        ),

        const SizedBox(height: 32),
        
        // Disconnect Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: MaatriColors.danger,
              side: const BorderSide(color: MaatriColors.danger, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
              ),
            ),
            onPressed: () => _handleDisconnect(
              connectionId: connectionId,
              motherUid: motherUid,
              partnerUid: userProvider.uid,
              isMotherView: false,
            ),
            child: const Text(
              'Disconnect from Pregnancy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPermissionIndicatorTile({
    required String title,
    required bool granted,
    required IconData icon,
    required Color iconColor,
  }) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MaatriColors.charcoal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: granted ? MaatriColors.successLight : MaatriColors.dangerLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              granted ? 'GRANTED' : 'REVOKED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: granted ? MaatriColors.successDark : MaatriColors.dangerDark,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
