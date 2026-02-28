import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/backend_planner_service.dart';

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final BackendPlannerService _plannerService = BackendPlannerService();

  bool _isSaving = false;
  String _selectedUnit = 'acres';

  final List<Map<String, String>> _areaUnits = [
    {'value': 'acres', 'label': 'Acres'},
    {'value': 'hectares', 'label': 'Ha'},
    {'value': 'perches', 'label': 'Perch'},
    {'value': 'square_meters', 'label': 'Sq.m'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _cropTypeController.dispose();
    super.dispose();
  }

  Future<void> _saveField() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final fieldData = {
          'name': _nameController.text.trim(),
          'area': {
            'value': double.parse(_areaController.text.trim()),
            'unit': _selectedUnit,
          },
          'budget': _budgetController.text.trim().isNotEmpty
              ? double.parse(_budgetController.text.trim())
              : 0,
          if (_locationController.text.trim().isNotEmpty)
            'location': {'address': _locationController.text.trim()},
          if (_cropTypeController.text.trim().isNotEmpty)
            'currentCrop': {'cropName': _cropTypeController.text.trim()},
        };

        await _plannerService.createField(fieldData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Field added successfully!'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ Error saving field: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Failed to add field: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
      appBar: AppBar(
        title: const Text(
          'Add New Field',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveField,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🎨 Modern Header
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryGreen.withOpacity(0.15),
                              AppTheme.primaryGreen.withOpacity(0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: AppTheme.primaryGreen,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'New Field Setup',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add details for accurate profit planning',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 📝 Field Name
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Field Name *',
                  hintText: 'e.g., North Field, Paddy 1',
                  prefixIcon: Icons.agriculture_outlined,
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? 'Field name is required' : null,
                ),
                const SizedBox(height: 24),

                // 📏 Area Input Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _areaController,
                        labelText: 'Area *',
                        hintText: 'e.g., 5.25',
                        prefixIcon: Icons.square_foot_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) return 'Area is required';
                          if (double.tryParse(value!) == null) return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: const TextStyle(fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          items: _areaUnits.map((unit) => DropdownMenuItem(
                                value: unit['value'],
                                child: Text(unit['label']!, style: const TextStyle(fontSize: 15)),
                              )).toList(),
                          onChanged: (value) => setState(() => _selectedUnit = value!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 💰 Budget
                CustomTextField(
                  controller: _budgetController,
                  labelText: 'Budget (Rs)',
                  hintText: 'e.g., 250000',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) return 'Invalid amount';
                      if (double.parse(value) < 0) return 'Budget cannot be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 📍 Location
                CustomTextField(
                  controller: _locationController,
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., Near river, Kandy',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),

                // 🌾 Current Crop
                CustomTextField(
                  controller: _cropTypeController,
                  labelText: 'Current Crop (Optional)',
                  hintText: 'e.g., Rice, Maize, Vegetables',
                  prefixIcon: Icons.grass_outlined,
                ),
                const SizedBox(height: 48),

                // 🚀 Save Button
                SizedBox(
                  height: 56,
                  child: CustomButton(
                    text: _isSaving ? 'Creating Field...' : 'Create Field',
                    onPressed: _saveField,
                    isLoading: _isSaving,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
