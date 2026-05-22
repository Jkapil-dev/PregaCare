import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';

class BabyUpdatesPage extends StatefulWidget {
  const BabyUpdatesPage({super.key});

  @override
  State<BabyUpdatesPage> createState() => _BabyUpdatesPageState();
}

class _BabyUpdatesPageState extends State<BabyUpdatesPage> {
  int _selectedWeek = 1;
  bool _isInit = true;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentWeek = userProvider.pregnancyWeek;

    if (_isInit) {
      _selectedWeek = currentWeek > 0 ? currentWeek.clamp(1, 40) : 1;
      _isInit = false;
    }

    final hasPermission = userProvider.hasBabyUpdatesPermission;

    if (!hasPermission) {
      return Scaffold(
        backgroundColor: MaatriColors.warmCream,
        appBar: AppBar(
          title: const Text('Baby Development'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: MaatriColors.charcoal,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(MaatriTheme.spacingLg),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: Colors.pinkAccent, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Disabled',
                    style: MaatriTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Baby growth updates are currently hidden by the mother.',
                    textAlign: TextAlign.center,
                    style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    // Browse week stats
    final browseStats = UserProvider.weeklyDevelopment[_selectedWeek] ?? UserProvider.weeklyDevelopment[24]!;
    final currentStats = UserProvider.weeklyDevelopment[currentWeek.clamp(1, 40)] ?? UserProvider.weeklyDevelopment[24]!;

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(MaatriTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Baby Development', style: MaatriTypography.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Track baby\'s size, milestones, and development.',
                    style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                  ),
                ],
              ),
            ),

            // Horizontal week selector list
            SizedBox(
              height: 54,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd),
                itemCount: 40,
                itemBuilder: (context, index) {
                  final weekNum = index + 1;
                  final isSelected = weekNum == _selectedWeek;
                  final isCurrent = weekNum == currentWeek;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedWeek = weekNum;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? MaatriColors.coral
                            : isCurrent
                                ? MaatriColors.coral.withValues(alpha: 0.15)
                                : MaatriColors.pureWhite,
                        borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                        border: isCurrent && !isSelected
                            ? Border.all(color: MaatriColors.coral, width: 1.5)
                            : Border.all(color: MaatriColors.lightGray),
                      ),
                      child: Center(
                        child: Text(
                          'Wk $weekNum',
                          style: MaatriTypography.labelMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : isCurrent
                                    ? MaatriColors.coral
                                    : MaatriColors.charcoal,
                            fontWeight: isSelected || isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: MaatriTheme.spacingMd),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Highlight Card for browse week
                    _buildBabyGrowthCard(browseStats, _selectedWeek, currentWeek),
                    const SizedBox(height: MaatriTheme.spacingLg),

                    // Weekly milestone details
                    SectionHeader(
                      title: "Week $_selectedWeek Milestones",
                      icon: Icons.auto_awesome,
                    ),
                    const SizedBox(height: MaatriTheme.spacingSm),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            browseStats['description'] ?? '',
                            style: MaatriTypography.bodyLarge.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: MaatriTheme.spacingMd),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: MaatriColors.teal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedWeek <= 13
                                      ? "Trimester 1: Early structural development & organs forming."
                                      : _selectedWeek <= 26
                                          ? "Trimester 2: Rapid growth, active movement & hair/nails detail."
                                          : "Trimester 3: Lung maturation, fat accumulation & preparation for birth.",
                                  style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.slate),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MaatriTheme.spacingLg),

                    // Quick Comparison with Current Week
                    if (currentWeek > 0 && _selectedWeek != currentWeek) ...[
                      SectionHeader(
                        title: "Current Status (Week $currentWeek)",
                        icon: Icons.child_care_rounded,
                      ),
                      const SizedBox(height: MaatriTheme.spacingSm),
                      GlassCard(
                        onTap: () {
                          setState(() {
                            _selectedWeek = currentWeek.clamp(1, 40);
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: MaatriColors.coral.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, color: MaatriColors.coral, size: 24),
                            ),
                            const SizedBox(width: MaatriTheme.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Baby is currently size of: ${currentStats['size']}",
                                    style: MaatriTypography.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Tap to view this week's full details.",
                                    style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: MaatriColors.mediumGray),
                          ],
                        ),
                      ),
                      const SizedBox(height: MaatriTheme.spacingLg),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabyGrowthCard(Map<String, String> stats, int weekNum, int currentWeek) {
    final size = stats['size'] ?? '';
    final weight = stats['weight'] ?? '';
    final length = stats['length'] ?? '';
    final isCurrent = weekNum == currentWeek;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: MaatriColors.primaryGradient,
        borderRadius: BorderRadius.circular(MaatriTheme.radiusLg),
        boxShadow: MaatriTheme.glowCoral,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.child_care_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(MaatriTheme.radiusFull),
                      ),
                      child: Text(
                        isCurrent ? 'Current Week' : 'Week $weekNum',
                        style: MaatriTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      weekNum <= 13
                          ? '1st Trimester'
                          : weekNum <= 26
                              ? '2nd Trimester'
                              : '3rd Trimester',
                      style: MaatriTypography.labelMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: MaatriTheme.spacingLg),
                Text(
                  'Size of a $size',
                  style: MaatriTypography.headlineLarge.copyWith(color: Colors.white, fontSize: 26),
                ),
                const SizedBox(height: MaatriTheme.spacingLg),
                Divider(color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: MaatriTheme.spacingMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatDetail(Icons.fitness_center_rounded, 'Weight', weight),
                    _buildStatDetail(Icons.straighten_rounded, 'Length', length),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: MaatriTypography.labelSmall.copyWith(color: Colors.white70),
            ),
            Text(
              value,
              style: MaatriTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        )
      ],
    );
  }
}
