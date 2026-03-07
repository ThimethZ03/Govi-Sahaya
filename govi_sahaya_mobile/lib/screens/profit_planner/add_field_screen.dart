import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart'; // ✅ NEW
import '../../config/routes.dart';
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
    {'value': 'acres', 'label': 'Acres', 'si': 'අක්කර', 'ta': 'ஏக்கர்'},
    {'value': 'hectares', 'label': 'Ha', 'si': 'හෙක්ටෙයාර්', 'ta': 'ஹெக்டேர்'},
    {'value': 'perches', 'label': 'Perch', 'si': 'පර්ච', 'ta': 'பர்ச்'},
    {'value': 'square_meters', 'label': 'Sq.m', 'si': 'ව.මී', 'ta': 'சதுர மீ'},
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

  Future<void> _saveField(String lang) async {
    if (!_formKey.currentState!.validate()) return;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'ක්ෂේත්‍රය සාර්ථකව එකතු කරන ලදී'
              : lang == 'ta'
                  ? 'வயல் வெற்றிகரமாக சேர்க்கப்பட்டது'
                  : 'Field added successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'ක්ෂේත්‍රය එකතු කිරීම අසාර්ථකයි: $e'
              : lang == 'ta'
                  ? 'வயல் சேர்க்க முடியவில்லை: $e'
                  : 'Failed to add field: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                          ? 'ක්ෂේත්‍රයක් එකතු කරන්න'
                          : lang == 'ta'
                              ? 'வயல் சேர்க்கவும்'
                              : 'Add Field',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Basic Info ───────────────────────────────
                        _buildSectionLabel(
                            lang == 'si'
                                ? 'ක්ෂේත්‍ර තොරතුරු'
                                : lang == 'ta'
                                    ? 'வயல் விவரங்கள்'
                                    : 'FIELD DETAILS',
                            isDark),
                        const SizedBox(height: 12),

                        _buildField(
                          icon: Icons.agriculture_rounded,
                          label: lang == 'si'
                              ? 'ක්ෂේත්‍ර නාමය'
                              : lang == 'ta'
                                  ? 'வயல் பெயர்'
                                  : 'Field Name',
                          isDark: isDark,
                          child: _styledTextFormField(
                            controller: _nameController,
                            hint: lang == 'si'
                                ? 'උදා: උතුරු ක්ෂේත්‍රය'
                                : lang == 'ta'
                                    ? 'எ.கா.: வடக்கு வயல்'
                                    : 'e.g., North Field',
                            isDark: isDark,
                            validator: (v) => (v == null || v.isEmpty)
                                ? (lang == 'si'
                                    ? 'ක්ෂේත්‍ර නාමය ඇතුළත් කරන්න'
                                    : lang == 'ta'
                                        ? 'வயல் பெயர் உள்ளிடுங்கள்'
                                        : 'Please enter field name')
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Area Row ─────────────────────────────────
                        _buildField(
                          icon: Icons.square_foot_rounded,
                          label: lang == 'si'
                              ? 'ප්‍රදේශය'
                              : lang == 'ta'
                                  ? 'பரப்பளவு'
                                  : 'Area',
                          isDark: isDark,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _styledTextFormField(
                                  controller: _areaController,
                                  hint: lang == 'si'
                                      ? 'ප්‍රදේශය ඇතුළත් කරන්න'
                                      : lang == 'ta'
                                          ? 'பரப்பளவு உள்ளிடுங்கள்'
                                          : 'Enter area',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'))
                                  ],
                                  isDark: isDark,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return lang == 'si'
                                          ? 'ප්‍රදේශය ඇතුළත් කරන්න'
                                          : lang == 'ta'
                                              ? 'பரப்பளவு உள்ளிடுங்கள்'
                                              : 'Please enter area';
                                    }
                                    if (double.tryParse(v) == null) {
                                      return lang == 'si'
                                          ? 'වලංගු නොවේ'
                                          : lang == 'ta'
                                              ? 'செல்லுபடியற்றது'
                                              : 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: _styledDropdown<String>(
                                  value: _selectedUnit,
                                  isDark: isDark,
                                  items: _areaUnits.map((unit) {
                                    final label = lang == 'si'
                                        ? unit['si']!
                                        : lang == 'ta'
                                            ? unit['ta']!
                                            : unit['label']!;
                                    return DropdownMenuItem<String>(
                                      value: unit['value'],
                                      child: Text(label,
                                          style: TextStyle(
                                              fontSize: 12,
                                              // ✅ dark mode dropdown item
                                              color: isDark
                                                  ? Colors.white
                                                  : AppTheme.textDark),
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedUnit = v!),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          icon: Icons.account_balance_wallet_rounded,
                          label: lang == 'si'
                              ? 'අයවැය (රු.)'
                              : lang == 'ta'
                                  ? 'பட்ஜெட் (ரூ.)'
                                  : 'Budget (Rs.)',
                          isDark: isDark,
                          child: _styledTextFormField(
                            controller: _budgetController,
                            hint: lang == 'si'
                                ? 'ක්ෂේත්‍රය සඳහා අයවැය ඇතුළත් කරන්න'
                                : lang == 'ta'
                                    ? 'வயலுக்கான பட்ஜெட் உள்ளிடுங்கள்'
                                    : 'Enter your budget for this field',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                            isDark: isDark,
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                if (double.tryParse(v) == null) {
                                  return lang == 'si'
                                      ? 'වලංගු මුදලක් ඇතුළත් කරන්න'
                                      : lang == 'ta'
                                          ? 'செல்லுபடியான தொகை உள்ளிடுங்கள்'
                                          : 'Please enter a valid amount';
                                }
                                if (double.parse(v) < 0) {
                                  return lang == 'si'
                                      ? 'අයවැය ඍණාත්මක විය නොහැක'
                                      : lang == 'ta'
                                          ? 'பட்ஜெட் எதிர்மறையாக இருக்க முடியாது'
                                          : 'Budget cannot be negative';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Optional Info ────────────────────────────
                        _buildSectionLabel(
                            lang == 'si'
                                ? 'අතිරේක තොරතුරු (විකල්ප)'
                                : lang == 'ta'
                                    ? 'கூடுதல் தகவல் (விருப்பம்)'
                                    : 'ADDITIONAL INFO (OPTIONAL)',
                            isDark),
                        const SizedBox(height: 12),

                        _buildField(
                          icon: Icons.location_on_rounded,
                          label: lang == 'si'
                              ? 'ස්ථානය'
                              : lang == 'ta'
                                  ? 'இடம்'
                                  : 'Location',
                          isDark: isDark,
                          child: _styledTextFormField(
                            controller: _locationController,
                            hint: lang == 'si'
                                ? 'උදා: ගංගාව අසල'
                                : lang == 'ta'
                                    ? 'எ.கா.: ஆற்றின் அருகில்'
                                    : 'e.g., Near the river',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          icon: Icons.grass_rounded,
                          label: lang == 'si'
                              ? 'වර්තමාන බෝගය'
                              : lang == 'ta'
                                  ? 'தற்போதைய பயிர்'
                                  : 'Current Crop',
                          isDark: isDark,
                          child: _styledTextFormField(
                            controller: _cropTypeController,
                            hint: lang == 'si'
                                ? 'උදා: හාල්, තිරිඟු'
                                : lang == 'ta'
                                    ? 'எ.கா.: அரிசி, கோதுமை'
                                    : 'e.g., Rice, Wheat',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Save Button
                        GestureDetector(
                          onTap: _isSaving ? null : () => _saveField(lang),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                                        color: Colors.white, strokeWidth: 2),
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
                                          ? 'ක්ෂේත්‍රය සුරකින්න'
                                          : lang == 'ta'
                                              ? 'வயலை சேமிக்கவும்'
                                              : 'Save Field'),
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
          fontSize: 12,
          // ✅ dark mode input text
          color: isDark ? Colors.white : AppTheme.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 12,
            // ✅ dark mode hint text
            color: isDark ? Colors.white24 : Colors.grey.shade400),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        // ✅ dark mode fill color
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
      // ✅ dark mode dropdown arrow
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
