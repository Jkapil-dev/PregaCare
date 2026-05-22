import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/widgets/responsive_widgets.dart';
import '../../../../core/navigation/app_router.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: MaatriTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: MaatriColors.charcoal,
          ),
        ),
        backgroundColor: MaatriColors.warmCream,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MaatriColors.charcoal, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: Text(
                    'Mark all read',
                    style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.teal),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: MaatriColors.coral));
          }

          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // Group by Today vs Earlier
          final today = <AppNotification>[];
          final earlier = <AppNotification>[];
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          for (final n in notifications) {
            if (n.timestamp.isAfter(todayStart)) {
              today.add(n);
            } else {
              earlier.add(n);
            }
          }

          return ResponsivePageWrapper(
            useSafeArea: true,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              children: [
                if (today.isNotEmpty) ...[
                  Text(
                    'Today',
                    style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.charcoal),
                  ),
                  const SizedBox(height: 12),
                  ...today.map((n) => _NotificationTile(key: ValueKey(n.id), notification: n)),
                  const SizedBox(height: 24),
                ],
                if (earlier.isNotEmpty) ...[
                  Text(
                    'Earlier',
                    style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.charcoal),
                  ),
                  const SizedBox(height: 12),
                  ...earlier.map((n) => _NotificationTile(key: ValueKey(n.id), notification: n)),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MaatriColors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 64,
              color: MaatriColors.teal.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: MaatriTypography.titleLarge.copyWith(color: MaatriColors.charcoal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no new notifications right now.',
            style: MaatriTypography.bodyLarge.copyWith(color: MaatriColors.slate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final (icon, bgColor, iconColor) = _getNotificationVisuals(notification.type);
    final isUnread = !notification.isRead;
    final timeStr = DateFormat('h:mm a').format(notification.timestamp);

    return GestureDetector(
      onTap: () {
        context.read<NotificationProvider>().markAsRead(notification.id);
        if (notification.actionRoute != null) {
          final route = notification.actionRoute!;
          // Use go() for bottom nav shell routes, push() for sub-routes
          if (route == AppRoutes.home || 
              route == AppRoutes.tracking || 
              route == AppRoutes.knowledgeHub || 
              route == AppRoutes.profile) {
            context.go(route);
          } else {
            context.push(route);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? MaatriColors.pureWhite : MaatriColors.pureWhite.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? MaatriColors.teal.withOpacity(0.3) : MaatriColors.lightGray.withOpacity(0.5),
            width: isUnread ? 1.5 : 1.0,
          ),
          boxShadow: isUnread
              ? [BoxShadow(color: MaatriColors.teal.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: MaatriTypography.titleMedium.copyWith(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: MaatriColors.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: MaatriTypography.labelSmall.copyWith(
                          color: isUnread ? MaatriColors.teal : MaatriColors.mediumGray,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: MaatriTypography.bodyMedium.copyWith(
                      color: isUnread ? MaatriColors.charcoal.withOpacity(0.8) : MaatriColors.slate,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread Dot
            if (isUnread) ...[
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: MaatriColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _getNotificationVisuals(NotificationType type) {
    switch (type) {
      case NotificationType.medicine:
        return (Icons.medication_rounded, MaatriColors.coralLight.withOpacity(0.5), MaatriColors.coral);
      case NotificationType.hydration:
        return (Icons.water_drop_rounded, MaatriColors.tealLight.withOpacity(0.5), MaatriColors.teal);
      case NotificationType.appointment:
        return (Icons.calendar_month_rounded, MaatriColors.lavenderDark.withOpacity(0.2), MaatriColors.lavenderDark);
      case NotificationType.vaccination:
        return (Icons.vaccines_rounded, MaatriColors.tealLight.withOpacity(0.5), MaatriColors.teal);
      case NotificationType.emergency:
        return (Icons.warning_rounded, Colors.red.withOpacity(0.1), Colors.red);
      case NotificationType.wellness:
        return (Icons.self_improvement_rounded, MaatriColors.goldenAmber.withOpacity(0.2), MaatriColors.goldenAmber);
      case NotificationType.knowledge:
        return (Icons.auto_stories_rounded, MaatriColors.tealLight.withOpacity(0.5), MaatriColors.tealDark);
      case NotificationType.system:
        return (Icons.info_outline_rounded, MaatriColors.lightGray, MaatriColors.slate);
    }
  }
}
