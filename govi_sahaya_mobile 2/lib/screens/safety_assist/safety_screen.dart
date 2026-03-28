// lib/screens/safety_assist/safety_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/safety_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/routes.dart';
import 'first_aid_detail_screen.dart';
import 'nearby_hospitals_screen.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafetyProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _topBarButton({required Widget child}) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDark;
    final lang = langProvider.languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    final title = lang == 'si'
        ? 'ආරක්ෂිත සහාය'
        : lang == 'ta'
            ? 'பாதுகாப்பு உதவி'
            : 'Safety Assist';

    // ✅ FIX: body background matches scaffold to eliminate dark border line
    final bodyColor = isDark ? AppTheme.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false, // ✅ FIX: prevent double bottom padding causing line
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _topBarButton(
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            )),
                        Text(
                          lang == 'si'
                              ? 'හදිසි ආධාර සහ සෞඛ්‍ය'
                              : lang == 'ta'
                                  ? 'அவசர உதவி மற்றும் சுகாதாரம்'
                                  : 'Emergency & Health Guide',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ REMOVED: Language switcher button
                  // ✅ REMOVED: Dark mode toggle button

                  // Notifications
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _topBarButton(
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 18),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              constraints: const BoxConstraints(
                                  minWidth: 15, minHeight: 15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.primaryGreen, width: 1.5),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Tab Bar ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                // ✅ FIX: remove default divider that causes dark line
                dividerColor: Colors.transparent,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: Colors.white,
                labelStyle:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                padding: const EdgeInsets.all(4),
                tabs: [
                  Tab(
                      text: lang == 'si'
                          ? 'හදිසි'
                          : lang == 'ta'
                              ? 'அவசர'
                              : 'Emergency'),
                  Tab(
                      text: lang == 'si'
                          ? 'ප්‍රථමාධාර'
                          : lang == 'ta'
                              ? 'முதலுதவி'
                              : 'First Aid'),
                  Tab(
                      text: lang == 'si'
                          ? 'රෝහල්'
                          : lang == 'ta'
                              ? 'மருத்துவமனை'
                              : 'Hospitals'),
                  Tab(
                      text: lang == 'si'
                          ? 'ඉඟි'
                          : lang == 'ta'
                              ? 'குறிப்புகள்'
                              : 'Tips'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Body ────────────────────────────────────────────
            // ✅ FIX: wrap with same color as body to kill green bleed-through
            Expanded(
              child: Container(
                color: AppTheme.primaryGreen, // ✅ kills any gap/line at edges
                child: Container(
                  decoration: BoxDecoration(
                    color: bodyColor,
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
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _EmergencyTab(isDark: isDark, lang: lang),
                        _FirstAidTab(isDark: isDark, lang: lang),
                        NearbyHospitalsScreen(isDark: isDark, lang: lang),
                        _SafetyTipsTab(isDark: isDark, lang: lang),
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

// ═══════════════════════════════════════════════════════════════════
// TAB 1 — Emergency Contacts
// ═══════════════════════════════════════════════════════════════════
class _EmergencyTab extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _EmergencyTab({required this.isDark, required this.lang});

  Color _hex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  IconData _icon(String cat) {
    switch (cat) {
      case 'police':
        return Icons.local_police_rounded;
      case 'medical':
        return Icons.local_hospital_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'agriculture':
        return Icons.agriculture_rounded;
      case 'disaster':
        return Icons.warning_amber_rounded;
      case 'poison':
        return Icons.science_rounded;
      default:
        return Icons.phone_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SafetyProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.fetchEmergencyContacts(),
      color: AppTheme.primaryGreen,
      child: provider.isLoadingContacts && provider.contacts.isEmpty
          ? _buildSkeleton(isDark)
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              itemCount: provider.contacts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSectionLabel(
                      lang == 'si'
                          ? 'හදිසි දුරකතන'
                          : lang == 'ta'
                              ? 'அவசர தொடர்புகள்'
                              : 'EMERGENCY CONTACTS',
                      isDark,
                    ),
                  );
                }
                final c = provider.contacts[index - 1];
                final color = _hex(c.color);
                final name = lang == 'si'
                    ? c.nameSi
                    : lang == 'ta'
                        ? c.nameTa
                        : c.name;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: color.withOpacity(isDark ? 0.35 : 0.25)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Icon(_icon(c.category),
                          color: Colors.white, size: 24),
                    ),
                    title: Text(name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textDark,
                        )),
                    subtitle: Text(c.number,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        )),
                    trailing: GestureDetector(
                      onTap: () => _call(c.number),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.phone_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSkeleton(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          children: List.generate(
              5,
              (i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  )),
        ),
      );

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2 — First Aid
// ═══════════════════════════════════════════════════════════════════
class _FirstAidTab extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _FirstAidTab({required this.isDark, required this.lang});

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
    final provider = context.watch<SafetyProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.fetchFirstAidGuides(),
      color: AppTheme.primaryGreen,
      child: provider.isLoadingGuides && provider.firstAidGuides.isEmpty
          ? _buildSkeleton(isDark)
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              itemCount: provider.firstAidGuides.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSectionLabel(
                      lang == 'si'
                          ? 'ප්‍රථමාධාර මාර්ගෝපදේශ'
                          : lang == 'ta'
                              ? 'முதலுதவி வழிகாட்டி'
                              : 'FIRST AID GUIDE',
                      isDark,
                    ),
                  );
                }
                final g = provider.firstAidGuides[index - 1];
                final color = _hex(g.color);
                final title = lang == 'si'
                    ? g.titleSi
                    : lang == 'ta'
                        ? g.titleTa
                        : g.title;
                final subtitle = lang == 'si'
                    ? (g.stepsSi.isNotEmpty ? g.stepsSi.first : '')
                    : lang == 'ta'
                        ? (g.stepsTa.isNotEmpty ? g.stepsTa.first : '')
                        : (g.steps.isNotEmpty ? g.steps.first : '');

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FirstAidDetailScreen(
                          guide: g, isDark: isDark, lang: lang),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              isDark ? Colors.white12 : Colors.grey.shade200),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(_icon(g.icon), color: color, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.textDark,
                                  )),
                              const SizedBox(height: 4),
                              Text(subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.textLight,
                                  )),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textLight,
                            size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSkeleton(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          children: List.generate(
              5,
              (i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  )),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
// TAB 4 — Safety Tips
// ═══════════════════════════════════════════════════════════════════
class _SafetyTipsTab extends StatelessWidget {
  final bool isDark;
  final String lang;
  const _SafetyTipsTab({required this.isDark, required this.lang});

  Color _hex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  IconData _icon(String name) {
    switch (name) {
      case 'health_and_safety':
        return Icons.health_and_safety_rounded;
      case 'wb_sunny':
        return Icons.wb_sunny_rounded;
      case 'build':
        return Icons.build_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'electric_bolt':
        return Icons.electric_bolt_rounded;
      case 'pest_control':
        return Icons.pest_control_rounded;
      default:
        return Icons.tips_and_updates_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SafetyProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.fetchSafetyTips(),
      color: AppTheme.primaryGreen,
      child: provider.isLoadingTips && provider.safetyTips.isEmpty
          ? _buildSkeleton(isDark)
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              itemCount: provider.safetyTips.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSectionLabel(
                      lang == 'si'
                          ? 'ආරක්ෂිතතා ඉඟි'
                          : lang == 'ta'
                              ? 'பாதுகாப்பு குறிப்புகள்'
                              : 'SAFETY TIPS',
                      isDark,
                    ),
                  );
                }
                final t = provider.safetyTips[index - 1];
                final color = _hex(t.color);
                final title = lang == 'si'
                    ? t.titleSi
                    : lang == 'ta'
                        ? t.titleTa
                        : t.title;
                final desc = lang == 'si'
                    ? t.descriptionSi
                    : lang == 'ta'
                        ? t.descriptionTa
                        : t.description;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: color.withOpacity(isDark ? 0.3 : 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withOpacity(isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_icon(t.icon), color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textDark,
                                )),
                            const SizedBox(height: 5),
                            Text(desc,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textLight,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSkeleton(bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          children: List.generate(
              5,
              (i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  )),
        ),
      );
}

// ── Shared section label ─────────────────────────────────────────────
Widget _buildSectionLabel(String label, bool isDark) => Row(
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
        Text(label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textLight.withOpacity(0.7),
              letterSpacing: 1.5,
            )),
      ],
    );
