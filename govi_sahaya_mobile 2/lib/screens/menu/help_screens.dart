import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// INVITE FRIENDS
// ─────────────────────────────────────────────────────────────────────────────
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  static const String _inviteLink = 'https://govisahaya.lk/invite';

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lang = context.watch<LanguageProvider>().languageCode;

    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final bodyBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F9F7);

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _headerButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc('Invite Friends', 'මිතුරන් ආරාධනා කරන්න',
                              'நண்பர்களை அழைக்கவும்'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          loc(
                            'Share and grow together',
                            'හවුලේ වගා කරමු',
                            'பகிர்ந்து வளர்வோம்',
                          ),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Body sheet ────────────────────────────────────────
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: Column(
                      children: [
                        // ── Hero icon ──────────────────────────
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen
                                .withOpacity(isDark ? 0.2 : 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_alt_outlined,
                              size: 44, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          loc(
                            'Invite Your Farming Friends',
                            'ගොවි මිතුරන් ආරාධනා කරන්න',
                            'உங்கள் விவசாய நண்பர்களை அழைக்கவும்',
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          loc(
                            'Share Govi Sahaya with fellow farmers\nand grow together!',
                            'ගොවි සහාය යෙදුම හවුල් කර හැමෝ එකට දියුණු වෙමු!',
                            'கோவி சஹாயவை சக விவசாயிகளுடன் பகிர்ந்து\nஒன்றாக வளர்வோம்!',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textLight,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // ── Section label ──────────────────────
                        _sectionLabel(
                          loc('INVITE LINK', 'ආරාධනා සබැඳිය',
                              'அழைப்பு இணைப்பு'),
                          isDark,
                        ),
                        const SizedBox(height: 12),

                        // ── Link box ───────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen
                                      .withOpacity(isDark ? 0.2 : 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.link_rounded,
                                    color: AppTheme.primaryGreen, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _inviteLink,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                      const ClipboardData(text: _inviteLink));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(loc(
                                        'Link copied!',
                                        'සබැඳිය පිටපත් කළා!',
                                        'இணைப்பு நகலெடுக்கப்பட்டது!')),
                                    backgroundColor: AppTheme.primaryGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    loc('Copy', 'පිටපත්', 'நகல்'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Share button ───────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(loc(
                                  'Share feature coming soon!',
                                  'හවුල් කිරීමේ විශේෂාංගය ළඟදීම!',
                                  'பகிர்வு அம்சம் விரைவில்!')),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            )),
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: Text(
                              loc('Share Now', 'දැන් හවුල් කරන්න',
                                  'இப்போது பகிரவும்'),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Info note ──────────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textLight),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  loc(
                                    'Your friends will get full access to all farming tools when they join.',
                                    'ඔබේ මිතුරන් සම්බන්ධ වූ විට සියලු ගොවිතැන් මෙවලම් භාවිත කළ හැකිය.',
                                    'உங்கள் நண்பர்கள் இணையும்போது அனைத்து விவசாய கருவிகளையும் பயன்படுத்தலாம்.',
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// RATE US
// ─────────────────────────────────────────────────────────────────────────────
class RateUsScreen extends StatefulWidget {
  const RateUsScreen({super.key});

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  static const _labels = [
    '',
    'Poor',
    'Fair',
    'Good',
    'Great',
    'Excellent!',
  ];
  static const _labelsSi = [
    '',
    'දුර්වල',
    'සාමාන්‍ය',
    'හොඳ',
    'ඉතා හොඳ',
    'අති විශිෂ්ට!',
  ];
  static const _labelsTa = [
    '',
    'மோசம்',
    'சரி',
    'நல்லது',
    'சிறந்தது',
    'அருமை!',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      final lang = context.read<LanguageProvider>().languageCode;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang == 'si'
            ? 'කරුණාකර ස්ටාර් ශ්‍රේණිගත කිරීමක් තෝරන්න'
            : lang == 'ta'
                ? 'ஒரு நட்சத்திர மதிப்பீட்டை தேர்வு செய்யவும்'
                : 'Please select a star rating'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lang = context.watch<LanguageProvider>().languageCode;

    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final bodyBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F9F7);

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _headerButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc('Rate Us', 'අපට ශ්‍රේණිගත කරන්න',
                              'எங்களை மதிப்பிடவும்'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          loc(
                            'Your feedback helps us improve',
                            'ඔබේ අදහස් අපට දියුණු වීමට උදවු කරයි',
                            'உங்கள் கருத்து எங்களை மேம்படுத்த உதவுகிறது',
                          ),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Body sheet ───────────────────────────────────────
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
                  child: _submitted
                      ? _buildThankYou(isDark, lang)
                      : _buildRatingForm(isDark, lang, loc),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingForm(
    bool isDark,
    String lang,
    String Function(String, String, String) loc,
  ) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textPri = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.textLight;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    final ratingLabel = _rating == 0
        ? loc(
            'Tap to rate', 'ශ්‍රේණිගත කිරීමට ස්පර්ශ කරන්න', 'மதிப்பிட தட்டவும்')
        : (lang == 'si'
            ? _labelsSi[_rating]
            : lang == 'ta'
                ? _labelsTa[_rating]
                : _labels[_rating]);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        children: [
          // ── Hero icon ────────────────────────────────────
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7).withOpacity(isDark ? 0.15 : 1.0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded,
                size: 48, color: Color(0xFFF57F17)),
          ),
          const SizedBox(height: 20),

          Text(
            loc('Enjoying Govi Sahaya?', 'ගොවි සහාය රසවිඳිනවාද?',
                'கோவி சஹாயவை ரசிக்கிறீர்களா?'),
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textPri),
          ),
          const SizedBox(height: 8),
          Text(
            loc(
                'Your feedback helps us improve',
                'ඔබේ අදහස් අපට දියුණු වීමට උදවු කරයි',
                'உங்கள் கருத்து எங்களை மேம்படுத்த உதவுகிறது'),
            style: TextStyle(fontSize: 14, color: textSec),
          ),
          const SizedBox(height: 28),

          // ── Stars ─────────────────────────────────────────
          _sectionLabel(
              loc('YOUR RATING', 'ඔබේ ශ්‍රේණිය', 'உங்கள் மதிப்பீடு'), isDark),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _rating >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: _rating >= star ? 44 : 38,
                    color: _rating >= star
                        ? const Color(0xFFF57F17)
                        : (isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            ratingLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _rating > 0 ? const Color(0xFFF57F17) : textSec,
            ),
          ),
          const SizedBox(height: 24),

          // ── Feedback textarea ─────────────────────────────
          _sectionLabel(
              loc('FEEDBACK (OPTIONAL)', 'අදහස් (අවශ්‍ය නොවේ)',
                  'கருத்து (விருப்பமானது)'),
              isDark),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: TextStyle(fontSize: 13, color: textPri),
              decoration: InputDecoration(
                hintText: loc(
                  'Tell us what you think...',
                  'ඔබේ අදහස් දන්වන්න...',
                  'உங்கள் கருத்தை தெரிவிக்கவும்...',
                ),
                hintStyle: TextStyle(color: textSec, fontSize: 13),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Submit button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      loc('Submit Rating', 'ශ්‍රේණිගත කිරීම යොමු කරන්න',
                          'மதிப்பீட்டை சமர்ப்பிக்கவும்'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYou(bool isDark, String lang) {
    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 50, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            Text(
              loc('Thank You!', 'ස්තූතියි!', 'நன்றி!'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc(
                'Your feedback means a lot to us.',
                'ඔබේ අදහස් අපට ඉතා වැදගත්.',
                'உங்கள் கருத்து எங்களுக்கு மிகவும் முக்கியமானது.',
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TERMS & PRIVACY
// ─────────────────────────────────────────────────────────────────────────────
class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});

  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lang = context.watch<LanguageProvider>().languageCode;

    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final bodyBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F9F7);

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _headerButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc('Terms & Privacy', 'නීති සහ පෞද්ගලිකත්වය',
                              'விதிமுறைகள் & தனியுரிமை'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          loc(
                            'Our policies and agreements',
                            'අපගේ ප්‍රතිපත්ති සහ ගිවිසුම්',
                            'எங்கள் கொள்கைகள் மற்றும் ஒப்பந்தங்கள்',
                          ),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                        text: loc('Terms of Use', 'භාවිත නියම',
                            'பயன்பாட்டு விதிமுறைகள்')),
                    Tab(
                        text: loc('Privacy Policy', 'පෞද්ගලිකතා ප්‍රතිපත්තිය',
                            'தனியுரிமைக் கொள்கை')),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Body sheet ───────────────────────────────────────
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContent(_termsContent, isDark),
                      _buildContent(_privacyContent, isDark),
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

  Widget _buildContent(List<Map<String, String>> sections, bool isDark) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textPri = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.textLight;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 30),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sections[index]['title']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPri,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sections[index]['body']!,
                style: TextStyle(fontSize: 13, color: textSec, height: 1.6),
              ),
            ],
          ),
        );
      },
    );
  }

  static const List<Map<String, String>> _termsContent = [
    {
      'title': 'Acceptance of Terms',
      'body':
          'By using Govi Sahaya, you agree to these terms. If you do not agree, please do not use the application.',
    },
    {
      'title': 'Use of the App',
      'body':
          'Govi Sahaya is intended for agricultural purposes. You agree to use it lawfully and not misuse any features.',
    },
    {
      'title': 'Intellectual Property',
      'body':
          'All content, logos, and data within Govi Sahaya are property of DARTIS Dynamics. Unauthorized reproduction is prohibited.',
    },
    {
      'title': 'Disclaimer',
      'body':
          'AI-generated crop recommendations are for guidance only. DARTIS Dynamics is not liable for agricultural decisions made based on app data.',
    },
    {
      'title': 'Changes to Terms',
      'body':
          'We may update these terms at any time. Continued use of the app after changes constitutes acceptance.',
    },
  ];

  static const List<Map<String, String>> _privacyContent = [
    {
      'title': 'Data We Collect',
      'body':
          'We collect your name, email, phone number, farm location, and usage data to provide our services.',
    },
    {
      'title': 'How We Use Your Data',
      'body':
          'Your data is used to personalize crop recommendations, weather alerts, and community features.',
    },
    {
      'title': 'Data Sharing',
      'body':
          'We do not sell your personal data. Data may be shared with service providers who help operate the app.',
    },
    {
      'title': 'Data Security',
      'body':
          'We use industry-standard encryption and secure servers to protect your information.',
    },
    {
      'title': 'Your Rights',
      'body':
          'You may request deletion of your account and data at any time via Settings → Delete Account.',
    },
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORT PROBLEM
// ─────────────────────────────────────────────────────────────────────────────
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _selectedCategory = 'App Crash';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _categories = [
    'App Crash',
    'Login Issue',
    'Weather Data',
    'AI Crop Doctor',
    'Forum',
    'Shop',
    'Other',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lang = context.watch<LanguageProvider>().languageCode;

    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final bodyBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F9F7);

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _headerButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc('Report Problem', 'ගැටලුවක් වාර්තා කරන්න',
                              'சிக்கலை அறிக்கை செய்யவும்'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          loc(
                            'Help us fix issues faster',
                            'ගැටලු ඉක්මනින් නිරාකරණයට උදවු කරන්න',
                            'சிக்கல்களை விரைவாக சரிசெய்ய உதவுங்கள்',
                          ),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Body sheet ───────────────────────────────────────
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
                  child: _submitted
                      ? _buildSuccess(isDark, lang)
                      : _buildForm(isDark, lang, loc),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    bool isDark,
    String lang,
    String Function(String, String, String) loc,
  ) {
    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textPri = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.textLight;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category section ────────────────────────────
            _sectionLabel(loc('CATEGORY', 'කාණ්ඩය', 'வகை'), isDark),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : (isDark ? AppTheme.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGreen : borderCol,
                      ),
                      boxShadow: isDark || isSelected
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : textPri,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Description section ─────────────────────────
            _sectionLabel(loc('DESCRIPTION', 'විස්තරය', 'விளக்கம்'), isDark),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
              ),
              child: TextFormField(
                controller: _descController,
                maxLines: 5,
                style: TextStyle(fontSize: 13, color: textPri),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc('Please describe the problem',
                        'කරුණාකර ගැටලුව විස්තර කරන්න', 'சிக்கலை விவரிக்கவும்')
                    : null,
                decoration: InputDecoration(
                  hintText: loc(
                    'Describe the issue in detail...',
                    'ගැටලුව විස්තරාත්මකව විස්තර කරන්න...',
                    'சிக்கலை விரிவாக விவரிக்கவும்...',
                  ),
                  hintStyle: TextStyle(color: textSec, fontSize: 13),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryGreen, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppTheme.errorRed, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppTheme.errorRed, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Submit button ───────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        loc(
                          'Submit Report',
                          'වාර්තාව යොමු කරන්න',
                          'அறிக்கையை சமர்ப்பிக்கவும்',
                        ),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(bool isDark, String lang) {
    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 50, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            Text(
              loc('Report Submitted!', 'වාර්තාව යොමු කළා!',
                  'அறிக்கை சமர்ப்பிக்கப்பட்டது!'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc(
                'Thank you for the report.\nOur team will review it shortly.',
                'වාර්තාව සඳහා ස්තූතියි.\nඅපගේ කණ්ඩායම ඉක්මනින් සමාලෝචනය කරනු ඇත.',
                'அறிக்கைக்கு நன்றி.\nஎங்கள் குழு விரைவில் மதிப்பாய்வு செய்யும்.',
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  loc('Back to Menu', 'මෙනුවට ආපසු යන්න',
                      'மெனுவிற்கு திரும்பவும்'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
