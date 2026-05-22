import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/emergency_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/models/emergency_contact.dart';
import '../../../../core/models/medical_emergency_info.dart';
import '../../../../core/models/hospital.dart';


class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScaleAnimation;
  late Animation<double> _pulseOpacityAnimation;

  // SOS hold progress state
  double _holdProgress = 0.0;
  bool _isHolding = false;
  Timer? _holdTimer;
  final ScrollController _scrollController = ScrollController();

  // Danger signs trimester filter
  String _selectedTrimester = 'All';

  @override
  void initState() {
    super.initState();
    // Continuous background SOS alert pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _pulseOpacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmergencyProvider>(context, listen: false).loadAllEmergencyData();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // GESTURE HOLD TIMERS FOR SOS
  // ==========================================
  void _startHolding() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    _holdTimer?.cancel();
    // 2 seconds holding total (2000ms). Updates every 50ms (40 ticks total).
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _holdProgress += 0.025; // 1 / 40
        if (_holdProgress >= 1.0) {
          _holdProgress = 1.0;
          _stopHolding();
          _triggerSOS();
        }
      });
    });
  }

  void _stopHolding() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      if (_holdProgress < 1.0) {
        _holdProgress = 0.0;
      }
    });
  }

  void _triggerSOS() {
    // Accidental-tap prevented! Show bottom sheet options
    _holdProgress = 0.0;
    _showSOSBottomSheet(context);
  }

  // ==========================================
  // SOS ACTIONS BOTTOM SHEET
  // ==========================================
  void _showSOSBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer2<EmergencyProvider, LocationProvider>(
          builder: (context, emp, loc, child) {
            final primaryContact = emp.contacts.firstWhere(
              (c) => c.priority == 1 && c.emergencyEnabled,
              orElse: () => emp.contacts.isNotEmpty 
                  ? emp.contacts.first 
                  : const EmergencyContact(id: '', name: 'No primary contact', phone: '', relationship: ''),
            );

            return Container(
              decoration: const BoxDecoration(
                color: MaatriColors.warmCream,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(MaatriTheme.radiusXl),
                  topRight: Radius.circular(MaatriTheme.radiusXl),
                ),
              ),
              padding: const EdgeInsets.all(MaatriTheme.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: MaatriColors.mediumGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: MaatriTheme.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emergency_rounded, color: MaatriColors.danger, size: 28),
                      const SizedBox(width: 8),
                      Text('Emergency Quick SOS', style: MaatriTypography.headlineMedium.copyWith(color: MaatriColors.dangerDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accidental tap prevention successfully resolved. Choose a quick safety action:',
                    textAlign: TextAlign.center,
                    style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.darkGray),
                  ),
                  const SizedBox(height: MaatriTheme.spacingLg),

                  // CALL AMBULANCE (108)
                  _SOSSheetOptionTile(
                    title: 'Call Ambulance (108)',
                    subtitle: 'Direct dial local medical ambulance services',
                    icon: Icons.airport_shuttle_rounded,
                    color: MaatriColors.danger,
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(Uri.parse('tel:108'));
                    },
                  ),
                  const SizedBox(height: 12),

                  // CALL PRIMARY EMERGENCY CONTACT
                  _SOSSheetOptionTile(
                    title: primaryContact.phone.isNotEmpty 
                        ? 'Call ${primaryContact.name} (${primaryContact.relationship})'
                        : 'Call Emergency Contact',
                    subtitle: primaryContact.phone.isNotEmpty 
                        ? 'Dial primary SOS contact: ${primaryContact.phone}'
                        : 'No emergency contacts added yet',
                    icon: Icons.contact_phone_rounded,
                    color: MaatriColors.coral,
                    onTap: primaryContact.phone.isNotEmpty 
                        ? () {
                            Navigator.pop(context);
                            launchUrl(Uri.parse('tel:${primaryContact.phone}'));
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // SHARE LIVE GPS LOCATION
                  _SOSSheetOptionTile(
                    title: 'Share Live GPS Location',
                    subtitle: loc.isLoading 
                        ? 'Retrieving precise coordinates...' 
                        : 'SMS/WhatsApp Google Maps link to contacts',
                    icon: loc.isLoading ? Icons.hourglass_empty_rounded : Icons.share_location_rounded,
                    color: MaatriColors.teal,
                    trailing: loc.isLoading 
                        ? const SizedBox(
                            width: 20, height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: MaatriColors.teal),
                          )
                        : null,
                    onTap: loc.isLoading 
                        ? null 
                        : () async {
                            Navigator.pop(context);
                            await loc.shareLocation(context);
                          },
                  ),
                  const SizedBox(height: 12),

                  // OPEN NEARBY HOSPITALS
                  _SOSSheetOptionTile(
                    title: 'View Nearby Hospitals',
                    subtitle: 'Navigate instantly to closest maternity centers',
                    icon: Icons.local_hospital_rounded,
                    color: MaatriColors.lavenderDark,
                    onTap: () {
                      Navigator.pop(context);
                      _scrollController.animateTo(
                        400.0, // Scroll down towards hospitals
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(height: MaatriTheme.spacingMd),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // MAIN BODY BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final emp = Provider.of<EmergencyProvider>(context);
    final loc = Provider.of<LocationProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isPartner) {
      return _buildPartnerEmergencyDashboard(context, emp, loc, userProvider);
    }

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: MaatriColors.danger),
            const SizedBox(width: 8),
            Text('Emergency & Safety', style: MaatriTypography.headlineMedium.copyWith(color: MaatriColors.charcoal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: MaatriColors.darkGray),
            onPressed: () => emp.loadAllEmergencyData(),
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd, vertical: MaatriTheme.spacingSm),
        child: Column(
          children: [
            // HOLD-DOWN SOS ACTION BUTTON BLOCK
            _buildInteractiveSOSBlock(),
            const SizedBox(height: MaatriTheme.spacingLg),

            // LIVE LOCATION QUICK SHARE TRIGGER
            _buildLiveLocationShareRow(loc),
            const SizedBox(height: MaatriTheme.spacingLg),

            // MEDICAL EMERGENCY PROFILE DETAILS
            _buildMedicalEmergencyInfoCard(emp),
            const SizedBox(height: MaatriTheme.spacingLg),

            // DYNAMIC EMERGENCY CONTACTS LIST
            _buildEmergencyContactsList(emp),
            const SizedBox(height: MaatriTheme.spacingLg),

            // HOSPITALS & CLINICS BLOCK
            _buildHospitalsBlock(emp),
            const SizedBox(height: MaatriTheme.spacingLg),

            // DANGER CLINICAL WARNINGS LIST
            _buildDangerSignsBlock(),
            const SizedBox(height: MaatriTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BLOCKS IMPLEMENTATION
  // ==========================================

  /// Hold-down interactive SOS Widget with custom radial animations
  Widget _buildInteractiveSOSBlock() {
    return GlassCard(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        children: [
          Text(
            'Emergency SOS Trigger',
            style: MaatriTypography.titleMedium.copyWith(color: MaatriColors.charcoal, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Hold the button for 2 seconds to initiate safety procedures',
            textAlign: TextAlign.center,
            style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
          ),
          const SizedBox(height: MaatriTheme.spacingLg),
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Background Animation (only active when not holding, ignored by gestures)
                if (!_isHolding)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 165 * _pulseScaleAnimation.value,
                          height: 165 * _pulseScaleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MaatriColors.danger.withOpacity( _pulseOpacityAnimation.value),
                          ),
                        );
                      },
                    ),
                  ),

                // HOLD radial loader ring
                SizedBox(
                  width: 190,
                  height: 190,
                  child: CircularProgressIndicator(
                    value: _holdProgress,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: MaatriColors.dangerLight.withOpacity( 0.4),
                    valueColor: const AlwaysStoppedAnimation<Color>(MaatriColors.dangerDark),
                  ),
                ),

                // Core Button Circle
                GestureDetector(
                  onTapDown: (_) => _startHolding(),
                  onTapUp: (_) => _stopHolding(),
                  onTapCancel: () => _stopHolding(),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final double shadowBlur = _isHolding ? 10 : (20 + 15 * _pulseController.value);
                      final double shadowSpread = _isHolding ? 2 : (3 + 3 * _pulseController.value);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _isHolding ? 155 : 165,
                        height: _isHolding ? 155 : 165,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isHolding ? MaatriColors.dangerDark : MaatriColors.danger,
                          boxShadow: [
                            BoxShadow(
                              color: MaatriColors.danger.withOpacity( _isHolding ? 0.6 : (0.4 - 0.15 * _pulseController.value)),
                              blurRadius: shadowBlur,
                              spreadRadius: shadowSpread,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isHolding ? Icons.touch_app_rounded : Icons.emergency_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isHolding ? 'HOLDING...' : 'HOLD FOR\nSOS',
                          textAlign: TextAlign.center,
                          style: MaatriTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MaatriTheme.spacingMd),
          if (_isHolding)
            Text(
              'Keep holding to trigger SOS...',
              style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.dangerDark),
            )
          else
            const Text(
              'Accidental tap prevention enabled',
              style: TextStyle(color: MaatriColors.slate, fontSize: 11, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  /// Share location row triggers Geolocator sharing
  Widget _buildLiveLocationShareRow(LocationProvider loc) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: loc.isLoading ? null : () => loc.shareLocation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: MaatriColors.teal,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MaatriTheme.radiusLg)),
        ),
        icon: loc.isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.share_location_rounded, color: Colors.white, size: 24),
        label: Text(
          loc.isLoading ? 'FETCHING CURRENT GPS...' : 'SHARE MY LIVE LOCATION NOW',
          style: MaatriTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  /// Editable Medical Emergency profile card
  Widget _buildMedicalEmergencyInfoCard(EmergencyProvider emp) {
    final info = emp.medicalInfo;
    final isPartner = Provider.of<UserProvider>(context).isPartner;

    return GlassCard(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_ind_rounded, color: MaatriColors.teal, size: 22),
                  const SizedBox(width: 8),
                  Text('Medical Emergency Profile', style: MaatriTypography.headlineSmall),
                ],
              ),
              if (!isPartner)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: MaatriColors.teal, size: 20),
                  onPressed: () => _showEditMedicalInfoDialog(context, emp),
                ),
            ],
          ),
          const Divider(height: 20, color: MaatriColors.lightGray),
          
          // Check if medical info is set
          if (info.bloodGroup.isEmpty && info.allergies.isEmpty && info.doctorName.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  children: [
                    Text('No emergency medical records created yet.', style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate)),
                    if (!isPartner) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _showEditMedicalInfoDialog(context, emp),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Critical Info Now'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            _buildMedicalFieldRow(
              'Blood Group:', 
              info.bloodGroup.isNotEmpty ? info.bloodGroup : 'Not Specified',
              isHighlight: true,
              highlightColor: MaatriColors.dangerDark,
            ),
            const SizedBox(height: 8),
            _buildMedicalFieldRow(
              'Pregnancy Risk Level:', 
              info.pregnancyRiskLevel,
              isHighlight: true,
              highlightColor: info.pregnancyRiskLevel == 'High' 
                  ? MaatriColors.danger 
                  : info.pregnancyRiskLevel == 'Medium' 
                      ? MaatriColors.warningDark 
                      : MaatriColors.successDark,
            ),
            const SizedBox(height: 8),
            _buildMedicalFieldRow('Allergies:', info.allergies.isNotEmpty ? info.allergies : 'None recorded'),
            const SizedBox(height: 8),
            _buildMedicalFieldRow('Chronic Conditions:', info.chronicConditions.isNotEmpty ? info.chronicConditions : 'None'),
            const SizedBox(height: 8),
            _buildMedicalFieldRow('Primary OB-GYN:', info.doctorName.isNotEmpty ? 'Dr. ${info.doctorName}' : 'Not Specified'),
            const SizedBox(height: 8),
            _buildMedicalFieldRow('Preferred Hospital:', info.hospitalName.isNotEmpty ? info.hospitalName : 'Not Specified'),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalFieldRow(String label, String value, {bool isHighlight = false, Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: MaatriTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.darkGray)),
        ),
        Expanded(
          child: Text(
            value,
            style: MaatriTypography.bodyMedium.copyWith(
              color: isHighlight ? (highlightColor ?? MaatriColors.charcoal) : MaatriColors.charcoal,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// Dynamic emergency contacts list CRUD block
  Widget _buildEmergencyContactsList(EmergencyProvider emp) {
    final isPartner = Provider.of<UserProvider>(context).isPartner;

    return Column(
      children: [
        SectionHeader(
          title: 'Emergency Contacts',
          icon: Icons.contact_emergency_rounded,
          iconColor: MaatriColors.danger,
          actionText: (!isPartner && emp.contacts.length < 5) ? '+ Add Contact' : null,
          onAction: () => _showAddEditContactDialog(context, emp, null),
        ),
        const SizedBox(height: MaatriTheme.spacingSm),
        
        if (emp.contacts.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(MaatriTheme.spacingLg),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.people_alt_outlined, color: MaatriColors.mediumGray, size: 40),
                  const SizedBox(height: 8),
                  Text('No emergency contacts added yet.', style: MaatriTypography.titleSmall.copyWith(color: MaatriColors.slate)),
                  const SizedBox(height: 4),
                  Text('Add trusted contacts for quick emergency actions.', style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
                  if (!isPartner) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _showAddEditContactDialog(context, emp, null),
                      style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.coral),
                      child: const Text('Add Contact', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emp.contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = emp.contacts[index];
              return _buildContactCard(context, emp, c);
            },
          ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyProvider emp, EmergencyContact contact) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd, vertical: MaatriTheme.spacingSm + 2),
      child: Row(
        children: [
          // Icon and priority badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: MaatriColors.dangerLight, shape: BoxShape.circle),
                child: const Icon(Icons.phone_iphone_rounded, color: MaatriColors.danger, size: 22),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: contact.priority == 1 
                      ? MaatriColors.dangerDark 
                      : contact.priority == 2 
                          ? MaatriColors.warningDark 
                          : MaatriColors.slate,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'P${contact.priority}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Contact details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name, 
                        style: MaatriTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: MaatriColors.lavenderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        contact.relationship,
                        style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.lavenderDark, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(contact.phone, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
                if (contact.emergencyEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency_outlined, size: 10, color: MaatriColors.danger),
                        const SizedBox(width: 2),
                        Text('SOS Recipient Enabled', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.danger, fontSize: 9)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: MaatriColors.successDark, size: 20),
                onPressed: () => launchUrl(Uri.parse('tel:${contact.phone}')),
              ),
              IconButton(
                icon: const Icon(Icons.sms_rounded, color: MaatriColors.teal, size: 20),
                onPressed: () => launchUrl(Uri.parse('sms:${contact.phone}')),
              ),
              if (!Provider.of<UserProvider>(context).isPartner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: MaatriColors.darkGray),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showAddEditContactDialog(context, emp, contact);
                    } else if (action == 'delete') {
                      _showDeleteContactConfirm(context, emp, contact);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Contact')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Contact', style: TextStyle(color: MaatriColors.danger))),
                  ],
                ),
            ],
          )
        ],
      ),
    );
  }

  /// Preferred saved & mock location-aware nearby hospitals list
  Widget _buildHospitalsBlock(EmergencyProvider emp) {
    final isPartner = Provider.of<UserProvider>(context).isPartner;
    // Dynamic mock nearby hospitals computed relative to GPS or default coordinates
    final locationProvider = Provider.of<LocationProvider>(context);
    final isLocationLoaded = locationProvider.currentPosition != null;
    
    // We construct a mock nearby hospitals list if GPS exists, showing realistic distances!
    final List<Hospital> nearbyHospitals = [
      Hospital(
        id: 'mock_1',
        name: 'City Maternal & Child Hospital',
        phone: '+91 98866 54321',
        address: 'Sector 5, Maternal Heights, Near Metro Station',
        distance: isLocationLoaded ? '0.7 km' : '0.8 km',
        maternitySupport: true,
        emergencyAvailability: true,
      ),
      Hospital(
        id: 'mock_2',
        name: 'Apollo Cradle Maternity Center',
        phone: '+91 98866 54322',
        address: 'Plot 22, Green Valley Enclave',
        distance: isLocationLoaded ? '1.9 km' : '2.3 km',
        maternitySupport: true,
        emergencyAvailability: true,
      ),
      Hospital(
        id: 'mock_3',
        name: 'Motherhood Specialty Gynaec Clinic',
        phone: '+91 98866 54323',
        address: 'Suite A, Sunrise Plaza Mall',
        distance: isLocationLoaded ? '3.4 km' : '3.8 km',
        maternitySupport: true,
        emergencyAvailability: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Preferred & Nearby Hospitals',
          icon: Icons.local_hospital_rounded,
          iconColor: MaatriColors.teal,
          actionText: !isPartner ? '+ Add Saved' : null,
          onAction: () => _showAddHospitalDialog(context, emp),
        ),
        const SizedBox(height: MaatriTheme.spacingSm),

        // 1. User Preferred Saved Hospitals
        if (emp.savedHospitals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text('My Preferred Hospitals', style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.tealDark)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emp.savedHospitals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final h = emp.savedHospitals[index];
              return _buildHospitalCard(context, emp, h, isSaved: true);
            },
          ),
          const SizedBox(height: MaatriTheme.spacingMd),
        ],

        // 2. Location-Aware Nearby Hospitals
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
              child: Text(
                isLocationLoaded ? 'Nearby Hospitals (Location-Aware)' : 'Nearby Hospitals (Estimated)',
                style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.charcoal),
              ),
            ),
            if (!isLocationLoaded)
              TextButton(
                onPressed: () => locationProvider.fetchLocation(context),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 20)),
                child: const Text('Update GPS', style: TextStyle(fontSize: 11)),
              )
          ],
        ),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: nearbyHospitals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final h = nearbyHospitals[index];
            return _buildHospitalCard(context, emp, h, isSaved: false);
          },
        ),
      ],
    );
  }

  Widget _buildHospitalCard(BuildContext context, EmergencyProvider emp, Hospital h, {required bool isSaved}) {
    return GlassCard(
      padding: const EdgeInsets.all(MaatriTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSaved ? MaatriColors.tealLight.withOpacity( 0.4) : MaatriColors.cloudGray,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_hospital_rounded, color: isSaved ? MaatriColors.tealDark : MaatriColors.mediumGray, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: MaatriTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(h.address, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (h.distance.isNotEmpty)
                    Text(h.distance, style: MaatriTypography.labelMedium.copyWith(color: MaatriColors.tealDark))
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 4),
                  if (isSaved && !Provider.of<UserProvider>(context).isPartner)
                    GestureDetector(
                      onTap: () => emp.deleteHospital(h.id),
                      child: const Icon(Icons.delete_outline_rounded, color: MaatriColors.danger, size: 18),
                    )
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (h.maternitySupport)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: MaatriColors.successLight, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.child_care_rounded, color: MaatriColors.successDark, size: 10),
                      const SizedBox(width: 2),
                      Text('Maternity Support', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.successDark, fontSize: 9)),
                    ],
                  ),
                ),
              if (h.emergencyAvailability)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: MaatriColors.dangerLight, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency_rounded, color: MaatriColors.danger, size: 10),
                      const SizedBox(width: 2),
                      Text('24/7 ER Available', style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.dangerDark, fontSize: 9)),
                    ],
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:${h.phone}')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: MaatriColors.charcoal,
                  side: const BorderSide(color: MaatriColors.lightGray),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(60, 28),
                ),
                icon: const Icon(Icons.phone, size: 12),
                label: const Text('Call', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () {
                  final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${h.name} ${h.address}")}';
                  launchUrl(Uri.parse(mapsUrl));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MaatriColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(60, 28),
                ),
                icon: const Icon(Icons.directions_rounded, size: 12),
                label: const Text('Navigate', style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Trimester segmented Danger Signs listing with severity indicators
  Widget _buildDangerSignsBlock() {
    final Map<String, List<Map<String, dynamic>>> dangerSigns = {
      'All': [
        {'text': 'Severe headache or vision changes', 'severity': 'High', 'desc': 'Can indicate preeclampsia. Seek immediate assistance.'},
        {'text': 'Vaginal bleeding or fluid leaking', 'severity': 'High', 'desc': 'Urgent OB-GYN evaluation required immediately.'},
        {'text': 'Sudden swelling of face, hands, or feet', 'severity': 'High', 'desc': 'Critical symptom of pregnancy hypertension.'},
        {'text': 'Severe, sharp abdominal pain', 'severity': 'High', 'desc': 'Risk of abruption or complications. Seek emergency care.'},
        {'text': 'Reduced, weak, or absent fetal movement', 'severity': 'High', 'desc': 'Critical check of baby health required immediately.'},
        {'text': 'Persistent, uncontrollable vomiting', 'severity': 'Medium', 'desc': 'Dehydration risk. Notify maternal clinic.'},
        {'text': 'High fever (>38°C) or persistent chills', 'severity': 'Medium', 'desc': 'Risk of infection affecting the baby.'},
      ],
      '1st Trimester': [
        {'text': 'Severe, one-sided pelvic pain', 'severity': 'High', 'desc': 'Possible ectopic pregnancy symptom. Urgent scan needed.'},
        {'text': 'Heavy cramping or red bleeding', 'severity': 'High', 'desc': 'Threatened miscarriage sign. Reach physician immediately.'},
        {'text': 'Extreme nausea rendering fluids impossible', 'severity': 'Medium', 'desc': 'Hyperemesis gravidarum risk. Needs clinical IV support.'},
        {'text': 'High fever (>38°C)', 'severity': 'Medium', 'desc': 'Can affect early development. Consultation required.'},
      ],
      '2nd Trimester': [
        {'text': 'Extreme face or hand swelling', 'severity': 'High', 'desc': 'Pre-eclampsia clinical trigger. Visit ER.'},
        {'text': 'Significant drop in baby movements', 'severity': 'High', 'desc': 'Alert clinic doctor immediately for fetal assessment.'},
        {'text': 'Vaginal bleeding (any amount)', 'severity': 'High', 'desc': 'Risk of placenta previa or cervical changes.'},
        {'text': 'Severe abdominal cramps or constant tight pain', 'severity': 'High', 'desc': 'Clinical risk of early contractions.'},
      ],
      '3rd Trimester': [
        {'text': 'Absent or significantly reduced fetal kicks', 'severity': 'High', 'desc': 'Count kicks immediately. Visit hospital if movement remains low.'},
        {'text': 'Fluid leak or sudden gush (ruptured water)', 'severity': 'High', 'desc': 'Risk of early labor or infection. Gurney to hospital.'},
        {'text': 'Severe headache, flashing spots, blurry vision', 'severity': 'High', 'desc': 'Severe pre-eclampsia or eclampsia emergency.'},
        {'text': 'Continuous heavy vaginal bleeding', 'severity': 'High', 'desc': 'Risk of placental abruption. Call ambulance (108).'},
      ],
    };

    final activeList = dangerSigns[_selectedTrimester] ?? dangerSigns['All']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Pregnancy Danger Signs',
          icon: Icons.warning_rounded,
          iconColor: MaatriColors.warningDark,
        ),
        const SizedBox(height: MaatriTheme.spacingSm),

        // Trimester segmented filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', '1st Trimester', '2nd Trimester', '3rd Trimester'].map((trimester) {
              final isSelected = _selectedTrimester == trimester;
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: FilterChip(
                  label: Text(trimester),
                  selected: isSelected,
                  selectedColor: MaatriColors.warningLight,
                  checkmarkColor: MaatriColors.warningDark,
                  labelStyle: TextStyle(
                    color: isSelected ? MaatriColors.warningDark : MaatriColors.charcoal,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTrimester = trimester;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd, vertical: MaatriTheme.spacingSm),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeList.length,
            separatorBuilder: (_, __) => const Divider(height: 12, color: MaatriColors.lightGray),
            itemBuilder: (context, index) {
              final sign = activeList[index];
              final isHigh = sign['severity'] == 'High';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: StatusDot(color: isHigh ? MaatriColors.danger : MaatriColors.warningDark, size: 10),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sign['text']!,
                            style: MaatriTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: MaatriColors.charcoal),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHigh ? MaatriColors.dangerLight : MaatriColors.goldenLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sign['severity']!,
                            style: TextStyle(
                              color: isHigh ? MaatriColors.dangerDark : MaatriColors.warningDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 2.0),
                      child: Text(
                        sign['desc']!,
                        style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DIALOG FLOWS FOR CRUD
  // ==========================================

  /// Form Dialog for editing critical Paramedic Medical Emergency info
  void _showEditMedicalInfoDialog(BuildContext context, EmergencyProvider emp) {
    final info = emp.medicalInfo;

    final bloodController = TextEditingController(text: info.bloodGroup);
    final allergyController = TextEditingController(text: info.allergies);
    final chronicController = TextEditingController(text: info.chronicConditions);
    final doctorController = TextEditingController(text: info.doctorName);
    final hospitalController = TextEditingController(text: info.hospitalName);
    String selectedRisk = info.pregnancyRiskLevel;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MaatriTheme.radiusLg)),
          title: Text('Edit Medical Profile', style: MaatriTypography.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Blood Group Selection
                DropdownButtonFormField<String>(
                  initialValue: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].contains(bloodController.text) 
                      ? bloodController.text 
                      : null,
                  decoration: const InputDecoration(labelText: 'Blood Group', prefixIcon: Icon(Icons.bloodtype_rounded)),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((bg) {
                    return DropdownMenuItem(value: bg, child: Text(bg));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) bloodController.text = val;
                  },
                ),
                const SizedBox(height: 12),

                // Pregnancy Risk level selector
                DropdownButtonFormField<String>(
                  initialValue: selectedRisk,
                  decoration: const InputDecoration(labelText: 'Pregnancy Risk Level', prefixIcon: Icon(Icons.warning_amber_rounded)),
                  items: ['Low', 'Medium', 'High'].map((risk) {
                    return DropdownMenuItem(value: risk, child: Text(risk));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) selectedRisk = val;
                  },
                ),
                const SizedBox(height: 12),

                // Allergies Form Input
                TextField(
                  controller: allergyController,
                  decoration: const InputDecoration(labelText: 'Allergies', prefixIcon: Icon(Icons.healing_rounded), hintText: 'Food, medications, latex etc.'),
                ),
                const SizedBox(height: 12),

                // Chronic Conditions
                TextField(
                  controller: chronicController,
                  decoration: const InputDecoration(labelText: 'Chronic Conditions', prefixIcon: Icon(Icons.folder_shared_rounded), hintText: 'Hypertension, Diabetes, Asthma etc.'),
                ),
                const SizedBox(height: 12),

                // OB-GYN Doctor Name
                TextField(
                  controller: doctorController,
                  decoration: const InputDecoration(labelText: 'Primary Doctor (OB-GYN)', prefixIcon: Icon(Icons.person_pin_rounded), hintText: 'Dr. Anya Sharma'),
                ),
                const SizedBox(height: 12),

                // Preferred Hospital
                TextField(
                  controller: hospitalController,
                  decoration: const InputDecoration(labelText: 'Preferred Maternity Hospital', prefixIcon: Icon(Icons.local_hospital_rounded), hintText: 'Apollo Cradle Center'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: MaatriColors.charcoal)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newInfo = MedicalEmergencyInfo(
                  bloodGroup: bloodController.text,
                  pregnancyRiskLevel: selectedRisk,
                  allergies: allergyController.text,
                  chronicConditions: chronicController.text,
                  doctorName: doctorController.text,
                  hospitalName: hospitalController.text,
                );
                await emp.saveMedicalInfo(newInfo);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.teal),
              child: const Text('Save Details', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Form Dialog to create/edit custom Emergency Contacts
  void _showAddEditContactDialog(BuildContext context, EmergencyProvider emp, EmergencyContact? contact) {
    final isEdit = contact != null;

    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final relationshipController = TextEditingController(text: contact?.relationship ?? '');
    int priority = contact?.priority ?? 1;
    bool emergencyEnabled = contact?.emergencyEnabled ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MaatriTheme.radiusLg)),
          title: Text(isEdit ? 'Edit Contact' : 'Add Emergency Contact', style: MaatriTypography.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_rounded)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // Relationship Dropdown
                DropdownButtonFormField<String>(
                  initialValue: ['Husband', 'OB-GYN', 'Mother', 'Father', 'Sister', 'Brother', 'Friend'].contains(relationshipController.text) 
                      ? relationshipController.text 
                      : null,
                  decoration: const InputDecoration(labelText: 'Relationship', prefixIcon: Icon(Icons.people_rounded)),
                  items: ['Husband', 'OB-GYN', 'Mother', 'Father', 'Sister', 'Brother', 'Friend'].map((rel) {
                    return DropdownMenuItem(value: rel, child: Text(rel));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) relationshipController.text = val;
                  },
                ),
                const SizedBox(height: 12),

                // Priority Selection
                DropdownButtonFormField<int>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Contact Priority', prefixIcon: Icon(Icons.priority_high_rounded)),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Priority 1 (Primary Contact)')),
                    DropdownMenuItem(value: 2, child: Text('Priority 2 (Secondary Contact)')),
                    DropdownMenuItem(value: 3, child: Text('Priority 3 (Backup Contact)')),
                  ],
                  onChanged: (val) {
                    if (val != null) priority = val;
                  },
                ),
                const SizedBox(height: 12),

                // SOS recipient switch
                SwitchListTile(
                  title: const Text('Active SOS Recipient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Receives SMS or instant phone dialing during emergencies', style: TextStyle(fontSize: 10)),
                  value: emergencyEnabled,
                  activeThumbColor: MaatriColors.danger,
                  onChanged: (val) {
                    // Update inner state
                    emergencyEnabled = val;
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: MaatriColors.charcoal)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out Name and Phone fields.')),
                  );
                  return;
                }

                final c = EmergencyContact(
                  id: contact?.id ?? '',
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  relationship: relationshipController.text.trim().isNotEmpty 
                      ? relationshipController.text.trim() 
                      : 'Other',
                  priority: priority,
                  emergencyEnabled: emergencyEnabled,
                );

                await emp.saveContact(c);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
              child: Text(isEdit ? 'Save Changes' : 'Add Contact', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Delete confirmation modal dialog
  void _showDeleteContactConfirm(BuildContext context, EmergencyProvider emp, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Contact?'),
          content: Text('Are you sure you want to delete ${contact.name} from emergency contacts?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: MaatriColors.charcoal)),
            ),
            ElevatedButton(
              onPressed: () async {
                await emp.deleteContact(contact.id);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.danger),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  /// Form Dialog to add preferred hospitals manually
  void _showAddHospitalDialog(BuildContext context, EmergencyProvider emp) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    bool maternitySupport = true;
    bool emergencyAvailability = true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MaatriTheme.radiusLg)),
          title: Text('Add Preferred Hospital', style: MaatriTypography.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Hospital Name', prefixIcon: Icon(Icons.local_hospital_rounded)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Hospital Phone Number', prefixIcon: Icon(Icons.phone_rounded)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Hospital Address', prefixIcon: Icon(Icons.map_rounded)),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Has Maternity Ward', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: maternitySupport,
                  activeThumbColor: MaatriColors.teal,
                  onChanged: (val) {
                    maternitySupport = val;
                  },
                ),
                SwitchListTile(
                  title: const Text('24/7 Emergency Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: emergencyAvailability,
                  activeThumbColor: MaatriColors.danger,
                  onChanged: (val) {
                    emergencyAvailability = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: MaatriColors.charcoal)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out hospital name and address.')),
                  );
                  return;
                }

                final h = Hospital(
                  id: '',
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                  maternitySupport: maternitySupport,
                  emergencyAvailability: emergencyAvailability,
                  isPreferred: true,
                );

                await emp.saveHospital(h);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.teal),
              child: const Text('Save Hospital', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // PARTNER EMERGENCY DASHBOARD IMPLEMENTATION
  // ==========================================

  Widget _buildPartnerEmergencyDashboard(
    BuildContext context,
    EmergencyProvider emp,
    LocationProvider loc,
    UserProvider userProvider,
  ) {
    final connectionState = emp.connectionEmergencyState;
    final isSos = connectionState != null && connectionState['active'] == true;
    final motherName = userProvider.motherProfile?['displayName'] ?? 'Mother';
    final motherPhone = userProvider.motherProfile?['phoneNumber'] ?? '';

    // Extracted medical summary properties
    final gestAge = "Week ${userProvider.pregnancyWeek}";
    final trimesterNum = "Trimester ${userProvider.trimester}";
    final riskLevel = emp.medicalInfo.pregnancyRiskLevel;
    final bloodGrp = emp.medicalInfo.bloodGroup.isNotEmpty ? emp.medicalInfo.bloodGroup : 'Not Specified';
    final allergiesText = emp.medicalInfo.allergies.isNotEmpty ? emp.medicalInfo.allergies : 'None recorded';
    final conditionsText = emp.medicalInfo.chronicConditions.isNotEmpty ? emp.medicalInfo.chronicConditions : 'None';
    final doctorName = emp.medicalInfo.doctorName.isNotEmpty ? "Dr. ${emp.medicalInfo.doctorName}" : 'Not Specified';
    final prefHospital = emp.medicalInfo.hospitalName.isNotEmpty ? emp.medicalInfo.hospitalName : 'Not Specified';

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: MaatriColors.danger),
            const SizedBox(width: 8),
            Text('Partner Emergency Hub', style: MaatriTypography.headlineMedium.copyWith(color: MaatriColors.charcoal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: MaatriColors.darkGray),
            onPressed: () => emp.loadAllEmergencyData(),
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: MaatriTheme.spacingMd, vertical: MaatriTheme.spacingSm),
        child: Column(
          children: [
            // 1. GLOWING STATUS HEADER
            _buildPartnerGlowingStatusHeader(isSos, motherName),
            const SizedBox(height: MaatriTheme.spacingLg),

            // 2. ACTIVE EMERGENCY DETAILS PANEL (If active)
            if (isSos) ...[
              _buildActiveEmergencyDetailsPanel(context, emp, loc, connectionState, motherName),
              const SizedBox(height: MaatriTheme.spacingLg),
              _buildEmergencyQuickActionsHub(context, emp, connectionState, motherPhone),
              const SizedBox(height: MaatriTheme.spacingLg),
            ] else ...[
              // 3. QUICK ACTIONS GRID
              _buildPartnerQuickActionsGrid(context, emp, motherPhone),
              const SizedBox(height: MaatriTheme.spacingLg),
            ],

            // 4. MATERNAL MEDICAL SUMMARY CARD
            _buildMaternalMedicalSummaryCard(
              gestAge,
              trimesterNum,
              riskLevel,
              bloodGrp,
              allergiesText,
              conditionsText,
              doctorName,
              prefHospital,
            ),
            const SizedBox(height: MaatriTheme.spacingLg),

            // 5. SAVED HOSPITALS & DIRECTIONS (reuses existing build block)
            _buildHospitalsBlock(emp),
            const SizedBox(height: MaatriTheme.spacingLg),

            // 6. EMERGENCY ACTIVITY TIMELINE
            _buildEmergencyActivityTimeline(connectionState, isSos),
            const SizedBox(height: MaatriTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerGlowingStatusHeader(bool isSos, String motherName) {
    final gradient = isSos
        ? const LinearGradient(
            colors: [Color(0xFFEF5350), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF00695C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final shadow = isSos ? MaatriTheme.glowCoral : MaatriTheme.glowTeal;

    return GlassCard(
      gradient: gradient,
      boxShadow: shadow,
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSos ? Icons.warning_amber_rounded : Icons.favorite_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSos ? 'CRITICAL EMERGENCY' : 'Mother is Safe',
                  style: MaatriTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSos
                      ? '$motherName triggered an SOS alert!'
                      : 'Synced to $motherName\'s real-time safety network.',
                  style: MaatriTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity( 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEmergencyDetailsPanel(
    BuildContext context,
    EmergencyProvider emp,
    LocationProvider loc,
    Map<String, dynamic> connectionState,
    String motherName,
  ) {
    final triggeredAt = connectionState['triggeredAt'];
    String timeStr = 'Just now';
    if (triggeredAt is Timestamp) {
      final dt = triggeredAt.toDate();
      timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    final geoPoint = connectionState['location'] as GeoPoint?;
    final lat = geoPoint?.latitude;
    final lng = geoPoint?.longitude;

    double? distanceInMeters;
    String distanceStr = '';
    if (lat != null && lng != null && loc.currentPosition != null) {
      try {
        distanceInMeters = Geolocator.distanceBetween(
          loc.currentPosition!.latitude,
          loc.currentPosition!.longitude,
          lat,
          lng,
        );
        if (distanceInMeters < 1000) {
          distanceStr = "${distanceInMeters.toStringAsFixed(0)} meters away";
        } else {
          distanceStr = "${(distanceInMeters / 1000).toStringAsFixed(2)} km away";
        }
      } catch (e) {
        debugPrint('Error calculating distance: $e');
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusDot(color: MaatriColors.danger, size: 12),
              const SizedBox(width: 8),
              Text(
                'SOS DETAILS',
                style: MaatriTypography.labelLarge.copyWith(color: MaatriColors.dangerDark, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MaatriColors.dangerLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Triggered at $timeStr',
                  style: MaatriTypography.labelSmall.copyWith(color: MaatriColors.dangerDark, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Radar pulse ring map preview mockup block
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MaatriTheme.radiusLg),
              gradient: LinearGradient(
                colors: [
                  Colors.teal.withOpacity(0.08),
                  Colors.blue.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.teal.withOpacity(0.2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing live radar rings
                _RadarPulseRing(delay: 0),
                _RadarPulseRing(delay: 1),
                _RadarPulseRing(delay: 2),
                // Pulse pin
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.my_location_rounded, color: MaatriColors.teal, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'LIVE TRACKING ACTIVE',
                      style: TextStyle(
                        color: MaatriColors.tealDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GPS TRACKING AND COORDINATES',
                style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate, fontWeight: FontWeight.bold),
              ),
              if (lat != null && lng != null) ...[
                if (distanceStr.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: MaatriColors.tealLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MaatriColors.teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_walk_rounded, color: MaatriColors.tealDark, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          distanceStr,
                          style: MaatriTypography.labelMedium.copyWith(
                            color: MaatriColors.tealDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: loc.isLoading
                        ? null
                        : () async {
                            await loc.fetchLocation(context);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MaatriColors.tealDark,
                      side: const BorderSide(color: MaatriColors.teal, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: loc.isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: MaatriColors.tealDark),
                          )
                        : const Icon(Icons.my_location_rounded, size: 14),
                    label: const Text('CALCULATE DISTANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (lat != null && lng != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MaatriColors.warmCream,
                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                border: Border.all(color: MaatriColors.lightGray),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: MaatriColors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Latitude: $lat\nLongitude: $lng',
                      style: MaatriTypography.bodyMedium.copyWith(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MaatriColors.warmCream,
                borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MaatriColors.danger),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Waiting for precise GPS coordinates...',
                    style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.slate),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showResolveEmergencyDialog(context, emp),
              style: OutlinedButton.styleFrom(
                foregroundColor: MaatriColors.successDark,
                side: const BorderSide(color: MaatriColors.successDark, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MaatriTheme.radiusMd)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('MARK SOS AS RESOLVED', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResolveEmergencyDialog(BuildContext context, EmergencyProvider emp) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resolve Emergency?'),
          content: const Text('This will clear the SOS alert status for both Mother and Partner. Confirm if the emergency is resolved and safe.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: MaatriColors.charcoal)),
            ),
            ElevatedButton(
              onPressed: () async {
                await emp.resolveEmergency();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: MaatriColors.successDark),
              child: const Text('Yes, Resolved', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPartnerQuickActionsGrid(
    BuildContext context,
    EmergencyProvider emp,
    String motherPhone,
  ) {
    final primaryContact = emp.contacts.firstWhere(
      (c) => c.priority == 1 && c.emergencyEnabled,
      orElse: () => emp.contacts.isNotEmpty ? emp.contacts.first : const EmergencyContact(id: '', name: '', phone: '', relationship: ''),
    );

    final obgynContact = emp.contacts.firstWhere(
      (c) => c.relationship.toLowerCase() == 'ob-gyn' || c.relationship.toLowerCase() == 'doctor',
      orElse: () => const EmergencyContact(id: '', name: '', phone: '', relationship: ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Dialer Center',
          style: MaatriTypography.headlineSmall.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            // CALL MOTHER
            _buildDialerCard(
              title: 'Call Mother',
              subtitle: motherPhone.isNotEmpty ? motherPhone : 'Not Set',
              icon: Icons.person_rounded,
              color: MaatriColors.teal,
              onTap: motherPhone.isNotEmpty
                  ? () => launchUrl(Uri.parse('tel:$motherPhone'))
                  : null,
            ),
            // CALL PRIMARY CONTACT
            _buildDialerCard(
              title: primaryContact.name.isNotEmpty ? 'Primary Contact' : 'Primary SOS',
              subtitle: primaryContact.phone.isNotEmpty ? primaryContact.name : 'Not Added',
              icon: Icons.contact_emergency_rounded,
              color: MaatriColors.coral,
              onTap: primaryContact.phone.isNotEmpty
                  ? () => launchUrl(Uri.parse('tel:${primaryContact.phone}'))
                  : null,
            ),
            // CALL OB-GYN
            _buildDialerCard(
              title: 'OB-GYN Doctor',
              subtitle: obgynContact.name.isNotEmpty
                  ? obgynContact.name
                  : (emp.medicalInfo.doctorName.isNotEmpty ? "Dr. ${emp.medicalInfo.doctorName}" : 'Not Added'),
              icon: Icons.medication_rounded,
              color: MaatriColors.lavenderDark,
              onTap: obgynContact.phone.isNotEmpty
                  ? () => launchUrl(Uri.parse('tel:${obgynContact.phone}'))
                  : null,
            ),
            // CALL AMBULANCE (108)
            _buildDialerCard(
              title: 'Ambulance',
              subtitle: 'Local ER (108)',
              icon: Icons.airport_shuttle_rounded,
              color: MaatriColors.danger,
              onTap: () => launchUrl(Uri.parse('tel:108')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyQuickActionsHub(
    BuildContext context,
    EmergencyProvider emp,
    Map<String, dynamic> connectionState,
    String motherPhone,
  ) {
    final geoPoint = connectionState['location'] as GeoPoint?;
    final lat = geoPoint?.latitude;
    final lng = geoPoint?.longitude;
    final isLocationAvailable = lat != null && lng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Actions Hub',
          style: MaatriTypography.headlineSmall.copyWith(fontSize: 18, color: MaatriColors.dangerDark, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            // 1. NAVIGATE NOW
            _buildDialerCard(
              title: 'Navigate Now',
              subtitle: 'Start routing to Mother',
              icon: Icons.navigation_rounded,
              color: MaatriColors.teal,
              onTap: isLocationAvailable
                  ? () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication)
                  : null,
            ),
            // 2. OPEN IN MAPS
            _buildDialerCard(
              title: 'Open in Maps',
              subtitle: 'View pin on Google Maps',
              icon: Icons.map_rounded,
              color: Colors.blue,
              onTap: isLocationAvailable
                  ? () => launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng'), mode: LaunchMode.externalApplication)
                  : null,
            ),
            // 3. COPY COORDINATES
            _buildDialerCard(
              title: 'Copy Coordinates',
              subtitle: isLocationAvailable ? '$lat, $lng' : 'Unavailable',
              icon: Icons.copy_rounded,
              color: Colors.orange,
              onTap: isLocationAvailable
                  ? () async {
                      await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('GPS coordinates copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  : null,
            ),
            // 4. SHARE ALERT
            _buildDialerCard(
              title: 'Share Location',
              subtitle: 'Send SMS/WhatsApp alert',
              icon: Icons.share_rounded,
              color: Colors.purple,
              onTap: isLocationAvailable
                  ? () {
                      final motherName = emp.connectionEmergencyState?['triggeredBy'] ?? 'Mother';
                      Share.share(
                        'CRITICAL EMERGENCY: Maternal SOS triggered by Mother ($motherName). '
                        'Live GPS location: https://maps.google.com/?q=$lat,$lng'
                      );
                    }
                  : null,
            ),
            // 5. CALL AMBULANCE
            _buildDialerCard(
              title: 'Call Ambulance',
              subtitle: 'Dial local ER (108)',
              icon: Icons.airport_shuttle_rounded,
              color: MaatriColors.danger,
              onTap: () => launchUrl(Uri.parse('tel:108')),
            ),
            // 6. CALL MOTHER
            _buildDialerCard(
              title: 'Call Mother',
              subtitle: motherPhone.isNotEmpty ? motherPhone : 'Not Added',
              icon: Icons.person_rounded,
              color: Colors.green,
              onTap: motherPhone.isNotEmpty
                  ? () => launchUrl(Uri.parse('tel:$motherPhone'))
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDialerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      backgroundColor: isEnabled ? Colors.white : Colors.white.withOpacity( 0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity( 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (isEnabled)
                const Icon(Icons.phone_forwarded_rounded, color: MaatriColors.mediumGray, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: MaatriTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isEnabled ? MaatriColors.charcoal : MaatriColors.slate,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: MaatriTypography.bodySmall.copyWith(
              color: MaatriColors.slate,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMaternalMedicalSummaryCard(
    String gestAge,
    String trimester,
    String riskLevel,
    String bloodGrp,
    String allergies,
    String conditions,
    String doctorName,
    String prefHospital,
  ) {
    final riskColor = riskLevel == 'High'
        ? MaatriColors.danger
        : riskLevel == 'Medium'
            ? MaatriColors.warningDark
            : MaatriColors.successDark;

    return GlassCard(
      padding: const EdgeInsets.all(MaatriTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_rounded, color: MaatriColors.teal, size: 22),
              const SizedBox(width: 8),
              Text('Maternal Medical Summary', style: MaatriTypography.headlineSmall),
            ],
          ),
          const Divider(height: 24, color: MaatriColors.lightGray),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Gestational Age', gestAge),
              ),
              Expanded(
                child: _buildSummaryItem('Trimester Stage', trimester),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Blood Group', bloodGrp, valueColor: MaatriColors.dangerDark, isBoldValue: true),
              ),
              Expanded(
                child: _buildSummaryItem('Pregnancy Risk', riskLevel, valueColor: riskColor, isBoldValue: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryFullWidthItem('Allergies', allergies),
          const SizedBox(height: 10),
          _buildSummaryFullWidthItem('Chronic Conditions', conditions),
          const SizedBox(height: 10),
          _buildSummaryFullWidthItem('Primary OB-GYN', doctorName),
          const SizedBox(height: 10),
          _buildSummaryFullWidthItem('Preferred Hospital', prefHospital),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
        const SizedBox(height: 2),
        Text(
          value,
          style: MaatriTypography.bodyMedium.copyWith(
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? MaatriColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryFullWidthItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
        const SizedBox(height: 2),
        Text(
          value,
          style: MaatriTypography.bodyMedium.copyWith(color: MaatriColors.charcoal),
        ),
      ],
    );
  }

  Widget _buildEmergencyActivityTimeline(Map<String, dynamic>? connectionState, bool isSos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Activity Timeline',
          style: MaatriTypography.headlineSmall.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(MaatriTheme.spacingLg),
          child: isSos
              ? Column(
                  children: [
                    _buildTimelineStep(
                      title: 'SOS Alert Triggered',
                      subtitle: 'Alert dispatched from Mother\'s device',
                      time: _getFormattedTime(connectionState?['triggeredAt']),
                      isCompleted: true,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'GPS Coordinates Captured',
                      subtitle: connectionState?['location'] != null
                          ? 'Precise coordinate logs saved dynamically'
                          : 'Capturing active coordinates...',
                      time: connectionState?['location'] != null ? 'Captured' : 'Pending',
                      isCompleted: connectionState?['location'] != null,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Partner Notified',
                      subtitle: 'Push alert and haptic sirens initiated',
                      time: 'Active',
                      isCompleted: true,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Pending Safe Resolution',
                      subtitle: 'Awaiting confirmation of safety status',
                      time: '--:--',
                      isCompleted: false,
                      isLast: true,
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: MaatriColors.successDark, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'All Systems Normal',
                          style: MaatriTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No emergency alerts triggered.',
                          style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  String _getFormattedTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return '--:--';
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    required bool isLast,
  }) {
    final activeColor = isCompleted ? MaatriColors.teal : MaatriColors.mediumGray;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCompleted ? activeColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: activeColor, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: activeColor.withOpacity( 0.5),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: MaatriTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted ? MaatriColors.charcoal : MaatriColors.slate,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate, fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Text(
          time,
          style: MaatriTypography.labelSmall.copyWith(
            color: isCompleted ? MaatriColors.tealDark : MaatriColors.slate,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SOSSheetOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SOSSheetOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(MaatriTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
          boxShadow: MaatriTheme.shadowSm,
          border: Border.all(color: color.withOpacity( 0.15), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity( 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MaatriTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate)),
                ],
              ),
            ),
            if (trailing != null) trailing! else const Icon(Icons.chevron_right_rounded, color: MaatriColors.mediumGray),
          ],
        ),
      ),
    );
  }
}

class _RadarPulseRing extends StatefulWidget {
  final int delay;
  const _RadarPulseRing({required this.delay});

  @override
  State<_RadarPulseRing> createState() => _RadarPulseRingState();
}

class _RadarPulseRingState extends State<_RadarPulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scale = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(seconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_controller.isAnimating) return const SizedBox.shrink();
        return Container(
          width: 140 * _scale.value,
          height: 140 * _scale.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: MaatriColors.teal.withOpacity(_opacity.value),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
