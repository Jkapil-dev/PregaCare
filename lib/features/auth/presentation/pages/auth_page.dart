import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../providers/auth_provider.dart';

/// Authentication page supporting toggling between Email/Password Login & Sign Up
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success = false;

    if (_isSignUp) {
      success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
      );
    } else {
      success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSignUp ? 'Account created successfully! Welcome.' : 'Signed in successfully!'),
          backgroundColor: MaatriColors.teal,
        ),
      );
      // Reactive navigation handles routing automatically
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Authentication failed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingLg, vertical: MaatriTheme.spacingMd),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: MaatriTheme.spacingLg),
                  
                  // Brand Header
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
                    _isSignUp 
                        ? 'Create an account to start your maternal journey' 
                        : 'Sign in to access your maternal health records',
                    style: MaatriTypography.bodyLarge.copyWith(
                      color: MaatriColors.slate,
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingXl),

                  // Toggle Login / Sign Up Tab
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: MaatriColors.lightGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = false),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !_isSignUp ? MaatriColors.coral : Colors.transparent,
                                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                                boxShadow: !_isSignUp ? MaatriTheme.glowCoral : null,
                              ),
                              child: Text(
                                'Sign In',
                                style: MaatriTypography.labelLarge.copyWith(
                                  color: !_isSignUp ? Colors.white : MaatriColors.charcoal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = true),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isSignUp ? MaatriColors.coral : Colors.transparent,
                                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                                boxShadow: _isSignUp ? MaatriTheme.glowCoral : null,
                              ),
                              child: Text(
                                'Sign Up',
                                style: MaatriTypography.labelLarge.copyWith(
                                  color: _isSignUp ? Colors.white : MaatriColors.charcoal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // Display Name Field (Sign Up Only)
                  if (_isSignUp) ...[
                    Text(
                      'Full Name',
                      style: MaatriTypography.labelLarge.copyWith(
                        color: MaatriColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: MaatriTheme.spacingXs),
                    TextFormField(
                      controller: _nameController,
                      style: MaatriTypography.bodyLarge,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: MaatriColors.coral),
                      ),
                      validator: (value) {
                        if (_isSignUp && (value == null || value.trim().isEmpty)) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: MaatriTheme.spacingMd),
                  ],

                  // Email Field
                  Text(
                    'Email Address',
                    style: MaatriTypography.labelLarge.copyWith(
                      color: MaatriColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingXs),
                  TextFormField(
                    controller: _emailController,
                    style: MaatriTypography.bodyLarge,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(Icons.email_outlined, color: MaatriColors.coral),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: MaatriTheme.spacingMd),

                  // Password Field
                  Text(
                    'Password',
                    style: MaatriTypography.labelLarge.copyWith(
                      color: MaatriColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingXs),
                  TextFormField(
                    controller: _passwordController,
                    style: MaatriTypography.bodyLarge,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: _isSignUp ? 'Create a secure password (min 6 chars)' : 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: MaatriColors.coral),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: MaatriColors.mediumGray,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleSubmit,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: MaatriTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // Switch between Sign In / Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                        style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp ? 'Sign In' : 'Sign Up',
                          style: MaatriTypography.labelLarge.copyWith(
                            color: MaatriColors.coral,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: MaatriTheme.spacingXl),

                  // Terms and Footer
                  Center(
                    child: Text(
                      'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: MaatriTypography.bodySmall.copyWith(
                        color: MaatriColors.mediumGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingLg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
