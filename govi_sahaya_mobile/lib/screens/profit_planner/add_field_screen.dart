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
      setState(() {
        _isSaving = true;
      });

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
            'location': {
              'address': _locationController.text.trim(),
            },
          if (_cropTypeController.text.trim().isNotEmpty)
            'currentCrop': {
              'cropName': _cropTypeController.text.trim(),
            },
        };

        await _plannerService.createField(fieldData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Field added successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ Error saving field: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add field: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('Add Field'),
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
                // Field Name
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Field Name',
                  hintText: 'e.g., North Field',
                  prefixIcon: Icons.agriculture,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter field name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Area Input - ✅ FIXED OVERFLOW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _areaController,
                        labelText: 'Area',
                        hintText: 'Enter area',
                        prefixIcon: Icons.square_foot,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter area';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryGreen, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                        ),
                        items: _areaUnits.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit['value'],
                            child: Text(
                              unit['label']!,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Budget Input
                CustomTextField(
                  controller: _budgetController,
                  labelText: 'Budget (Rs.)',
                  hintText: 'Enter your budget for this field',
                  prefixIcon: Icons.account_balance_wallet,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid amount';
                      }
                      if (double.parse(value) < 0) {
                        return 'Budget cannot be negative';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location
                CustomTextField(
                  controller: _locationController,
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., Near the river',
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: 16),

                // Current Crop
                CustomTextField(
                  controller: _cropTypeController,
                  labelText: 'Current Crop (Optional)',
                  hintText: 'e.g., Rice, Wheat',
                  prefixIcon: Icons.grass,
                ),
                const SizedBox(height: 32),

                // Save Button
                CustomButton(
                  text: 'Save Field',
                  onPressed: _saveField,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
