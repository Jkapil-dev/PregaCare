import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';
import 'package:maatricare/core/widgets/responsive_widgets.dart';
import 'package:maatricare/core/providers/user_provider.dart';

class HealthTrackingPage extends StatefulWidget {
  const HealthTrackingPage({super.key});

  @override
  State<HealthTrackingPage> createState() => _HealthTrackingPageState();
}

class _HealthTrackingPageState extends State<HealthTrackingPage> {
  late TextEditingController _bpSysController;
  late TextEditingController _bpDiaController;
  bool _controllersInitialized = false;
  static const int _waterGoal = 10;

  @override
  void initState() {
    super.initState();
    _bpSysController = TextEditingController();
    _bpDiaController = TextEditingController();
  }

  @override
  void dispose() {
    _bpSysController.dispose();
    _bpDiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (!_controllersInitialized) {
      _bpSysController.text = userProvider.bpSys;
      _bpDiaController.text = userProvider.bpDia;
      _controllersInitialized = true;
    }

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Health Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsivePageWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MaatriTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Vitals & Loggers', style: MaatriTypography.headlineMedium),
            const SizedBox(height: 4),
            Text('Keep your pregnancy bio-metrics fully updated', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
            const SizedBox(height: MaatriTheme.spacingLg),

            // ── BLOOD PRESSURE ──
            _buildBPSection(userProvider),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── WATER INTAKE ──
            _buildWaterSection(userProvider),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── SLEEP TRACKER ──
            _buildSleepSection(userProvider),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── SYMPTOMS LOGGER ──
            _buildSymptomsSection(userProvider),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── TEMPERATURE ──
            _buildTemperatureSection(userProvider),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBPSection(UserProvider userProvider) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.coralLight.withOpacity( 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.favorite_rounded, color: MaatriColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Blood Pressure', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text(
                (userProvider.bpSys.isEmpty || userProvider.bpDia.isEmpty)
                    ? 'Not recorded'
                    : '${userProvider.bpSys}/${userProvider.bpDia} mmHg',
                style: MaatriTypography.labelLarge.copyWith(
                  color: (userProvider.bpSys.isEmpty || userProvider.bpDia.isEmpty)
                      ? MaatriColors.slate
                      : MaatriColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Systolic (SYS)', suffixText: 'mmHg'),
                  keyboardType: TextInputType.number,
                  controller: _bpSysController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Diastolic (DIA)', suffixText: 'mmHg'),
                  keyboardType: TextInputType.number,
                  controller: _bpDiaController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await userProvider.addBPLog(_bpSysController.text, _bpDiaController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blood Pressure updated!'), backgroundColor: MaatriColors.success),
                  );
                }
              },
              child: const Text('Save BP Log'),
            ),
          ),
          if (userProvider.bpHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Text('Recent Logs:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.charcoal)),
            const SizedBox(height: 4),
            ...userProvider.bpHistory.take(2).map((log) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: ResponsiveActionRow(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ResponsiveText(log, style: MaatriTypography.bodySmall),
                  const Icon(Icons.check_circle_rounded, color: MaatriColors.success, size: 14),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterSection(UserProvider userProvider) {
    final glasses = userProvider.waterGlasses;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.tealLight.withOpacity( 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.water_drop_rounded, color: MaatriColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Water Intake', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text('$glasses / $_waterGoal Glasses', style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.teal)),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (glasses / _waterGoal).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: MaatriColors.lightGray,
              valueColor: const AlwaysStoppedAnimation<Color>(MaatriColors.teal),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 28, color: MaatriColors.mediumGray),
                onPressed: glasses > 0 ? () => userProvider.updateWaterGlasses(glasses - 1) : null,
              ),
              Text('$glasses glasses', style: MaatriTypography.headlineSmall),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 28, color: MaatriColors.teal),
                onPressed: glasses < _waterGoal * 2 ? () => userProvider.updateWaterGlasses(glasses + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepSection(UserProvider userProvider) {
    final sleep = userProvider.sleepHours;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.lavenderLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bedtime_rounded, color: MaatriColors.lavenderDark, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Sleep Log', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text(
                sleep == 0.0 ? 'Not logged' : '${sleep.toStringAsFixed(1)} hrs',
                style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.lavenderDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: sleep.clamp(2.0, 14.0),
            min: 2,
            max: 14,
            divisions: 24,
            activeColor: MaatriColors.lavenderDark,
            inactiveColor: MaatriColors.lightGray,
            onChanged: (val) => userProvider.updateSleepHours(val),
          ),
          Center(
            child: Text(
              sleep == 0.0 ? 'Use slider to log your sleep' : (sleep >= 8 ? 'Excellent Rest! 😴' : 'Try to get 8 hours of sleep.'),
              style: MaatriTypography.labelSmall.copyWith(
                color: sleep == 0.0 ? MaatriColors.slate : (sleep >= 8 ? MaatriColors.success : MaatriColors.goldenAmber),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection(UserProvider userProvider) {
    final symptoms = userProvider.symptoms;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.warningLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.sick_outlined, color: MaatriColors.goldenAmber, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Symptoms Tracker', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.keys.map((symptom) {
              final active = symptoms[symptom]!;
              return FilterChip(
                label: Text(symptom),
                selected: active,
                selectedColor: MaatriColors.goldenAmber.withOpacity( 0.15),
                checkmarkColor: MaatriColors.goldenAmber,
                onSelected: (val) => userProvider.updateSymptom(symptom, val),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSection(UserProvider userProvider) {
    final temp = userProvider.temperature;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.coralLight.withOpacity( 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.thermostat_rounded, color: MaatriColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Body Temperature', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text(
                temp == 0.0 ? 'Not recorded' : '${temp.toStringAsFixed(1)} °C',
                style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.coral),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResponsiveActionRow(
            alignment: WrapAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  final newTemp = temp == 0.0 ? 36.7 : temp - 0.1;
                  userProvider.updateTemperature(newTemp);
                },
                style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.lightGray, foregroundColor: MaatriColors.charcoal),
                child: const Icon(Icons.remove, size: 16),
              ),
              ResponsiveText(
                temp == 0.0 ? 'Log today\'s temperature' : (temp > 37.5 ? 'Slight Fever ⚠️' : 'Normal Temp ✓'),
                style: MaatriTypography.bodyMedium.copyWith(
                  color: temp == 0.0 ? MaatriColors.slate : (temp > 37.5 ? MaatriColors.danger : MaatriColors.success),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final newTemp = temp == 0.0 ? 36.9 : temp + 0.1;
                  userProvider.updateTemperature(newTemp);
                },
                style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.lightGray, foregroundColor: MaatriColors.charcoal),
                child: const Icon(Icons.add, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
