import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
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

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _recurringController = TextEditingController(text: '1');
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _loadFields();
  }

  @override
 void dispose() {
  _descriptionController.dispose();
  _amountController.dispose();
  _quantityController.dispose();
  _recurringController.dispose(); // ADD THIS
  _animationController.dispose();
  super.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang == 'si'
                        ? 'වියදම සාර්ථකව එකතු කරන ලදී'
                        : lang == 'ta'
                            ? 'செலவு வெற்றிகரமாக சேர்க்கப்பட்டது'
                            : 'Expense added successfully',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang == 'si'
                        ? 'වියදම එකතු කිරීම අසාර්ථකයි: $e'
                        : lang == 'ta'
                            ? 'செலவு சேர்க்க முடியவில்லை: $e'
                            : 'Failed to add expense: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
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
        child: Text(
          _categoryLabel(item, lang),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
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
                      lang == 'si'
                          ? 'වියදමක් එකතු කරන්න'
                          : lang == 'ta'
                              ? 'செலவு சேர்க்கவும்'
                              : 'Add Expense',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _isLoadingFields
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen,
                            strokeWidth: 2,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildPremiumSectionLabel(
                                  lang == 'si'
                                      ? 'වියදම් තොරතුරු'
                                      : lang == 'ta'
                                          ? 'செலவு விவரங்கள்'
                                          : 'EXPENSE DETAILS',
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.description_rounded,
                                  label: lang == 'si'
                                      ? 'විස්තරය'
                                      : lang == 'ta'
                                          ? 'விளக்கம்'
                                          : 'Description',
                                  child: _styledTextFormField(
                                    controller: _descriptionController,
                                    hint: lang == 'si'
                                        ? 'වියදම් විස්තරය ඇතුළත් කරන්න'
                                        : lang == 'ta'
                                            ? 'செலவு விவரம் உள்ளிடுங்கள்'
                                            : 'Enter expense description',
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? (lang == 'si'
                                            ? 'කරුණාකර විස්තරය ඇතුළත් කරන්න'
                                            : lang == 'ta'
                                                ? 'விவரம் உள்ளிடுங்கள்'
                                                : 'Please enter description')
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.payments_rounded,
                                  label: lang == 'si'
                                      ? 'මුදල (රු.)'
                                      : lang == 'ta'
                                          ? 'தொகை (ரூ.)'
                                          : 'Amount (Rs.)',
                                  child: _styledTextFormField(
                                    controller: _amountController,
                                    hint: lang == 'si'
                                        ? 'මුදල ඇතුළත් කරන්න'
                                        : lang == 'ta'
                                            ? 'தொகையை உள்ளிடுங்கள்'
                                            : 'Enter amount',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return lang == 'si'
                                            ? 'කරුණාකර මුදල ඇතුළත් කරන්න'
                                            : lang == 'ta'
                                                ? 'தொகையை உள்ளிடுங்கள்'
                                                : 'Please enter amount';
                                      }
                                      if (double.tryParse(v) == null) {
                                        return lang == 'si'
                                            ? 'වලංගු සංඛ්‍යාවක් ඇතුළත් කරන්න'
                                            : lang == 'ta'
                                                ? 'செல்லுபடியான எண் உள்ளிடுங்கள்'
                                                : 'Enter a valid number';
                                      }
                                      if (double.parse(v) <= 0) {
                                        return lang == 'si'
                                            ? 'මුදල ඍණාත්මක විය නොහැක'
                                            : lang == 'ta'
                                                ? 'தொகை எதிர்மறையாக இருக்க முடியாது'
                                                : 'Amount cannot be negative or zero';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.store_rounded,
                                  label: lang == 'si'
                                      ? 'සැපයුම්කරු (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'உபதேசம் (விருப்பம்)'
                                          : 'Supplier (Optional)',
                                  child: _styledDropdown<String?>(
                                    value: _selectedSupplier,
                                    hint: lang == 'si'
                                        ? 'සැපයුම්කරුවෙකු තෝරන්න'
                                        : lang == 'ta'
                                            ? 'உபதேசம் தேர்ந்தெடுக்கவும்'
                                            : 'Select supplier',
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          lang == 'si'
                                              ? 'තෝරන්න'
                                              : lang == 'ta'
                                                  ? 'தேர்வு செய்யவும்'
                                                  : 'Select',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ..._suppliers.map((supplier) {
                                        final label = lang == 'si'
                                            ? supplier['si']!
                                            : lang == 'ta'
                                                ? supplier['ta']!
                                                : supplier['label']!;
                                        return DropdownMenuItem<String>(
                                          value: supplier['value'],
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (v) => setState(() => _selectedSupplier = v),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.payment_rounded,
                                  label: lang == 'si'
                                      ? 'ගෙවීම් ක්‍රමය (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'கட்டுப்படுத்தும் முறை (விருப்பம்)'
                                          : 'Payment Method (Optional)',
                                  child: _styledDropdown<String?>(
                                    value: _selectedPaymentMethod,
                                    hint: lang == 'si'
                                        ? 'ගෙවීම් ක්‍රමය තෝරන්න'
                                        : lang == 'ta'
                                            ? 'கட்டுப்படுத்தும் முறை தேர்ந்தெடுக்கவும்'
                                            : 'Select payment method',
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          lang == 'si'
                                              ? 'තෝරන්න'
                                              : lang == 'ta'
                                                  ? 'தேர்வு செய்யவும்'
                                                  : 'Select',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ..._paymentMethods.map((method) {
                                        final label = lang == 'si'
                                            ? method['si']!
                                            : lang == 'ta'
                                                ? method['ta']!
                                                : method['label']!;
                                        return DropdownMenuItem<String>(
                                          value: method['value'],
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (v) => setState(() => _selectedPaymentMethod = v),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.inventory_2_rounded,
                                  label: lang == 'si'
                                      ? 'ප්‍රමාණය (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'அளவு (விருப்பம்)'
                                          : 'Quantity (Optional)',
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _styledTextFormField(
                                          controller: _quantityController,
                                          hint: lang == 'si'
                                              ? 'ප්‍රමාණය'
                                              : lang == 'ta'
                                                  ? 'அளவு'
                                                  : 'Qty',
                                          keyboardType:
                                              const TextInputType.numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}'),
                                            ),
                                          ],
                                          validator: (v) {
                                            if (v != null && v.isNotEmpty) {
                                              if (double.tryParse(v) == null || double.parse(v) <= 0) {
                                                return lang == 'si'
                                                    ? 'වලංගු ප්‍රමාණයක්'
                                                    : lang == 'ta'
                                                        ? 'செல்லுபடியான அளவு'
                                                        : 'Valid quantity';
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
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: _styledDropdown<String>(
                                          value: _unit,
                                          items: _units.map((unit) {
                                            return DropdownMenuItem<String>(
                                              value: unit,
                                              child: Text(
                                                unit.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) => setState(() => _unit = v!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _buildPremiumSectionLabel(
                                  lang == 'si'
                                      ? 'වර්ගීකරණය'
                                      : lang == 'ta'
                                          ? 'வகைப்படுத்தல்'
                                          : 'CATEGORIZATION',
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.category_rounded,
                                  label: lang == 'si'
                                      ? 'වර්ගය'
                                      : lang == 'ta'
                                          ? 'வகை'
                                          : 'Category',
                                  child: _styledDropdown<String>(
                                    value: _selectedCategory,
                                    items: _buildDropdownItems(_categories, lang),
                                    onChanged: (v) => setState(() => _selectedCategory = v!),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                if (_fields.isNotEmpty) ...[
                                  _buildPremiumField(
                                    icon: Icons.agriculture_rounded,
                                    label: lang == 'si'
                                        ? 'ක්ෂේත්‍රය (විකල්ප)'
                                        : lang == 'ta'
                                            ? 'வயல் (விருப்பம்)'
                                            : 'Field (Optional)',
                                    child: _styledDropdown<String?>(
                                      value: _selectedFieldId,
                                      hint: lang == 'si'
                                          ? 'ක්ෂේත්‍රයක් තෝරන්න'
                                          : lang == 'ta'
                                              ? 'வயல் தேர்ந்தெடுக்கவும்'
                                              : 'Select field',
                                      items: [
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(
                                            lang == 'si'
                                                ? 'ක්ෂේත්‍රයක් තෝරා නැත'
                                                : lang == 'ta'
                                                    ? 'வயல் தேர்ந்தெடுக்கவில்லை'
                                                    : 'No field selected',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        ..._fields.map((field) => DropdownMenuItem<String?>(
                                              value: field['_id'] as String?,
                                              child: Text(
                                                field['name']?.toString() ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )),
                                      ],
                                      onChanged: (v) => setState(() => _selectedFieldId = v),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                _buildPremiumField(
                                  icon: Icons.calendar_today_rounded,
                                  label: lang == 'si'
                                      ? 'දිනය'
                                      : lang == 'ta'
                                          ? 'தேதி'
                                          : 'Date',
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: Colors.grey.shade200, width: 1.5),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            size: 20,
                                            color: Colors.grey.shade500,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.repeat_rounded,
                                  label: lang == 'si'
                                      ? 'නිදහස් වියදම් (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'மீண்டும் வரும் செலவு (விருப்பம்)'
                                          : 'Recurring Expense (Optional)',
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _isRecurring,
                                        onChanged: (v) =>
                                            setState(() => _isRecurring = v ?? false),
                                        activeColor: AppTheme.primaryGreen,
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
                                                  child: _styledTextFormField(
                                                    controller: _recurringController,
                                                     hint: '1',
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.digitsOnly,
                                                    ],
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
                                                  child: _styledDropdown<String>(
                                                    value: _recurringUnit,
                                                    items: _buildDropdownItems(_recurringUnits, lang),
                                                    onChanged: (v) {
                                                      if (!_isRecurring || v == null) return;
                                                      setState(() => _recurringUnit = v);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _buildPremiumField(
                                  icon: Icons.receipt_long_rounded,
                                  label: lang == 'si'
                                      ? 'රිසිට් එකතු කරන්න (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'ரசீது இணைக்கவும் (விருப்பம்)'
                                          : 'Attach Receipt (Optional)',
                                  child: GestureDetector(
                                    onTap: () => setState(() => _attachReceipt = !_attachReceipt),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _attachReceipt
                                            ? AppTheme.primaryGreen.withOpacity(0.1)
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _attachReceipt
                                              ? AppTheme.primaryGreen
                                              : Colors.grey.shade200,
                                          width: _attachReceipt ? 2 : 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _attachReceipt
                                                ? Icons.check_circle
                                                : Icons.receipt_outlined,
                                            color: _attachReceipt
                                                ? AppTheme.primaryGreen
                                                : Colors.grey.shade600,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _attachReceipt
                                                  ? (lang == 'si'
                                                      ? 'රිසිට් එකතු කර ඇත'
                                                      : lang == 'ta'
                                                          ? 'ரசீது இணைக்கப்பட்டது'
                                                          : 'Receipt attached')
                                                  : (lang == 'si'
                                                      ? 'රිසිට් එකතු කරන්න'
                                                      : lang == 'ta'
                                                          ? 'ரசீது இணைக்கவும்'
                                                          : 'Attach receipt'),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: _attachReceipt
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: _attachReceipt
                                                    ? AppTheme.primaryGreen
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _buildPremiumSaveButton(lang),
                              ],
                            ),
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

  // ✅ ALL WIDGETS - SAME SIZE, COLORS, BOLDER TEXT (EXACTLY LIKE AddFieldScreen)
  Widget _topBarButton(IconData icon, {double size = 18}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _notificationBadge(int count) {
    return Positioned(
      top: -3,
      right: -3,
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.red],
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPremiumSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark.withOpacity(0.95),
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumField({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen.withOpacity(0.15),
                    AppTheme.primaryGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 14, color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildPremiumSaveButton(String lang) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: _isSaving ? null : () => _saveExpense(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSaving
                      ? [
                          Colors.grey.shade400,
                          Colors.grey.shade300,
                        ]
                      : [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen.withOpacity(0.85),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isSaving
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    )
                  else
                    const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _isSaving
                        ? (lang == 'si'
                            ? 'සුරකිමින්...'
                            : lang == 'ta'
                                ? 'சேமிக்கிறது...'
                                : 'Saving...')
                        : (lang == 'si'
                            ? 'වියදම සුරකින්න'
                            : lang == 'ta'
                                ? 'செலவை சேமிக்கவும்'
                                : 'Save Expense'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _styledTextFormField({
   TextEditingController? controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextAlign? textAlign,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlign: textAlign ?? TextAlign.start,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.textDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Widget _styledDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    String? hint,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      hint: hint != null
          ? Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.textDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryGreen,
            width: 2,
          ),
        ),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      dropdownColor: Colors.white,
      elevation: 8,
    );
  }
}
