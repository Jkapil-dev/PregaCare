import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../theme/typography.dart';
import 'common_widgets.dart';

/// A globally safe text widget that structurally enforces ellipsis
/// truncation to prevent horizontal overflow in bounded containers.
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign textAlign;
  final bool isFlexible;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.isFlexible = false,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      softWrap: maxLines > 1,
    );

    if (isFlexible) {
      return Flexible(child: textWidget);
    }
    return textWidget;
  }
}

/// A responsive equivalent to a Section Header that wraps the title
/// and action buttons gracefully when screen space shrinks.
class ResponsiveSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? iconColor;

  const ResponsiveSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4.0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor ?? MaatriColors.coral),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: ResponsiveText(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 2,
              ),
            ),
          ],
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 0),
            ),
            child: Text(actionText!),
          ),
      ],
    );
  }
}

/// A responsive action row that automatically breaks into multiple rows
/// preventing the common clipped button UI issue.
class ResponsiveActionRow extends StatelessWidget {
  final List<Widget> children;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final double spacing;
  final double runSpacing;

  const ResponsiveActionRow({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.center,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}

/// A chip bar that ensures horizontal scrolling without breaking the layout bounds.
/// It uses SingleChildScrollView to keep chips safe.
class ResponsiveChipBar extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;

  const ResponsiveChipBar({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// A wrapper for cards that applies responsive sizing logic internally.
/// Guarantees that GlassCard constraints won't blow up parent Row wrappers.
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: GlassCard(
            padding: padding,
            onTap: onTap,
            child: child,
          ),
        );
      },
    );
  }
}

/// A global page wrapper that enforces safe boundaries.
/// Prevents the UI from stretching infinitely on wide screens (tablets)
/// and strictly enforces the mobile safe area constraint.
class ResponsivePageWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double maxWidth;
  final bool useSafeArea;
  final EdgeInsetsGeometry padding;

  const ResponsivePageWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
    this.maxWidth = 600.0,
    this.useSafeArea = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      color: backgroundColor,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}
