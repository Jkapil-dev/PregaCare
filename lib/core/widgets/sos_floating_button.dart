import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';
import '../navigation/app_router.dart';
import '../theme/colors.dart';

class SOSFloatingActionButton extends StatefulWidget {
  const SOSFloatingActionButton({super.key});

  @override
  State<SOSFloatingActionButton> createState() => _SOSFloatingActionButtonState();
}

class _SOSFloatingActionButtonState extends State<SOSFloatingActionButton> with SingleTickerProviderStateMixin {
  bool _isHolding = false;
  double _progress = 0.0;
  Timer? _timer;
  late AnimationController _glowController;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  void _startHolding() {
    setState(() {
      _isHolding = true;
      _progress = 0.0;
    });
    
    // We update progress every 50ms (40 steps total for 2000ms)
    const stepDuration = Duration(milliseconds: 50);
    int tickCount = 0;
    
    _timer = Timer.periodic(stepDuration, (timer) {
      tickCount++;
      setState(() {
        _progress = tickCount / 40.0;
      });
      
      // Every 4 ticks (200ms), perform a haptic feedback pulse
      if (tickCount % 4 == 0) {
        HapticFeedback.lightImpact();
      }
      
      if (tickCount >= 40) {
        _timer?.cancel();
        _triggerSOS();
      }
    });
  }

  void _stopHolding() {
    if (!_isHolding) return;
    
    _timer?.cancel();
    _timer = null;
    
    if (_progress < 1.0) {
      // Released before 2 seconds, trigger a double-check haptic pulse and reset
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
    }
    
    setState(() {
      _isHolding = false;
      _progress = 0.0;
    });
  }

  void _triggerSOS() {
    setState(() {
      _isHolding = false;
      _progress = 0.0;
    });
    
    // Play a distinct heavy haptic pulse
    HapticFeedback.heavyImpact();
    
    // Trigger SOS Alert in EmergencyProvider
    final emergencyProvider = Provider.of<EmergencyProvider>(context, listen: false);
    emergencyProvider.triggerSOSAlert(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _stopHolding(),
      onTapCancel: () => _stopHolding(),
      onTap: () {
        // Only navigate if we weren't just holding/long-pressing
        if (!_isHolding && _progress == 0.0) {
          context.push(AppRoutes.emergency);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prompt Tooltip
          AnimatedOpacity(
            opacity: _isHolding ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(_isHolding ? 0 : 10, 0, 0),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Hold 2s to Trigger SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Outer circular loader & button
          Stack(
            alignment: Alignment.center,
            children: [
              // Breathing Glow Animation
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MaatriColors.danger.withOpacity(0.4 * _glowController.value),
                          blurRadius: 8 + 8 * _glowController.value,
                          spreadRadius: 2 + 3 * _glowController.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Circular Loader progress ring (wraps around FAB)
              if (_isHolding)
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 3.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              
              // Main Compact FAB Icon
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MaatriColors.danger,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
