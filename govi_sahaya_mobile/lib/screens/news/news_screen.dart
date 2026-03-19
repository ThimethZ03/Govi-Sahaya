import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/news_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';

/// NewsScreen displays a scrollable, filterable list of agriculture news articles.
/// Supports dark mode, multilingual labels (EN/SI/TA), and category filtering.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  
  // Animation controller for fade-in effect when screen loads
  AnimationController? _animCtrl;
  Animation<double>? _fadeAnim;
  
  // Tracks currently selected category filter chip
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();

    // Initialise fade animation controller with 500ms duration
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // Apply ease-out curve to the fade animation
    _fadeAnim = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);

    // Fetch news after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNews();
    });
  }

  @override
  void dispose() {
    // Dispose animation controller to free memory
    _animCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for reactive UI updates
    final newsProvider = context.watch<NewsProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final isDark = context.watch<ThemeProvider>().isDark;
    final t = _NewsTranslations(lang);

    // Filter news list based on selected category
    // If 'all' is selected, show all articles
    final filtered = _selectedCategory == 'all'
        ? newsProvider.newsList
        : newsProvider.newsList.where((n) {
            final cat = (n.category).toLowerCase().trim();
            final sel = _selectedCategory.toLowerCase();
            // Support partial and underscore-insensitive matching
            return cat == sel ||
                cat.replaceAll('_', '') == sel.replaceAll('_', '') ||
                cat.startsWith(sel) ||
                sel.startsWith(cat);
          }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Force light status bar icons on green header
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        body: Column(
          children: [
            // Green header with back button, title, and refresh button
            _buildHeader(context, t, newsProvider),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // Use dark or light background depending on theme
                  color: isDark
                      ? const Color(0xFF0F0F0F)
                      : const Color(0xFFF4F6FA),
                  // Rounded top corners for card-style layout
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    // Horizontal scrollable category filter chips
                    _buildCategoryFilter(t, isDark),
                    Expanded(
                      child: newsProvider.isLoading
                          // Show shimmer loading cards while fetching
                          ? _buildLoader(isDark)
                          : filtered.isEmpty
                              // Show empty state if no articles match filter
                              ? _buildEmpty(t, isDark)
                              : RefreshIndicator(
                                  color: AppTheme.primaryGreen,
                                  onRefresh: () => newsProvider.refreshNews(),
                                  child: _fadeAnim != null
                                      // Apply fade-in animation to news list
                                      ? FadeTransition(
                                          opacity: _fadeAnim!,
                                          child: _buildList(filtered, t, isDark),
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
  /// Builds the green top header with back button, screen title, and refresh button
  Widget _buildHeader(
      BuildContext context, _NewsTranslations t, NewsProvider newsProvider) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            // Back button navigates to previous screen
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
            // Screen title and subtitle (translated based on language)
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
            // Refresh button triggers a new API fetch
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
  /// Builds horizontally scrollable category filter chips
  /// Each chip filters the news list by its assigned category key
  Widget _buildCategoryFilter(_NewsTranslations t, bool isDark) {
    // Define all available categories with their label and icon
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
            // Update selected category and rebuild filtered list
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                // Selected chip uses primary green; unselected uses white or dark bg
                color: isSelected
                    ? AppTheme.primaryGreen
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  width: 1.2,
                ),
                // Add green glow shadow to selected chip
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
  /// Builds the scrollable news list
  /// First item is always rendered as a large featured card
  /// Remaining items are rendered as compact regular cards
  Widget _buildList(List<dynamic> items, _NewsTranslations t, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        // First item gets featured card layout with hero image
        if (index == 0) return _buildFeaturedCard(items[0], t, isDark);
        // Remaining items get compact horizontal card layout
        return _buildNewsCard(items[index], t, isDark);
      },
    );
  }

  // ── Featured Card ─────────────────────────────────────────────────────
  /// Builds the large featured card shown at the top of the news list
  /// Displays a full-width hero image with gradient overlay and article info
  Widget _buildFeaturedCard(dynamic news, _NewsTranslations t, bool isDark) {
    return GestureDetector(
      // Navigate to news detail screen passing the article ID
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
              // Full-width cover image
              _buildNewsImageFull(news, isDark),
              // Dark gradient overlay for text readability
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
              // Article info positioned at bottom of card
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
                          // Category badge showing article type
                          _buildCategoryBadge(news.category ?? 'general'),
                          const SizedBox(width: 8),
                          // Featured badge shown in amber
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
                      // Article title with max 2 lines
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
                      // Footer row with time ago and view count
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
  /// Builds a compact horizontal news card for regular (non-featured) articles
  /// Shows thumbnail image on the left and article info on the right
  Widget _buildNewsCard(dynamic news, _NewsTranslations t, bool isDark) {
    return GestureDetector(
      // Navigate to news detail screen passing the article ID
      onTap: () =>
          Navigator.pushNamed(context, '/news-detail', arguments: news.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          // Dark mode uses dark card background; light mode uses white
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          // Only show shadow in light mode
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
            // Thumbnail image with rounded left corners
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
            // Article info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    _buildCategoryBadge(news.category ?? 'general'),
                    const SizedBox(height: 7),
                    // Article title with max 2 lines
                    Text(
                      news.title ?? t.noTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textDark,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Short description with max 1 line
                    Text(
                      news.description ?? t.noDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppTheme.textLight,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Footer row with time ago and view count
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color: isDark ? Colors.white38 : AppTheme.textLight),
                        const SizedBox(width: 3),
                        Text(
                          Helpers.getTimeAgo(
                              news.publishedDate ?? DateTime.now()),
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : AppTheme.textLight),
                        ),
                        const Spacer(),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 11,
                            color: isDark ? Colors.white38 : AppTheme.textLight),
                        const SizedBox(width: 3),
                        Text(
                          '${news.views ?? 0}',
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : AppTheme.textLight),
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
  /// Builds a small coloured badge showing the article category
  /// Uses category-specific colours with low opacity background
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
          // Category icon
          Icon(_getCategoryIcon(category),
              size: 10, color: _getCategoryColor(category)),
          const SizedBox(width: 4),
          // Category label in uppercase
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
  /// Loads and displays the article cover image from a URL
  /// Shows a shimmer placeholder while loading
  /// Falls back to a category icon placeholder if URL is invalid or image fails
  Widget _buildNewsImageFull(dynamic news, bool isDark) {
    final imageUrl = news.coverImage?.url;

    // Validate that URL exists and starts with http or https
    final bool isValidUrl = imageUrl != null &&
        imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    if (isValidUrl) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Loading placeholder with spinner
        placeholder: (context, url) => Container(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryGreen.withOpacity(0.5),
            ),
          ),
        ),
        // Error fallback shows category icon placeholder
        errorWidget: (context, url, error) =>
            _buildImagePlaceholder(news.category ?? 'general', isDark),
      );
    }
    // No valid URL — show category icon placeholder directly
    return _buildImagePlaceholder(news.category ?? 'general', isDark);
  }

  // ── Image Placeholder ─────────────────────────────────────────────────
  /// Builds a category-coloured placeholder shown when no image is available
  Widget _buildImagePlaceholder(String category, bool isDark) {
    return Container(
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
  /// Builds a list of shimmer placeholder cards shown while news is loading
  Widget _buildLoader(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 5,
      // First card is larger to match featured card size
      itemBuilder: (_, i) => _buildShimmerCard(i == 0, isDark),
    );
  }

  /// Builds a single animated shimmer placeholder card
  Widget _buildShimmerCard(bool isFeatured, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: isFeatured ? 220 : 110,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(isFeatured ? 22 : 18),
      ),
      child: _ShimmerEffect(isDark: isDark),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────
  /// Builds the empty state UI shown when no articles match the selected filter
  Widget _buildEmpty(_NewsTranslations t, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper_rounded,
              size: 64,
              color: isDark ? Colors.white12 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(t.noNews,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
  /// Returns the display colour associated with a news category
  Color _getCategoryColor(String? category) {
    switch ((category ?? 'general').toLowerCase()) {
      case 'government':
      case 'government_policy':
        return const Color(0xFF1565C0); // Blue
      case 'alert':
        return const Color(0xFFC62828); // Red
      case 'market':
      case 'market_prices':
        return const Color(0xFF2E7D32); // Green
      case 'safety':
        return const Color(0xFFE65100); // Orange
      case 'technology':
        return const Color(0xFF6A1B9A); // Purple
      case 'weather':
        return const Color(0xFF0277BD); // Light blue
      case 'success_stories':
        return const Color(0xFF00695C); // Teal
      case 'events':
        return const Color(0xFFAD1457); // Pink
      default:
        return AppTheme.primaryGreen;   // Default green
    }
  }

  /// Returns the icon associated with a news category
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
/// Animated shimmer widget shown as a loading placeholder for news cards
/// Pulses between two opacity values to simulate a loading effect
class _ShimmerEffect extends StatefulWidget {
  final bool isDark;

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
    // Repeat animation back and forth for pulsing shimmer effect
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Animate opacity between 0.4 and 0.9
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Dispose controller to prevent memory leaks
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
          // Interpolate between dark or light shimmer colours
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
/// Provides translated UI strings for English, Sinhala, and Tamil languages
/// Used throughout NewsScreen to support multilingual display
class _NewsTranslations {
  final String lang;
  const _NewsTranslations(this.lang);

  // Screen title in EN/SI/TA
  String get title => lang == 'si'
      ? 'කෘෂිකාර්මික පුවත්'
      : lang == 'ta' ? 'விவசாய செய்திகள்' : 'Agri News';

  // Screen subtitle
  String get subtitle => lang == 'si'
      ? 'නවතම ගොවිතැන් ප්‍රවෘත්ති'
      : lang == 'ta' ? 'சமீபத்திய விவசாய செய்திகள்' : 'Latest farming updates';

  // Featured badge label
  String get featured => lang == 'si'
      ? 'ප්‍රධාන' : lang == 'ta' ? 'சிறப்பு' : 'Featured';

  // Views label
  String get views => lang == 'si'
      ? 'නැරඹීම්' : lang == 'ta' ? 'பார்வைகள்' : 'views';

  // Fallback labels for missing data
  String get noTitle => lang == 'si'
      ? 'මාතෘකාවක් නැත' : lang == 'ta' ? 'தலைப்பு இல்லை' : 'No title';

  String get noDescription => lang == 'si'
      ? 'විස්තරයක් නැත' : lang == 'ta' ? 'விளக்கம் இல்லை' : 'No description available';

  // Empty state messages
  String get noNews => lang == 'si'
      ? 'පුවත් නොමැත' : lang == 'ta' ? 'செய்திகள் இல்லை' : 'No news available';

  String get noNewsSubtitle => lang == 'si'
      ? 'නැවුම් කිරීමට ඉහළට අදින්න'
      : lang == 'ta' ? 'புதுப்பிக்க மேலே இழுக்கவும்' : 'Pull down to refresh';

  // Category chip labels
  String get catAll => lang == 'si' ? 'සියල්ල' : lang == 'ta' ? 'அனைத்தும்' : 'All';
  String get catMarket => lang == 'si' ? 'වෙළඳ මිල' : lang == 'ta' ? 'சந்தை விலை' : 'Prices';
  String get catWeather => lang == 'si' ? 'කාලගුණ' : lang == 'ta' ? 'வானிலை' : 'Weather';
  String get catGov => lang == 'si' ? 'රජය ප්‍රතිපත්ති' : lang == 'ta' ? 'அரசு கொள்கை' : 'Policy';
  String get catTech => lang == 'si' ? 'කෘෂි තාක්ෂණ' : lang == 'ta' ? 'விவசாய தொழில்நுட்பம்' : 'Agri Tech';
  String get catSuccess => lang == 'si' ? 'සාර්ථක කතා' : lang == 'ta' ? 'வெற்றிக் கதைகள்' : 'Success';
  String get catSafety => lang == 'si' ? 'ගොවිතැන් ආරක්ෂාව' : lang == 'ta' ? 'விவசாய பாதுகாப்பு' : 'Safety';
  String get catAlert => lang == 'si' ? 'අනතුරු ඇඟවීම' : lang == 'ta' ? 'எச்சரிக்கை' : 'Alert';
  String get catEvents => lang == 'si' ? 'කෘෂි සිදුවීම්' : lang == 'ta' ? 'விவசாய நிகழ்வுகள்' : 'Agri Events';
}