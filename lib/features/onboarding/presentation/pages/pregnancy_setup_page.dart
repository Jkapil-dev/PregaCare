import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/navigation/app_router.dart';

/// 4-step pregnancy setup flow
class PregnancySetupPage extends StatefulWidget {
  const PregnancySetupPage({super.key});

  @override
  State<PregnancySetupPage> createState() => _PregnancySetupPageState();
}

class _PregnancySetupPageState extends State<PregnancySetupPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  DateTime? _lmpDate;
  DateTime? _dueDate;
  bool _isFirstPregnancy = true;
  final Set<String> _conditions = {};

  final _medicalConditions = [
    'Diabetes', 'Hypertension', 'Thyroid', 'Anemia',
    'Asthma', 'Heart Disease', 'PCOS', 'None',
  ];

  void _selectLMP() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 60)),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MaatriColors.coral,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _lmpDate = date;
        _dueDate = date.add(const Duration(days: 280));
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // Complete setup
      context.go(AppRoutes.home);
    }
  }

  int get _currentWeek {
    if (_lmpDate == null) return 0;
    return DateTime.now().difference(_lmpDate!).inDays ~/ 7;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Pregnancy Setup'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                  setState(() => _currentStep--);
                },
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MaatriTheme.spacingLg,
            ),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _currentStep
                          ? MaatriColors.coral
                          : MaatriColors.lightGray,
                      borderRadius:
                          BorderRadius.circular(MaatriTheme.radiusFull),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of 4',
            style: MaatriTypography.labelMedium.copyWith(
              color: MaatriColors.slate,
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildLMPStep(),
                _buildPregnancyTypeStep(),
                _buildMedicalHistoryStep(),
                _buildSummaryStep(),
              ],
            ),
          ),

          // CTA
          Padding(
            padding: const EdgeInsets.all(MaatriTheme.spacingLg),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_currentStep == 0 && _lmpDate == null)
                    ? null
                    : _nextStep,
                child: Text(
                  _currentStep == 3 ? 'Start My Journey' : 'Continue',
                  style: MaatriTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLMPStep() {
    return Padding(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: MaatriTheme.spacingLg),
          Text(
            'When was your last\nmenstrual period?',
            style: MaatriTypography.headlineLarge,
          ),
          const SizedBox(height: MaatriTheme.spacingSm),
          Text(
            'This helps us calculate your due date and track your pregnancy progress.',
            style: MaatriTypography.bodyMedium.copyWith(
              color: MaatriColors.slate,
            ),
          ),
          const SizedBox(height: MaatriTheme.spacingXl),

          // Date picker card
          GestureDetector(
            onTap: _selectLMP,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MaatriTheme.spacingLg),
              decoration: BoxDecoration(
                color: MaatriColors.pureWhite,
                borderRadius: BorderRadius.circular(MaatriTheme.radiusLg),
                border: Border.all(
                  color: _lmpDate != null
                      ? MaatriColors.coral
                      : MaatriColors.lightGray,
                ),
                boxShadow: MaatriTheme.shadowSm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: MaatriColors.coral,
                    size: 28,
                  ),
                  const SizedBox(width: MaatriTheme.spacingMd),
                  Text(
                    _lmpDate != null
                        ? DateFormat('MMMM d, yyyy').format(_lmpDate!)
                        : 'Select date',
                    style: MaatriTypography.titleMedium.copyWith(
                      color: _lmpDate != null
                          ? MaatriColors.charcoal
                          : MaatriColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Due date display
          if (_dueDate != null) ...[
            const SizedBox(height: MaatriTheme.spacingLg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(MaatriTheme.spacingMd),
              decoration: BoxDecoration(
                color: MaatriColors.tealLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    'Estimated Due Date',
                    style: MaatriTypography.labelMedium.copyWith(
                      color: MaatriColors.tealDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM d, yyyy').format(_dueDate!),
                    style: MaatriTypography.headlineMedium.copyWith(
                      color: MaatriColors.tealDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Currently Week $_currentWeek',
                    style: MaatriTypography.bodySmall.copyWith(
                      color: MaatriColors.tealDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPregnancyTypeStep() {
    return Padding(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: MaatriTheme.spacingLg),
          Text('Tell us about\nyour pregnancy',
              style: MaatriTypography.headlineLarge),
          const SizedBox(height: MaatriTheme.spacingXl),
          Text('Is this your first pregnancy?',
              style: MaatriTypography.titleMedium),
          const SizedBox(height: MaatriTheme.spacingMd),
          Row(
            children: [
              _buildChoiceChip('Yes', _isFirstPregnancy, () {
                setState(() => _isFirstPregnancy = true);
              }),
              const SizedBox(width: MaatriTheme.spacingSm),
              _buildChoiceChip('No', !_isFirstPregnancy, () {
                setState(() => _isFirstPregnancy = false);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryStep() {
    return Padding(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: MaatriTheme.spacingLg),
          Text('Medical History', style: MaatriTypography.headlineLarge),
          const SizedBox(height: MaatriTheme.spacingSm),
          Text(
            'Select any existing conditions (optional)',
            style: MaatriTypography.bodyMedium.copyWith(
              color: MaatriColors.slate,
            ),
          ),
          const SizedBox(height: MaatriTheme.spacingLg),
          Wrap(
            spacing: MaatriTheme.spacingSm,
            runSpacing: MaatriTheme.spacingSm,
            children: _medicalConditions.map((c) {
              final selected = _conditions.contains(c);
              return _buildChoiceChip(c, selected, () {
                setState(() {
                  if (c == 'None') {
                    _conditions.clear();
                    _conditions.add('None');
                  } else {
                    _conditions.remove('None');
                    selected ? _conditions.remove(c) : _conditions.add(c);
                  }
                });
              });
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Padding(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: MaatriTheme.spacingLg),
          Text("You're all set! 🎉", style: MaatriTypography.headlineLarge),
          const SizedBox(height: MaatriTheme.spacingLg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MaatriTheme.spacingLg),
            decoration: BoxDecoration(
              gradient: MaatriColors.primaryGradient,
              borderRadius: BorderRadius.circular(MaatriTheme.radiusLg),
            ),
            child: Column(
              children: [
                Text('Week $_currentWeek',
                    style: MaatriTypography.weekCounter
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                if (_dueDate != null)
                  Text(
                    'Due ${DateFormat('MMM d, yyyy').format(_dueDate!)}',
                    style: MaatriTypography.bodyLarge
                        .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MaatriTheme.spacingLg),
          _buildSummaryRow(
              'First pregnancy', _isFirstPregnancy ? 'Yes' : 'No'),
          _buildSummaryRow(
            'Conditions',
            _conditions.isEmpty ? 'None' : _conditions.join(', '),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: MaatriTypography.bodyMedium
                  .copyWith(color: MaatriColors.slate)),
          Text(value, style: MaatriTypography.titleSmall),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? MaatriColors.coral : MaatriColors.pureWhite,
          borderRadius: BorderRadius.circular(MaatriTheme.radiusFull),
          border: Border.all(
            color: selected ? MaatriColors.coral : MaatriColors.lightGray,
          ),
          boxShadow: selected ? MaatriTheme.glowCoral : null,
        ),
        child: Text(
          label,
          style: MaatriTypography.labelLarge.copyWith(
            color: selected ? Colors.white : MaatriColors.charcoal,
          ),
        ),
      ),
    );
  }
}
