import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/helpers.dart';

class FieldCard extends StatelessWidget {
  final String fieldName;
  final String? fieldArea; // ✅ ADD AREA
  final double totalBudget;
  final double totalSpent;
  final int percentageUsed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // ✅ ADD LONG PRESS

  const FieldCard({
    super.key,
    required this.fieldName,
    this.fieldArea, // ✅ OPTIONAL AREA
    required this.totalBudget,
    required this.totalSpent,
    required this.percentageUsed,
    this.onTap,
    this.onLongPress, // ✅ ADD LONG PRESS CALLBACK
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalBudget - totalSpent;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress, // ✅ HANDLE LONG PRESS
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fieldName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // ✅ SHOW AREA IF PROVIDED
                            if (fieldArea != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                fieldArea!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            if (totalBudget > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentageUsed > 100 ? 1.0 : percentageUsed / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(_getStatusColor()),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Budget Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildBudgetDetail(
                    'Budget',
                    Helpers.formatCurrency(totalBudget),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBudgetDetail(
                    'Spent',
                    Helpers.formatCurrency(totalSpent),
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBudgetDetail(
                    'Remaining',
                    Helpers.formatCurrency(remaining),
                    Icons.savings,
                    remaining < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ BUILD BUDGET DETAIL WIDGET
  Widget _buildBudgetDetail(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ✅ GET STATUS TEXT
  String _getStatusText() {
    if (totalBudget == 0) return 'No budget';
    if (percentageUsed > 100) return 'Over budget';
    return '$percentageUsed% used';
  }

  // ✅ GET STATUS COLOR
  Color _getStatusColor() {
    if (totalBudget == 0) return Colors.grey;
    if (percentageUsed > 100) return Colors.red;
    if (percentageUsed >= 90) return Colors.red;
    if (percentageUsed >= 75) return Colors.orange;
    return AppTheme.primaryGreen;
  }
}
