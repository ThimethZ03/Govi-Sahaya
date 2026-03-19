import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/news_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart'; // ✅ NEW
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';

/// Displays a scrollable, filterable list of agriculture news articles.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

    @override
    State<NewsScreen> createState() => _NewsScreenState();
    
}


class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animCtrl;
  Animation<double>? _fadeAnim;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNews();
    });
  }

  @override
  void dispose() {
    _animCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final isDark = context.watch<ThemeProvider>().isDark; // ✅ use ThemeProvider
    final t = _NewsTranslations(lang);

    final filtered = _selectedCategory == 'all'
        ? newsProvider.newsList
        : newsProvider.newsList.where((n) {
            final cat = (n.category).toLowerCase().trim();
            final sel = _selectedCategory.toLowerCase();
            return cat == sel ||
                cat.replaceAll('_', '') == sel.replaceAll('_', '') ||
                cat.startsWith(sel) ||
                sel.startsWith(cat);
          }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        body: Column(
          children: [
            _buildHeader(context, t, newsProvider),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // ✅ dark mode background
                  color: isDark
                      ? const Color(0xFF0F0F0F)
                      : const Color(0xFFF4F6FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    _buildCategoryFilter(t, isDark),
                    Expanded(
                      child: newsProvider.isLoading
                          ? _buildLoader(isDark)
                          : filtered.isEmpty
                              ? _buildEmpty(t, isDark)
                              : RefreshIndicator(
                                  color: AppTheme.primaryGreen,
                                  onRefresh: () => newsProvider.refreshNews(),
                                  child: _fadeAnim != null
                                      ? FadeTransition(
                                          opacity: _fadeAnim!,
                                          child:
                                              _buildList(filtered, t, isDark),
                                        )
                                      : _buildList(filtered, t, isDark),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, _NewsTranslations t, NewsProvider newsProvider) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      )),
                  Text(t.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      )),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => newsProvider.refreshNews(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Filter Chips ─────────────────────────────────────────────
  Widget _buildCategoryFilter(_NewsTranslations t, bool isDark) {
    final categories = [
      ('all', t.catAll, Icons.grid_view_rounded),
      ('market_prices', t.catMarket, Icons.storefront_rounded),
      ('weather', t.catWeather, Icons.wb_sunny_rounded),
      ('government_policy', t.catGov, Icons.account_balance_rounded),
      ('technology', t.catTech, Icons.agriculture_rounded),
      ('success_stories', t.catSuccess, Icons.emoji_events_rounded),
      ('safety', t.catSafety, Icons.health_and_safety_rounded),
      ('alert', t.catAlert, Icons.warning_amber_rounded),
      ('events', t.catEvents, Icons.festival_rounded),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label, icon) = categories[i];
          final isSelected = _selectedCategory == key;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen
                    // ✅ dark mode unselected chip
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      // ✅ dark mode chip border
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 13,
                      color: isSelected ? Colors.white : AppTheme.primaryGreen),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      // ✅ dark mode chip label
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── News List ─────────────────────────────────────────────────────────
  Widget _buildList(List<dynamic> items, _NewsTranslations t, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        if (index == 0) return _buildFeaturedCard(items[0], t, isDark);
        return _buildNewsCard(items[index], t, isDark);
      },
    );
  }

  // ── Featured Card ─────────────────────────────────────────────────────
  // Featured card has its own dark overlay — minimal change needed
  Widget _buildFeaturedCard(dynamic news, _NewsTranslations t, bool isDark) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/news-detail', arguments: news.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(isDark ? 0.08 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildNewsImageFull(news, isDark),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildCategoryBadge(news.category ?? 'general'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(t.featured,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news.title ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.getTimeAgo(
                                news.publishedDate ?? DateTime.now()),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70),
                          ),
                          const Spacer(),
                          const Icon(Icons.remove_red_eye_outlined,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${news.views ?? 0} ${t.views}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Regular News Card ─────────────────────────────────────────────────
  Widget _buildNewsCard(dynamic news, _NewsTranslations t, bool isDark) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/news-detail', arguments: news.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          // ✅ dark mode card bg
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: _buildNewsImageFull(news, isDark),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryBadge(news.category ?? 'general'),
                    const SizedBox(height: 7),
                    Text(
                      news.title ?? t.noTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        // ✅ dark mode title
                        color: isDark ? Colors.white : AppTheme.textDark,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      news.description ?? t.noDescription,
                      style: TextStyle(
                        fontSize: 12,
                        // ✅ dark mode description
                        color: isDark ? Colors.white54 : AppTheme.textLight,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color:
                                isDark ? Colors.white38 : AppTheme.textLight),
                        const SizedBox(width: 3),
                        Text(
                          Helpers.getTimeAgo(
                              news.publishedDate ?? DateTime.now()),
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.white38 : AppTheme.textLight),
                        ),
                        const Spacer(),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 11,
                            color:
                                isDark ? Colors.white38 : AppTheme.textLight),
                        const SizedBox(width: 3),
                        Text(
                          '${news.views ?? 0}',
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.white38 : AppTheme.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Badge ────────────────────────────────────────────────────
  // Badge uses category-specific colors with opacity — no dark change needed
  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _getCategoryColor(category).withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(category),
              size: 10, color: _getCategoryColor(category)),
          const SizedBox(width: 4),
          Text(
            category.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: _getCategoryColor(category),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Full Image Widget ─────────────────────────────────────────────────
  Widget _buildNewsImageFull(dynamic news, bool isDark) {
    final imageUrl = news.coverImage?.url;
    final bool isValidUrl = imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    if (isValidUrl) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          // ✅ dark mode image placeholder loading
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryGreen.withOpacity(0.5),
            ),
          ),
        ),
        errorWidget: (context, url, error) =>
            _buildImagePlaceholder(news.category ?? 'general', isDark),
      );
    }
    return _buildImagePlaceholder(news.category ?? 'general', isDark);
  }

  // ── Image Placeholder ─────────────────────────────────────────────────
  Widget _buildImagePlaceholder(String category, bool isDark) {
    return Container(
      // ✅ dark mode placeholder bg
      color: isDark
          ? _getCategoryColor(category).withOpacity(0.05)
          : _getCategoryColor(category).withOpacity(0.08),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 36,
          color: _getCategoryColor(category).withOpacity(isDark ? 0.25 : 0.4),
        ),
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────────────────────
  Widget _buildLoader(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      itemBuilder: (_, i) => _buildShimmerCard(i == 0, isDark),
    );
  }

  Widget _buildShimmerCard(bool isFeatured, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: isFeatured ? 220 : 110,
      decoration: BoxDecoration(
        // ✅ dark mode shimmer bg
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(isFeatured ? 22 : 18),
      ),
      child: _ShimmerEffect(isDark: isDark),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────
  Widget _buildEmpty(_NewsTranslations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper_rounded,
              size: 64,
              // ✅ dark mode empty icon
              color: isDark ? Colors.white12 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(t.noNews,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                // ✅ dark mode empty text
                color: isDark ? Colors.white38 : AppTheme.textLight,
              )),
          const SizedBox(height: 8),
          Text(t.noNewsSubtitle,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white24 : AppTheme.textLight)),
        ],
      ),
    );
  }

  // ── Category Helpers ──────────────────────────────────────────────────
  Color _getCategoryColor(String? category) {
    switch ((category ?? 'general').toLowerCase()) {
      case 'government':
      case 'government_policy':
        return const Color(0xFF1565C0);
      case 'alert':
        return const Color(0xFFC62828);
      case 'market':
      case 'market_prices':
        return const Color(0xFF2E7D32);
      case 'safety':
        return const Color(0xFFE65100);
      case 'technology':
        return const Color(0xFF6A1B9A);
      case 'weather':
        return const Color(0xFF0277BD);
      case 'success_stories':
        return const Color(0xFF00695C);
      case 'events':
        return const Color(0xFFAD1457);
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch ((category ?? 'general').toLowerCase()) {
      case 'government':
      case 'government_policy':
        return Icons.account_balance_rounded;
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'market':
      case 'market_prices':
        return Icons.storefront_rounded;
      case 'safety':
        return Icons.health_and_safety_rounded;
      case 'technology':
        return Icons.agriculture_rounded;
      case 'weather':
        return Icons.wb_sunny_rounded;
      case 'success_stories':
        return Icons.emoji_events_rounded;
      case 'events':
        return Icons.festival_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

// ── Shimmer Effect ────────────────────────────────────────────────────────
class _ShimmerEffect extends StatefulWidget {
  final bool isDark; // ✅ NEW

  const _ShimmerEffect({required this.isDark});

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // ✅ dark mode shimmer animation colors
          color: widget.isDark
              ? Color.lerp(
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1E1E1E),
                  _anim.value,
                )
              : Colors.grey.shade200.withOpacity(_anim.value),
        ),
      ),
    );
  }
}

