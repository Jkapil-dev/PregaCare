import 'package:cloud_firestore/cloud_firestore.dart';

class PregnancyConnection {
  final String id;
  final String motherUid;
  final String partnerUid;
  final String connectionCode; // MAT-XXXXXX
  final String status; // 'pending', 'active', 'disconnected'
  final Map<String, bool> permissions; // viewTracker, viewEmergency, viewReminders, viewNotifications
  final List<String> linkedUsers; // [motherUid, partnerUid]
  final DateTime createdAt;
  final bool active;

  PregnancyConnection({
    required this.id,
    required this.motherUid,
    required this.partnerUid,
    required this.connectionCode,
    required this.status,
    required this.permissions,
    required this.linkedUsers,
    required this.createdAt,
    required this.active,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motherUid': motherUid,
      'partnerUid': partnerUid,
      'connectionCode': connectionCode,
      'status': status,
      'permissions': permissions,
      'linkedUsers': linkedUsers,
      'createdAt': createdAt.toIso8601String(),
      'active': active,
    };
  }

  factory PregnancyConnection.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final created = json['createdAt'];
    if (created is Timestamp) {
      parsedDate = created.toDate();
    } else if (created is String) {
      parsedDate = DateTime.tryParse(created) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawPermissions = json['permissions'];
    Map<String, bool> permissionsMap = {
      'viewTracker': true,
      'viewEmergency': true,
      'viewReminders': true,
      'viewNotifications': true,
    };
    if (rawPermissions is Map) {
      rawPermissions.forEach((k, v) {
        permissionsMap[k.toString()] = v == true;
      });
    }

    final rawLinked = json['linkedUsers'];
    List<String> linked = [];
    if (rawLinked is List) {
      linked = List<String>.from(rawLinked);
    }

    return PregnancyConnection(
      id: json['id'] as String? ?? '',
      motherUid: json['motherUid'] as String? ?? '',
      partnerUid: json['partnerUid'] as String? ?? '',
      connectionCode: json['connectionCode'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      permissions: permissionsMap,
      linkedUsers: linked,
      createdAt: parsedDate,
      active: json['active'] as bool? ?? false,
    );
  }

  PregnancyConnection copyWith({
    String? id,
    String? motherUid,
    String? partnerUid,
    String? connectionCode,
    String? status,
    Map<String, bool>? permissions,
    List<String>? linkedUsers,
    DateTime? createdAt,
    bool? active,
  }) {
    return PregnancyConnection(
      id: id ?? this.id,
      motherUid: motherUid ?? this.motherUid,
      partnerUid: partnerUid ?? this.partnerUid,
      connectionCode: connectionCode ?? this.connectionCode,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      linkedUsers: linkedUsers ?? this.linkedUsers,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
    );
  }
}
