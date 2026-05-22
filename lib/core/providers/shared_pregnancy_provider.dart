import 'package:flutter/material.dart';
import 'user_provider.dart';

class SharedPregnancyProvider extends ChangeNotifier {
  UserProvider? _userProvider;

  void update(UserProvider userProvider) {
    _userProvider = userProvider;
    notifyListeners();
  }

  // Proxy getters
  bool get hasAppointmentsPermission => _userProvider?.hasAppointmentsPermission ?? false;
  bool get hasMedicinesPermission => _userProvider?.hasMedicinesPermission ?? false;
  bool get hasRemindersPermission => _userProvider?.hasRemindersPermission ?? false;
  bool get hasBabyUpdatesPermission => _userProvider?.hasBabyUpdatesPermission ?? false;
  bool get hasEmergencyAlertsPermission => _userProvider?.hasEmergencyAlertsPermission ?? false;

  // Pregnancy Progress
  int get pregnancyWeek => _userProvider?.pregnancyWeek ?? 0;
  int get trimester => _userProvider?.trimester ?? 1;
  String get dueDateString => _userProvider?.dueDateString ?? '';
  double get progress => _userProvider?.progress ?? 0.0;

  // Baby development
  String get babySize => _userProvider?.babySize ?? '';
  Map<String, String>? get weeklyDevelopmentStats => _userProvider?.weeklyDevelopmentStats;

  // Healthcare Summaries / Emergency
  String get bloodGroup => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.bloodGroup ?? '') : '';
  String get doctorName => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.doctorName ?? '') : '';
  String get hospitalName => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.hospitalName ?? '') : '';
  String get emergencyContactName => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.emergencyContactName ?? '') : '';
  String get emergencyContactPhone => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.emergencyContactPhone ?? '') : '';
  List<String> get allergies => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.allergies ?? []) : [];
  List<String> get conditions => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.conditions ?? []) : [];
  String get healthNotes => (_userProvider?.hasEmergencyAlertsPermission ?? false) ? (_userProvider?.healthNotes ?? '') : '';
}