// ── Translations ──────────────────────────────────────────────────────────
class _NewsTranslations {
  final String lang;
  const _NewsTranslations(this.lang);

  String get title => lang == 'si'
      ? 'කෘෂිකාර්මික පුවත්'
      : lang == 'ta'
          ? 'விவசாய செய்திகள்'
          : 'Agri News';

  String get subtitle => lang == 'si'
      ? 'නවතම ගොවිතැන් ප්‍රවෘත්ති'
      : lang == 'ta'
          ? 'சமீபத்திய விவசாய செய்திகள்'
          : 'Latest farming updates';

  String get featured => lang == 'si'
      ? 'ප්‍රධාන'
      : lang == 'ta'
          ? 'சிறப்பு'
          : 'Featured';

  String get views => lang == 'si'
      ? 'නැරඹීම්'
      : lang == 'ta'
          ? 'பார்வைகள்'
          : 'views';

  String get noTitle => lang == 'si'
      ? 'මාතෘකාවක් නැත'
      : lang == 'ta'
          ? 'தலைப்பு இல்லை'
          : 'No title';

  String get noDescription => lang == 'si'
      ? 'විස්තරයක් නැත'
      : lang == 'ta'
          ? 'விளக்கம் இல்லை'
          : 'No description available';

  String get noNews => lang == 'si'
      ? 'පුවත් නොමැත'
      : lang == 'ta'
          ? 'செய்திகள் இல்லை'
          : 'No news available';

