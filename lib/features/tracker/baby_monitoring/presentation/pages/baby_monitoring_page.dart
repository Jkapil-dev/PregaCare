import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maatricare/core/theme/colors.dart';
import 'package:maatricare/core/theme/typography.dart';
import 'package:maatricare/core/theme/theme.dart';
import 'package:maatricare/core/widgets/common_widgets.dart';

class BabyMonitoringPage extends StatefulWidget {
  const BabyMonitoringPage({super.key});

  @override
  State<BabyMonitoringPage> createState() => _BabyMonitoringPageState();
}

class _BabyMonitoringPageState extends State<BabyMonitoringPage> {
  // Kick Counter State
  int _kickCount = 0;
  bool _isCountingKicks = false;
  int _kickSeconds = 0;
  Timer? _kickTimer;
  final List<String> _kickLogs = ['10 kicks in 45 mins (Yesterday)', '8 kicks in 30 mins (2 days ago)'];

  // Contraction Timer State
  bool _isContractionActive = false;
  int _contractionSeconds = 0;
  Timer? _contractionTimer;
  final List<_ContractionLog> _contractionLogs = [];
  DateTime? _lastContractionTime;

  @override
  void dispose() {
    _kickTimer?.cancel();
    _contractionTimer?.cancel();
    super.dispose();
  }

  // ── Kick Counter Functions ──
  void _startKickSession() {
    setState(() {
      _isCountingKicks = true;
      _kickCount = 0;
      _kickSeconds = 0;
    });
    _kickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _kickSeconds++);
    });
  }

  void _recordKick() {
    if (!_isCountingKicks) return;
    setState(() {
      _kickCount++;
      if (_kickCount >= 10) {
        _stopKickSession(completed: true);
      }
    });
  }

  void _stopKickSession({bool completed = false}) {
    _kickTimer?.cancel();
    setState(() {
      _isCountingKicks = false;
      if (completed) {
        final mins = _kickSeconds ~/ 60;
        final secs = _kickSeconds % 60;
        _kickLogs.insert(0, '10 kicks in $mins mins $secs secs (Just Now)');
      }
    });
  }

  // ── Contraction Timer Functions ──
  void _toggleContraction() {
    if (_isContractionActive) {
      // Stop contraction and save log
      _contractionTimer?.cancel();
      final now = DateTime.now();
      String frequency = '--';
      if (_lastContractionTime != null) {
        final diff = now.difference(_lastContractionTime!);
        frequency = '${diff.inMinutes} mins ago';
      }

      setState(() {
        _contractionLogs.insert(
          0,
          _ContractionLog(
            durationSeconds: _contractionSeconds,
            startTime: _lastContractionTime ?? now.subtract(Duration(seconds: _contractionSeconds)),
            frequency: frequency,
          ),
        );
        _isContractionActive = false;
        _contractionSeconds = 0;
      });
    } else {
      // Start contraction
      setState(() {
        _isContractionActive = true;
        _contractionSeconds = 0;
        _lastContractionTime = DateTime.now();
      });
      _contractionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _contractionSeconds++);
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Baby Monitoring'),
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
            Text('Fetal Development & Vitals', style: MaatriTypography.headlineMedium),
            const SizedBox(height: 4),
            Text('Track baby movement and contraction milestones', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
            const SizedBox(height: MaatriTheme.spacingLg),

            // ── BABY GROWTH PREVIEW ──
            _buildGrowthSection(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── KICK COUNTER ──
            _buildKickCounterSection(),
            const SizedBox(height: MaatriTheme.spacingMd),

            // ── CONTRACTION TIMER ──
            _buildContractionTimerSection(),
            const SizedBox(height: MaatriTheme.spacingXxl),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: MaatriColors.primaryGradient,
            ),
            child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Week 24 Growth', style: MaatriTypography.titleMedium),
                const SizedBox(height: 2),
                Text('Baby is the size of an Eggplant 🍆', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.coral, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Weight is about 600g and length is around 30cm. Senses are developing rapidly!', style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKickCounterSection() {
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
                child: const Icon(Icons.child_friendly_rounded, color: MaatriColors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Kick Counter', style: MaatriTypography.titleMedium),
              const Spacer(),
              Text('Goal: 10 Kicks', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.teal, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isCountingKicks)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startKickSession,
                child: const Text('Start Counting Kicks'),
              ),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Session Time: ${_formatDuration(_kickSeconds)}', style: MaatriTypography.labelLarge),
                    Text('$_kickCount / 10 kicks', style: MaatriTypography.titleMedium.copyWith(color: MaatriColors.teal)),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _recordKick,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MaatriColors.teal,
                      boxShadow: MaatriTheme.glowTeal,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 32),
                        SizedBox(height: 4),
                        Text('TAP ON KICK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _stopKickSession(completed: false),
                  child: const Text('Cancel Session', style: TextStyle(color: MaatriColors.danger)),
                ),
              ],
            ),
          if (_kickLogs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            Text('Movement Log history:', style: MaatriTypography.labelMedium),
            const SizedBox(height: 6),
            ..._kickLogs.take(2).map((log) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: MaatriColors.teal, size: 8),
                  const SizedBox(width: 8),
                  Text(log, style: MaatriTypography.bodySmall),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildContractionTimerSection() {
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
                child: const Icon(Icons.timer_outlined, color: MaatriColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Contraction Timer', style: MaatriTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isContractionActive ? 'CONTRACING NOW' : 'IDLE', style: MaatriTypography.labelLarge.copyWith(color: _isContractionActive ? MaatriColors.danger : MaatriColors.slate)),
                    if (_isContractionActive)
                      Text(_formatDuration(_contractionSeconds), style: MaatriTypography.headlineLarge.copyWith(color: MaatriColors.danger)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _toggleContraction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isContractionActive ? MaatriColors.danger : MaatriColors.coral,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: Text(_isContractionActive ? 'STOP CONTRACTION' : 'START CONTRACTION'),
              ),
            ],
          ),
          if (_contractionLogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Contraction Log History:', style: MaatriTypography.labelMedium),
            const SizedBox(height: 6),
            ..._contractionLogs.take(3).map((log) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Duration: ${log.durationSeconds}s', style: MaatriTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text('Freq: ${log.frequency}', style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _ContractionLog {
  final int durationSeconds;
  final DateTime startTime;
  final String frequency;

  _ContractionLog({
    required this.durationSeconds,
    required this.startTime,
    required this.frequency,
  });
}
