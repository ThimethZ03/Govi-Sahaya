// lib/screens/safety_assist/first_aid_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/safety_models.dart';

class FirstAidDetailScreen extends StatelessWidget {
  final FirstAidGuide guide;
  final bool isDark;
  final String lang;

  const FirstAidDetailScreen({
    super.key,
    required this.guide,
    required this.isDark,
    required this.lang,
  });

  Color _hex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  IconData _icon(String name) {
    switch (name) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'wb_sunny':
        return Icons.wb_sunny_rounded;
      case 'healing':
        return Icons.healing_rounded;
      case 'visibility':
        return Icons.visibility_rounded;
      case 'coronavirus':
        return Icons.coronavirus_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _hex(guide.color);

    final title = lang == 'si'
        ? guide.titleSi
        : lang == 'ta'
            ? guide.titleTa
            : guide.title;

    final symptoms = lang == 'si'
        ? guide.symptomsSi
        : lang == 'ta'
            ? guide.symptomsTa
            : guide.symptoms;

    final steps = lang == 'si'
        ? guide.stepsSi
        : lang == 'ta'
            ? guide.stepsTa
            : guide.steps;

    final doNot = lang == 'si'
        ? guide.doNotSi
        : lang == 'ta'
            ? guide.doNotTa
            : guide.doNot;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          lang == 'si'
                              ? 'ප්‍රථමාධාර මාර්ගෝපදේශය'
                              : lang == 'ta'
                                  ? 'முதலுதவி வழிகாட்டி'
                                  : 'First Aid Guide',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Guide icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child:
                        Icon(_icon(guide.icon), color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Body ──────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Hero banner ──────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color:
                                color.withValues(alpha: isDark ? 0.15 : 0.07),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: color.withValues(
                                    alpha: isDark ? 0.35 : 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: color.withValues(
                                      alpha: isDark ? 0.25 : 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(_icon(guide.icon),
                                    color: color, size: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      guide.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      guide.titleSi,
                                      style: AppTheme.sinhalaText(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      guide.titleTa,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Symptoms ─────────────────────────────
                        _buildSection(
                          context: context,
                          label: lang == 'si'
                              ? 'රෝග ලක්ෂණ'
                              : lang == 'ta'
                                  ? 'அறிகுறிகள்'
                                  : 'SYMPTOMS',
                          icon: Icons.monitor_heart_rounded,
                          color: Colors.orange,
                          items: symptoms,
                          isDark: isDark,
                          isBullet: true,
                        ),

                        const SizedBox(height: 14),

                        // ── Immediate Steps ───────────────────────
                        _buildSection(
                          context: context,
                          label: lang == 'si'
                              ? 'කළ යුතු දේ'
                              : lang == 'ta'
                                  ? 'செய்ய வேண்டியவை'
                                  : 'IMMEDIATE STEPS',
                          icon: Icons.medical_services_rounded,
                          color: AppTheme.primaryGreen,
                          items: steps,
                          isDark: isDark,
                          isBullet: false, // numbered steps
                        ),

                        const SizedBox(height: 14),

                        // ── Do NOT ────────────────────────────────
                        _buildSection(
                          context: context,
                          label: lang == 'si'
                              ? 'නොකළ යුතු දේ'
                              : lang == 'ta'
                                  ? 'செய்யக்கூடாதவை'
                                  : 'DO NOT',
                          icon: Icons.block_rounded,
                          color: Colors.red,
                          items: doNot,
                          isDark: isDark,
                          isBullet: true,
                        ),

                        const SizedBox(height: 24),

                        // ── Emergency call button ─────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _call('1990'),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: Text(
                              lang == 'si'
                                  ? 'හදිසි ඇමතුම: 1990'
                                  : lang == 'ta'
                                      ? 'அவசர அழைப்பு: 1990'
                                      : 'Call Emergency: 1990',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
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

  // ── Section builder ───────────────────────────────────────────────
  Widget _buildSection({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required List<String> items,
    required bool isDark,
    required bool isBullet,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final text = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bullet or number
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: isBullet ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isBullet ? null : BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: isBullet
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
