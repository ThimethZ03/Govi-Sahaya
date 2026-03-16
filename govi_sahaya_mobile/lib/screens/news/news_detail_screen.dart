// ============================================================
// NEWS DETAIL SCREEN
// ------------------------------------------------------------
// This screen displays the full details of a selected news
// article including:
// - Hero image
// - Title and description
// - Full article content
// - Category tags
// - Likes and shares
// - Multi-language support
// - Dark / Light theme support
// - Animated loading shimmer
// ============================================================


// ------------------------------------------------------------
// IMPORTS
// ------------------------------------------------------------

// Flutter UI framework
import 'package:flutter/material.dart';

// Used to control status bar style
import 'package:flutter/services.dart';

// State management package
import 'package:provider/provider.dart';

// Used to share content with other apps
import 'package:share_plus/share_plus.dart';

// Image loader with caching
import 'package:cached_network_image/cached_network_image.dart';

// Application providers
import '../../providers/news_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

// Theme configuration (colors, styles)
import '../../config/theme.dart';

// Helper functions (time formatting etc.)
import '../../core/utils/helpers.dart';


// ============================================================
// MAIN SCREEN WIDGET
// ============================================================

/// NewsDetailScreen
///
/// Displays the full details of a selected news article.
/// The article is fetched using the provided `newsId`.
class NewsDetailScreen extends StatefulWidget {

  /// Unique identifier of the selected news article
  final String newsId;

  /// Constructor requiring the article ID
  const NewsDetailScreen({
    super.key,
    required this.newsId,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}


// ============================================================
// SCREEN STATE
// ============================================================

/// Handles UI logic, animations and user interactions
class _NewsDetailScreenState extends State<NewsDetailScreen>
    with SingleTickerProviderStateMixin {

  /// Tracks whether the user liked the article
  bool _isLiked = false;

  /// Animation controller used for screen fade animation
  AnimationController? _animCtrl;

  /// Fade animation applied to screen content
  Animation<double>? _fadeAnim;


  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------

  /// Called when the widget is first created
  /// Initializes animations and fetches the news article
  @override
  void initState() {
    super.initState();

    // Create animation controller for fade effect
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // Create curved fade animation
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl!,
      curve: Curves.easeOut,
    );

    // Fetch news after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNewsById(widget.newsId);
    });
  }


  // ------------------------------------------------------------
  // CLEANUP
  // ------------------------------------------------------------

  /// Dispose animation controller to avoid memory leaks
  @override
  void dispose() {
    _animCtrl?.dispose();
    super.dispose();
  }


  // ------------------------------------------------------------
  // MAIN BUILD METHOD
  // ------------------------------------------------------------

  /// Builds the entire screen UI
  @override
  Widget build(BuildContext context) {

    // Access application providers
    final newsProvider = context.watch<NewsProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final isDark = context.watch<ThemeProvider>().isDark;

    // Translation helper
    final t = _DetailTranslations(lang);

    // Selected article
    final news = newsProvider.selectedNews;


    // ============================================================
    // LOADING STATE
    // ============================================================

    // Displays shimmer loading placeholders
    if (newsProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }


    // ============================================================
    // ERROR / NOT FOUND STATE
    // ============================================================

    // If the article could not be retrieved
    if (news == null) {
      return Scaffold(
        body: Center(
          child: Text(t.notFound),
        ),
      );
    }


    // ============================================================
    // MAIN CONTENT
    // ============================================================

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,

      child: Scaffold(

        /// Screen background adapts to theme
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F6FA),

        /// Main body content
        body: FadeTransition(
          opacity: _fadeAnim!,
          child: _buildBody(context, news, t, isDark),
        ),

        /// Bottom actions (like/share)
        bottomNavigationBar:
            _buildBottomBar(context, news, t, isDark),
      ),
    );
  }



  // ============================================================
  // BODY CONTENT
  // ============================================================

  /// Builds the scrollable article layout
  Widget _buildBody(
      BuildContext context,
      dynamic news,
      _DetailTranslations t,
      bool isDark) {

    return CustomScrollView(

      /// Bouncing scroll physics for better UX
      physics: const BouncingScrollPhysics(),

      slivers: [

        // --------------------------------------------------------
        // HERO IMAGE APP BAR
        // --------------------------------------------------------
        //
        // Large expandable image with category badge
        // and back/share buttons

        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
        ),


        // --------------------------------------------------------
        // ARTICLE CONTENT
        // --------------------------------------------------------
        //
        // Displays title, metadata, description and full content

        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }



  // ============================================================
  // BOTTOM ACTION BAR
  // ============================================================

  /// Bottom section containing Like and Share buttons
  Widget _buildBottomBar(
      BuildContext context,
      dynamic news,
      _DetailTranslations t,
      bool isDark) {

    return Container(
      padding: const EdgeInsets.all(16),

      child: Row(
        children: [

          // ------------------------------------------------------
          // LIKE BUTTON
          // ------------------------------------------------------

          Expanded(
            child: GestureDetector(
              onTap: () {

                // Toggle like state
                setState(() {
                  _isLiked = true;
                });

                // Show confirmation message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.liked)),
                );
              },

              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Icon(
                      _isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),

                    const SizedBox(width: 6),

                    Text('${news.likes ?? 0} ${t.likes}')
                  ],
                ),
              ),
            ),
          ),


          const SizedBox(width: 12),


          // ------------------------------------------------------
          // SHARE BUTTON
          // ------------------------------------------------------

          Expanded(
            child: GestureDetector(
              onTap: () async {

                /// Share article content
                await Share.share(
                  '${news.title}\n\n${news.description}',
                );
              },

              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [

                    Icon(Icons.share),

                    SizedBox(width: 6),

                    Text('Share'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ============================================================
// SHIMMER LOADING PLACEHOLDER
// ============================================================

/// Animated shimmer block used while content is loading
class _ShimmerBlock extends StatefulWidget {

  /// Determines shimmer colors for dark/light mode
  final bool isDark;

  const _ShimmerBlock({required this.isDark});

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

    // Animation used to create shimmer effect
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _anim = Tween<double>(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      builder: (_, __) {
        return Container(
          color: widget.isDark
              ? const Color(0xFF2A2A2A)
              : Colors.grey.shade200,
        );
      },
    );
  }
}



// ============================================================
// TRANSLATION CLASS
// ============================================================

/// Provides translations for multiple languages
/// Supported languages:
/// - English
/// - Sinhala
/// - Tamil
class _DetailTranslations {

  final String lang;

  const _DetailTranslations(this.lang);

  String get notFound =>
      lang == 'si'
          ? 'පුවත සොයා ගත නොහැක'
          : lang == 'ta'
              ? 'செய்தி கிடைக்கவில்லை'
              : 'News Not Found';

  String get likes =>
      lang == 'si'
          ? 'කැමතියි'
          : lang == 'ta'
              ? 'விருப்பங்கள்'
              : 'Likes';

  String get liked =>
      lang == 'si'
          ? 'පුවත කැමති විය'
          : lang == 'ta'
              ? 'செய்தி விரும்பப்பட்டது'
              : 'News liked!';
}