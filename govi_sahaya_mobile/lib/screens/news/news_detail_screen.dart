import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/news_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;
  const NewsDetailScreen({super.key, required this.newsId});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  AnimationController? _animCtrl;
  Animation<double>? _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNewsById(widget.newsId);
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
    final t = _DetailTranslations(lang);
    final news = newsProvider.selectedNews;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Loading ────────────────────────────────────────────────────────
    if (newsProvider.isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F6FA),
        body: Column(
          children: [
            Container(
              height: 300,
              color: AppTheme.primaryGreen.withOpacity(0.15),
              child: const _ShimmerBlock(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerLine(200, 16),
                  const SizedBox(height: 12),
                  _shimmerLine(double.infinity, 28),
                  const SizedBox(height: 8),
                  _shimmerLine(280, 28),
                  const SizedBox(height: 20),
                  _shimmerLine(double.infinity, 14),
                  const SizedBox(height: 8),
                  _shimmerLine(double.infinity, 14),
                  const SizedBox(height: 8),
                  _shimmerLine(180, 14),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Error / Not Found ──────────────────────────────────────────────
    if (news == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    _backButton(context),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F0F0F)
                      : const Color(0xFFF4F6FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.error_outline_rounded,
                            size: 40, color: Colors.red.shade300),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t.notFound,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        newsProvider.errorMessage ?? t.notFoundSubtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textLight),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: Text(t.goBack),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Main Content ───────────────────────────────────────────────────
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F6FA),
        body: _fadeAnim != null
            ? FadeTransition(
                opacity: _fadeAnim!,
                child: _buildBody(context, news, t, isDark),
              )
            : _buildBody(context, news, t, isDark),
        // ── Bottom Action Bar ────────────────────────────────────────
        bottomNavigationBar: _buildBottomBar(context, news, t, isDark),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, dynamic news, _DetailTranslations t, bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Image Sliver AppBar ─────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: AppTheme.primaryGreen,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Hero image
                _buildHeroImage(news),

                // Top gradient for legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Bottom gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Back + Share buttons overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _backButton(context),
                          _shareButton(context, news, t),
                        ],
                      ),
                    ),
                  ),
                ),

                // Category badge at bottom of image
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: _buildCategoryBadge(news.category ?? 'general',
                      solid: true),
                ),
              ],
            ),
          ),
        ),

        // ── Article Content ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F6FA),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // White card content area
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ──────────────────────────────────────
                      Text(
                        news.title ?? t.noTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textDark,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Meta row ───────────────────────────────────
                      _buildMetaRow(news, t, isDark),

                      const SizedBox(height: 18),
                      Divider(
                          color:
                              isDark ? Colors.white12 : Colors.grey.shade100),
                      const SizedBox(height: 18),

                      // ── Description highlight ──────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                news.description ?? t.noDescription,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: isDark
                                      ? Colors.white70
                                      : AppTheme.textDark,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Full Content ───────────────────────────────────
                if ((news.content ?? '').isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t.fullArticle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: isDark
                                    ? Colors.white54
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          news.content ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.8,
                            color: isDark ? Colors.white70 : AppTheme.textDark,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Tags / Related ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: _buildTagsRow(news, t, isDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Bar ────────────────────────────────────────────────
  Widget _buildBottomBar(
      BuildContext context, dynamic news, _DetailTranslations t, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Like button
          Expanded(
            child: GestureDetector(
              onTap: _isLiked
                  ? null
                  : () {
                      setState(() => _isLiked = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.liked),
                          backgroundColor: Colors.red.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: _isLiked
                      ? Colors.red.shade50
                      : (isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        _isLiked ? Colors.red.shade200 : Colors.grey.shade200,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: _isLiked ? Colors.red : AppTheme.textLight,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${news.likes ?? 0}  ${t.likes}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isLiked ? Colors.red : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Share button
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Share.share(
                  '${news.title ?? ''}\n\n${news.description ?? ''}\n\n${t.shareMsg}',
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 7),
                    Text(
                      '${news.shares ?? 0}  ${t.shares}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Meta Row ─────────────────────────────────────────────────────────
  Widget _buildMetaRow(dynamic news, _DetailTranslations t, bool isDark) {
    return Row(
      children: [
        _metaChip(
          icon: Icons.access_time_rounded,
          label: Helpers.getTimeAgo(news.publishedDate ?? DateTime.now()),
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _metaChip(
          icon: Icons.remove_red_eye_outlined,
          label: '${news.views ?? 0} ${t.views}',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _metaChip(
      {required IconData icon, required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade100, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  // ── Tags Row ──────────────────────────────────────────────────────────
  Widget _buildTagsRow(dynamic news, _DetailTranslations t, bool isDark) {
    final category = news.category ?? 'general';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(Icons.label_outline_rounded,
              size: 15, color: AppTheme.textLight),
          const SizedBox(width: 8),
          Text(
            t.tags,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10),
          _buildCategoryBadge(category),
          const SizedBox(width: 8),
          _buildCategoryBadge('agriculture'),
        ],
      ),
    );
  }

  // ── Category Badge ────────────────────────────────────────────────────
  Widget _buildCategoryBadge(String category, {bool solid = false}) {
    final color = _getCategoryColor(category);
    if (solid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getCategoryIcon(category), size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              category.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(category), size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            category.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Image ────────────────────────────────────────────────────────
  Widget _buildHeroImage(dynamic news) {
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
          color: AppTheme.primaryGreen.withOpacity(0.15),
          child: const _ShimmerBlock(),
        ),
        errorWidget: (context, url, error) =>
            _buildImagePlaceholder(news.category ?? 'general'),
      );
    }
    return _buildImagePlaceholder(news.category ?? 'general');
  }

  Widget _buildImagePlaceholder(String category) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(category),
            _getCategoryColor(category).withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 90,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }

  // ── Reusable Buttons ──────────────────────────────────────────────────
  Widget _backButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 16),
      ),
    );
  }

  Widget _shareButton(
      BuildContext context, dynamic news, _DetailTranslations t) {
    return GestureDetector(
      onTap: () async {
        await Share.share(
          '${news.title ?? ''}\n\n${news.description ?? ''}\n\n${t.shareMsg}',
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: const Icon(Icons.share_rounded, color: Colors.white, size: 17),
      ),
    );
  }

  // ── Shimmer line helper ───────────────────────────────────────────────
  Widget _shimmerLine(double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const _ShimmerBlock(),
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
        return Icons.trending_up_rounded;
      case 'safety':
        return Icons.security_rounded;
      case 'technology':
        return Icons.memory_rounded;
      case 'weather':
        return Icons.cloud_rounded;
      case 'success_stories':
        return Icons.emoji_events_rounded;
      case 'events':
        return Icons.event_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

// ── Shimmer Block ────────────────────────────────────────────────────────
class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock();

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
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
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200.withOpacity(_anim.value),
        ),
      ),
    );
  }
}

// ── Translations ─────────────────────────────────────────────────────────
class _DetailTranslations {
  final String lang;
  const _DetailTranslations(this.lang);

  String get notFound => lang == 'si'
      ? 'පුවත සොයා ගත නොහැක'
      : lang == 'ta'
          ? 'செய்தி கிடைக்கவில்லை'
          : 'News Not Found';

  String get notFoundSubtitle => lang == 'si'
      ? 'මෙම පුවත බලා ගැනීමට නොහැකි විය'
      : lang == 'ta'
          ? 'இந்த செய்தியை காண முடியவில்லை'
          : 'Unable to load this article';

  String get goBack => lang == 'si'
      ? 'ආපසු යන්න'
      : lang == 'ta'
          ? 'திரும்பு'
          : 'Go Back';

  String get fullArticle => lang == 'si'
      ? 'සම්පූර්ණ ලිපිය'
      : lang == 'ta'
          ? 'முழு கட்டுரை'
          : 'FULL ARTICLE';

  String get tags => lang == 'si'
      ? 'ටැග:'
      : lang == 'ta'
          ? 'குறிச்சொல்:'
          : 'Tags:';

  String get views => lang == 'si'
      ? 'නැරඹීම්'
      : lang == 'ta'
          ? 'பார்வைகள்'
          : 'views';

  String get likes => lang == 'si'
      ? 'කැමතියි'
      : lang == 'ta'
          ? 'விருப்பங்கள்'
          : 'Likes';

  String get shares => lang == 'si'
      ? 'බෙදා ගැනීම්'
      : lang == 'ta'
          ? 'பகிர்வுகள்'
          : 'Shares';

  String get liked => lang == 'si'
      ? 'පුවත කැමති විය ✅'
      : lang == 'ta'
          ? 'செய்தி விரும்பப்பட்டது ✅'
          : 'News liked! ✅';

  String get shareMsg => lang == 'si'
      ? 'ගොවි සහාය යෙදුමෙන් කියවන්න'
      : lang == 'ta'
          ? 'கோவி சஹாய பயன்பாட்டில் படிக்கவும்'
          : 'Read more on Govi Sahaya App';

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
}
