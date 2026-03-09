import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/theme_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CategoryUtils — single source of truth for category colours + translations.
// Import this class wherever categories need to be displayed (PlannerScreen,
// ExpenseChart, FieldCard, etc.) to avoid duplication.
// ══════════════════════════════════════════════════════════════════════════════
class CategoryUtils {
  static const Map<String, String> _siLabels = {
    'fertilizers': 'පොහොර',
    'seeds': 'බීජ',
    'pesticides': 'පළිබෝධනාශක',
    'labor': 'ශ්‍රම',
    'equipment': 'උපකරණ',
    'irrigation': 'වාරිමාර්ග',
    'transportation': 'ප්‍රවාහන',
    'other': 'වෙනත්',
  };

  static const Map<String, String> _taLabels = {
    'fertilizers': 'உரங்கள்',
    'seeds': 'விதைகள்',
    'pesticides': 'பூச்சிக்கொல்லி',
    'labor': 'தொழிலாளர்',
    'equipment': 'உபகரணங்கள்',
    'irrigation': 'நீர்ப்பாசனம்',
    'transportation': 'போக்குவரத்து',
    'other': 'மற்றவை',
  };

  static String translate(String key, String lang) {
    final cap = key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
    if (lang == 'si') return _siLabels[key] ?? cap;
    if (lang == 'ta') return _taLabels[key] ?? cap;
    return cap;
  }

  static Color colorFor(String category) {
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
}

// ══════════════════════════════════════════════════════════════════════════════
// ExpenseChart — Pie chart + legend.
// Pass raw monetary amounts; percentages are calculated internally.
// Usage: ExpenseChart(categoryData: {'fertilizers': 12500, 'seeds': 3000})
// ══════════════════════════════════════════════════════════════════════════════
class ExpenseChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const ExpenseChart({super.key, required this.categoryData});

  List<PieChartSectionData> _getSections(double total) {
    return categoryData.entries.map((entry) {
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      return PieChartSectionData(
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: CategoryUtils.colorFor(entry.key),
        radius: 46,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;
    final isDark = context.watch<ThemeProvider>().isDark;

    if (categoryData.isEmpty) return const SizedBox.shrink();

    final total = categoryData.values.fold<double>(0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
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
                lang == 'si'
                    ? 'වියදම් විශ්ලේෂණය'
                    : lang == 'ta'
                        ? 'செலவு பகுப்பாய்வு'
                        : 'EXPENSE BREAKDOWN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? Colors.white38
                      : AppTheme.textLight.withOpacity(0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Chart + Legend ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sections: _getSections(total),
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
                  children: categoryData.entries.map((entry) {
                    final color = CategoryUtils.colorFor(entry.key);
                    final label = CategoryUtils.translate(entry.key, lang);
                    final pct = total > 0
                        ? (entry.value / total * 100).toStringAsFixed(0)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white54
                                    : AppTheme.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
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
        ],
      ),
    );
  }
}
