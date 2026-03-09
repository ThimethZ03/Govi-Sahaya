import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/knowledge_hub_service.dart';
import '../../models/guide_model.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final KnowledgeHubService _service = KnowledgeHubService();

  bool _isLoading = true;

  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<GuideModel> _guides = [];
  List<GuideModel> _featuredGuides = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final lang = context.read<LanguageProvider>().languageCode;
    try {
      final cats = await _service.getCategories();
      final guides = await _service.getGuides(language: lang);
      final featured = await _service.getFeaturedGuides(language: lang);
      if (!mounted) return;
      setState(() {
        _categories = ['All', ..._mapCategories(cats)];
        _guides = guides;
        _featuredGuides = featured;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<String> _mapCategories(List<String> cats) => cats.map((c) {
        const map = {
          'crop_management': 'Crop Management',
          'pest_control': 'Pest Control',
          'fertilizers': 'Fertilizers',
          'irrigation': 'Irrigation',
          'harvesting': 'Harvesting',
          'storage': 'Storage',
          'marketing': 'Marketing',
          'organic_farming': 'Organic Farming',
          'modern_techniques': 'Modern Techniques',
        };
        return map[c] ?? c;
      }).toList();

  String _toBackendCategory(String label) {
    const map = {
      'Crop Management': 'crop_management',
      'Pest Control': 'pest_control',
      'Fertilizers': 'fertilizers',
      'Irrigation': 'irrigation',
      'Harvesting': 'harvesting',
      'Storage': 'storage',
      'Marketing': 'marketing',
      'Organic Farming': 'organic_farming',
      'Modern Techniques': 'modern_techniques',
    };
    return map[label] ?? label;
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final lang = context.read<LanguageProvider>().languageCode;
    final category = _selectedCategory == 'All'
        ? null
        : _toBackendCategory(_selectedCategory);
    try {
      final guides = await _service.getGuides(
        category: category,
        language: lang,
        search: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _guides = guides;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final title = loc('Knowledge Hub', 'දැනුම් සමුදාය', 'அறிவியல் மையம்');
    final subtitle = loc(
      'Guides and articles for better farming',
      'වැවිලි හැදෑරීමට උපකාරී මාර්ගෝපදේශ',
      'விவசாய வழிகாட்டி மற்றும் கட்டுரைகள்',
    );
    final searchHint = loc(
      'Search guides...',
      'මාර්ගෝපදේශ සෙවීම...',
      'வழிகாட்டி தேடவும்...',
    );

    final bodyBg = isDark ? AppTheme.darkBackground : const Color(0xFFF7F9F7);

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ═══════════════════════════════════════════════
            // Header
            // ═══════════════════════════════════════════════
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

                  // ── FIX: Notification bell with correct badge position ──
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // The button container with a known 38×38 size
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 20),
                        ),
                        // Badge anchors to the top-right corner of the 38×38 box
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
                                  height: 1.1,
                                ),
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

            const SizedBox(height: 14),

            // ═══════════════════════════════════════════════
            // Search + category chips
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Column(
                  children: [
                    // Search field
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (v) {
                          _searchQuery = v.trim();
                          _refresh();
                        },
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: AppTheme.textLight,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryGreen,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Category chips
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          final isSelected = cat == _selectedCategory;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              _refresh();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                  right: i == _categories.length - 1 ? 0 : 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white38,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppTheme.primaryGreen,
                    child: _isLoading
                        ? _buildSkeleton(isDark)
                        : _buildContent(isDark, lang),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header icon button (back button only — bell has its own Stack) ──
  Widget _headerButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
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

  Widget _buildSkeleton(bool isDark) {
    final shimmer = isDark ? AppTheme.darkCard : Colors.grey.shade100;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 30),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: shimmer,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, String lang) {
    String loc(String en, String si, String ta) => lang == 'si'
        ? si
        : lang == 'ta'
            ? ta
            : en;

    final featuredLabel =
        loc('FEATURED GUIDES', 'විශේෂ මාර්ගෝපදේශ', 'சிறப்பு வழிகாட்டிகள்');
    final guidesLabel =
        loc('FARMING GUIDES', 'ව්‍යාපාරික මාර්ගෝපදේශ', 'விவசாய வழிகாட்டிகள்');
    final noGuidesTitle =
        loc('No guides found', 'ග්‍රන්ථ නොමැත', 'கையேடுகள் இல்லை');
    final noGuidesBody = loc(
      'Try a different category or search term.',
      'වෙනත් කාණ්ඩයක් හෝ සෙවුම් වචනයක් අත්හදා බලන්න.',
      'வேறு வகை அல்லது தேடல் சொல் முயற்சிக்கவும்.',
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (_featuredGuides.isNotEmpty && _searchQuery.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 0, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(featuredLabel, isDark),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: _featuredGuides.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _FeaturedCard(
                        guide: _featuredGuides[i],
                        lang: lang,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.guideDetail,
                          arguments: _featuredGuides[i],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, _featuredGuides.isEmpty ? 24 : 8, 16, 12),
            child: _sectionLabel(guidesLabel, isDark),
          ),
        ),
        if (_guides.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              isDark: isDark,
              title: noGuidesTitle,
              body: noGuidesBody,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _GuideListTile(
                  guide: _guides[i],
                  isDark: isDark,
                  lang: lang,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.guideDetail,
                    arguments: _guides[i],
                  ),
                ),
                childCount: _guides.length,
              ),
            ),
          ),
      ],
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

// ══════════════════════════════════════════════════════════════════
// Featured horizontal card
// ══════════════════════════════════════════════════════════════════
class _FeaturedCard extends StatelessWidget {
  final GuideModel guide;
  final String lang;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.guide,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = lang == 'si' &&
            guide.titleSinhala != null &&
            guide.titleSinhala!.isNotEmpty
        ? guide.titleSinhala!
        : guide.title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              guide.coverImage.isNotEmpty
                  ? Image.network(
                      guide.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientBg(),
                    )
                  : _gradientBg(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        guide.category.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            color: Colors.white70, size: 11),
                        const SizedBox(width: 3),
                        Text('${guide.views}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10)),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite_border,
                            color: Colors.redAccent, size: 11),
                        const SizedBox(width: 3),
                        Text('${guide.likes}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════
// Guide list tile
// ══════════════════════════════════════════════════════════════════
class _GuideListTile extends StatelessWidget {
  final GuideModel guide;
  final bool isDark;
  final String lang;
  final VoidCallback onTap;

  const _GuideListTile({
    Key? key,
    required this.guide,
    required this.isDark,
    required this.lang,
    required this.onTap,
  }) : super(key: key);

  IconData _categoryIcon(String cat) {
    const icons = {
      'crop_management': Icons.agriculture_rounded,
      'pest_control': Icons.bug_report_rounded,
      'fertilizers': Icons.science_rounded,
      'irrigation': Icons.water_drop_rounded,
      'harvesting': Icons.grass_rounded,
      'storage': Icons.inventory_2_rounded,
      'marketing': Icons.campaign_rounded,
      'organic_farming': Icons.eco_rounded,
      'modern_techniques': Icons.lightbulb_rounded,
    };
    return icons[cat] ?? Icons.menu_book_rounded;
  }

  Color _difficultyColor(String? d) {
    switch (d?.toLowerCase()) {
      case 'beginner':
        return AppTheme.successGreen;
      case 'intermediate':
        return AppTheme.warningOrange;
      case 'advanced':
        return AppTheme.errorRed;
      default:
        return AppTheme.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTitle = lang == 'si' &&
            guide.titleSinhala != null &&
            guide.titleSinhala!.isNotEmpty
        ? guide.titleSinhala!
        : guide.title;

    final desc =
        guide.description.isNotEmpty ? guide.description : guide.content;

    final cardBg = isDark ? AppTheme.darkCard : Colors.white;
    final textPri = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;
    final textSec = isDark ? AppTheme.darkTextSecondary : AppTheme.textLight;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderCol),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: guide.coverImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          guide.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            _categoryIcon(guide.category),
                            color: AppTheme.primaryGreen,
                            size: 26,
                          ),
                        ),
                      )
                    : Icon(
                        _categoryIcon(guide.category),
                        color: AppTheme.primaryGreen,
                        size: 26,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPri,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: textSec,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _badge(
                          label: guide.category.replaceAll('_', ' '),
                          bgColor: AppTheme.primaryGreen
                              .withOpacity(isDark ? 0.18 : 0.08),
                          textColor: isDark
                              ? AppTheme.accentGreen
                              : AppTheme.primaryGreen,
                          icon: Icons.category_outlined,
                        ),
                        if (guide.difficulty != null &&
                            guide.difficulty!.isNotEmpty)
                          _badge(
                            label: guide.difficulty!,
                            bgColor: _difficultyColor(guide.difficulty)
                                .withOpacity(isDark ? 0.18 : 0.08),
                            textColor: _difficultyColor(guide.difficulty),
                            icon: Icons.speed_outlined,
                          ),
                        _badge(
                          label: '${guide.views} views · ${guide.likes} likes',
                          bgColor:
                              isDark ? Colors.white10 : Colors.grey.shade100,
                          textColor: textSec,
                          icon: Icons.bar_chart_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      AppTheme.primaryGreen.withOpacity(isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Empty state widget
// ══════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String body;

  const _EmptyState({
    required this.isDark,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
