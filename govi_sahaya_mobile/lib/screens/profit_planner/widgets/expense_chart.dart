import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/language_provider.dart';

class ExpenseChart extends StatefulWidget {
  final Map<String, double> categoryData;

  const ExpenseChart({super.key, required this.categoryData});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isTouched = false;
  PieTouchResponse? _touchResponse;

  static const List<Color> _colors = [
    AppTheme.primaryGreen,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    return widget.categoryData.entries.map((entry) {
      final color = _colors[index % _colors.length];
      index++;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toInt()}%',
        color: color,
        radius: _isTouched ? 55 : 46,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageCode;

    return Semantics(
      label: lang == 'si'
          ? 'වියදම් විශ්ලේෂණය - ${widget.categoryData.values.reduce((a, b) => a + b).toInt()}% මුළු වියදම්'
          : lang == 'ta'
              ? 'செலவு பகுப்பாய்வு - ${widget.categoryData.values.reduce((a, b) => a + b).toInt()}% மொத்த செலவு'
              : 'Expense breakdown - ${widget.categoryData.values.reduce((a, b) => a + b).toInt()}% total expenses',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Enhanced Header with shimmer ──────────────────────────────
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _animation.value)),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.primaryGreen.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lang == 'si'
                                ? 'වියදම් විශ්ලේෂණය'
                                : lang == 'ta'
                                    ? 'செலவு பகுப்பாய்வு'
                                    : 'EXPENSE BREAKDOWN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textLight.withOpacity(0.85),
                              letterSpacing: 1.8,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 1,
                                  color: Colors.black12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Chart + Legend Row with shimmer effect ────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Pie Chart
                  AnimatedBuilder(
                    animation: Listenable.merge([_animation, _animationController]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.95 + 0.05 * _animation.value,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    _touchResponse = pieTouchResponse;
                                    _isTouched = event is FlTapUpEvent ||
                                        event is FlLongPressEvent;
                                  });
                                },
                              ),
                              sections: _getSections(),
                              sectionsSpace: _isTouched ? 3 : 2,
                              centerSpaceRadius: _isTouched ? 32 : 36,
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 18),

                  // Enhanced Legend with animations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(widget.categoryData.length, (index) {
                        final entry = widget.categoryData.entries.elementAt(index);
                        final color = _colors[index % _colors.length];
                        final label = _translateCategory(entry.key, lang);
                        
                        return AnimatedOpacity(
                          opacity: _animation.value,
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _isTouched ? 8 : 6,
                                    vertical: _isTouched ? 4 : 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: _isTouched
                                        ? Border.all(color: color, width: 1)
                                        : null,
                                  ),
                                  child: Text(
                                    '${entry.value.toInt()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],flutter clean
flutter pub get
flutter run
        ),
      ),
    );
  }
}
