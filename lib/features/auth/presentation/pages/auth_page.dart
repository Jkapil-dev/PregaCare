import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/navigation/app_router.dart';

/// Authentication page with Phone OTP and Google Sign-In
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handlePhoneLogin() {
    setState(() => _isLoading = true);
    // TODO: Implement Firebase Phone OTP
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.go(AppRoutes.pregnancySetup);
      }
    });
  }

  void _handleGoogleLogin() {
    // TODO: Implement Google Sign-In
    context.go(AppRoutes.pregnancySetup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MaatriTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: MaatriTheme.spacingXxl),

              // Welcome text
              Text(
                'Welcome to',
                style: MaatriTypography.headlineLarge.copyWith(
                  color: MaatriColors.slate,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: MaatriTypography.displayMedium.copyWith(
                    color: MaatriColors.charcoal,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Maatri',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Care',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MaatriTheme.spacingSm),
              Text(
                'Sign in to start your maternal healthcare journey',
                style: MaatriTypography.bodyLarge.copyWith(
                  color: MaatriColors.slate,
                ),
              ),

              const SizedBox(height: MaatriTheme.spacingXxl),

              // Phone input
              Text(
                'Phone Number',
                style: MaatriTypography.labelLarge.copyWith(
                  color: MaatriColors.charcoal,
                ),
              ),
              const SizedBox(height: MaatriTheme.spacingSm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: MaatriColors.pureWhite,
                      borderRadius:
                          BorderRadius.circular(MaatriTheme.radiusLg),
                      border: Border.all(color: MaatriColors.lightGray),
                    ),
                    child: Text(
                      '+91',
                      style: MaatriTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: MaatriTheme.spacingSm),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: MaatriTypography.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Enter your phone number',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: MaatriTheme.spacingLg),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handlePhoneLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Continue with Phone',
                          style: MaatriTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: MaatriTheme.spacingLg),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MaatriTheme.spacingMd,
                    ),
                    child: Text(
                      'or',
                      style: MaatriTypography.bodyMedium.copyWith(
                        color: MaatriColors.mediumGray,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: MaatriTheme.spacingLg),

              // Google Sign-In
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: Text(
                    'Continue with Google',
                    style: MaatriTypography.labelLarge.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: MaatriTheme.spacingXxl),

              // Terms
              Center(
                child: Text(
                  'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: MaatriTypography.bodySmall.copyWith(
                    color: MaatriColors.mediumGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
