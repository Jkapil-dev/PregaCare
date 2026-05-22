import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/providers/user_provider.dart';

/// Personalized async splash screen
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _textController;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _glow;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  String _loadingMessage = '';

  final _loadingMessages = [
    'Preparing your pregnancy dashboard…',
    'Loading your health insights…',
    'Almost ready…',
  ];

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _mainController.forward();

    // Cycle loading messages
    _startLoadingSequence();
  }

  void _startLoadingSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    for (int i = 0; i < _loadingMessages.length; i++) {
      if (!mounted) return;
      setState(() => _loadingMessage = _loadingMessages[i]);
      _textController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 900));
    }
    
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Wait for provider loading to complete
    while (authProvider.isLoading || userProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      if (!authProvider.isAuthenticated) {
        context.go(AppRoutes.onboarding);
      } else if (userProvider.isOnboardingCompleted) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.pregnancySetup);
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _textController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _textController]),
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
                ...List.generate(15, (i) => _buildParticle(i)),

                // Main content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Glowing logo
                    Transform.scale(
                      scale: _scale.value,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                                alpha: 0.15 + (_glow.value * 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white
                                    .withValues(alpha: _glow.value * 0.25),
                                blurRadius: 40 + (_glow.value * 20),
                                spreadRadius: _glow.value * 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pregnant_woman_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App name
                    FadeTransition(
                      opacity: _fadeIn,
                      child: RichText(
                        text: TextSpan(
                          style: MaatriTypography.displaySmall.copyWith(
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

                    const Spacer(flex: 1),

                    // Personalized greeting
                    FadeTransition(
                      opacity: _glow,
                      child: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          final userName = userProvider.displayName.isNotEmpty 
                              ? userProvider.displayName 
                              : 'Sarah';
                          return Text(
                            '$_greeting, $userName',
                            style: MaatriTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loading message with slide animation
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Text(
                          _loadingMessage,
                          style: MaatriTypography.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Loading indicator
                    FadeTransition(
                      opacity: _glow,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),
                  ],
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
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final top = (index * 47.0) % screenH;
    final left = (index * 73.0) % screenW;

    return Positioned(
      top: top,
      left: left,
      child: FadeTransition(
        opacity: _glow,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25 + (index % 3) * 0.12),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
