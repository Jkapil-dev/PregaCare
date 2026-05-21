import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

/// MaatriCare custom bottom navigation bar
class MaatriBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MaatriBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.favorite_outline_rounded, activeIcon: Icons.favorite_rounded, label: 'Track'),
    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'AI'),
    _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Community'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MaatriColors.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MaatriTheme.spacingSm,
            vertical: MaatriTheme.spacingXs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;
              return _buildNavItem(context, item, isActive, index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    _NavItem item,
    bool isActive,
    int index,
  ) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: MaatriColors.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MaatriTheme.radiusFull),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? MaatriColors.coral : MaatriColors.mediumGray,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MaatriColors.coral,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
