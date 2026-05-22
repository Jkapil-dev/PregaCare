import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../navigation/app_router.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Seed mock data to represent integration with actual subsystems
    _notifications = [
      AppNotification(
        id: '1',
        title: 'Time for your Prenatal Vitamin',
        body: 'Please take your daily prenatal vitamin with food.',
        type: NotificationType.medicine,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        priority: NotificationPriority.high,
        actionRoute: AppRoutes.medicationCare,
      ),
      AppNotification(
        id: '2',
        title: 'Hydration Goal Update',
        body: 'You are halfway to your hydration goal today. Drink a glass of water!',
        type: NotificationType.hydration,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        actionRoute: AppRoutes.healthTracking,
      ),
      AppNotification(
        id: '3',
        title: 'Upcoming Appointment',
        body: 'Dr. Smith - Routine ANC Checkup tomorrow at 10:00 AM.',
        type: NotificationType.appointment,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        priority: NotificationPriority.high,
        actionRoute: AppRoutes.medicationCare,
      ),
      AppNotification(
        id: '4',
        title: 'Weekly Knowledge Highlight',
        body: 'Read about fetal development in week 24.',
        type: NotificationType.knowledge,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        actionRoute: AppRoutes.knowledgeHub,
        isRead: true,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
