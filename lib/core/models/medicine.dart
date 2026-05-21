import 'dart:convert';
import 'package:flutter/material.dart';

/// Production-grade medicine data model for MaatriCare.
/// Supports multi-time selection, duration tracking, and reminder notifications.
class Medicine {
  final String id;
  String medicineName;
  String dosage;
  List<String> selectedTimes; // ["Morning", "Afternoon", "Night"]
  DateTime startDate;
  DateTime endDate;
  int durationDays;
  String notes;
  String mealTiming; // "Pre-meal", "Post-meal", "Not Applicable"
  bool reminderEnabled;
  List<int> notificationIds;
  final DateTime createdAt;

  Medicine({
    required this.id,
    required this.medicineName,
    this.dosage = '',
    required this.selectedTimes,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.notes = '',
    this.mealTiming = 'Not Applicable',
    this.reminderEnabled = true,
    this.notificationIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Number of remaining days from today
  int get remainingDays {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Whether the medicine schedule is still active
  bool get isActive {
    final now = DateTime.now();
    return now.isBefore(endDate.add(const Duration(days: 1))) &&
        now.isAfter(startDate.subtract(const Duration(days: 1)));
  }

  /// Whether the medicine has expired
  bool get isExpired => DateTime.now().isAfter(endDate.add(const Duration(days: 1)));

  /// Formatted time schedule string (e.g., "Morning • Night")
  String get timeSchedule => selectedTimes.join(' • ');

  /// Get actual hour for a time label
  static int hourForTime(String time) {
    switch (time) {
      case 'Morning':
        return 8;
      case 'Afternoon':
        return 14;
      case 'Night':
        return 20;
      default:
        return 8;
    }
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineName': medicineName,
        'dosage': dosage,
        'selectedTimes': selectedTimes,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'durationDays': durationDays,
        'notes': notes,
        'mealTiming': mealTiming,
        'reminderEnabled': reminderEnabled,
        'notificationIds': notificationIds,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserialize from JSON map (backward compatible)
  factory Medicine.fromJson(Map<String, dynamic> json) {
    // Backward compat: old model had single 'timing' field
    List<String> times;
    if (json.containsKey('selectedTimes')) {
      times = List<String>.from(json['selectedTimes']);
    } else if (json.containsKey('timing')) {
      times = [json['timing'] as String];
    } else {
      times = ['Morning'];
    }

    final startDate = json.containsKey('startDate')
        ? DateTime.parse(json['startDate'])
        : DateTime.now();
    final durationDays = json['durationDays'] as int? ?? 7;
    final endDate = json.containsKey('endDate')
        ? DateTime.parse(json['endDate'])
        : startDate.add(Duration(days: durationDays));

    return Medicine(
      id: json['id'] as String? ?? UniqueKey().toString(),
      medicineName: json['medicineName'] as String? ?? json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      selectedTimes: times,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      notes: json['notes'] as String? ?? '',
      mealTiming: json['mealTiming'] as String? ?? json['meal'] as String? ?? 'Not Applicable',
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      notificationIds: json.containsKey('notificationIds')
          ? List<int>.from(json['notificationIds'])
          : [],
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Create a copy with modifications
  Medicine copyWith({
    String? medicineName,
    String? dosage,
    List<String>? selectedTimes,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? notes,
    String? mealTiming,
    bool? reminderEnabled,
    List<int>? notificationIds,
  }) {
    return Medicine(
      id: id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      selectedTimes: selectedTimes ?? this.selectedTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      notes: notes ?? this.notes,
      mealTiming: mealTiming ?? this.mealTiming,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      notificationIds: notificationIds ?? this.notificationIds,
      createdAt: createdAt,
    );
  }
}
