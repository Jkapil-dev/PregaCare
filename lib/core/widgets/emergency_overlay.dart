import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/emergency_provider.dart';
import '../providers/location_provider.dart';

class EmergencyOverlay extends StatefulWidget {
  const EmergencyOverlay({super.key});

  @override
  State<EmergencyOverlay> createState() => _EmergencyOverlayState();
}

class _EmergencyOverlayState extends State<EmergencyOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    
    // Only display if SOS is triggered
    if (!emergencyProvider.isSosTriggered) {
      return const SizedBox.shrink();
    }

    final medicalInfo = emergencyProvider.medicalInfo;
    final primaryContact = emergencyProvider.contacts.isNotEmpty 
        ? emergencyProvider.contacts.first 
        : null;

    final currentPos = locationProvider.currentPosition;
    final isLocationLoading = locationProvider.isLoading;

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            // Flash color overlay: red/pink flashing border and glow
            final flashVal = _flashController.value;
            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3 + 0.7 * flashVal),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2 * flashVal),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      const Color(0xFF1E1E24), 
                      const Color(0xFF3A0D10), 
                      flashVal
                    )!,
                    const Color(0xFF1E1E24),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              // 1. Header (Flashing Hazard Pattern & Active Banner)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                color: Colors.red[900]?.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CRITICAL EMERGENCY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'SOS ALARM ACTIVE',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // GPS Coordinates Card
                      _buildSectionCard(
                        title: 'LIVE GPS LOCATION',
                        icon: Icons.my_location_rounded,
                        accentColor: Colors.blueAccent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isLocationLoading) ...[
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Fetching latest high-accuracy GPS...',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ] else if (currentPos != null) ...[
                              Text(
                                'Latitude: ${currentPos.latitude.toStringAsFixed(6)}\nLongitude: ${currentPos.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final mapsUrl = 'https://maps.google.com/?q=${currentPos.latitude},${currentPos.longitude}';
                                  final uri = Uri.parse(mapsUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[900],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.map_rounded),
                                label: const Text('VIEW ON GOOGLE MAPS'),
                              ),
                            ] else ...[
                              const Text(
                                'GPS location not cached yet.',
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => locationProvider.fetchLocation(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blueAccent,
                                  side: const BorderSide(color: Colors.blueAccent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('RE-FETCH LOCATION'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Speed Dial Contacts
                      _buildSectionCard(
                        title: 'SPEED DIAL ACTIONS',
                        icon: Icons.phone_forwarded_rounded,
                        accentColor: Colors.greenAccent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Ambulance Call
                            _buildCallButton(
                              label: 'Call Ambulance (108)',
                              subtitle: 'National emergency services',
                              phone: '108',
                              color: Colors.redAccent,
                              icon: Icons.local_hospital_rounded,
                            ),
                            const SizedBox(height: 10),
                            
                            // Primary Contact Call
                            if (primaryContact != null) ...[
                              _buildCallButton(
                                label: 'Call Primary: ${primaryContact.name}',
                                subtitle: 'Relationship: ${primaryContact.relationship}',
                                phone: primaryContact.phone,
                                color: Colors.green[700]!,
                                icon: Icons.person_rounded,
                              ),
                              const SizedBox(height: 10),
                            ],
                            
                            // Doctor Info / Call
                            if (medicalInfo.doctorName.isNotEmpty) ...[
                              _buildCallButton(
                                label: 'Call OB-GYN: ${medicalInfo.doctorName}',
                                subtitle: 'Preferred doctor',
                                phone: primaryContact != null ? primaryContact.phone : '108',
                                color: Colors.teal[700]!,
                                icon: Icons.medical_services_rounded,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Crucial Paramedic Medical Card
                      _buildSectionCard(
                        title: 'PARAMEDIC MEDICAL CARD',
                        icon: Icons.assignment_ind_rounded,
                        accentColor: Colors.orangeAccent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMedicalInfoRow('BLOOD GROUP', medicalInfo.bloodGroup.isNotEmpty ? medicalInfo.bloodGroup : 'Unknown', isCritical: true),
                            _buildMedicalInfoRow('PREGNANCY RISK', medicalInfo.pregnancyRiskLevel, isCritical: medicalInfo.pregnancyRiskLevel == 'High'),
                            _buildMedicalInfoRow('ALLERGIES', medicalInfo.allergies.isNotEmpty ? medicalInfo.allergies : 'None Reported'),
                            _buildMedicalInfoRow('CHRONIC CONDITIONS', medicalInfo.chronicConditions.isNotEmpty ? medicalInfo.chronicConditions : 'None Reported'),
                            _buildMedicalInfoRow('PREFERRED HOSPITAL', medicalInfo.hospitalName.isNotEmpty ? medicalInfo.hospitalName : 'Not Specified'),
                            _buildMedicalInfoRow('OB-GYN DOCTOR', medicalInfo.doctorName.isNotEmpty ? medicalInfo.doctorName : 'Not Specified'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 4. Cancel / Dismiss Alarm Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Reset SOS Alert State
                    emergencyProvider.cancelSOSAlert();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.cancel_rounded, size: 24),
                  label: const Text(
                    'DISMISS & CANCEL ALARM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required String label,
    required String subtitle,
    required String phone,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _makeCall(phone),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalInfoRow(String label, String value, {bool isCritical = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isCritical ? Colors.redAccent : Colors.white,
                fontSize: 13,
                fontWeight: isCritical ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
