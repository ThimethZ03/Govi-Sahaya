import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/routes.dart';
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
      setState(() => _isLoadingFields = false);
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

  Future<void> _updateExpense(String lang) async {
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
      await _plannerService.updateExpense(widget.expense['_id'], expenseData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'වියදම සාර්ථකව යාවත්කාලීන කරන ලදී'
              : lang == 'ta'
                  ? 'செலவு வெற்றிகரமாக புதுப்பிக்கப்பட்டது'
                  : 'Expense updated successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'යාවත්කාලීන කිරීම අසාර්ථකයි: $e'
              : lang == 'ta'
                  ? 'புதுப்பிக்க முடியவில்லை: $e'
                  : 'Failed to update expense: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteExpense(String lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10)),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 20),
            Text(
              lang == 'si'
                  ? 'ඔබට සැබවින්ම මෙම වියදම මකා දැමීමට අවශ්‍යද?'
                  : lang == 'ta'
                      ? 'இந்த செலவை நிச்சயமாக நீக்க விரும்புகிறீர்களா?'
                      : 'Are you sure you want to delete this expense?',
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
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
              style: const TextStyle(color: AppTheme.textLight),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(lang == 'si'
                ? 'වියදම සාර්ථකව මකා දමන ලදී'
                : lang == 'ta'
                    ? 'செலவு வெற்றிகரமாக நீக்கப்பட்டது'
                    : 'Expense deleted successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(lang == 'si'
                ? 'වියදම මැකීම අසාර්ථකයි: $e'
                : lang == 'ta'
                    ? 'செலவை நீக்க முடியவில்லை: $e'
                    : 'Failed to delete expense: $e'),
          ));
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
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

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────
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
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Delete button
                  GestureDetector(
                    onTap: (_isDeleting || _isSaving)
                        ? null
                        : () => _deleteExpense(lang),
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
                  // Notification
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

            // ── White Body ────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
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
                              _buildSectionLabel(lang == 'si'
                                  ? 'වියදම් තොරතුරු'
                                  : lang == 'ta'
                                      ? 'செலவு விவரங்கள்'
                                      : 'EXPENSE DETAILS'),
                              const SizedBox(height: 12),

                              _buildField(
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

                              _buildField(
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
                                  keyboardType: TextInputType.number,
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
                              const SizedBox(height: 12),

                              _buildSectionLabel(lang == 'si'
                                  ? 'වර්ගීකරණය'
                                  : lang == 'ta'
                                      ? 'வகைப்படுத்தல்'
                                      : 'CATEGORIZATION'),
                              const SizedBox(height: 12),

                              _buildField(
                                icon: Icons.category_rounded,
                                label: lang == 'si'
                                    ? 'වර්ගය'
                                    : lang == 'ta'
                                        ? 'வகை'
                                        : 'Category',
                                child: _styledDropdown<String>(
                                  value: _selectedCategory,
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat['value'] as String,
                                      child: Text(_categoryLabel(cat, lang),
                                          style: const TextStyle(fontSize: 12)),
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
                                  child: _styledDropdown<String?>(
                                    value: _selectedFieldId,
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(
                                          lang == 'si'
                                              ? 'ක්ෂේත්‍රයක් තෝරා නැත'
                                              : lang == 'ta'
                                                  ? 'வயல் தேர்ந்தெடுக்கவில்லை'
                                                  : 'No field selected',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      ..._fields.map((field) =>
                                          DropdownMenuItem<String?>(
                                            value: field['_id'] as String?,
                                            child: Text(
                                              field['name'] as String? ??
                                                  'Unknown',
                                              style:
                                                  const TextStyle(fontSize: 12),
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
                                child: GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(_selectedDate),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textDark),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                            Icons.arrow_drop_down_rounded,
                                            color: AppTheme.textLight,
                                            size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Update Button
                              GestureDetector(
                                onTap: (_isSaving || _isDeleting)
                                    ? null
                                    : () => _updateExpense(lang),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: (_isSaving || _isDeleting)
                                        ? Colors.grey.shade300
                                        : AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: (_isSaving || _isDeleting)
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
                                        Icon(
                                          Icons.save_rounded,
                                          color: (_isSaving || _isDeleting)
                                              ? Colors.grey.shade500
                                              : Colors.white,
                                          size: 16,
                                        ),
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
                                          color: (_isSaving || _isDeleting)
                                              ? Colors.grey.shade500
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

  Widget _buildSectionLabel(String label) {
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
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppTheme.textLight.withOpacity(0.7),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.primaryGreen),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
          ],
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _styledTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
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
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
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
