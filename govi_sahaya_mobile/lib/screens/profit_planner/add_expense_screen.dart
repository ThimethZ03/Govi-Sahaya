import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart'; // ✅ NEW
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
  final BackendPlannerService _plannerService = BackendPlannerService();

  String _selectedCategory = 'fertilizers';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  List<dynamic> _fields = [];
  String? _selectedFieldId;
  bool _isLoadingFields = true;

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
      'ta': 'உபகரணங்கள்'
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
    super.dispose();
  }

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
      };
      await _plannerService.createExpense(expenseData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'වියදම සාර්ථකව එකතු කරන ලදී'
              : lang == 'ta'
                  ? 'செலவு வெற்றிகரமாக சேர்க்கப்பட்டது'
                  : 'Expense added successfully'),
          backgroundColor: AppTheme.primaryGreen,
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

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final isDark = context.watch<ThemeProvider>().isDark; // ✅ NEW

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
                          ? 'වියදමක් එකතු කරන්න'
                          : lang == 'ta'
                              ? 'செலவு சேர்க்கவும்'
                              : 'Add Expense',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
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

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // ✅ dark mode body bg
                  color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: _isLoadingFields
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionLabel(
                                  lang == 'si'
                                      ? 'වියදම් තොරතුරු'
                                      : lang == 'ta'
                                          ? 'செலவு விவரங்கள்'
                                          : 'EXPENSE DETAILS',
                                  isDark),
                              const SizedBox(height: 12),

                              _buildField(
                                icon: Icons.description_rounded,
                                label: lang == 'si'
                                    ? 'විස්තරය'
                                    : lang == 'ta'
                                        ? 'விளக்கம்'
                                        : 'Description',
                                isDark: isDark,
                                child: _styledTextFormField(
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

                              _buildField(
                                icon: Icons.payments_rounded,
                                label: lang == 'si'
                                    ? 'මුදල (රු.)'
                                    : lang == 'ta'
                                        ? 'தொகை (ரூ.)'
                                        : 'Amount (Rs.)',
                                isDark: isDark,
                                child: _styledTextFormField(
                                  controller: _amountController,
                                  hint: lang == 'si'
                                      ? 'මුදල ඇතුළත් කරන්න'
                                      : lang == 'ta'
                                          ? 'தொகையை உள்ளிடுங்கள்'
                                          : 'Enter amount',
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
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
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildSectionLabel(
                                  lang == 'si'
                                      ? 'වර්ගීකරණය'
                                      : lang == 'ta'
                                          ? 'வகைப்படுத்தல்'
                                          : 'CATEGORIZATION',
                                  isDark),
                              const SizedBox(height: 12),

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
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat['value'] as String,
                                      child: Text(_categoryLabel(cat, lang),
                                          style: TextStyle(
                                              fontSize: 12,
                                              // ✅ dark mode dropdown item text
                                              color: isDark
                                                  ? Colors.white
                                                  : AppTheme.textDark)),
                                    );
                                  }).toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedCategory = v!),
                                ),
                              ),
                              const SizedBox(height: 12),

                              if (_fields.isNotEmpty)
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
                                              // ✅ dark mode "none" text
                                              color: isDark
                                                  ? Colors.white54
                                                  : AppTheme.textLight),
                                        ),
                                      ),
                                      ..._fields.map(
                                          (field) => DropdownMenuItem<String?>(
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
                              if (_fields.isNotEmpty)
                                const SizedBox(height: 12),

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
                                      // ✅ dark mode date picker bg
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
                                              // ✅ dark mode date text
                                              color: isDark
                                                  ? Colors.white
                                                  : AppTheme.textDark),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          // ✅ dark mode dropdown arrow
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
                              const SizedBox(height: 20),

                              // Save Button
                              GestureDetector(
                                onTap:
                                    _isSaving ? null : () => _saveExpense(lang),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    // ✅ dark mode disabled button bg
                                    color: _isSaving
                                        ? (isDark
                                            ? const Color(0xFF2A2A2A)
                                            : Colors.grey.shade300)
                                        : AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: _isSaving
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: AppTheme.primaryGreen
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isSaving)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      else
                                        const Icon(Icons.save_rounded,
                                            color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
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
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          // ✅ dark mode disabled text
                                          color: _isSaving
                                              ? (isDark
                                                  ? Colors.white24
                                                  : Colors.grey.shade500)
                                              : Colors.white,
                                        ),
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

  // ── Top Bar Button — always on green header ────────────────────────
  Widget _topBarButton(IconData icon, {double size = 18}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  // ── Notification Badge ─────────────────────────────────────────────
  Widget _notificationBadge(int count) {
    return Positioned(
      top: -3,
      right: -3,
      child: Container(
        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1.1),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              // ✅ dark mode section label
              color:
                  isDark ? Colors.white38 : AppTheme.textLight.withOpacity(0.7),
              letterSpacing: 1.5,
            )),
      ],
    );
  }

  // ── Field Wrapper ──────────────────────────────────────────────────
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
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    // ✅ dark mode field label
                    color: isDark ? Colors.white70 : AppTheme.textDark)),
          ],
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  // ── Text Form Field ────────────────────────────────────────────────
  Widget _styledTextFormField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
          fontSize: 12,
          // ✅ dark mode input text
          color: isDark ? Colors.white : AppTheme.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 12,
            // ✅ dark mode hint
            color: isDark ? Colors.white24 : Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        // ✅ dark mode fill
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

  // ── Dropdown ───────────────────────────────────────────────────────
  Widget _styledDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      // ✅ dark mode dropdown panel bg
      dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      // ✅ dark mode dropdown arrow color
      iconEnabledColor: isDark ? Colors.white38 : AppTheme.textLight,
      style: TextStyle(
          fontSize: 12, color: isDark ? Colors.white : AppTheme.textDark),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        // ✅ dark mode dropdown fill
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
