import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'responsive_widgets.dart';

/// Glassmorphism-style card used throughout MaatriCare
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.gradient,
    this.backgroundColor,
    this.borderRadius = MaatriTheme.radiusLg,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? (backgroundColor ?? MaatriColors.pureWhite)
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ?? MaatriTheme.shadowSm,
          border: Border.all(
            color: MaatriColors.glassBorder,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding:
                  padding ?? const EdgeInsets.all(MaatriTheme.spacingMd),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary gradient card (coral)
class PrimaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PrimaryCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: MaatriColors.primaryGradient,
      boxShadow: MaatriTheme.glowCoral,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// Accent card (teal)
class AccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AccentCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: MaatriColors.tealGradient,
      boxShadow: MaatriTheme.glowTeal,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// Quick action tile used on dashboard
class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MaatriTheme.spacingMd,
          vertical: MaatriTheme.spacingSm + 4,
        ),
        decoration: BoxDecoration(
          color: MaatriColors.pureWhite,
          borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
          boxShadow: MaatriTheme.shadowSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity( 0.12),
                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: MaatriColors.darkGray,
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional action
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? iconColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveSectionHeader(
      title: title,
      actionText: actionText,
      onAction: onAction,
      icon: icon,
      iconColor: iconColor,
    );
  }
}

/// Animated progress ring
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.foregroundColor,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: backgroundColor ??
                  MaatriColors.pureWhite.withOpacity( 0.3),
              color: foregroundColor ?? MaatriColors.pureWhite,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Status indicator dot
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;

  const StatusDot({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity( 0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
