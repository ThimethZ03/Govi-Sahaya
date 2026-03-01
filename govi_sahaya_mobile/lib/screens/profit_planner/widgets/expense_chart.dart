import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/language_provider.dart';

class ExpenseChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const ExpenseChart({super.key, required this.categoryData});

  static const List<Color> _colors = [
    AppTheme.primaryGreen,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.amber,
  ];

  String _translateCategory(String key, String lang) {
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
    if (lang == 'si') return si[key] ?? _capitalize(key);
    if (lang == 'ta') return ta[key] ?? _capitalize(key);
    return _capitalize(key);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<PieChartSectionData> _getSections() {
    int index = 0;
    return categoryData.entries.map((entry) {
      final color = _colors[index % _colors.length];
      index++;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toInt()}%',
        color: color,
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
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
                  color: AppTheme.textLight.withOpacity(0.7),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Chart + Legend Row ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pie chart
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sections: _getSections(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(categoryData.length, (index) {
                    final entry = categoryData.entries.elementAt(index);
                    final color = _colors[index % _colors.length];
                    final label = _translateCategory(entry.key, lang);
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
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value.toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
