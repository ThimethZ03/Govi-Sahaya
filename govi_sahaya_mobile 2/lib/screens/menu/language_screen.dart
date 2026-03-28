import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
    {'code': 'si', 'name': 'Sinhala', 'native': 'සිංහල', 'flag': '🇱🇰'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇱🇰'},
  ];

  Future<void> _saveLanguage(BuildContext context, String code) async {
    final provider = context.read<LanguageProvider>();
    final success = await provider.changeLanguage(code);

    if (context.mounted) {
      final langName = _languages.firstWhere((l) => l['code'] == code)['name']!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Language changed to $langName'
                : 'Saved locally. Will sync when online.',
          ),
          backgroundColor: success ? AppTheme.primaryGreen : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final selectedLanguage = langProvider.languageCode;
    final isSaving = langProvider.isLoading;

    // ── tri-language helpers ──────────────────────────────────
    String loc(String en, String si, String ta) => selectedLanguage == 'si'
        ? si
        : selectedLanguage == 'ta'
            ? ta
            : en;

    final title = loc('Language', 'භාෂාව', 'மொழி');
    final subtitle = loc(
      'Choose your preferred language',
      'ඔබේ කැමති භාෂාව තෝරන්න',
      'உங்கள் விருப்பமான மொழியை தேர்வு செய்யவும்',
    );

    final bodyBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F9F7);

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ═══════════════════════════════════════════════
            // Header  — matches LibraryScreen / ShopScreen
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Back button
                  _headerButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Saving spinner (replaces notification bell here)
                  if (isSaving)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ═══════════════════════════════════════════════
            // Info chip — current language indicator
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc(
                          'Currently active: ${_languages.firstWhere((l) => l['code'] == selectedLanguage)['name']}',
                          'දැනට සක්‍රිය: ${_languages.firstWhere((l) => l['code'] == selectedLanguage)['native']}',
                          'தற்போது செயல்பாட்டில்: ${_languages.firstWhere((l) => l['code'] == selectedLanguage)['native']}',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Active language flag
                    Text(
                      _languages.firstWhere(
                          (l) => l['code'] == selectedLanguage)['flag']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ═══════════════════════════════════════════════
            // Body sheet
            // ═══════════════════════════════════════════════
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: bodyBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    children: [
                      // ── Section label ──────────────────────
                      _sectionLabel(
                        loc('SELECT LANGUAGE', 'භාෂාව තෝරන්න',
                            'மொழியை தேர்வு செய்யவும்'),
                        isDark,
                      ),
                      const SizedBox(height: 16),

                      // ── Language cards ─────────────────────
                      ..._languages.map((lang) {
                        final isSelected = selectedLanguage == lang['code'];
                        return _LanguageCard(
                          lang: lang,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => _saveLanguage(context, lang['code']!),
                        );
                      }),

                      const SizedBox(height: 24),

                      // ── Footer note ─────────────────────────
                      _FooterNote(isDark: isDark, lang: selectedLanguage),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryGreen, AppTheme.mediumGreen],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textLight.withOpacity(0.8),
            ),
          ),
        ],
      );
}

// ══════════════════════════════════════════════════════════
// Language selection card
// ══════════════════════════════════════════════════════════
class _LanguageCard extends StatelessWidget {
  final Map<String, String> lang;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.lang,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? (isSelected
            ? AppTheme.primaryGreen.withOpacity(0.18)
            : AppTheme.darkCard)
        : (isSelected ? AppTheme.primaryGreen.withOpacity(0.06) : Colors.white);

    final borderColor = isSelected
        ? AppTheme.primaryGreen
        : (isDark ? Colors.white12 : Colors.grey.shade200);

    final textPri = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.textLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Flag in styled container ───────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withOpacity(isDark ? 0.25 : 0.1)
                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),

            // ── Language name + native ─────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.primaryGreen : textPri,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lang['native']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSec,
                    ),
                  ),
                ],
              ),
            ),

            // ── Selected / unselected indicator ───────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isSelected
                  ? Container(
                      key: const ValueKey('selected'),
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    )
                  : Container(
                      key: const ValueKey('unselected'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Footer note
// ══════════════════════════════════════════════════════════
class _FooterNote extends StatelessWidget {
  final bool isDark;
  final String lang;

  const _FooterNote({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc(
                'The app will update immediately after selecting a language.',
                'භාෂාවක් තෝරාගත් වහාම යෙදුම යාවත්කාලීන වේ.',
                'மொழியை தேர்ந்தெடுத்த உடனே பயன்பாடு புதுப்பிக்கப்படும்.',
              ),
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
