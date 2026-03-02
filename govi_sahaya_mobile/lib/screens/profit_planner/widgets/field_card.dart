import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/theme_provider.dart'; // ✅ NEW

class FieldCard extends StatelessWidget {
  final String fieldName;
  final String? fieldArea;
  final double totalBudget;
  final double totalSpent;
  final int percentageUsed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FieldCard({
    super.key,
    required this.fieldName,
    this.fieldArea,
    required this.totalBudget,
    required this.totalSpent,
    required this.percentageUsed,
    this.onTap,
    this.onLongPress,
  });

  Color _statusColor() {
    if (totalBudget == 0) return Colors.grey;
    if (percentageUsed > 100) return Colors.red;
    if (percentageUsed >= 90) return Colors.red;
    if (percentageUsed >= 75) return Colors.orange;
    return AppTheme.primaryGreen;
  }

  String _statusText(String lang) {
    if (totalBudget == 0) {
      return lang == 'si'
          ? 'අයවැය නැත'
          : lang == 'ta'
              ? 'பட்ஜெட் இல்லை'
              : 'No budget';
    }
    if (percentageUsed > 100) {
      return lang == 'si'
          ? 'අයවැය ඉක්මවා'
          : lang == 'ta'
              ? 'பட்ஜெட் தாண்டியது'
              : 'Over budget';
    }
    return '$percentageUsed%';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final isDark = context.watch<ThemeProvider>().isDark; // ✅ NEW
    final remaining = totalBudget - totalSpent;
    final color = _statusColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ✅ dark mode card bg
          color: isDark
              ? AppTheme.primaryGreen.withOpacity(0.07)
              : AppTheme.primaryGreen.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            // ✅ dark mode card border
            color: isDark
                ? AppTheme.primaryGreen.withOpacity(0.25)
                : AppTheme.primaryGreen.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.12),
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
                      Text(
                        fieldName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          // ✅ dark mode field name
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (fieldArea != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          fieldArea!,
                          style: TextStyle(
                              fontSize: 10,
                              // ✅ dark mode area text
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    _statusText(lang),
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // ── Progress Bar ─────────────────────────────────────────
            if (totalBudget > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            percentageUsed > 100 ? 1.0 : percentageUsed / 100,
                        // ✅ dark mode progress track
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentageUsed%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],

            // ── Budget Details ───────────────────────────────────────
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetDetail(
                    lang == 'si'
                        ? 'අයවැය'
                        : lang == 'ta'
                            ? 'பட்ஜெட்'
                            : 'Budget',
                    Helpers.formatCurrency(totalBudget),
                    Icons.account_balance_wallet_rounded,
                    Colors.blue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildBudgetDetail(
                    lang == 'si'
                        ? 'වියදම්'
                        : lang == 'ta'
                            ? 'செலவு'
                            : 'Spent',
                    Helpers.formatCurrency(totalSpent),
                    Icons.shopping_cart_rounded,
                    Colors.orange,
                    isDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildBudgetDetail(
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

  Widget _buildBudgetDetail(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark, // ✅ NEW
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 9,
                    // ✅ dark mode budget detail label
                    color: isDark ? Colors.white38 : Colors.grey.shade500),
                overflow: TextOverflow.ellipsis,
              ),
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
}
