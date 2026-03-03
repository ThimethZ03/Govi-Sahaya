import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/routes.dart';
import '../../services/backend_planner_service.dart';

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final BackendPlannerService _plannerService = BackendPlannerService();

  bool _isSaving = false;
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
    _animationController.forward();
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang == 'si'
                        ? 'ක්ෂේත්‍රය සාර්ථකව එකතු කරන ලදී'
                        : lang == 'ta'
                            ? 'வயல் வெற்றிகரமாக சேர்க்கப்பட்டது'
                            : 'Field added successfully',
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
                        ? 'ක්ෂේත්‍රය එකතු කිරීම අසාර්ථකයි: $e'
                        : lang == 'ta'
                            ? 'வயல் சேர்க்க முடியவில்லை: $e'
                            : 'Failed to add field: $e',
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
      if (mounted) setState(() => _isSaving = false);
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

            // ── White / Dark Body ────────────────────────────────────
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                          setState(
                                              () => _selectedUnit = v!);
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
        color: isDark ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50,
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

  // ── Notification Badge ─────────────────────────────────────────────
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

  // ── Premium Section Label ──────────────────────────────────────────
  Widget _buildPremiumSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.8),
              ],
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
            fontWeight: FontWeight.w800,
            color: isDark
                ? Colors.white38
                : AppTheme.textDark.withOpacity(0.85),
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: _isSaving ? null : () => _saveField(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSaving
                      ? (isDark
                          ? [
                              const Color(0xFF2A2A2A),
                              const Color(0xFF1A1A1A),
                            ]
                          : [
                              Colors.grey.shade400,
                              Colors.grey.shade300,
                            ])
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
                    const Icon(Icons.save_rounded,
                        color: Colors.white, size: 18),
                  const SizedBox(width: 10),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isSaving && isDark
                          ? Colors.white24
                          : Colors.white,
                      letterSpacing: 0.5,
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
        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1.5,
          ),
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

  // ── Styled Dropdown ────────────────────────────────────────────────
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
      dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      iconEnabledColor: isDark ? Colors.white38 : AppTheme.textLight,
      elevation: 8,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : AppTheme.textDark,
      ),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1.5,
          ),
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
    );
  }
}