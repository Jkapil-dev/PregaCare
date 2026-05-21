import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/navigation/app_router.dart';

/// Splash screen with animated logo and gradient background
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Navigate after splash
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        // TODO: Check auth state to determine route
        context.go(AppRoutes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: MaatriColors.splashGradient,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floating particles
                ...List.generate(20, (i) => _buildParticle(i)),

                // Logo and text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing logo container
                    Transform.scale(
                      scale: _scale.value,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                                alpha: 0.15 + (_glow.value * 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white
                                    .withValues(alpha: _glow.value * 0.3),
                                blurRadius: 40 + (_glow.value * 20),
                                spreadRadius: _glow.value * 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pregnant_woman_rounded,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App name
                    FadeTransition(
                      opacity: _fadeIn,
                      child: RichText(
                        text: TextSpan(
                          style: MaatriTypography.displayMedium.copyWith(
                            color: Colors.white,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Maatri',
                              style: TextStyle(fontWeight: FontWeight.w300),
                            ),
                            TextSpan(
                              text: 'Care',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Text(
                        'Your maternal healthcare companion',
                        style: MaatriTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),

                // Loading indicator at bottom
                Positioned(
                  bottom: 80,
                  child: FadeTransition(
                    opacity: _glow,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final size = 2.0 + (index % 4) * 1.5;
    final top = (index * 47.0) % MediaQuery.of(context).size.height;
    final left = (index * 73.0) % MediaQuery.of(context).size.width;

    return Positioned(
      top: top,
      left: left,
      child: FadeTransition(
        opacity: _glow,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3 + (index % 3) * 0.15),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
