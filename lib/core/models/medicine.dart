import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Production-grade medicine data model for MaatriCare.
/// Supports multi-time selection, meal relations, reminder status, duration, and adherence history logs.
class Medicine {
  final String id;
  String medicineName;
  String dosage;
  List<String> selectedTimes; // ["Morning", "Afternoon", "Night"]
  String mealType; // "Before Meal", "After Meal", "With Meal", "Empty Stomach"
  DateTime startDate;
  DateTime endDate;
  int durationDays;
  String notes;
  bool reminderEnabled;
  List<int> notificationIds;
  Map<String, Map<String, String>> adherenceLogs; // {"yyyy-MM-dd": {"Morning": "Taken", "Night": "Pending"}}
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.medicineName,
    this.dosage = '',
    required this.selectedTimes,
    this.mealType = 'After Meal',
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.notes = '',
    this.reminderEnabled = true,
    this.notificationIds = const [],
    Map<String, Map<String, String>>? adherenceLogs,
    DateTime? createdAt,
  })  : adherenceLogs = adherenceLogs ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// Calculate Adherence Percentage
  double get adherencePercentage {
    int takenCount = 0;
    int missedCount = 0;

    adherenceLogs.forEach((date, timesMap) {
      timesMap.forEach((time, status) {
        if (status == 'Taken') {
          takenCount++;
        } else if (status == 'Missed') {
          missedCount++;
        }
      });
    });

    final totalLogged = takenCount + missedCount;
    if (totalLogged == 0) return 100.0;
    return (takenCount / totalLogged) * 100.0;
  }

  /// Total Scheduled Doses in logs
  int get totalScheduledDoses {
    int total = 0;
    adherenceLogs.forEach((date, timesMap) {
      total += timesMap.length;
    });
    return total;
  }

  /// Total completed doses in logs
  int get completedDoses {
    int takenCount = 0;
    adherenceLogs.forEach((date, timesMap) {
      timesMap.forEach((time, status) {
        if (status == 'Taken') {
          takenCount++;
        }
      });
    });
    return takenCount;
  }

  /// Total missed doses in logs
  int get missedDoses {
    int missedCount = 0;
    adherenceLogs.forEach((date, timesMap) {
      timesMap.forEach((time, status) {
        if (status == 'Missed') {
          missedCount++;
        }
      });
    });
    return missedCount;
  }

  /// Number of remaining days from today
  int get remainingDays {
    final today = DateTime.now();
    final todayZero = DateTime(today.year, today.month, today.day);
    final endZero = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = endZero.difference(todayZero).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  /// Whether the medicine schedule is still active
  bool get isActive {
    final now = DateTime.now();
    final todayZero = DateTime(now.year, now.month, now.day);
    final startZero = DateTime(startDate.year, startDate.month, startDate.day);
    final endZero = DateTime(endDate.year, endDate.month, endDate.day);
    return !todayZero.isBefore(startZero) && !todayZero.isAfter(endZero);
  }

  /// Whether the medicine has expired
  bool get isExpired {
    final now = DateTime.now();
    final todayZero = DateTime(now.year, now.month, now.day);
    final endZero = DateTime(endDate.year, endDate.month, endDate.day);
    return todayZero.isAfter(endZero);
  }

  /// Formatted time schedule string (e.g., "Morning • Night")
  String get timeSchedule => selectedTimes.join(' • ');

  /// Serialize to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineName': medicineName,
        'dosage': dosage,
        'selectedTimes': selectedTimes,
        'mealType': mealType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'durationDays': durationDays,
        'notes': notes,
        'reminderEnabled': reminderEnabled,
        'notificationIds': notificationIds,
        'adherenceLogs': adherenceLogs,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Helper to robustly parse DateTime from String, DateTime, Timestamp or custom Map representation
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    
    if (value is Map) {
      if (value.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch((value['_seconds'] as int) * 1000);
      }
      if (value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch((value['seconds'] as int) * 1000);
      }
    }
    return DateTime.now();
  }

  /// Deserialize from JSON map (backward compatible)
  factory Medicine.fromJson(Map<String, dynamic> json) {
    List<String> times;
    if (json.containsKey('selectedTimes')) {
      times = List<String>.from(json['selectedTimes']);
    } else if (json.containsKey('timing')) {
      times = [json['timing'] as String];
    } else {
      times = ['Morning'];
    }

    final startDate = json.containsKey('startDate')
        ? _parseDateTime(json['startDate'])
        : DateTime.now();
    final durationDays = json['durationDays'] as int? ?? 7;
    final endDate = json.containsKey('endDate')
        ? _parseDateTime(json['endDate'])
        : startDate.add(Duration(days: durationDays > 0 ? durationDays - 1 : 0));

    // Handle Adherence Logs safely
    Map<String, Map<String, String>> logs = {};
    if (json.containsKey('adherenceLogs')) {
      final rawLogs = json['adherenceLogs'] as Map<String, dynamic>;
      rawLogs.forEach((date, val) {
        if (val is Map) {
          logs[date] = val.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      });
    }

    return Medicine(
      id: json['id'] as String? ?? UniqueKey().toString(),
      medicineName: json['medicineName'] as String? ?? json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      selectedTimes: times,
      mealType: json['mealType'] as String? ?? json['mealTiming'] as String? ?? 'After Meal',
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      notes: json['notes'] as String? ?? '',
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      notificationIds: json.containsKey('notificationIds')
          ? List<int>.from(json['notificationIds'])
          : [],
      adherenceLogs: logs,
      createdAt: json.containsKey('createdAt')
          ? _parseDateTime(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Create a copy with modifications
  Medicine copyWith({
    String? medicineName,
    String? dosage,
    List<String>? selectedTimes,
    String? mealType,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? notes,
    bool? reminderEnabled,
    List<int>? notificationIds,
    Map<String, Map<String, String>>? adherenceLogs,
  }) {
    return Medicine(
      id: id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      selectedTimes: selectedTimes ?? this.selectedTimes,
      mealType: mealType ?? this.mealType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notificationIds: notificationIds ?? this.notificationIds,
      adherenceLogs: adherenceLogs ?? this.adherenceLogs,
      createdAt: createdAt,
    );
  }
}
