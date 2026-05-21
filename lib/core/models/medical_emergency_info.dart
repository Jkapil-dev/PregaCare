class MedicalEmergencyInfo {
  final String bloodGroup;
  final String allergies;
  final String chronicConditions;
  final String pregnancyRiskLevel; // "Low", "Medium", "High"
  final String doctorName;
  final String hospitalName;

  const MedicalEmergencyInfo({
    this.bloodGroup = '',
    this.allergies = '',
    this.chronicConditions = '',
    this.pregnancyRiskLevel = 'Low',
    this.doctorName = '',
    this.hospitalName = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'pregnancyRiskLevel': pregnancyRiskLevel,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
    };
  }

  factory MedicalEmergencyInfo.fromJson(Map<String, dynamic> json) {
    return MedicalEmergencyInfo(
      bloodGroup: json['bloodGroup'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      chronicConditions: json['chronicConditions'] as String? ?? '',
      pregnancyRiskLevel: json['pregnancyRiskLevel'] as String? ?? 'Low',
      doctorName: json['doctorName'] as String? ?? '',
      hospitalName: json['hospitalName'] as String? ?? '',
    );
  }

  MedicalEmergencyInfo copyWith({
    String? bloodGroup,
    String? allergies,
    String? chronicConditions,
    String? pregnancyRiskLevel,
    String? doctorName,
    String? hospitalName,
  }) {
    return MedicalEmergencyInfo(
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      pregnancyRiskLevel: pregnancyRiskLevel ?? this.pregnancyRiskLevel,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }
}
