import 'package:flutter/material.dart';

/// Production-grade maternal consultation data model for MaatriCare.
class Consultation {
  final String id;
  String doctorName;
  String specialization;
  String hospitalOrClinic;
  DateTime appointmentDate;
  String appointmentTime; // "10:30 AM"
  String notes;
  bool reminderEnabled;
  String consultationStatus; // "Upcoming", "Completed", "Missed", "Cancelled"
  int notificationId;
  final DateTime createdAt;

  Consultation({
    required this.id,
    required this.doctorName,
    this.specialization = 'Gynecologist',
    this.hospitalOrClinic = '',
    required this.appointmentDate,
    required this.appointmentTime,
    this.notes = '',
    this.reminderEnabled = true,
    this.consultationStatus = 'Upcoming',
    int? notificationId,
    DateTime? createdAt,
  })  : notificationId = notificationId ?? (id.hashCode).abs() % 100000,
        createdAt = createdAt ?? DateTime.now();

  /// Serialize to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorName': doctorName,
        'specialization': specialization,
        'hospitalOrClinic': hospitalOrClinic,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'notes': notes,
        'reminderEnabled': reminderEnabled,
        'consultationStatus': consultationStatus,
        'notificationId': notificationId,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserialize from JSON map
  factory Consultation.fromJson(Map<String, dynamic> json) {
    final date = json.containsKey('appointmentDate')
        ? DateTime.parse(json['appointmentDate'])
        : DateTime.now();

    return Consultation(
      id: json['id'] as String? ?? UniqueKey().toString(),
      doctorName: json['doctorName'] as String? ?? '',
      specialization: json['specialization'] as String? ?? 'Gynecologist',
      hospitalOrClinic: json['hospitalOrClinic'] as String? ?? '',
      appointmentDate: date,
      appointmentTime: json['appointmentTime'] as String? ?? '10:00 AM',
      notes: json['notes'] as String? ?? '',
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      consultationStatus: json['consultationStatus'] as String? ?? 'Upcoming',
      notificationId: json['notificationId'] as int? ?? 0,
      createdAt: json.containsKey('createdAt')
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Create a copy with modifications
  Consultation copyWith({
    String? doctorName,
    String? specialization,
    String? hospitalOrClinic,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? notes,
    bool? reminderEnabled,
    String? consultationStatus,
    int? notificationId,
  }) {
    return Consultation(
      id: id,
      doctorName: doctorName ?? this.doctorName,
      specialization: specialization ?? this.specialization,
      hospitalOrClinic: hospitalOrClinic ?? this.hospitalOrClinic,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      consultationStatus: consultationStatus ?? this.consultationStatus,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt,
    );
  }
}
