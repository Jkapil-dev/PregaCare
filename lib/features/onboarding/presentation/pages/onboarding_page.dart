import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/navigation/app_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingData(
      icon: Icons.pregnant_woman_rounded,
      iconColor: MaatriColors.coral,
      bgColor: MaatriColors.softRose,
      title: 'Your Pregnancy\nCompanion',
      subtitle:
          'Track your baby\'s growth week by week with beautiful visualizations and personalized insights.',
    ),
    _OnboardingData(
      icon: Icons.monitor_heart_rounded,
      iconColor: MaatriColors.teal,
      bgColor: MaatriColors.tealLight,
      title: 'Smart Health\nTracking',
      subtitle:
          'Monitor symptoms, vitals, mood, and medications with intelligent alerts and trend analysis.',
    ),
    _OnboardingData(
      icon: Icons.auto_awesome_rounded,
      iconColor: MaatriColors.lavenderDark,
      bgColor: MaatriColors.lavenderLight,
      title: 'AI-Powered\nGuidance',
      subtitle:
          'Get instant answers, nutrition plans, and personalized recommendations from your AI assistant.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(MaatriTheme.spacingMd),
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.auth),
                  child: Text(
                    'Skip',
                    style: MaatriTypography.labelLarge.copyWith(
                      color: MaatriColors.slate,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page);
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.all(MaatriTheme.spacingLg),
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: MaatriColors.coral,
                      dotColor: MaatriColors.lightGray,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: MaatriTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration container
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.iconColor.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 90,
              color: page.iconColor,
            ),
          ),
          const SizedBox(height: MaatriTheme.spacingXxl),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: MaatriTypography.displaySmall.copyWith(
              color: MaatriColors.charcoal,
            ),
          ),
          const SizedBox(height: MaatriTheme.spacingMd),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: MaatriTypography.bodyLarge.copyWith(
              color: MaatriColors.slate,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });
}
