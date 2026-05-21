class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final int priority; // 1 = Primary, 2 = Secondary, 3 = Tertiary
  final bool emergencyEnabled; // True if this contact receives SOS updates or quick dials

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.priority = 1,
    this.emergencyEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'priority': priority,
      'emergencyEnabled': emergencyEnabled,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      priority: json['priority'] as int? ?? 1,
      emergencyEnabled: json['emergencyEnabled'] as bool? ?? true,
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    int? priority,
    bool? emergencyEnabled,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      emergencyEnabled: emergencyEnabled ?? this.emergencyEnabled,
    );
  }
}
