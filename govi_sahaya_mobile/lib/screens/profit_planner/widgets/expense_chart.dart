import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../../config/theme.dart';

class ExpenseChart extends StatefulWidget {
  final Map<String, double> categoryData;
  final double? totalAmount;
  final Function(String)? onCategoryTap;
  final bool showLegend;
  final bool showTotal;
  final bool enableAnimations;
  final Duration animationDuration;
  final List<Color>? customColors;
  final double chartHeight;
  final bool showValues;
  final bool interactive;

  const ExpenseChart({
    super.key,
    required this.categoryData,
    this.totalAmount,
    this.onCategoryTap,
    this.showLegend = true,
    this.showTotal = true,
    this.enableAnimations = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.customColors,
    this.chartHeight = 260,
    this.showValues = true,
    this.interactive = true,
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  double _touchedIndex = -1;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.categoryData.isNotEmpty;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: hasData ? _scaleAnimation.value : 1.0,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            height: widget.chartHeight,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: !hasData
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      Expanded(child: _buildInteractiveChart()),
                      if (widget.showLegend) const SizedBox(height: 16),
                      if (widget.showLegend) _buildAdvancedLegend(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pie_chart_outlined, size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'No Expenses Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to see breakdown',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {}, // Navigate to add expense
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalPercentage = widget.categoryData.values.fold(0.0, (sum, val) => sum + val);
    final totalFormatted = widget.totalAmount?.toStringAsFixed(0) ?? '100';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This month • ${_getTimePeriod()}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen.withOpacity(0.15), AppTheme.primaryGreen.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalFormatted%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.trending_up, size: 18, color: AppTheme.primaryGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveChart() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: widget.interactive
              ? PieChartWithTouch(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (event is FlTapUpEvent && pieTouchResponse.touchedSection != null) {
                          final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          final category = widget.categoryData.keys.elementAt(index);
                          setState(() => _selectedCategory = category);
                          widget.onCategoryTap?.call(category);
                        }
                      },
                    ),
                    sections: _getInteractiveSections(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    borderData: FlBorderData(show: false),
                  ),
                )
              : PieChart(
                  PieChartData(
                    sections: _getSections(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    borderData: FlBorderData(show: false),
                  ),
                ),
        ),
        const SizedBox(width: 24),
        Expanded(child: _buildChartInfo()),
      ],
    );
  }

  Widget _buildChartInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_selectedCategory != null) ...[
          _buildSelectedCategoryInfo(),
          const SizedBox(height: 20),
        ],
        _buildTopCategoriesPreview(),
      ],
    );
  }

  Widget _buildSelectedCategoryInfo() {
    final selectedData = widget.categoryData[_selectedCategory!];
    final percentage = selectedData ?? 0;
    final color = _getColorForCategory(_selectedCategory!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            _formatCategoryName(_selectedCategory!),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            'Selected',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesPreview() {
    final topCategories = widget.categoryData.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          ...topCategories.take(3).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatCategoryName(entry.key), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${entry.value.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text('${(entry.value / 100 * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getInteractiveSections() {
    final entries = widget.categoryData.entries.toList();
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value.value;
      final isTouched = index == _touchedIndex;
      final category = entry.value.key;
      
      return PieChartSectionData(
        value: data,
        title: '${data.toInt()}%',
        color: _getColorForCategory(category).withOpacity(isTouched ? 1.0 : 0.85),
        radius: isTouched ? 75 : 60,
        titleStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(offset: const Offset(1, 1), blurRadius: 2, color: Colors.black26),
          ],
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> _getSections() {
    final colors = widget.customColors ?? [
      AppTheme.primaryGreen, Colors.blue.shade600, Colors.orange.shade600,
      Colors.purple.shade600, Colors.red.shade600, Colors.teal.shade600,
      Colors.amber.shade600, Colors.pink.shade600, Colors.indigo.shade600,
    ];
    
    int index = 0;
    return widget.categoryData.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toInt()}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildAdvancedLegend() {
    final entries = widget.categoryData.entries.toList();
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: entries.map((entry) {
          final color = _getColorForCategory(entry.key);
          return GestureDetector(
            onTap: () => widget.onCategoryTap?.call(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatCategoryName(entry.key),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    final colors = {
      'fertilizers': Colors.green.shade600,
      'seeds': Colors.orange.shade600,
      'pesticides': Colors.red.shade600,
      'labor': Colors.purple.shade600,
      'equipment': Colors.blue.shade600,
      'irrigation': Colors.cyan.shade600,
      'transportation': Colors.amber.shade600,
      'other': Colors.grey.shade600,
    };
    return colors[category.toLowerCase()] ?? Colors.grey.shade600;
  }

  String _formatCategoryName(String category) {
    return category.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _getTimePeriod() {
    final now = DateTime.now();
    return '${DateFormat('MMM').format(now)} ${now.day}';
  }
}

class PieChartWithTouch extends StatelessWidget {
  final PieChartData pieChartData;

  const PieChartWithTouch({super.key, required this.pieChartData});

  @override
  Widget build(BuildContext context) {
    return PieChart(pieChartData);
  }
}
