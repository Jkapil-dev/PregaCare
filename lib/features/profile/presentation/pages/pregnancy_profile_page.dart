import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/responsive_widgets.dart';
import '../../../../core/providers/user_provider.dart';

class PregnancyProfilePage extends StatefulWidget {
  const PregnancyProfilePage({super.key});

  @override
  State<PregnancyProfilePage> createState() => _PregnancyProfilePageState();
}

class _PregnancyProfilePageState extends State<PregnancyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedLmp;
  late TextEditingController _doctorNameController;
  late TextEditingController _hospitalNameController;
  String? _selectedBloodGroup;
  bool _isFirstPregnancy = true;
  int _pregnancyNumber = 1;
  bool _isSaving = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    
    // Parse LMP date if exists
    final lmpStr = userProvider.lmpDateString;
    if (lmpStr.isNotEmpty) {
      _selectedLmp = DateTime.tryParse(lmpStr);
    }

    _doctorNameController = TextEditingController(text: userProvider.doctorName);
    _hospitalNameController = TextEditingController(text: userProvider.hospitalName);
    
    if (_bloodGroups.contains(userProvider.bloodGroup)) {
      _selectedBloodGroup = userProvider.bloodGroup;
    }
    
    _isFirstPregnancy = userProvider.isFirstPregnancy;
    _pregnancyNumber = userProvider.pregnancyNumber;
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _hospitalNameController.dispose();
    super.dispose();
  }

  // Calculate Due Date from LMP (LMP + 280 days)
  DateTime? get _calculatedDueDate {
    if (_selectedLmp == null) return null;
    return _selectedLmp!.add(const Duration(days: 280));
  }

  // Calculate Pregnancy Week
  int get _calculatedWeek {
    if (_selectedLmp == null) return 0;
    final diffDays = DateTime.now().difference(_selectedLmp!).inDays;
    final calcWeek = diffDays ~/ 7;
    return calcWeek >= 0 ? calcWeek : 0;
  }

  // Calculate Trimester
  int get _calculatedTrimester {
    final week = _calculatedWeek;
    if (week <= 13) return 1;
    if (week <= 26) return 2;
    return 3;
  }

  Future<void> _selectLmpDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedLmp ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MaatriColors.coral,
              onPrimary: Colors.white,
              onSurface: MaatriColors.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedLmp) {
      setState(() {
        _selectedLmp = picked;
      });
    }
  }

  Future<void> _savePregnancyProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLmp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your Last Menstrual Period (LMP) date.'),
          backgroundColor: MaatriColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userProvider = context.read<UserProvider>();
      
      final lmpStr = _selectedLmp!.toIso8601String().split('T')[0];
      final dueStr = _calculatedDueDate!.toIso8601String().split('T')[0];

      await userProvider.updateProfile({
        'lmpDate': lmpStr,
        'dueDate': dueStr,
        'pregnancyWeek': _calculatedWeek,
        'trimester': _calculatedTrimester,
        'bloodGroup': _selectedBloodGroup,
        'doctorName': _doctorNameController.text.trim(),
        'hospitalName': _hospitalNameController.text.trim(),
        'isFirstPregnancy': _isFirstPregnancy,
        'pregnancyNumber': _pregnancyNumber,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pregnancy Profile updated successfully!'),
            backgroundColor: MaatriColors.teal,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save pregnancy info: $e'),
            backgroundColor: MaatriColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Pregnancy Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MaatriColors.charcoal,
      ),
      body: SafeArea(
        child: ResponsivePageWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Recalculator Preview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: MaatriColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: MaatriTheme.glowCoral,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregnancy Calculator',
                        style: MaatriTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ResponsiveActionRow(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Week',
                                style: MaatriTypography.labelSmall.copyWith(color: Colors.white.withOpacity(0.8)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLmp != null ? 'Week $_calculatedWeek' : 'Not Set',
                                style: MaatriTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trimester',
                                style: MaatriTypography.labelSmall.copyWith(color: Colors.white.withOpacity(0.8)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLmp != null ? 'Trimester $_calculatedTrimester' : 'Not Set',
                                style: MaatriTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      ResponsiveActionRow(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Due Date:',
                            style: MaatriTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.9)),
                          ),
                          Text(
                            _calculatedDueDate != null ? dateFormat.format(_calculatedDueDate!) : 'Select LMP Below',
                            style: MaatriTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Inputs Group
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregnancy Details',
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),

                      // LMP Date Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_rounded, color: MaatriColors.coral),
                        title: const Text('Last Menstrual Period (LMP)'),
                        subtitle: Text(
                          _selectedLmp != null ? dateFormat.format(_selectedLmp!) : 'Tap to select date',
                          style: MaatriTypography.bodyMedium.copyWith(
                            color: _selectedLmp != null ? MaatriColors.charcoal : MaatriColors.mediumGray,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                        onTap: () => _selectLmpDate(context),
                      ),
                      const Divider(),

                      // Blood Group Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBloodGroup,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group',
                          prefixIcon: Icon(Icons.bloodtype_outlined),
                          border: InputBorder.none,
                        ),
                        items: _bloodGroups.map((bg) {
                          return DropdownMenuItem<String>(
                            value: bg,
                            child: Text(bg),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBloodGroup = val;
                          });
                        },
                      ),
                      const Divider(),

                      // Doctor Name
                      TextFormField(
                        controller: _doctorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Primary Ob-Gyn / Doctor Name',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                          border: InputBorder.none,
                        ),
                      ),
                      const Divider(),

                      // Hospital Name
                      TextFormField(
                        controller: _hospitalNameController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Hospital / Clinic',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // History / Order inputs
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregnancy History',
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      ResponsiveActionRow(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          const Text('First Pregnancy?'),
                          Switch(
                            activeColor: MaatriColors.coral,
                            value: _isFirstPregnancy,
                            onChanged: (val) {
                              setState(() {
                                _isFirstPregnancy = val;
                                if (val) {
                                  _pregnancyNumber = 1;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (!_isFirstPregnancy) ...[
                        const Divider(),
                        ResponsiveActionRow(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            const Text('Pregnancy Number'),
                            DropdownButton<int>(
                              value: _pregnancyNumber,
                              items: List.generate(10, (index) => index + 1).map((n) {
                                return DropdownMenuItem<int>(
                                  value: n,
                                  child: Text('$n'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _pregnancyNumber = val;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaatriColors.coral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MaatriTheme.radiusMd),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isSaving ? null : _savePregnancyProfile,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Pregnancy Profile',
                            style: MaatriTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
