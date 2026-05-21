import 'package:flutter/material.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';

class HealthTrackingPage extends StatefulWidget {
  const HealthTrackingPage({super.key});

  @override
  State<HealthTrackingPage> createState() => _HealthTrackingPageState();
}

class _HealthTrackingPageState extends State<HealthTrackingPage> {
  // Blood Pressure
  String _bpSys = '120';
  String _bpDia = '80';
  final List<String> _bpHistory = ['120/80 mmHg (Today)', '118/79 mmHg (2 days ago)'];

  // Water
  int _waterGlasses = 5;
  static const int _waterGoal = 10;

  // Sleep
  double _sleepHours = 7.5;

  // Temperature
  double _temperature = 36.8;

  // Symptoms
  final Map<String, bool> _symptoms = {
    'Morning Sickness': true,
    'Fatigue': false,
    'Backache': true,
    'Headache': false,
    'Swollen Ankles': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Health Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MaatriTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Vitals & Loggers', style: MaatriTypography.headlineMedium),
            const SizedBox(height: 4),
            Text('Keep your pregnancy bio-metrics fully updated', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
            const SizedBox(height: MaatriTheme.spacingLg),

            // ── BLOOD PRESSURE ──
            _buildBPSection(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── WATER INTAKE ──
            _buildWaterSection(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── SLEEP TRACKER ──
            _buildSleepSection(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── SYMPTOMS LOGGER ──
            _buildSymptomsSection(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── TEMPERATURE ──
            _buildTemperatureSection(),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildBPSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.coralLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.favorite_rounded, color: MaatriColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Blood Pressure', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text('Normal Range', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Systolic (SYS)', suffixText: 'mmHg'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _bpSys = val,
                  controller: TextEditingController(text: _bpSys),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Diastolic (DIA)', suffixText: 'mmHg'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _bpDia = val,
                  controller: TextEditingController(text: _bpDia),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _bpHistory.insert(0, '$_bpSys/$_bpDia mmHg (Just Now)');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Blood Pressure updated!'), backgroundColor: MaatriColors.success),
                );
              },
              child: const Text('Save BP Log'),
            ),
          ),
          if (_bpHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Text('Recent Logs:', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.charcoal)),
            const SizedBox(height: 4),
            ..._bpHistory.take(2).map((log) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(log, style: MaatriTypography.bodySmall),
                  const Icon(Icons.check_circle_rounded, color: MaatriColors.success, size: 14),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.tealLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.water_drop_rounded, color: MaatriColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Water Intake', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text('$_waterGlasses / $_waterGoal Glasses', style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.teal)),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _waterGlasses / _waterGoal,
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
                onPressed: _waterGlasses > 0 ? () => setState(() => _waterGlasses--) : null,
              ),
              Text('$_waterGlasses glasses', style: MaatriTypography.headlineSmall),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 28, color: MaatriColors.teal),
                onPressed: _waterGlasses < _waterGoal * 2 ? () => setState(() => _waterGlasses++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepSection() {
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
              Text('${_sleepHours.toStringAsFixed(1)} hrs', style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.lavenderDark)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _sleepHours,
            min: 2,
            max: 14,
            divisions: 24,
            activeColor: MaatriColors.lavenderDark,
            inactiveColor: MaatriColors.lightGray,
            onChanged: (val) => setState(() => _sleepHours = val),
          ),
          Center(
            child: Text(
              _sleepHours >= 8 ? 'Excellent Rest! 😴' : 'Try to get 8 hours of sleep.',
              style: MaatriTypography.labelSmall.copyWith(color: _sleepHours >= 8 ? MaatriColors.success : MaatriColors.goldenAmber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection() {
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
            children: _symptoms.keys.map((symptom) {
              final active = _symptoms[symptom]!;
              return FilterChip(
                label: Text(symptom),
                selected: active,
                selectedColor: MaatriColors.goldenAmber.withValues(alpha: 0.15),
                checkmarkColor: MaatriColors.goldenAmber,
                onSelected: (val) {
                  setState(() => _symptoms[symptom] = val);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MaatriColors.coralLight.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.thermostat_rounded, color: MaatriColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Body Temperature', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text('${_temperature.toStringAsFixed(1)} °C', style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.coral)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _temperature -= 0.1),
                style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.lightGray, foregroundColor: MaatriColors.charcoal),
                child: const Icon(Icons.remove, size: 16),
              ),
              Text(
                _temperature > 37.5 ? 'Slight Fever ⚠️' : 'Normal Temp ✓',
                style: MaatriTypography.bodyMedium.copyWith(color: _temperature > 37.5 ? MaatriColors.danger : MaatriColors.success),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _temperature += 0.1),
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
