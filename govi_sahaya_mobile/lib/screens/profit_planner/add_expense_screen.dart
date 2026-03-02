import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/routes.dart';
import '../../services/backend_planner_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final BackendPlannerService _plannerService = BackendPlannerService();

  String _selectedCategory = 'fertilizers';
  String? _selectedFieldId;
  String? _selectedSupplier;
  String _unit = 'kg';
  double? _quantity;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  List<dynamic> _fields = [];
  bool _isLoadingFields = true;

  // New features state variables
  String? _selectedPaymentMethod;
  bool _isRecurring = false;
  int _recurringInterval = 1;
  String _recurringUnit = 'months';
  bool _attachReceipt = false;

  final List<Map<String, dynamic>> _suppliers = [
    {'value': 'local_agri_store', 'label': 'Local Agri Store', 'si': 'දේශීය කෘෂි වස්තු', 'ta': 'உள்ளூர் விவசாயக் கடை'},
    {'value': 'fertilizer_co', 'label': 'Fertilizer Co', 'si': 'පොහොර සමාගම', 'ta': 'உரங்கள் நிறுவனம்'},
    {'value': 'pesticide_dist', 'label': 'Pesticide Distributor', 'si': 'පළිබෝධනාශක බෙදාහරින්නා', 'ta': 'பூச்சிக்கொல்லி விநியோகஸ்தர்'},
    {'value': 'labor_contractor', 'label': 'Labor Contractor', 'si': 'ශ්‍රම සැපයුම්කරු', 'ta': 'தொழிலாளர் ஒப்பந்தக்காரர்'},
    {'value': 'other', 'label': 'Other', 'si': 'වෙනත්', 'ta': 'மற்றவை'},
  ];

  final List<String> _units = ['kg', 'liters', 'bags', 'units', 'hours', 'days'];

  final List<Map<String, dynamic>> _categories = [
    {'value': 'seeds', 'label': 'Seeds', 'si': 'බීජ', 'ta': 'விதைகள்'},
    {'value': 'fertilizers', 'label': 'Fertilizers', 'si': 'පොහොර', 'ta': 'உரங்கள்'},
    {'value': 'pesticides', 'label': 'Pesticides', 'si': 'පළිබෝධනාශක', 'ta': 'பூச்சிக்கொல்லி'},
    {'value': 'labor', 'label': 'Labor', 'si': 'ශ්‍රම', 'ta': 'தொழிலாளர்'},
    {'value': 'equipment', 'label': 'Equipment', 'si': 'උපකරණ', 'ta': 'உபகரணங்கள்'},
    {'value': 'irrigation', 'label': 'Irrigation', 'si': 'වාරිමාර්ග', 'ta': 'நீர்ப்பாசனம்'},
    {'value': 'transportation', 'label': 'Transportation', 'si': 'ප්‍රවාහන', 'ta': 'போக்குவரத்து'},
    {'value': 'other', 'label': 'Other', 'si': 'වෙනත්', 'ta': 'மற்றவை'},
  ];

  // New payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash', 'si': 'මුදල්', 'ta': 'பணம்'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'si': 'බැංකු හරහා', 'ta': 'வங்கி இடமாற்றம்'},
    {'value': 'credit', 'label': 'Credit', 'si': 'ණය', 'ta': 'கடன்'},
  ];

  final List<Map<String, dynamic>> _recurringUnits = [
    {'value': 'days', 'label': 'Days', 'si': 'දින', 'ta': 'நாட்கள்'},
    {'value': 'weeks', 'label': 'Weeks', 'si': 'සති', 'ta': 'வாரங்கள்'},
    {'value': 'months', 'label': 'Months', 'si': 'මාස', 'ta': 'மாதங்கள்'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _plannerService.getAllFields(isActive: true);
      setState(() {
        _fields = fields;
        if (_fields.isNotEmpty) {
          _selectedFieldId = _fields[0]['_id'] as String?;
        }
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() => _isLoadingFields = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.green),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense(String lang) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final expenseData = {
        'description': _descriptionController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'category': _selectedCategory,
        'date': _selectedDate.toIso8601String(),
        if (_selectedFieldId != null) 'field': _selectedFieldId,
        if (_selectedSupplier != null && _selectedSupplier != 'other') 'supplier': _selectedSupplier,
        if (_quantity != null) 'quantity': {'value': _quantity, 'unit': _unit},
        // New features data
        if (_selectedPaymentMethod != null) 'paymentMethod': _selectedPaymentMethod,
        if (_isRecurring)
          'recurring': {
            'interval': _recurringInterval,
            'unit': _recurringUnit,
          },
        if (_attachReceipt) 'attachReceipt': true,
      };
      await _plannerService.createExpense(expenseData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'වියදම සාර්ථකව එකතු කරන ලදී'
              : lang == 'ta'
                  ? 'செலவு வெற்றிகரமாக சேர்க்கப்பட்டது'
                  : 'Expense added successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'වියදම එකතු කිරීම අසාර්ථකයි: $e'
              : lang == 'ta'
                  ? 'செலவு சேர்க்க முடியவில்லை: $e'
                  : 'Failed to add expense: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _categoryLabel(Map<String, dynamic> cat, String lang) {
    if (lang == 'si') return cat['si'] as String;
    if (lang == 'ta') return cat['ta'] as String;
    return cat['label'] as String;
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(List<Map<String, dynamic>> items, String lang) {
    return items.map<DropdownMenuItem<String>>((item) {
      return DropdownMenuItem<String>(
        value: item['value'] as String,
        child: Text(_categoryLabel(item, lang), style: const TextStyle(fontSize: 14)),
      );
    }).toList();
  }

  List<DropdownMenuItem<String?>> _buildNullableDropdownItems(List<Map<String, dynamic>> items, String lang) {
    return [
      DropdownMenuItem<String?>(
        value: null,
        child: Text(lang == 'si' ? 'තෝරන්න' : lang == 'ta' ? 'தேர்வு செய்யவும்' : 'Select', style: const TextStyle(fontSize: 14)),
      ),
      ...items.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item['value'] as String,
          child: Text(_categoryLabel(item, lang), style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
    ];
  }

  Widget _buildSupplierField(String lang) {
    return _buildField(
      icon: Icons.store_rounded,
      label: lang == 'si' ? 'සැපයුම්කරු (විකල්ප)' : lang == 'ta' ? 'உபதேசம் (விருப்பம்)' : 'Supplier (Optional)',
      child: DropdownButtonFormField<String?>(
        value: _selectedSupplier,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: _buildNullableDropdownItems(_suppliers, lang),
        onChanged: (v) => setState(() => _selectedSupplier = v),
      ),
    );
  }

  Widget _buildPaymentMethodField(String lang) {
    return _buildField(
      icon: Icons.payment_rounded,
      label: lang == 'si' ? 'ගෙවීම් ක්‍රමය (විකල්ප)' : lang == 'ta' ? 'கட்டுப்படுத்தும் முறை (விருப்பம்)' : 'Payment Method (Optional)',
      child: DropdownButtonFormField<String?>(
        value: _selectedPaymentMethod,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: _buildNullableDropdownItems(_paymentMethods, lang),
        onChanged: (v) => setState(() => _selectedPaymentMethod = v),
      ),
    );
  }

  Widget _buildQuantityField(String lang) {
    return _buildField(
      icon: Icons.inventory_2_rounded,
      label: lang == 'si' ? 'ප්‍රමාණය (විකල්ප)' : lang == 'ta' ? 'அளவு (விருப்பம்)' : 'Quantity (Optional)',
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: lang == 'si' ? 'ප්‍රමාණය' : lang == 'ta' ? 'அளவு' : 'Qty',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return lang == 'si' ? 'වලංගු ප්‍රමාණයක්' : lang == 'ta' ? 'செல்லுபடியான அளவு' : 'Valid quantity';
                  }
                }
                return null;
              },
              onChanged: (v) {
                final qty = double.tryParse(v);
                if (qty != null) setState(() => _quantity = qty);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _unit,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: _units.map((unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit.toUpperCase(), style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _unit = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringField(String lang) {
    return _buildField(
      icon: Icons.repeat_rounded,
      label: lang == 'si' ? 'නිදහස් වියදම් (විකල්ප)' : lang == 'ta' ? 'மீண்டும் வரும் செலவு (விருப்பம்)' : 'Recurring Expense (Optional)',
      child: Row(
        children: [
          Checkbox(
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v ?? false),
            activeColor: Colors.green,
            checkColor: Colors.white,
          ),
          Expanded(
            child: AbsorbPointer(
              absorbing: !_isRecurring,
              child: Opacity(
                opacity: _isRecurring ? 1.0 : 0.5,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '1',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) {
                          final interval = int.tryParse(v);
                          if (interval != null && interval > 0) {
                            _recurringInterval = interval;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _recurringUnit,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _buildDropdownItems(_recurringUnits, lang),
                        onChanged: _isRecurring ? (v) => setState(() => _recurringUnit = v!) : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptToggle(String lang) {
    return _buildField(
      icon: Icons.receipt_long_rounded,
      label: lang == 'si' ? 'රිසිට් එකතු කරන්න (විකල්ප)' : lang == 'ta' ? 'ரசீது இணைக்கவும் (விருப்பம்)' : 'Attach Receipt (Optional)',
      child: GestureDetector(
        onTap: () => setState(() => _attachReceipt = !_attachReceipt),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _attachReceipt ? Colors.green.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _attachReceipt ? Colors.green : Colors.grey.shade200,
              width: _attachReceipt ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _attachReceipt ? Icons.check_circle : Icons.receipt_outlined,
                color: _attachReceipt ? Colors.green : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _attachReceipt
                    ? (lang == 'si' ? 'රිසිට් එකතු කර ඇත' : lang == 'ta' ? 'ரசீது இணைக்கப்பட்டது' : 'Receipt attached')
                    : (lang == 'si' ? 'රිසිට් එකතු කරන්න' : lang == 'ta' ? 'ரசீது இணைக்கவும்' : 'Attach receipt'),
                style: TextStyle(
                  color: _attachReceipt ? Colors.green.shade700 : Colors.grey.shade600,
                  fontWeight: _attachReceipt ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _topBarButton(Icons.arrow_back_ios_new_rounded, size: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang == 'si' ? 'වියදමක් එකතු කරන්න' : lang == 'ta' ? 'செலவு சேர்க்கவும்' : 'Add Expense',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _topBarButton(Icons.notifications_outlined),
                        if (unreadCount > 0) _notificationBadge(unreadCount),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                ),
                child: _isLoadingFields
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionLabel(lang == 'si' ? 'වියදම් තොරතුරු' : lang == 'ta' ? 'செலவு விவரங்கள்' : 'EXPENSE DETAILS'),
                              const SizedBox(height: 12),

                              _buildField(
                                icon: Icons.description_rounded,
                                label: lang == 'si' ? 'විස්තරය' : lang == 'ta' ? 'விளக்கம்' : 'Description',
                                child: TextFormField(
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    hintText: lang == 'si' ? 'වියදම් විස්තරය ඇතුළත් කරන්න' : lang == 'ta' ? 'செலவு விவரம் உள்ளிடுங்கள்' : 'Enter expense description',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? (lang == 'si' ? 'කරුණාකර විස්තරය ඇතුළත් කරන්න' : lang == 'ta' ? 'விவரம் உள்ளிடுங்கள்' : 'Please enter description')
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildField(
                                icon: Icons.payments_rounded,
                                label: lang == 'si' ? 'මුදල (රු.)' : lang == 'ta' ? 'தொகை (ரூ.)' : 'Amount (Rs.)',
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: lang == 'si' ? 'මුදල ඇතුළත් කරන්න' : lang == 'ta' ? 'தொகையை உள்ளிடுங்கள்' : 'Enter amount',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return lang == 'si' ? 'කරුණාකර මුදල ඇතුළත් කරන්න' : lang == 'ta' ? 'தொகையை உள்ளிடுங்கள்' : 'Please enter amount';
                                    if (double.tryParse(v) == null) return lang == 'si' ? 'වලංගු සංඛ්‍යාවක් ඇතුළත් කරන්න' : lang == 'ta' ? 'செல்லுபடியான எண் உள்ளிடுங்கள்' : 'Enter a valid number';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildSupplierField(lang),
                              const SizedBox(height: 12),
                              _buildPaymentMethodField(lang),
                              const SizedBox(height: 12),
                              _buildQuantityField(lang),
                              const SizedBox(height: 20),

                              _buildSectionLabel(lang == 'si' ? 'වර්ගීකරණය' : lang == 'ta' ? 'வகைப்படுத்தல்' : 'CATEGORIZATION'),
                              const SizedBox(height: 12),

                              _buildField(
                                icon: Icons.category_rounded,
                                label: lang == 'si' ? 'වර්ගය' : lang == 'ta' ? 'வகை' : 'Category',
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  items: _buildDropdownItems(_categories, lang),
                                  onChanged: (v) => setState(() => _selectedCategory = v!),
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (_fields.isNotEmpty) ...[
                                _buildField(
                                  icon: Icons.agriculture_rounded,
                                  label: lang == 'si' ? 'ක්ෂේත්‍රය (විකල්ප)' : lang == 'ta' ? 'வயல் (விருப்பம்)' : 'Field (Optional)',
                                  child: DropdownButtonFormField<String?>(
                                    value: _selectedFieldId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(lang == 'si' ? 'ක්ෂේත්‍රයක් තෝරා නැත' : lang == 'ta' ? 'வயல் தேர்ந்தெடுக்கவில்லை' : 'No field selected'),
                                      ),
                                      ..._fields.map((field) => DropdownMenuItem<String?>(
                                            value: field['_id'] as String?,
                                            child: Text(field['name']?.toString() ?? 'Unknown'),
                                          )),
                                    ],
                                    onChanged: (v) => setState(() => _selectedFieldId = v),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              _buildField(
                                icon: Icons.calendar_today_rounded,
                                label: lang == 'si' ? 'දිනය' : lang == 'ta' ? 'தேதி' : 'Date',
                                child: GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 14)),
                                        const Spacer(),
                                        const Icon(Icons.arrow_drop_down_rounded, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildRecurringField(lang),
                              const SizedBox(height: 12),
                              _buildReceiptToggle(lang),
                              const SizedBox(height: 32),

                              GestureDetector(
                                onTap: _isSaving ? null : () => _saveExpense(lang),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _isSaving ? Colors.grey : Colors.green,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isSaving)
                                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      else
                                        const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Text(
                                        _isSaving
                                            ? (lang == 'si' ? 'සුරකිමින්...' : lang == 'ta' ? 'சேமிக்கிறது...' : 'Saving...')
                                            : (lang == 'si' ? 'වියදම සුරකින්න' : lang == 'ta' ? 'செலவை சேமிக்கவும்' : 'Save Expense'),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBarButton(IconData icon, {double size = 18}) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: size),
      );

  Widget _notificationBadge(int count) => Positioned(
        top: -2,
        right: -2,
        child: Container(
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
          child: Text(count > 99 ? '99+' : '$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _buildSectionLabel(String label) => Row(
        children: [
          Container(width: 4, height: 12, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        ],
      );

  Widget _buildField({required IconData icon, required String label, required Widget child}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: Colors.green), const SizedBox(width: 6), Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))]),
          const SizedBox(height: 6),
          child,
        ],
      );
}
