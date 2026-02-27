import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/backend_planner_service.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final BackendPlannerService _plannerService = BackendPlannerService();

  String _selectedCategory = 'fertilizers';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isDeleting = false;
  List<dynamic> _fields = [];
  String? _selectedFieldId;
  bool _isLoadingFields = true;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'seeds', 'label': 'Seeds'},
    {'value': 'fertilizers', 'label': 'Fertilizers'},
    {'value': 'pesticides', 'label': 'Pesticides'},
    {'value': 'labor', 'label': 'Labor'},
    {'value': 'equipment', 'label': 'Equipment'},
    {'value': 'irrigation', 'label': 'Irrigation'},
    {'value': 'transportation', 'label': 'Transportation'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFields();
    _initializeFields();
  }

  void _initializeFields() {
    _descriptionController.text = widget.expense['description'] ?? '';
    _amountController.text = widget.expense['amount'].toString();
    _selectedCategory = widget.expense['category'] ?? 'fertilizers';
    _selectedDate = DateTime.parse(widget.expense['date']);
    _selectedFieldId = widget.expense['field']?['_id'];
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _plannerService.getAllFields(isActive: true);
      setState(() {
        _fields = fields;
        _isLoadingFields = false;
      });
    } catch (e) {
      print('❌ Error loading fields: $e');
      setState(() {
        _isLoadingFields = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final expenseData = {
          'description': _descriptionController.text.trim(),
          'amount': double.parse(_amountController.text.trim()),
          'category': _selectedCategory,
          'date': _selectedDate.toIso8601String(),
          if (_selectedFieldId != null) 'field': _selectedFieldId,
        };

        await _plannerService.updateExpense(widget.expense['_id'], expenseData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ Error updating expense: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update expense: $e')),
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

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await _plannerService.deleteExpense(widget.expense['_id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ Error deleting expense: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete expense: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
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
        title: const Text('Edit Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _deleteExpense,
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
        child: _isLoadingFields
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _descriptionController,
                        labelText: 'Description',
                        hintText: 'Enter expense description',
                        prefixIcon: Icons.description,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _amountController,
                        labelText: 'Amount (Rs.)',
                        hintText: 'Enter amount',
                        prefixIcon: Icons.money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['value'] as String,
                            child: Text(category['label'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_fields.isNotEmpty)
                        DropdownButtonFormField<String?>(
                          value: _selectedFieldId,
                          decoration: const InputDecoration(
                            labelText: 'Field (Optional)',
                            prefixIcon: Icon(Icons.agriculture),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No field selected'),
                            ),
                            ..._fields.map((field) {
                              return DropdownMenuItem<String?>(
                                value: field['_id'] as String?,
                                child:
                                    Text(field['name'] as String? ?? 'Unknown'),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFieldId = value;
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Update Expense',
                        onPressed: _updateExpense,
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
