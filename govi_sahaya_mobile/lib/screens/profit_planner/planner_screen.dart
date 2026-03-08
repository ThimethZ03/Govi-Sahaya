import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/notification_provider.dart';
import '../../services/backend_planner_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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

      // ✅ Refresh notification badge after every reload
      if (mounted) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  Future<void> _showDeleteFieldDialog(String fieldId, String fieldName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$fieldName"?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All expenses related to this field will also be deleted permanently.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        height: 1.4,
                      ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteField(fieldId);
    }
  }

  Future<void> _deleteField(String fieldId) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting field...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await _plannerService.deleteField(fieldId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Field and related expenses deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Reload data + refresh badge (🗑️ notification was created on backend)
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete field: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      appBar: AppBar(
        title: const Text('Profit Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary Cards ──────────────────────────────
                      if (_stats != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Total Spent',
                                ' ${Helpers.formatCurrency((_stats!['total'] ?? 0).toDouble())}',
                                Icons.shopping_cart,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Transactions',
                                '${_stats!['count'] ?? 0}',
                                Icons.receipt_long,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Active Fields',
                                '${_fields.length}',
                                Icons.agriculture,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Categories',
                                '${_stats!['categoryBreakdown']?.length ?? 0}',
                                Icons.category,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── Expense Chart ──────────────────────────────
                      if (_stats != null &&
                          _stats!['categoryBreakdown'] != null &&
                          (_stats!['categoryBreakdown'] as List).isNotEmpty)
                        _buildExpenseChart(),
                      const SizedBox(height: 24),

                      // ── Field Budgets ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Field Budgets',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                AppRoutes.addField,
                              );
                              if (result == true) {
                                // ✅ Backend sent 🌾 notification — reload + refresh badge
                                await _loadData();
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Field'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_fields.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(Icons.agriculture,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No fields yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.addField,
                                    );
                                    if (result == true) {
                                      await _loadData();
                                    }
                                  },
                                  child: const Text('Add Your First Field'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._fields.map((field) {
                          final totalSpent =
                              (field['totalSpent'] ?? 0).toDouble();
                          final budget = (field['budget'] ?? 0).toDouble();
                          final percentage =
                              (field['percentageUsed'] ?? 0) as int;
                          final remaining =
                              (field['remaining'] ?? 0).toDouble();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFieldBudgetCard(
                              field['name'] ?? 'Unknown Field',
                              field['areaDisplay'] ?? 'N/A',
                              budget,
                              totalSpent,
                              remaining,
                              percentage,
                              field['_id'],
                            ),
                          );
                        }),
                      const SizedBox(height: 24),

                      // ── Recent Expenses ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to all expenses
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_recentExpenses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._recentExpenses.map((expense) {
                          return _buildExpenseItem(
                            expense['description'] ?? 'No description',
                            (expense['amount'] ?? 0).toDouble(),
                            expense['category'] ?? 'other',
                            DateTime.parse(expense['date']),
                            expense,
                          );
                        }),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, AppRoutes.addExpense);
          if (result == true) {
            // ✅ Backend checked budget — reload + refresh badge
            await _loadData();
          }
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    final categoryBreakdown = _stats!['categoryBreakdown'] as List<dynamic>;

    if (categoryBreakdown.isEmpty) return const SizedBox.shrink();

    final total = categoryBreakdown.fold<double>(
      0,
      (sum, item) => sum + (item['total'] ?? 0).toDouble(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: PieChart(
            PieChartData(
              sections: categoryBreakdown.take(5).map((item) {
                final categoryTotal = (item['total'] ?? 0).toDouble();
                final percentage =
                    total > 0 ? (categoryTotal / total) * 100 : 0;
                final category = item['_id'] ?? 'other';

                return PieChartSectionData(
                  value: categoryTotal,
                  title: '${percentage.toStringAsFixed(0)}%',
                  color: _getCategoryColor(category),
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: categoryBreakdown.take(5).map((item) {
            final category = item['_id'] ?? 'other';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatCategoryName(category),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'fertilizers': Colors.green,
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

  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  Widget _buildFieldBudgetCard(
    String name,
    String area,
    double budget,
    double spent,
    double remaining,
    int percentage,
    String fieldId,
  ) {
    Color statusColor;
    String statusText;

    if (budget == 0) {
      statusColor = Colors.grey;
      statusText = 'No budget set';
    } else if (percentage > 100) {
      statusColor = Colors.red;
      statusText = 'Over budget';
    } else if (percentage > 80) {
      statusColor = Colors.orange;
      statusText = '$percentage% used';
    } else {
      statusColor = AppTheme.primaryGreen;
      statusText = '$percentage% used';
    }

    return GestureDetector(
      onLongPress: () async {
        await _showDeleteFieldDialog(fieldId, name);
      },
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        area,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (budget > 0) ...[
              LinearProgressIndicator(
                value: percentage > 100 ? 1.0 : percentage / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildBudgetDetail(
                    'Budget',
                    Helpers.formatCurrency(budget),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBudgetDetail(
                    'Spent',
                    Helpers.formatCurrency(spent),
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

  Widget _buildBudgetDetail(
      String label, String value, IconData icon, Color color) {
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
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _buildExpenseItem(
    String description,
    double amount,
    String category,
    DateTime date,
    Map<String, dynamic> expense,
  ) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.editExpense,
          arguments: expense,
        );
        if (result == true) {
          // ✅ Budget alert may have triggered on edit — reload + refresh badge
          await _loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt,
                color: _getCategoryColor(category),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCategoryName(category)} • ${Helpers.getTimeAgo(date)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helpers.formatCurrency(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppTheme.textLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