  String get noNewsSubtitle => lang == 'si'
      ? 'නැවුම් කිරීමට ඉහළට අදින්න'
      : lang == 'ta'
          ? 'புதுப்பிக்க மேலே இழுக்கவும்'
          : 'Pull down to refresh';

  String get catAll => lang == 'si'
      ? 'සියල්ල'
      : lang == 'ta'
          ? 'அனைத்தும்'
          : 'All';

  String get catMarket => lang == 'si'
      ? 'වෙළඳ මිල'
      : lang == 'ta'
          ? 'சந்தை விலை'
          : 'Prices';

  String get catWeather => lang == 'si'
      ? 'කාලගුණ'
      : lang == 'ta'
          ? 'வானிலை'
          : 'Weather';

  String get catGov => lang == 'si'
      ? 'රජය ප්‍රතිපත්ති'
      : lang == 'ta'
          ? 'அரசு கொள்கை'
          : 'Policy';

  String get catTech => lang == 'si'
      ? 'කෘෂි තාක්ෂණ'
      : lang == 'ta'
          ? 'விவசாய தொழில்நுட்பம்'
          : 'Agri Tech';

  String get catSuccess => lang == 'si'
      ? 'සාර්ථක කතා'
      : lang == 'ta'
          ? 'வெற்றிக் கதைகள்'
          : 'Success';

  String get catSafety => lang == 'si'
      ? 'ගොවිතැන් ආරක්ෂාව'
      : lang == 'ta'
          ? 'விவசாய பாதுகாப்பு'
          : 'Safety';

  String get catAlert => lang == 'si'
      ? 'අනතුරු ඇඟවීම'
      : lang == 'ta'
          ? 'எச்சரிக்கை'
          : 'Alert';

  String get catEvents => lang == 'si'
      ? 'කෘෂි සිදුවීම්'
      : lang == 'ta'
          ? 'விவசாய நிகழ்வுகள்'
          : 'Agri Events';
}
