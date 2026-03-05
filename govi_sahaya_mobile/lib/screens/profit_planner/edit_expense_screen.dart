import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/routes.dart';
import '../../services/backend_planner_service.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen>
    with TickerProviderStateMixin {
  // ── Form & Service ────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _recurringController = TextEditingController(text: '1');
  final BackendPlannerService _plannerService = BackendPlannerService();

  // ── Core state ────────────────────────────────────────────────────
  String _selectedCategory = 'fertilizers';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isDeleting = false;
  List<dynamic> _fields = [];
  String? _selectedFieldId;
  bool _isLoadingFields = true;

  // ── Optional fields state ─────────────────────────────────────────
  String? _selectedSupplier;
  String? _selectedPaymentMethod;
  double _quantity = 0;
  String _unit = 'kg';
  bool _isRecurring = false;
  int _recurringInterval = 1;
  String _recurringUnit = 'months';
  bool _attachReceipt = false;

  // ── Animation ─────────────────────────────────────────────────────
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ── Static data ───────────────────────────────────────────────────
  final List<Map<String, dynamic>> _categories = [
    {'value': 'seeds', 'label': 'Seeds', 'si': 'බීජ', 'ta': 'விதைகள்'},
    {
      'value': 'fertilizers',
      'label': 'Fertilizers',
      'si': 'පොහොර',
      'ta': 'உரங்கள்'
    },
    {
      'value': 'pesticides',
      'label': 'Pesticides',
      'si': 'පළිබෝධනාශක',
      'ta': 'பூச்சிக்கொல்லி'
    },
    {'value': 'labor', 'label': 'Labor', 'si': 'ශ්‍රම', 'ta': 'தொழிலாளர்'},
    {
      'value': 'equipment',
      'label': 'Equipment',
      'si': 'උපකරණ',
      'ta': 'உபகරணங்கள்'
    },
    {
      'value': 'irrigation',
      'label': 'Irrigation',
      'si': 'වාරිමාර්ග',
      'ta': 'நீர்ப்பாசனம்'
    },
    {
      'value': 'transportation',
      'label': 'Transportation',
      'si': 'ප්‍රවාහන',
      'ta': 'போக்குவரத்து'
    },
    {'value': 'other', 'label': 'Other', 'si': 'වෙනත්', 'ta': 'மற்றவை'},
  ];

  final List<Map<String, dynamic>> _suppliers = [
    {
      'value': 'local_agri_store',
      'label': 'Local Agri Store',
      'si': 'දේශීය කෘෂි වස්තු',
      'ta': 'உள்ளூர் விவசாயக் கடை'
    },
    {
      'value': 'fertilizer_co',
      'label': 'Fertilizer Co',
      'si': 'පොහොර සමාගම',
      'ta': 'உரங்கள் நிறுவனம்'
    },
    {
      'value': 'agro_supplies',
      'label': 'Agro Supplies',
      'si': 'කෘෂි සැපයුම්',
      'ta': 'விவசாய பொருட்கள்'
    },
    {'value': 'other', 'label': 'Other', 'si': 'වෙනත්', 'ta': 'மற்றவை'},
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash', 'si': 'මුදල්', 'ta': 'பணம்'},
    {
      'value': 'bank_transfer',
      'label': 'Bank Transfer',
      'si': 'බැංකු හරයාම',
      'ta': 'வங்கி பரிமாற்றம்'
    },
    {
      'value': 'mobile_payment',
      'label': 'Mobile Payment',
      'si': 'ජංගම ගෙවීම',
      'ta': 'மொபைல் பணம்'
    },
    {'value': 'credit', 'label': 'Credit', 'si': 'ණය', 'ta': 'கடன்'},
  ];

  final List<String> _units = ['kg', 'g', 'l', 'ml', 'units', 'bags'];

  final List<Map<String, dynamic>> _recurringUnits = [
    {'value': 'days', 'label': 'Days', 'si': 'දින', 'ta': 'நாட்கள்'},
    {'value': 'weeks', 'label': 'Weeks', 'si': 'සති', 'ta': 'வாரங்கள்'},
    {'value': 'months', 'label': 'Months', 'si': 'මාස', 'ta': 'மாதங்கள்'},
    {'value': 'years', 'label': 'Years', 'si': 'අවුරුදු', 'ta': 'ஆண்டுகள்'},
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────
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
    _initializeFields();
    _loadFields();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _recurringController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ── Pre-populate from existing expense ────────────────────────────
  void _initializeFields() {
    final e = widget.expense;

    _descriptionController.text = e['description'] ?? '';
    _amountController.text = e['amount']?.toString() ?? '';
    _selectedCategory = e['category'] ?? 'fertilizers';
    _selectedDate = DateTime.tryParse(e['date'] ?? '') ?? DateTime.now();
    _selectedFieldId = e['field']?['_id'] as String?;

    // Optional fields
    _selectedSupplier = e['supplier'] as String?;
    _selectedPaymentMethod = e['paymentMethod'] as String?;
    _attachReceipt = e['attachReceipt'] == true;

    final qty = e['quantity'];
    if (qty != null) {
      _quantity = (qty['value'] as num?)?.toDouble() ?? 0;
      _unit = qty['unit'] as String? ?? 'kg';
      if (_quantity > 0) {
        _quantityController.text = _quantity.toString();
      }
    }

    final recurring = e['recurring'];
    if (recurring != null) {
      _isRecurring = true;
      _recurringInterval = (recurring['interval'] as num?)?.toInt() ?? 1;
      _recurringUnit = recurring['unit'] as String? ?? 'months';
      _recurringController.text = _recurringInterval.toString();
    }
  }

  // ── Data loading ──────────────────────────────────────────────────
  Future<void> _loadFields() async {
    try {
      final fields = await _plannerService.getAllFields(isActive: true);
      setState(() {
        _fields = fields;
        _isLoadingFields = false;
      });
    } catch (e) {
      setState(() => _isLoadingFields = false);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────
  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: AppTheme.primaryGreen,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1A1A1A),
                  onSurface: Colors.white,
                )
              : const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Update ────────────────────────────────────────────────────────
  Future<void> _updateExpense(String lang) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final expenseData = <String, dynamic>{
        'description': _descriptionController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'category': _selectedCategory,
        'date': _selectedDate.toIso8601String(),
        if (_selectedFieldId != null) 'field': _selectedFieldId,
        if (_selectedSupplier != null) 'supplier': _selectedSupplier,
        if (_selectedPaymentMethod != null)
          'paymentMethod': _selectedPaymentMethod,
        if (_quantity > 0) 'quantity': {'value': _quantity, 'unit': _unit},
        if (_isRecurring)
          'recurring': {'interval': _recurringInterval, 'unit': _recurringUnit},
        if (_attachReceipt) 'attachReceipt': true,
      };

      await _plannerService.updateExpense(widget.expense['_id'], expenseData);

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
                        ? 'වියදම සාර්ථකව යාවත්කාලීන කරන ලදී'
                        : lang == 'ta'
                            ? 'செலவு வெற்றிகரமாக புதுப்பிக்கப்பட்டது'
                            : 'Expense updated successfully',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        ? 'යාවත්කාලීන කිරීම අසාර්ථකයි: $e'
                        : lang == 'ta'
                            ? 'புதுப்பிக்க முடியவில்லை: $e'
                            : 'Failed to update expense: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────
  Future<void> _deleteExpense(String lang, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.shade900.withOpacity(0.3)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              lang == 'si'
                  ? 'වියදම මකන්න'
                  : lang == 'ta'
                      ? 'செலவை நீக்கு'
                      : 'Delete Expense',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
                height: 20,
                color: isDark ? Colors.white12 : Colors.grey.shade200),
            Text(
              lang == 'si'
                  ? 'ඔබට සැබවින්ම මෙම වියදම මකා දැමීමට අවශ්‍යද?'
                  : lang == 'ta'
                      ? 'இந்த செலவை நிச்சயமாக நீக்க விரும்புகிறீர்களா?'
                      : 'Are you sure you want to delete this expense?',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppTheme.textLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang == 'si'
                  ? 'අවලංගු'
                  : lang == 'ta'
                      ? 'ரத்து'
                      : 'Cancel',
              style: TextStyle(
                  color: isDark ? Colors.white38 : AppTheme.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              lang == 'si'
                  ? 'මකන්න'
                  : lang == 'ta'
                      ? 'நீக்கு'
                      : 'Delete',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await _plannerService.deleteExpense(widget.expense['_id']);
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
                          ? 'වියදම සාර්ථකව මකා දමන ලදී'
                          : lang == 'ta'
                              ? 'செலவு வெற்றிகரமாக நீக்கப்பட்டது'
                              : 'Expense deleted successfully',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                          ? 'වියදම මැකීම අසාර්ථකයි: $e'
                          : lang == 'ta'
                              ? 'செலவை நீக்க முடியவில்லை: $e'
                              : 'Failed to delete expense: $e',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  // ── Label helper ──────────────────────────────────────────────────
  String _labelFor(Map<String, dynamic> item, String lang) {
    if (lang == 'si') return item['si'] as String;
    if (lang == 'ta') return item['ta'] as String;
    return item['label'] as String;
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _topBarButton(Icons.arrow_back_ios_new_rounded,
                        size: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang == 'si'
                          ? 'වියදම සංස්කරණය'
                          : lang == 'ta'
                              ? 'செலவை திருத்து'
                              : 'Edit Expense',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: (_isDeleting || _isSaving)
                        ? null
                        : () => _deleteExpense(lang, isDark),
                    child: AnimatedOpacity(
                      opacity: (_isDeleting || _isSaving) ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.withOpacity(0.4), width: 1),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: _isDeleting
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 17),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Notification button
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
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

            // ── White / dark body card ────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
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
                                // ════════════════════════════════════════
                                // EXPENSE DETAILS
                                // ════════════════════════════════════════
                                _buildSectionLabel(
                                  lang == 'si'
                                      ? 'වියදම් තොරතුරු'
                                      : lang == 'ta'
                                          ? 'செலவு விவரங்கள்'
                                          : 'EXPENSE DETAILS',
                                  isDark,
                                ),
                                const SizedBox(height: 12),

                                // Description
                                _buildField(
                                  icon: Icons.description_rounded,
                                  label: lang == 'si'
                                      ? 'විස්තරය'
                                      : lang == 'ta'
                                          ? 'விளக்கம்'
                                          : 'Description',
                                  isDark: isDark,
                                  child: _styledTextField(
                                    controller: _descriptionController,
                                    hint: lang == 'si'
                                        ? 'වියදම් විස්තරය ඇතුළත් කරන්න'
                                        : lang == 'ta'
                                            ? 'செலவு விவரம் உள்ளிடுங்கள்'
                                            : 'Enter expense description',
                                    isDark: isDark,
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

                                // Amount
                                _buildField(
                                  icon: Icons.payments_rounded,
                                  label: lang == 'si'
                                      ? 'මුදල (රු.)'
                                      : lang == 'ta'
                                          ? 'தொகை (ரூ.)'
                                          : 'Amount (Rs.)',
                                  isDark: isDark,
                                  child: _styledTextField(
                                    controller: _amountController,
                                    hint: lang == 'si'
                                        ? 'මුදල ඇතුළත් කරන්න'
                                        : lang == 'ta'
                                            ? 'தொகையை உள்ளிடுங்கள்'
                                            : 'Enter amount',
                                    isDark: isDark,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d{0,2}')),
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
                                            ? 'මුදල ශුන්‍ය හෝ ඍණ විය නොහැක'
                                            : lang == 'ta'
                                                ? 'தொகை எதிர்மறையாக இருக்க முடியாது'
                                                : 'Amount cannot be negative or zero';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Supplier (optional)
                                _buildField(
                                  icon: Icons.store_rounded,
                                  label: lang == 'si'
                                      ? 'සැපයුම්කරු (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'உபதேசம் (விருப்பம்)'
                                          : 'Supplier (Optional)',
                                  isDark: isDark,
                                  child: _styledDropdown<String?>(
                                    value: _selectedSupplier,
                                    isDark: isDark,
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
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey.shade500),
                                        ),
                                      ),
                                      ..._suppliers.map((s) =>
                                          DropdownMenuItem<String>(
                                            value: s['value'] as String,
                                            child: Text(
                                              _labelFor(s, lang),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppTheme.textDark),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedSupplier = v),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Payment Method (optional)
                                _buildField(
                                  icon: Icons.payment_rounded,
                                  label: lang == 'si'
                                      ? 'ගෙවීම් ක්‍රමය (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'கட்டுப்படுத்தும் முறை (விருப்பம்)'
                                          : 'Payment Method (Optional)',
                                  isDark: isDark,
                                  child: _styledDropdown<String?>(
                                    value: _selectedPaymentMethod,
                                    isDark: isDark,
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
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey.shade500),
                                        ),
                                      ),
                                      ..._paymentMethods.map((m) =>
                                          DropdownMenuItem<String>(
                                            value: m['value'] as String,
                                            child: Text(
                                              _labelFor(m, lang),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppTheme.textDark),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )),
                                    ],
                                    onChanged: (v) => setState(
                                        () => _selectedPaymentMethod = v),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Quantity + Unit (optional)
                                _buildField(
                                  icon: Icons.inventory_2_rounded,
                                  label: lang == 'si'
                                      ? 'ප්‍රමාණය (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'அளவு (விருப்பம்)'
                                          : 'Quantity (Optional)',
                                  isDark: isDark,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _styledTextField(
                                          controller: _quantityController,
                                          hint: lang == 'si'
                                              ? 'ප්‍රමාණය'
                                              : lang == 'ta'
                                                  ? 'அளவு'
                                                  : 'Qty',
                                          isDark: isDark,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d+\.?\d{0,2}')),
                                          ],
                                          validator: (v) {
                                            if (v != null && v.isNotEmpty) {
                                              if (double.tryParse(v) == null ||
                                                  double.parse(v) <= 0) {
                                                return lang == 'si'
                                                    ? 'වලංගු ප්‍රමාණයක්'
                                                    : lang == 'ta'
                                                        ? 'செல்லுபடியான அளவு'
                                                        : 'Enter valid quantity';
                                              }
                                            }
                                            return null;
                                          },
                                          onChanged: (v) {
                                            final qty = double.tryParse(v);
                                            if (qty != null)
                                              setState(() => _quantity = qty);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: _styledDropdown<String>(
                                          value: _unit,
                                          isDark: isDark,
                                          items: _units
                                              .map((u) =>
                                                  DropdownMenuItem<String>(
                                                    value: u,
                                                    child: Text(
                                                      u.toUpperCase(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? Colors.white
                                                              : AppTheme
                                                                  .textDark),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(
                                              () => _unit = v ?? _unit),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // ════════════════════════════════════════
                                // CATEGORIZATION
                                // ════════════════════════════════════════
                                _buildSectionLabel(
                                  lang == 'si'
                                      ? 'වර්ගීකරණය'
                                      : lang == 'ta'
                                          ? 'வகைப்படுத்தல்'
                                          : 'CATEGORIZATION',
                                  isDark,
                                ),
                                const SizedBox(height: 12),

                                // Category
                                _buildField(
                                  icon: Icons.category_rounded,
                                  label: lang == 'si'
                                      ? 'වර්ගය'
                                      : lang == 'ta'
                                          ? 'வகை'
                                          : 'Category',
                                  isDark: isDark,
                                  child: _styledDropdown<String>(
                                    value: _selectedCategory,
                                    isDark: isDark,
                                    items: _categories
                                        .map((cat) => DropdownMenuItem<String>(
                                              value: cat['value'] as String,
                                              child: Text(
                                                _labelFor(cat, lang),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? Colors.white
                                                        : AppTheme.textDark),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() =>
                                        _selectedCategory =
                                            v ?? _selectedCategory),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Field — only if fields available
                                if (_fields.isNotEmpty) ...[
                                  _buildField(
                                    icon: Icons.agriculture_rounded,
                                    label: lang == 'si'
                                        ? 'ක්ෂේත්‍රය (විකල්ප)'
                                        : lang == 'ta'
                                            ? 'வயல் (விருப்பம்)'
                                            : 'Field (Optional)',
                                    isDark: isDark,
                                    child: _styledDropdown<String?>(
                                      value: _selectedFieldId,
                                      isDark: isDark,
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
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white54
                                                    : AppTheme.textLight),
                                          ),
                                        ),
                                        ..._fields.map((field) =>
                                            DropdownMenuItem<String?>(
                                              value: field['_id'] as String?,
                                              child: Text(
                                                field['name'] as String? ??
                                                    'Unknown',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? Colors.white
                                                        : AppTheme.textDark),
                                              ),
                                            )),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _selectedFieldId = v),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Date
                                _buildField(
                                  icon: Icons.calendar_today_rounded,
                                  label: lang == 'si'
                                      ? 'දිනය'
                                      : lang == 'ta'
                                          ? 'தேதி'
                                          : 'Date',
                                  isDark: isDark,
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context, isDark),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1A1A1A)
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isDark
                                                ? Colors.white12
                                                : Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            DateFormat('MMM dd, yyyy')
                                                .format(_selectedDate),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppTheme.textDark,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: isDark
                                                ? Colors.white38
                                                : AppTheme.textLight,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Recurring Expense (optional)
                                _buildField(
                                  icon: Icons.repeat_rounded,
                                  label: lang == 'si'
                                      ? 'නිදහස් වියදම් (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'மீண்டும் வரும் செலவு (விருப்பம்)'
                                          : 'Recurring Expense (Optional)',
                                  isDark: isDark,
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _isRecurring,
                                        onChanged: (v) => setState(
                                            () => _isRecurring = v ?? false),
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
                                                  child: _styledTextField(
                                                    controller:
                                                        _recurringController,
                                                    hint: '1',
                                                    isDark: isDark,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .digitsOnly
                                                    ],
                                                    onChanged: (v) {
                                                      final interval =
                                                          int.tryParse(v);
                                                      if (interval != null &&
                                                          interval > 0) {
                                                        _recurringInterval =
                                                            interval;
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child:
                                                      _styledDropdown<String>(
                                                    value: _recurringUnit,
                                                    isDark: isDark,
                                                    items: _recurringUnits
                                                        .map((u) =>
                                                            DropdownMenuItem<
                                                                String>(
                                                              value: u['value']
                                                                  as String,
                                                              child: Text(
                                                                _labelFor(
                                                                    u, lang),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: isDark
                                                                        ? Colors
                                                                            .white
                                                                        : AppTheme
                                                                            .textDark),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ))
                                                        .toList(),
                                                    onChanged: (v) {
                                                      if (!_isRecurring ||
                                                          v == null) return;
                                                      setState(() =>
                                                          _recurringUnit = v);
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

                                // Attach Receipt (optional)
                                _buildField(
                                  icon: Icons.receipt_long_rounded,
                                  label: lang == 'si'
                                      ? 'රිසිට් එකතු කරන්න (විකල්ප)'
                                      : lang == 'ta'
                                          ? 'ரசீது இணைக்கவும் (விருப்பம்)'
                                          : 'Attach Receipt (Optional)',
                                  isDark: isDark,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _attachReceipt = !_attachReceipt),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _attachReceipt
                                            ? AppTheme.primaryGreen
                                                .withOpacity(0.1)
                                            : (isDark
                                                ? const Color(0xFF1A1A1A)
                                                : Colors.grey.shade50),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _attachReceipt
                                              ? AppTheme.primaryGreen
                                              : (isDark
                                                  ? Colors.white12
                                                  : Colors.grey.shade200),
                                          width: _attachReceipt ? 2 : 1,
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
                                                : (isDark
                                                    ? Colors.white38
                                                    : Colors.grey.shade600),
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
                                                fontSize: 13,
                                                fontWeight: _attachReceipt
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: _attachReceipt
                                                    ? AppTheme.primaryGreen
                                                    : (isDark
                                                        ? Colors.white54
                                                        : Colors.grey.shade600),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Update button
                                _buildUpdateButton(lang, isDark),
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

  // ════════════════════════════════════════════════════════════════════
  // WIDGET HELPERS
  // ════════════════════════════════════════════════════════════════════

  Widget _topBarButton(IconData icon, {double size = 18}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2)),
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
          gradient:
              const LinearGradient(colors: [Colors.redAccent, Colors.red]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 4)
          ],
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.1),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color:
                isDark ? Colors.white38 : AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required Widget child,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.primaryGreen),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _buildUpdateButton(String lang, bool isDark) {
    final bool isDisabled = _isSaving || _isDeleting;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: isDisabled ? null : () => _updateExpense(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: isDisabled
                    ? (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300)
                    : null,
                gradient: isDisabled
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen.withOpacity(0.85)
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    )
                  else
                    Icon(Icons.save_rounded,
                        color: isDisabled
                            ? (isDark ? Colors.white24 : Colors.grey.shade500)
                            : Colors.white,
                        size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _isSaving
                        ? (lang == 'si'
                            ? 'සුරකිමින්...'
                            : lang == 'ta'
                                ? 'சேமிக்கிறது...'
                                : 'Saving...')
                        : (lang == 'si'
                            ? 'වියදම යාවත්කාලීන කරන්න'
                            : lang == 'ta'
                                ? 'செலவை புதுப்பிக்கவும்'
                                : 'Update Expense'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isDisabled
                          ? (isDark ? Colors.white24 : Colors.grey.shade500)
                          : Colors.white,
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

  Widget _styledTextField({
    TextEditingController? controller,
    required String hint,
    required bool isDark,
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
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppTheme.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white24 : Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Widget _styledDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isDark,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      iconEnabledColor: isDark ? Colors.white38 : AppTheme.textLight,
      elevation: 8,
      hint: hint != null
          ? Text(hint,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white24 : Colors.grey.shade400))
          : null,
      style: TextStyle(
          fontSize: 12, color: isDark ? Colors.white : AppTheme.textDark),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
