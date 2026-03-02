import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart'; // ✅ NEW
import '../../services/backend_planner_service.dart';
import '../../services/in_app_notification_service.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final BackendPlannerService _plannerService = BackendPlannerService();

  bool _isLoading = false;
  Map<String, dynamic>? _stats;
  List<dynamic> _fields = [];
  List<dynamic> _recentExpenses = [];

  NotificationProvider? _notificationProvider;

  @override
  void initState() {
    super.initState();
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notificationProvider = context.read<NotificationProvider>();
        _notificationProvider!.attachContext(context);
      }
    });
  }

  @override
  void dispose() {
    _notificationProvider?.detachContext();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _plannerService.getExpenseStats(),
        _plannerService.getAllFields(isActive: true),
        _plannerService.getAllExpenses(limit: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _fields = results[1] as List<dynamic>;
        _recentExpenses =
            (results[2] as Map<String, dynamic>)['data'] as List<dynamic>;
        _isLoading = false;
      });

      if (mounted) {
        await _checkBudgetPopups();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final lang = context.read<LanguageProvider>().languageCode;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang == 'si'
            ? 'දත්ත පූරණය අසාර්ථකයි: $e'
            : lang == 'ta'
                ? 'தரவு ஏற்ற முடியவில்லை: $e'
                : 'Failed to load data: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _checkBudgetPopups() async {
    if (!mounted || _fields.isEmpty) return;

    for (final field in _fields) {
      final budget = (field['budget'] ?? 0).toDouble();
      final spent = (field['totalSpent'] ?? 0).toDouble();
      final name = field['name'] ?? 'Unknown Field';
      final percentage = field['percentageUsed'] ?? 0;

      if (budget <= 0) continue;

      String? title;
      String? message;
      String type = 'price_alert';

      if (percentage > 100) {
        final over = (spent - budget).toStringAsFixed(2);
        title = '🚨 Budget Exceeded!';
        message = '$name exceeded by Rs. $over';
        type = 'price_alert';
      } else if (percentage >= 90) {
        title = '⚠️ Budget Warning';
        message = '$name used $percentage% of budget';
        type = 'price_alert';
      } else if (percentage >= 75) {
        title = '💡 Budget Alert';
        message = '$name used $percentage% of budget';
        type = 'price_alert';
      }

      if (title != null && message != null && mounted) {
        await InAppNotificationService().show(
          context: context,
          title: title,
          message: message,
          type: type,
          priority: percentage > 100 ? 'urgent' : 'normal',
          onTap: () {
            if (mounted) {
              Navigator.pushNamed(context, AppRoutes.notifications);
            }
          },
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _showDeleteFieldDialog(
      String fieldId, String fieldName, String lang, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        // ✅ dark mode dialog bg
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  // ✅ dark mode delete icon container
                  color: isDark
                      ? Colors.red.shade900.withOpacity(0.3)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lang == 'si'
                    ? 'ක්ෂේත්‍රය මකන්න'
                    : lang == 'ta'
                        ? 'வயலை நீக்கு'
                        : 'Delete Field',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // ✅ dark mode dialog title
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
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
                // ✅ dark mode divider
                color: isDark ? Colors.white12 : Colors.grey.shade200),
            Text(
              lang == 'si'
                  ? '"$fieldName" මකා දැමීමට ඔබට විශ්වාසද?'
                  : lang == 'ta'
                      ? '"$fieldName" நீக்க விரும்புகிறீர்களா?'
                      : 'Are you sure you want to delete "$fieldName"?',
              style: TextStyle(
                  fontSize: 12,
                  // ✅ dark mode dialog content text
                  color: isDark ? Colors.white70 : AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  // ✅ dark mode warning box
                  color: isDark
                      ? Colors.red.shade900.withOpacity(0.2)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark
                          ? Colors.red.shade800.withOpacity(0.4)
                          : Colors.red.shade100)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang == 'si'
                          ? 'මෙම ක්ෂේත්‍රයට සම්බන්ධ සියලු වියදම් ද ස්ථිරවම මකා දැමේ.'
                          : lang == 'ta'
                              ? 'இந்த வயலுடன் தொடர்புடைய அனைத்து செலவுகளும் நிரந்தரமாக நீக்கப்படும்.'
                              : 'All expenses related to this field will also be deleted permanently.',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.red.shade300
                              : Colors.red.shade700,
                          height: 1.4),
                    ),
                  ),
                ],
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
                  // ✅ dark mode cancel
                  color: isDark ? Colors.white54 : AppTheme.textLight),
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
    if (confirmed == true) await _deleteField(fieldId, lang);
  }

  Future<void> _deleteField(String fieldId, String lang) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'ක්ෂේත්‍රය මකමින්...'
              : lang == 'ta'
                  ? 'வயல் நீக்கப்படுகிறது...'
                  : 'Deleting field...'),
          duration: const Duration(seconds: 1),
        ));
      }
      await _plannerService.deleteField(fieldId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'ක්ෂේත්‍රය සහ වියදම් සාර්ථකව මකා දමන ලදී'
              : lang == 'ta'
                  ? 'வயல் மற்றும் செலவுகள் வெற்றிகரமாக நீக்கப்பட்டன'
                  : 'Field and related expenses deleted successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ));
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang == 'si'
              ? 'ක්ෂේත්‍රය මැකීම අසාර්ථකයි: $e'
              : lang == 'ta'
                  ? 'வயல் நீக்க முடியவில்லை: $e'
                  : 'Failed to delete field: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Color _getCategoryColor(String category) {
    const colors = {
      'fertilizers': AppTheme.primaryGreen,
      'seeds': Colors.orange,
      'pesticides': Colors.red,
      'labor': Colors.purple,
      'equipment': Colors.blue,
      'irrigation': Colors.cyan,
      'transportation': Colors.amber,
      'other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  String _formatCategory(String category, String lang) {
    const si = {
      'fertilizers': 'පොහොර',
      'seeds': 'බීජ',
      'pesticides': 'පළිබෝධනාශක',
      'labor': 'ශ්‍රම',
      'equipment': 'උපකරණ',
      'irrigation': 'වාරිමාර්ග',
      'transportation': 'ප්‍රවාහන',
      'other': 'වෙනත්',
    };
    const ta = {
      'fertilizers': 'உரங்கள்',
      'seeds': 'விதைகள்',
      'pesticides': 'பூச்சிக்கொல்லி',
      'labor': 'தொழிலாளர்',
      'equipment': 'உபகரணங்கள்',
      'irrigation': 'நீர்ப்பாசனம்',
      'transportation': 'போக்குவரத்து',
      'other': 'மற்றவை',
    };
    if (lang == 'si') return si[category] ?? _cap(category);
    if (lang == 'ta') return ta[category] ?? _cap(category);
    return _cap(category);
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Build ──────────────────────────────────────────────────────────
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
            // ── Top Bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _topBtn(Icons.arrow_back_ios_new_rounded, size: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'si'
                              ? 'ලාභ සැලසුම්කරු'
                              : lang == 'ta'
                                  ? 'லாப திட்டமிடல்'
                                  : 'Profit Planner',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (_fields.isNotEmpty)
                          Text(
                            lang == 'si'
                                ? '${_fields.length} ක්ෂේත්‍ර'
                                : lang == 'ta'
                                    ? '${_fields.length} வயல்கள்'
                                    : '${_fields.length} active fields',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                          context, AppRoutes.addExpense);
                      if (result == true) await _loadData();
                    },
                    child: _topBtn(Icons.add_rounded, size: 20),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loadData,
                    child: _topBtn(Icons.refresh_rounded, size: 18),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _topBtn(Icons.notifications_outlined, size: 18),
                        if (unreadCount > 0) _badge(unreadCount),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Body ────────────────────────────────────────────────
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primaryGreen,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Overview ──────────────────────────
                              if (_stats != null) ...[
                                _sectionLabel(
                                    lang == 'si'
                                        ? 'සාරාංශය'
                                        : lang == 'ta'
                                            ? 'சுருக்கம்'
                                            : 'OVERVIEW',
                                    isDark),
                                const SizedBox(height: 10),
                                _buildOverviewGrid(lang, isDark),
                                const SizedBox(height: 22),
                              ],

                              // ── Expense Chart ──────────────────────
                              if (_stats != null &&
                                  (_stats!['categoryBreakdown'] as List?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                _buildExpenseChart(lang, isDark),
                                const SizedBox(height: 22),
                              ],

                              // ── Field Budgets ──────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _sectionLabel(
                                        lang == 'si'
                                            ? 'ක්ෂේත්‍ර අයවැය'
                                            : lang == 'ta'
                                                ? 'வயல் பட்ஜெட்'
                                                : 'FIELD BUDGETS',
                                        isDark),
                                  ),
                                  _addButton(
                                    lang == 'si'
                                        ? 'ක්ෂේත්‍රය'
                                        : lang == 'ta'
                                            ? 'வயல்'
                                            : 'Add Field',
                                    () async {
                                      final result = await Navigator.pushNamed(
                                          context, AppRoutes.addField);
                                      if (result == true) await _loadData();
                                    },
                                    isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_fields.isEmpty)
                                _emptyState(
                                  icon: Icons.agriculture_rounded,
                                  title: lang == 'si'
                                      ? 'ක්ෂේත්‍ර නොමැත'
                                      : lang == 'ta'
                                          ? 'வயல்கள் இல்லை'
                                          : 'No fields yet',
                                  subtitle: lang == 'si'
                                      ? 'ඔබේ පළමු ක්ෂේත්‍රය එකතු කරන්න'
                                      : lang == 'ta'
                                          ? 'உங்கள் முதல் வயலை சேர்க்கவும்'
                                          : 'Add your first field to track budget',
                                  btnLabel: lang == 'si'
                                      ? 'ක්ෂේත්‍රයක් එකතු කරන්න'
                                      : lang == 'ta'
                                          ? 'வயல் சேர்க்கவும்'
                                          : 'Add Your First Field',
                                  onTap: () async {
                                    final result = await Navigator.pushNamed(
                                        context, AppRoutes.addField);
                                    if (result == true) await _loadData();
                                  },
                                  isDark: isDark,
                                )
                              else
                                ..._fields.map((field) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _buildFieldCard(
                                        field['name'] ?? 'Unknown Field',
                                        field['areaDisplay'] ?? '',
                                        (field['budget'] ?? 0).toDouble(),
                                        (field['totalSpent'] ?? 0).toDouble(),
                                        (field['remaining'] ?? 0).toDouble(),
                                        (field['percentageUsed'] ?? 0) as int,
                                        field['_id'],
                                        lang,
                                        isDark,
                                      ),
                                    )),

                              const SizedBox(height: 22),

                              // ── Recent Expenses ────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _sectionLabel(
                                        lang == 'si'
                                            ? 'මෑත වියදම්'
                                            : lang == 'ta'
                                                ? 'சமீபத்திய செலவுகள்'
                                                : 'RECENT EXPENSES',
                                        isDark),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_recentExpenses.isEmpty)
                                _emptyState(
                                  icon: Icons.receipt_long_rounded,
                                  title: lang == 'si'
                                      ? 'වියදම් නොමැත'
                                      : lang == 'ta'
                                          ? 'செலவுகள் இல்லை'
                                          : 'No expenses yet',
                                  subtitle: lang == 'si'
                                      ? 'ඔබේ පළමු වියදම ලියාපදිංචි කරන්න'
                                      : lang == 'ta'
                                          ? 'உங்கள் முதல் செலவை பதிவு செய்யுங்கள்'
                                          : 'Record your first expense',
                                  btnLabel: lang == 'si'
                                      ? 'වියදමක් එකතු කරන්න'
                                      : lang == 'ta'
                                          ? 'செலவு சேர்க்கவும்'
                                          : 'Add Expense',
                                  onTap: () async {
                                    final result = await Navigator.pushNamed(
                                        context, AppRoutes.addExpense);
                                    if (result == true) await _loadData();
                                  },
                                  isDark: isDark,
                                )
                              else
                                ..._recentExpenses
                                    .map((expense) => _buildExpenseItem(
                                          expense['description'] ??
                                              'No description',
                                          (expense['amount'] ?? 0).toDouble(),
                                          expense['category'] ?? 'other',
                                          DateTime.parse(expense['date']),
                                          expense,
                                          lang,
                                          isDark,
                                        )),
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

  // ── Top Bar Button ─────────────────────────────────────────────────
  // Always on green header — no dark change needed
  Widget _topBtn(IconData icon, {double size = 18}) {
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
  Widget _badge(int count) {
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
  Widget _sectionLabel(String label, bool isDark) {
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
            // ✅ dark mode section label
            color:
                isDark ? Colors.white38 : AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Add Button ─────────────────────────────────────────────────────
  Widget _addButton(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // ✅ dark mode add button bg
          color: AppTheme.primaryGreen.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded,
                size: 13, color: AppTheme.primaryGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String btnLabel,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                // ✅ dark mode empty icon bg
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 28,
                  // ✅ dark mode empty icon
                  color: isDark ? Colors.white24 : Colors.grey.shade400),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    // ✅ dark mode empty title
                    color: isDark ? Colors.white54 : Colors.grey.shade600)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    // ✅ dark mode empty subtitle
                    color: isDark ? Colors.white30 : Colors.grey.shade400),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(btnLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview Grid (2×2) ────────────────────────────────────────────
  Widget _buildOverviewGrid(String lang, bool isDark) {
    final total = (_stats!['total'] ?? 0).toDouble();
    final count = _stats!['count'] ?? 0;
    final fieldCount = _fields.length;
    final catCount = (_stats!['categoryBreakdown'] as List?)?.length ?? 0;

    final cards = [
      _OverviewCard(
        title: lang == 'si'
            ? 'වියදම් කළ මුළු'
            : lang == 'ta'
                ? 'மொத்த செலவு'
                : 'Total Spent',
        value: Helpers.formatCurrency(total),
        icon: Icons.shopping_cart_rounded,
        color: Colors.orange,
      ),
      _OverviewCard(
        title: lang == 'si'
            ? 'ගනුදෙනු'
            : lang == 'ta'
                ? 'பரிவர்த்தனைகள்'
                : 'Transactions',
        value: '$count',
        icon: Icons.receipt_long_rounded,
        color: Colors.blue,
      ),
      _OverviewCard(
        title: lang == 'si'
            ? 'ක්‍රියාකාරී ක්ෂේත්‍ර'
            : lang == 'ta'
                ? 'செயலில் வயல்கள்'
                : 'Active Fields',
        value: '$fieldCount',
        icon: Icons.agriculture_rounded,
        color: AppTheme.primaryGreen,
      ),
      _OverviewCard(
        title: lang == 'si'
            ? 'වර්ග'
            : lang == 'ta'
                ? 'வகைகள்'
                : 'Categories',
        value: '$catCount',
        icon: Icons.category_rounded,
        color: Colors.purple,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard(cards[0], isDark)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard(cards[1], isDark)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _summaryCard(cards[2], isDark)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard(cards[3], isDark)),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(_OverviewCard data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ✅ dark mode summary card bg — slightly higher opacity for visibility
        color: data.color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withOpacity(isDark ? 0.25 : 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withOpacity(isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                      fontSize: 10, color: data.color.withOpacity(0.8)),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Expense Chart ──────────────────────────────────────────────────
  Widget _buildExpenseChart(String lang, bool isDark) {
    final categoryBreakdown = _stats!['categoryBreakdown'] as List<dynamic>;
    if (categoryBreakdown.isEmpty) return const SizedBox.shrink();

    final total = categoryBreakdown.fold<double>(
        0, (sum, item) => sum + (item['total'] ?? 0).toDouble());

    final items = categoryBreakdown.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
            lang == 'si'
                ? 'වියදම් විශ්ලේෂණය'
                : lang == 'ta'
                    ? 'செலவு பகுப்பாய்வு'
                    : 'EXPENSE BREAKDOWN',
            isDark),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // ✅ dark mode chart container
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sections: items.map((item) {
                      final cat = item['_id'] ?? 'other';
                      final val = (item['total'] ?? 0).toDouble();
                      final pct = total > 0 ? (val / total * 100) : 0.0;
                      return PieChartSectionData(
                        value: val,
                        title: '${pct.toStringAsFixed(0)}%',
                        color: _getCategoryColor(cat),
                        radius: 46,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    final cat = item['_id'] ?? 'other';
                    final val = (item['total'] ?? 0).toDouble();
                    final pct = total > 0 ? (val / total * 100) : 0.0;
                    final color = _getCategoryColor(cat);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _formatCategory(cat, lang),
                              style: TextStyle(
                                fontSize: 11,
                                // ✅ dark mode legend label
                                color: isDark
                                    ? Colors.white54
                                    : AppTheme.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Field Budget Card ──────────────────────────────────────────────
  Widget _buildFieldCard(
    String name,
    String area,
    double budget,
    double spent,
    double remaining,
    int percentage,
    String fieldId,
    String lang,
    bool isDark,
  ) {
    Color statusColor;
    String statusText;

    if (budget == 0) {
      statusColor = Colors.grey;
      statusText = lang == 'si'
          ? 'අයවැය නැත'
          : lang == 'ta'
              ? 'பட்ஜெட் இல்லை'
              : 'No budget';
    } else if (percentage > 100) {
      statusColor = Colors.red;
      statusText = lang == 'si'
          ? 'ඉක්මවා'
          : lang == 'ta'
              ? 'தாண்டியது'
              : 'Over';
    } else if (percentage >= 80) {
      statusColor = Colors.orange;
      statusText = '$percentage%';
    } else {
      statusColor = AppTheme.primaryGreen;
      statusText = '$percentage%';
    }

    return GestureDetector(
      onLongPress: () => _showDeleteFieldDialog(fieldId, name, lang, isDark),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ✅ dark mode field card bg
          color: isDark
              ? const Color(0xFF1A1A1A)
              : AppTheme.primaryGreen.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? AppTheme.primaryGreen.withOpacity(0.2)
                  : AppTheme.primaryGreen.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.grass_rounded,
                      color: AppTheme.primaryGreen, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              // ✅ dark mode field name
                              color:
                                  isDark ? Colors.white : AppTheme.textDark)),
                      if (area.isNotEmpty)
                        Text(area,
                            style: TextStyle(
                                fontSize: 10,
                                // ✅ dark mode area text
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (budget > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage > 100 ? 1.0 : percentage / 100,
                        // ✅ dark mode progress track
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _budgetDetail(
                    lang == 'si'
                        ? 'අයවැය'
                        : lang == 'ta'
                            ? 'பட்ஜெட்'
                            : 'Budget',
                    Helpers.formatCurrency(budget),
                    Icons.account_balance_wallet_rounded,
                    Colors.blue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _budgetDetail(
                    lang == 'si'
                        ? 'වියදම්'
                        : lang == 'ta'
                            ? 'செலவு'
                            : 'Spent',
                    Helpers.formatCurrency(spent),
                    Icons.shopping_cart_rounded,
                    Colors.orange,
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _budgetDetail(
                    lang == 'si'
                        ? 'ඉතිරි'
                        : lang == 'ta'
                            ? 'மீதி'
                            : 'Remaining',
                    Helpers.formatCurrency(remaining),
                    Icons.savings_rounded,
                    remaining < 0 ? Colors.red : AppTheme.primaryGreen,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetDetail(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      // ✅ dark mode budget label
                      color: isDark ? Colors.white38 : Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Expense Item ───────────────────────────────────────────────────
  Widget _buildExpenseItem(
    String description,
    double amount,
    String category,
    DateTime date,
    Map<String, dynamic> expense,
    String lang,
    bool isDark,
  ) {
    final catColor = _getCategoryColor(category);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(context, AppRoutes.editExpense,
            arguments: expense);
        if (result == true) await _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // ✅ dark mode expense item bg
          color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_rounded, color: catColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          // ✅ dark mode expense description
                          color: isDark ? Colors.white : AppTheme.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: catColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_formatCategory(category, lang)} • ${Helpers.getTimeAgo(date)}',
                          style: TextStyle(
                              fontSize: 10,
                              // ✅ dark mode expense meta
                              color: isDark
                                  ? Colors.white38
                                  : AppTheme.textLight.withOpacity(0.8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helpers.formatCurrency(amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      fontSize: 12),
                ),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 14,
                    // ✅ dark mode chevron
                    color: isDark ? Colors.white24 : AppTheme.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────
class _OverviewCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
