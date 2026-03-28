import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/routes.dart';
import '../../services/backend_planner_service.dart';

class EditFieldScreen extends StatefulWidget {
  final Map<String, dynamic> field;

  const EditFieldScreen({super.key, required this.field});

  @override
  State<EditFieldScreen> createState() => _EditFieldScreenState();
}

class _EditFieldScreenState extends State<EditFieldScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _budgetController;
  late final TextEditingController _locationController;
  late final TextEditingController _cropTypeController;
  final BackendPlannerService _plannerService = BackendPlannerService();

  bool _isLoading = false;
  String _selectedUnit = 'acres';
  bool _showAreaPreview = false;
  double _areaPreviewValue = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _areaUnits = [
    {'value': 'acres', 'label': 'Acres', 'si': 'අක්කර', 'ta': 'ஏக்கர்'},
    {'value': 'hectares', 'label': 'Ha', 'si': 'හෙක්ටෙයාර්', 'ta': 'ஹெக்டேர்'},
    {'value': 'perches', 'label': 'Perch', 'si': 'පර්ච', 'ta': 'பர்ச்'},
    {'value': 'square_meters', 'label': 'Sq.m', 'si': 'ව.මී', 'ta': 'சதுர மீ'},
  ];

  final Map<String, double> _unitFactors = {
    'acres': 0.4047,
    'hectares': 1.0,
    'perches': 0.002029,
    'square_meters': 0.0001,
  };

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
    _initializeControllers();
    _animationController.forward();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.field['name'] ?? '');

    final areaValue = widget.field['area'];
    if (areaValue is Map) {
      _selectedUnit = areaValue['unit'] ?? 'acres';
      _areaController =
          TextEditingController(text: areaValue['value']?.toString() ?? '');
    } else {
      _areaController = TextEditingController();
    }

    _budgetController =
        TextEditingController(text: (widget.field['budget'] ?? 0).toString());

    final location = widget.field['location'];
    _locationController = TextEditingController(
        text: (location is Map ? location['address'] : null) ?? '');

    final crop = widget.field['currentCrop'];
    _cropTypeController = TextEditingController(
        text: (crop is Map ? crop['cropName'] : null) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _cropTypeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateAreaPreview(String? value) {
    if (value != null && value.isNotEmpty) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        setState(() {
          _areaPreviewValue = parsed * (_unitFactors[_selectedUnit] ?? 1.0);
          _showAreaPreview = true;
        });
      } else {
        setState(() => _showAreaPreview = false);
      }
    } else {
      setState(() => _showAreaPreview = false);
    }
  }

  Future<void> _saveField(String lang) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
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
      await _plannerService.updateField(widget.field['_id'], fieldData);
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
                        ? 'ක්ෂේත්‍රය සාර්ථකව යාවත්කාලීන කරන ලදී'
                        : lang == 'ta'
                            ? 'வயல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது'
                            : 'Field updated successfully',
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
                        ? 'ක්ෂේත්‍රය යාවත්කාලීන කිරීම අසාර්ථකයි: $e'
                        : lang == 'ta'
                            ? 'வயல் புதுப்பிக்க முடியவில்லை: $e'
                            : 'Failed to update field: $e',
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                          ? 'ක්ෂේත්‍රය සංස්කරණය'
                          : lang == 'ta'
                              ? 'வயலை திருத்துக'
                              : 'Edit Field',
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

            // ── White / Dark Body ────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Basic Info ───────────────────────────
                          _buildPremiumSectionLabel(
                            lang == 'si'
                                ? 'ක්ෂේත්‍ර තොරතුරු'
                                : lang == 'ta'
                                    ? 'வயல் விவரங்கள்'
                                    : 'FIELD DETAILS',
                            isDark,
                          ),
                          const SizedBox(height: 12),

                          _buildPremiumField(
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

                          // ── Area Row ─────────────────────────────
                          _buildPremiumField(
                            icon: Icons.square_foot_rounded,
                            label: lang == 'si'
                                ? 'ප්‍රදේශය'
                                : lang == 'ta'
                                    ? 'பரப்பளவு'
                                    : 'Area',
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
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
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d{0,2}'),
                                          ),
                                        ],
                                        isDark: isDark,
                                        onChanged: _updateAreaPreview,
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
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppTheme.textDark,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (v) {
                                          setState(() => _selectedUnit = v!);
                                          _updateAreaPreview(
                                              _areaController.text);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (_showAreaPreview) ...[
                                  const SizedBox(height: 8),
                                  _buildAreaPreview(isDark),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildPremiumField(
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
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

                          // ── Optional Info ────────────────────────
                          _buildPremiumSectionLabel(
                            lang == 'si'
                                ? 'අතිරේක තොරතුරු (විකල්ප)'
                                : lang == 'ta'
                                    ? 'கூடுதல் தகவல் (விருப்பம்)'
                                    : 'ADDITIONAL INFO (OPTIONAL)',
                            isDark,
                          ),
                          const SizedBox(height: 12),

                          _buildPremiumField(
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

                          _buildPremiumField(
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

                          _buildPremiumSaveButton(lang, isDark),
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

  // ── Area Preview ───────────────────────────────────────────────────
  Widget _buildAreaPreview(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.green.shade900.withOpacity(0.4)
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.green.shade700 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility,
              size: 16,
              color: isDark ? Colors.green.shade400 : Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_areaPreviewValue.toStringAsFixed(2)} Ha (${_selectedUnit.toUpperCase()})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.green.shade400 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar Button ─────────────────────────────────────────────────
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
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 2),
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

  // ── Premium Section Label ──────────────────────────────────────────
  Widget _buildPremiumSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color:
                isDark ? Colors.white60 : AppTheme.textDark.withOpacity(0.85),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Premium Field Wrapper ──────────────────────────────────────────
  Widget _buildPremiumField({
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
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
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppTheme.textDark,
                  letterSpacing: 0.3,
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

  // ── Premium Save Button ────────────────────────────────────────────
  Widget _buildPremiumSaveButton(String lang, bool isDark) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _saveField(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: _isLoading
              ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
              : AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
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
              _isLoading
                  ? (lang == 'si'
                      ? 'යාවත්කාලීන කරමින්...'
                      : lang == 'ta'
                          ? 'புதுப்பிக்கிறது...'
                          : 'Updating...')
                  : (lang == 'si'
                      ? 'ක්ෂේත්‍රය යාවත්කාලීන කරන්න'
                      : lang == 'ta'
                          ? 'வயலை புதுப்பிக்கவும்'
                          : 'Update Field'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Styled Text Form Field ─────────────────────────────────────────
  Widget _styledTextFormField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : AppTheme.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white24 : Colors.grey.shade500,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  // ── Styled Dropdown ────────────────────────────────────────────────
  Widget _styledDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        isExpanded: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : AppTheme.textDark,
        ),
      ),
    );
  }
}
