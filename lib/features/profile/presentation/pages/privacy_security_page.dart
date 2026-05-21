import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../providers/auth_provider.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _isProcessing = false;

  Future<void> _sendPasswordReset() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.email.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: userProvider.email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset Sent'),
            content: Text(
              'A password reset link has been sent to ${userProvider.email}. Please check your inbox.',
              style: MaatriTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: MaatriColors.coral)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset link: $e'),
            backgroundColor: MaatriColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'WARNING: This will permanently delete your MaatriCare account, your pregnancy tracker data, and all sync entries. This action cannot be undone.',
          style: TextStyle(color: Colors.redAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: MaatriColors.slate)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Attempt deletion
        await user.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been deleted successfully.'),
              backgroundColor: MaatriColors.teal,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Security Notice'),
              content: const Text(
                'To complete this high-risk action, Firebase requires recent authentication. Please sign out and sign back in, then try again.',
                style: TextStyle(color: MaatriColors.charcoal),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: MaatriColors.slate)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().logout();
                  },
                  child: const Text('Sign Out Now', style: TextStyle(color: MaatriColors.danger)),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: ${e.message}'),
              backgroundColor: MaatriColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: MaatriColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
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
                  // Header
                  Text(
                    'Account Security',
                    style: MaatriTypography.titleMedium.copyWith(
                      color: MaatriColors.charcoal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your account credentials, password reset, and sign out options.',
                    style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                  ),
                  const SizedBox(height: 16),

                  // Actions list
                  GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MaatriColors.coral.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_reset_rounded, color: MaatriColors.coral),
                          ),
                          title: const Text('Reset Password'),
                          subtitle: Text('Send a reset email to ${userProvider.email}'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: _isProcessing ? null : _sendPasswordReset,
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MaatriColors.lavenderDark.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded, color: MaatriColors.lavenderDark),
                          ),
                          title: const Text('Sign Out'),
                          subtitle: const Text('Securely log out of this device'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sign Out?'),
                                content: const Text('Are you sure you want to sign out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel', style: TextStyle(color: MaatriColors.slate)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Sign Out', style: TextStyle(color: MaatriColors.danger)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await authProvider.logout();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Danger Zone',
                    style: MaatriTypography.titleMedium.copyWith(
                      color: MaatriColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Critical actions related to account and data erasure.',
                    style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                  ),
                  const SizedBox(height: 16),

                  GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MaatriColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_forever_rounded, color: MaatriColors.danger),
                      ),
                      title: Text(
                        'Delete My Account',
                        style: MaatriTypography.titleSmall.copyWith(color: MaatriColors.danger),
                      ),
                      subtitle: const Text('Permanently erase all your data from Firestore'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: MaatriColors.danger),
                      onTap: _isProcessing ? null : _confirmDeleteAccount,
                    ),
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
}
