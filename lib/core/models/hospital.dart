class Hospital {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String distance;
  final bool maternitySupport;
  final bool emergencyAvailability;
  final bool isPreferred;

  const Hospital({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.distance = '',
    this.maternitySupport = true,
    this.emergencyAvailability = true,
    this.isPreferred = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'distance': distance,
      'maternitySupport': maternitySupport,
      'emergencyAvailability': emergencyAvailability,
      'isPreferred': isPreferred,
    };
  }

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      maternitySupport: json['maternitySupport'] as bool? ?? true,
      emergencyAvailability: json['emergencyAvailability'] as bool? ?? true,
      isPreferred: json['isPreferred'] as bool? ?? false,
    );
  }

  Hospital copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? distance,
    bool? maternitySupport,
    bool? emergencyAvailability,
    bool? isPreferred,
  }) {
    return Hospital(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      maternitySupport: maternitySupport ?? this.maternitySupport,
      emergencyAvailability: emergencyAvailability ?? this.emergencyAvailability,
      isPreferred: isPreferred ?? this.isPreferred,
    );
  }
}
