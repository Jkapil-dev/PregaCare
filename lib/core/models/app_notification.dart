import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  medicine,
  hydration,
  appointment,
  vaccination,
  emergency,
  wellness,
  knowledge,
  system
}

enum NotificationPriority { low, normal, high }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final NotificationPriority priority;
  final bool isRead;
  final String? actionRoute;
  final String? relatedId;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.actionRoute,
    this.relatedId,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    NotificationPriority? priority,
    bool? isRead,
    String? actionRoute,
    String? relatedId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.name,
      'isRead': isRead,
      'actionRoute': actionRoute,
      'relatedId': relatedId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      timestamp: json['timestamp'] != null 
          ? (json['timestamp'] is Timestamp 
              ? (json['timestamp'] as Timestamp).toDate() 
              : DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      isRead: json['isRead'] as bool? ?? false,
      actionRoute: json['actionRoute'] as String?,
      relatedId: json['relatedId'] as String?,
    );
  }
}
