import 'package:flutter/material.dart';

/// Production-grade maternal vaccination data model for MaatriCare.
class Vaccination {
  final String id;
  String vaccineName;
  String doseNumber;
  DateTime scheduledDate;
  String hospitalOrClinic;
  String doctorName;
  String notes;
  bool reminderEnabled;
  String vaccinationStatus; // "Upcoming", "Completed", "Missed", "Overdue"
  int notificationId;
  final DateTime createdAt;

  Vaccination({
    required this.id,
    required this.vaccineName,
    required this.doseNumber,
    required this.scheduledDate,
    this.hospitalOrClinic = '',
    this.doctorName = '',
    this.notes = '',
    this.reminderEnabled = true,
    this.vaccinationStatus = 'Upcoming',
    int? notificationId,
    DateTime? createdAt,
  })  : notificationId = notificationId ?? (id.hashCode).abs() % 100000,
        createdAt = createdAt ?? DateTime.now();

  /// Whether the scheduled vaccination date has passed and is still not completed
  bool get isOverdue {
    if (vaccinationStatus == 'Completed') return false;
    final today = DateTime.now();
    final todayZero = DateTime(today.year, today.month, today.day);
    final scheduledZero = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    return todayZero.isAfter(scheduledZero);
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'vaccineName': vaccineName,
        'doseNumber': doseNumber,
        'scheduledDate': scheduledDate.toIso8601String(),
        'hospitalOrClinic': hospitalOrClinic,
        'doctorName': doctorName,
        'notes': notes,
        'reminderEnabled': reminderEnabled,
        'vaccinationStatus': vaccinationStatus,
        'notificationId': notificationId,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserialize from JSON map
  factory Vaccination.fromJson(Map<String, dynamic> json) {
    final scheduled = json.containsKey('scheduledDate')
        ? DateTime.parse(json['scheduledDate'])
        : DateTime.now();
    
    final status = json['vaccinationStatus'] as String? ?? 'Upcoming';

    return Vaccination(
      id: json['id'] as String? ?? UniqueKey().toString(),
      vaccineName: json['vaccineName'] as String? ?? '',
      doseNumber: json['doseNumber'] as String? ?? 'Dose 1',
      scheduledDate: scheduled,
      hospitalOrClinic: json['hospitalOrClinic'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      vaccinationStatus: status,
      notificationId: json['notificationId'] as int? ?? 0,
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Create a copy with modifications
  Vaccination copyWith({
    String? vaccineName,
    String? doseNumber,
    DateTime? scheduledDate,
    String? hospitalOrClinic,
    String? doctorName,
    String? notes,
    bool? reminderEnabled,
    String? vaccinationStatus,
    int? notificationId,
  }) {
    return Vaccination(
      id: id,
      vaccineName: vaccineName ?? this.vaccineName,
      doseNumber: doseNumber ?? this.doseNumber,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      hospitalOrClinic: hospitalOrClinic ?? this.hospitalOrClinic,
      doctorName: doctorName ?? this.doctorName,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt,
    );
  }
}
