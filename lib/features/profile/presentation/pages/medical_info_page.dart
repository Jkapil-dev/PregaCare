import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/user_provider.dart';

class MedicalInfoPage extends StatefulWidget {
  const MedicalInfoPage({super.key});

  @override
  State<MedicalInfoPage> createState() => _MedicalInfoPageState();
}

class _MedicalInfoPageState extends State<MedicalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late List<String> _allergies;
  late List<String> _conditions;
  late TextEditingController _allergyInputController;
  late TextEditingController _conditionInputController;
  late TextEditingController _medicationsController;
  late TextEditingController _healthNotesController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _allergies = List<String>.from(userProvider.allergies);
    _conditions = List<String>.from(userProvider.conditions);
    
    _allergyInputController = TextEditingController();
    _conditionInputController = TextEditingController();
    _medicationsController = TextEditingController(text: userProvider.medications);
    _healthNotesController = TextEditingController(text: userProvider.healthNotes);
    _emergencyNameController = TextEditingController(text: userProvider.emergencyContactName);
    _emergencyPhoneController = TextEditingController(text: userProvider.emergencyContactPhone);
  }

  @override
  void dispose() {
    _allergyInputController.dispose();
    _conditionInputController.dispose();
    _medicationsController.dispose();
    _healthNotesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _addAllergy() {
    final text = _allergyInputController.text.trim();
    if (text.isNotEmpty && !_allergies.contains(text)) {
      setState(() {
        _allergies.add(text);
        _allergyInputController.clear();
      });
    }
  }

  void _removeAllergy(String text) {
    setState(() {
      _allergies.remove(text);
    });
  }

  void _addCondition() {
    final text = _conditionInputController.text.trim();
    if (text.isNotEmpty && !_conditions.contains(text)) {
      setState(() {
        _conditions.add(text);
        _conditionInputController.clear();
      });
    }
  }

  void _removeCondition(String text) {
    setState(() {
      _conditions.remove(text);
    });
  }

  Future<void> _saveMedicalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userProvider = context.read<UserProvider>();

      await userProvider.updateProfile({
        'allergies': _allergies,
        'conditions': _conditions,
        'medications': _medicationsController.text.trim(),
        'healthNotes': _healthNotesController.text.trim(),
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical Info updated successfully!'),
            backgroundColor: MaatriColors.teal,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save medical info: $e'),
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
    return Scaffold(
      backgroundColor: MaatriColors.warmCream,
      appBar: AppBar(
        title: const Text('Medical Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MaatriColors.charcoal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Allergies card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allergies',
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add any food, medication, or environment allergies.',
                        style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                      ),
                      const Divider(height: 24),
                      
                      // Chips list
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _allergies.map((allergy) {
                          return InputChip(
                            label: Text(allergy, style: MaatriTypography.labelMedium),
                            backgroundColor: MaatriColors.coral.withValues(alpha: 0.1),
                            deleteIconColor: MaatriColors.coral,
                            onDeleted: () => _removeAllergy(allergy),
                          );
                        }).toList(),
                      ),
                      if (_allergies.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No allergies added yet.',
                            style: MaatriTypography.bodyMedium.copyWith(
                              color: MaatriColors.mediumGray,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _allergyInputController,
                              decoration: const InputDecoration(
                                hintText: 'Enter an allergy',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addAllergy(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: MaatriColors.coral,
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: _addAllergy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chronic conditions card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chronic Conditions',
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add any pre-existing health conditions.',
                        style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                      ),
                      const Divider(height: 24),

                      // Chips list
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _conditions.map((condition) {
                          return InputChip(
                            label: Text(condition, style: MaatriTypography.labelMedium),
                            backgroundColor: MaatriColors.lavenderDark.withValues(alpha: 0.1),
                            deleteIconColor: MaatriColors.lavenderDark,
                            onDeleted: () => _removeCondition(condition),
                          );
                        }).toList(),
                      ),
                      if (_conditions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No chronic conditions added yet.',
                            style: MaatriTypography.bodyMedium.copyWith(
                              color: MaatriColors.mediumGray,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _conditionInputController,
                              decoration: const InputDecoration(
                                hintText: 'Enter a chronic condition',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addCondition(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: MaatriColors.lavenderDark,
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: _addCondition,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Medications & Health Notes card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medications & Notes',
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: _medicationsController,
                        decoration: const InputDecoration(
                          labelText: 'Current Medications',
                          prefixIcon: Icon(Icons.medication_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _healthNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Health Notes',
                          prefixIcon: Icon(Icons.note_add_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Contact details
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Contact',
                        style: MaatriTypography.titleMedium.copyWith(
                          color: MaatriColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a contact person for emergency notifications.',
                        style: MaatriTypography.bodySmall.copyWith(color: MaatriColors.slate),
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: _emergencyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person Name',
                          prefixIcon: Icon(Icons.person_pin_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_emergencyPhoneController.text.isNotEmpty && (value == null || value.isEmpty)) {
                            return 'Please enter a name for the emergency contact';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone Number',
                          prefixIcon: Icon(Icons.phone_android_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (_emergencyNameController.text.isNotEmpty && (value == null || value.isEmpty)) {
                            return 'Please enter a phone number for the contact';
                          }
                          return null;
                        },
                      ),
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
                    onPressed: _isSaving ? null : _saveMedicalInfo,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Medical Profile',
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
    );
  }
}
