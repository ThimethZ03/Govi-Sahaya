import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart'; // ✅ NEW
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../screens/home/widgets/weather_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _newsPageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  AnimationController? _greetingAnim;
  Animation<double>? _greetingFade;

  int _currentNewsPage = 0;

  @override
  void initState() {
    super.initState();

    _greetingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _greetingFade = CurvedAnimation(
      parent: _greetingAnim!,
      curve: Curves.easeOut,
    );
    _greetingAnim!.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _refreshAll();
    });

    Future.delayed(const Duration(seconds: 1), _startNewsAutoSlide);
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    await Future.wait([
      context.read<WeatherProvider>().fetchWeather('Colombo Sri-Lanka'),
      context.read<NewsProvider>().fetchLatestNews(limit: 5),
      context.read<NotificationProvider>().fetchNotifications(refresh: true),
    ]);
  }

  void _startNewsAutoSlide() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      final newsProvider = context.read<NewsProvider>();
      if (newsProvider.latestNews.isEmpty) return true;
      final total = newsProvider.latestNews.length;
      final next = (_currentNewsPage + 1) % total;
      if (_newsPageController.hasClients) {
        _newsPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      return true;
    });
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    _searchController.dispose();
    _greetingAnim?.dispose();
    super.dispose();
  }

  String _getGreeting(String lang) {
    final hour = DateTime.now().hour;
    if (lang == 'si') {
      if (hour < 12) return 'සුබ උදෑසනක්';
      if (hour < 17) return 'සුබ දහවලක්';
      return 'සුබ සන්ධ්‍යාවක්';
    } else if (lang == 'ta') {
      if (hour < 12) return 'காலை வணக்கம்';
      if (hour < 17) return 'மதிய வணக்கம்';
      return 'மாலை வணக்கம்';
    } else {
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌤️';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  Widget _buildGreetingContent(String lang, String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _getGreeting(lang),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _getGreetingEmoji(),
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: lang == 'si'
                    ? 'හෙලෝ, '
                    : lang == 'ta'
                        ? 'வணக்கம், '
                        : 'Hello, ',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              TextSpan(
                text: firstName,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const TextSpan(
                text: ' 👋',
                style: TextStyle(fontSize: 17),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final newsProvider = context.watch<NewsProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final isDark = context.watch<ThemeProvider>().isDark; // ✅ NEW

    final userName = authProvider.user?.name ?? 'User';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TopBarBtn(
                        icon: Icons.more_vert_rounded,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.menu),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _greetingFade != null
                            ? FadeTransition(
                                opacity: _greetingFade!,
                                child: _buildGreetingContent(lang, firstName),
                              )
                            : _buildGreetingContent(lang, firstName),
                      ),
                      _NotificationBtn(
                        unreadCount: unreadCount,
                        onTap: () async {
                          await Navigator.pushNamed(
                              context, AppRoutes.notifications);
                          if (mounted) {
                            context
                                .read<NotificationProvider>()
                                .fetchNotifications(refresh: true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SearchBar(controller: _searchController, lang: lang),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // ✅ dark mode aware body background
                  color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: AppTheme.primaryGreen,
                  displacement: 20,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // ── Weather ──────────────────────────────
                        if (weatherProvider.isLoading)
                          const _WeatherSkeleton()
                        else if (weatherProvider.weather != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: WeatherCard(
                              weather: weatherProvider.weather,
                              lang: lang,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.weather),
                            ),
                          ),

                        const SizedBox(height: 26),

                        // ── Agri News ────────────────────────────
                        _SectionHeader(
                          title: lang == 'si'
                              ? 'කෘෂිකාර්මික පුවත්'
                              : lang == 'ta'
                                  ? 'விவசாய செய்திகள்'
                                  : 'Agri News',
                          seeAllLabel: lang == 'si'
                              ? 'සියල්ල'
                              : lang == 'ta'
                                  ? 'அனைத்தும்'
                                  : 'See all',
                          onSeeAll: () =>
                              Navigator.pushNamed(context, AppRoutes.news),
                          isDark: isDark, // ✅ pass isDark
                        ),
                        const SizedBox(height: 14),

                        if (newsProvider.isLoading)
                          const _NewsSkeleton()
                        else if (newsProvider.latestNews.isNotEmpty)
                          _buildNewsCarousel(newsProvider, lang, isDark)
                        else
                          _EmptyState(
                            icon: Icons.newspaper_rounded,
                            message: lang == 'si'
                                ? 'පුවත් නොමැත'
                                : lang == 'ta'
                                    ? 'செய்திகள் இல்லை'
                                    : 'No news available',
                            isDark: isDark, // ✅ pass isDark
                          ),

                        const SizedBox(height: 26),

                        // ── My Tools ─────────────────────────────
                        _SectionHeader(
                          title: lang == 'si'
                              ? 'මගේ මෙවලම්'
                              : lang == 'ta'
                                  ? 'என் கருவிகள்'
                                  : 'My Tools',
                          seeAllLabel: lang == 'si'
                              ? 'සියල්ල'
                              : lang == 'ta'
                                  ? 'அனைத்தும்'
                                  : 'See all',
                          onSeeAll: () =>
                              Navigator.pushNamed(context, AppRoutes.menu),
                          isDark: isDark, // ✅ pass isDark
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildToolsGrid(context, lang, isDark),
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

  // ── News Carousel ──────────────────────────────────────────────
  Widget _buildNewsCarousel(
      NewsProvider newsProvider, String lang, bool isDark) {
    final newsList = newsProvider.latestNews;
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _newsPageController,
            itemCount: newsList.length,
            onPageChanged: (i) => setState(() => _currentNewsPage = i),
            itemBuilder: (context, index) {
              final news = newsList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.newsDetail,
                    arguments: news.id,
                  ),
                  child: _NewsCard(news: news, lang: lang),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(newsList.length, (i) {
            final active = i == _currentNewsPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 5,
              height: 5,
              decoration: BoxDecoration(
                // ✅ dark mode aware dots
                color: active
                    ? AppTheme.primaryGreen
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Tools Grid ─────────────────────────────────────────────────
  Widget _buildToolsGrid(BuildContext context, String lang, bool isDark) {
    const tools = [
      _ToolData(
        icon: Icons.local_hospital_rounded,
        labelEn: 'Crop\nDoctor',
        labelSi: 'බෝග\nවෛද්‍යය',
        labelTa: 'பயிர்\nமருத்துவர்',
        route: AppRoutes.cropDoctor,
        color: Color(0xFF2E7D32),
      ),
      _ToolData(
        icon: Icons.menu_book_rounded,
        labelEn: 'Agri\nLibrary',
        labelSi: 'කෘෂි\nකෘතාගාරය',
        labelTa: 'விவசாய\nநூலகம்',
        route: AppRoutes.library,
        color: Color(0xFF1565C0),
      ),
      _ToolData(
        icon: Icons.account_balance_wallet_rounded,
        labelEn: 'Profit\nPlanner',
        labelSi: 'ලාභ\nසැලසුම',
        labelTa: 'லாப\nதிட்டமிடல்',
        route: AppRoutes.profitPlanner,
        color: Color(0xFF6A1B9A),
      ),
      _ToolData(
        icon: Icons.health_and_safety_rounded,
        labelEn: 'Safety\nAssist',
        labelSi: 'ආරක්ෂා\nසහාය',
        labelTa: 'பாதுகாப்பு\nஉதவி',
        route: AppRoutes.safetyAssist,
        color: Color(0xFFAD1457),
      ),
      _ToolData(
        icon: Icons.forum_rounded,
        labelEn: 'Community',
        labelSi: 'ප්‍රජාව',
        labelTa: 'சமூகம்',
        route: AppRoutes.forum,
        color: Color(0xFF00695C),
      ),
      _ToolData(
        icon: Icons.eco_rounded,
        labelEn: 'Crop\nInfo',
        labelSi: 'බෝග\nතොරතුරු',
        labelTa: 'பயிர்\nதகவல்',
        route: AppRoutes.library,
        color: Color(0xFF558B2F),
      ),
      _ToolData(
        icon: Icons.shopping_basket_rounded,
        labelEn: 'Shop',
        labelSi: 'වෙළඳසැල',
        labelTa: 'கடை',
        route: AppRoutes.shop,
        color: Color(0xFFE65100),
      ),
      _ToolData(
        icon: Icons.newspaper_rounded,
        labelEn: 'Agri\nNews',
        labelSi: 'කෘෂි\nපුවත්',
        labelTa: 'விவசாய\nசெய்திகள்',
        route: AppRoutes.news,
        color: Color(0xFF00838F),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        final label = lang == 'si'
            ? tool.labelSi
            : lang == 'ta'
                ? tool.labelTa
                : tool.labelEn;
        return _ToolItem(tool: tool, label: label, isDark: isDark);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Private widget components
// ═══════════════════════════════════════════════════════════════════

class _TopBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _NotificationBtn extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBtn({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
              border:
                  Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 18),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String lang;

  const _SearchBar({required this.controller, required this.lang});

  @override
  Widget build(BuildContext context) {
    // Search bar is always on the green header — no dark change needed
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          hintText: lang == 'si'
              ? 'බෝග, ආරංචි, මෙවලම් සොයන්න...'
              : lang == 'ta'
                  ? 'பயிர்கள், செய்திகள் தேடவும்...'
                  : 'Search crops, news, tools...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.primaryGreen, size: 20),
          suffixIcon: Container(
            margin: const EdgeInsets.all(7),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppTheme.primaryGreen, size: 15),
          ),
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String seeAllLabel;
  final VoidCallback onSeeAll;
  final bool isDark; // ✅ NEW

  const _SectionHeader({
    required this.title,
    required this.seeAllLabel,
    required this.onSeeAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              // ✅ dark mode aware title
              color: isDark ? Colors.white : AppTheme.textDark,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    seeAllLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 9, color: AppTheme.primaryGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _NewsCard is unchanged — it always has dark overlay so no change needed
class _NewsCard extends StatelessWidget {
  final dynamic news;
  final String lang;

  const _NewsCard({required this.news, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTheme.primaryGreen,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (news.coverImage?.url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                news.coverImage!.url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.22),
                  Colors.black.withOpacity(0.82),
                ],
                stops: const [0.3, 0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_new_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          lang == 'si'
                              ? 'නවතම'
                              : lang == 'ta'
                                  ? 'சமீபத்திய'
                                  : 'Latest',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        lang == 'si'
                            ? 'තව කියවන්න'
                            : lang == 'ta'
                                ? 'மேலும் படிக்கவும்'
                                : 'Read more',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final _ToolData tool;
  final String label;
  final bool isDark; // ✅ NEW

  const _ToolItem({
    required this.tool,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, tool.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tool.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tool.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(tool.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w600,
              // ✅ dark mode aware tool label
              color: isDark ? Colors.white70 : AppTheme.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Weather Skeleton ───────────────────────────────────────────────────
class _WeatherSkeleton extends StatelessWidget {
  const _WeatherSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: _ShimmerBox(height: 130, radius: 20),
    );
  }
}

// ── News Skeleton ──────────────────────────────────────────────────────
class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: _ShimmerBox(height: 210, radius: 22),
    );
  }
}

// ── Shimmer Box ────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;

  const _ShimmerBox({required this.height, required this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark; // ✅ NEW
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          // ✅ dark mode aware shimmer colors
          color: Color.lerp(
            isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
            isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
            _anim.value,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark; // ✅ NEW

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                // ✅ dark mode aware icon
                color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                // ✅ dark mode aware text
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tool Data ──────────────────────────────────────────────────────────
class _ToolData {
  final IconData icon;
  final String labelEn;
  final String labelSi;
  final String labelTa;
  final String route;
  final Color color;

  const _ToolData({
    required this.icon,
    required this.labelEn,
    required this.labelSi,
    required this.labelTa,
    required this.route,
    required this.color,
  });
}
