import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../screens/home/widgets/weather_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _newsPageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentNewsPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // ✅ Weather + news load on open
      // Notifications are handled by polling in NotificationProvider — no manual call needed
      await context.read<WeatherProvider>().fetchWeather('Colombo Sri-Lanka');
      if (mounted) context.read<NewsProvider>().fetchLatestNews(limit: 5);
    });

    Future.delayed(const Duration(seconds: 1), _startNewsAutoSlide);
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final newsProvider = context.watch<NewsProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final notificationProvider = context.watch<NotificationProvider>();

    final userName = authProvider.user?.name ?? 'User';
    final firstName = userName.split(' ').first;
    final unreadCount = notificationProvider.unreadCount;

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
                      // ── 3-dot menu ───────────────────────────────
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.menu),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ── Greeting + name ──────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(lang),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.75),
                                fontWeight: FontWeight.w400,
                              ),
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
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: firstName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' 👋',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Bell — badge auto-updates via polling ────
                      GestureDetector(
                        onTap: () async {
                          await Navigator.pushNamed(
                              context, AppRoutes.notifications);
                          // ✅ Refresh once on return (marks reads reflected)
                          if (mounted) {
                            context
                                .read<NotificationProvider>()
                                .fetchNotifications(refresh: true);
                          }
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),

                            // ✅ Badge — auto-updated by polling
                            if (unreadCount > 0)
                              Positioned(
                                top: -3,
                                right: -3,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  padding: unreadCount > 9
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 4)
                                      : EdgeInsets.zero,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: unreadCount > 9
                                        ? BoxShape.rectangle
                                        : BoxShape.circle,
                                    borderRadius: unreadCount > 9
                                        ? BorderRadius.circular(7)
                                        : null,
                                    border: Border.all(
                                      color: AppTheme.primaryGreen,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Search bar ────────────────────────────────────
                  SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: lang == 'si'
                            ? 'බෝග, ආරංචි, මෙවලම් සොයන්න...'
                            : lang == 'ta'
                                ? 'பயிர்கள், செய்திகள் தேடவும்...'
                                : 'Search crops, news, tools...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        suffixIcon: Icon(
                          Icons.tune_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.95),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
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
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── White scrollable content ─────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── Weather Card ──────────────────────────────
                      if (weatherProvider.isLoading)
                        _buildWeatherSkeleton()
                      else if (weatherProvider.weather != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: WeatherCard(
                            weather: weatherProvider.weather,
                            lang: lang,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.weather),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── Agri News ─────────────────────────────────
                      _buildSectionHeader(
                        lang == 'si'
                            ? 'කෘෂිකාර්මික පුවත්'
                            : lang == 'ta'
                                ? 'விவசாய செய்திகள்'
                                : 'Agri News',
                        lang,
                        isNews: true,
                      ),
                      const SizedBox(height: 14),

                      if (newsProvider.isLoading)
                        _buildNewsSkeleton()
                      else if (newsProvider.latestNews.isNotEmpty)
                        _buildSlidingNews(newsProvider, lang)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: Center(
                            child: Text(
                              lang == 'si'
                                  ? 'පුවත් නොමැත'
                                  : lang == 'ta'
                                      ? 'செய்திகள் இல்லை'
                                      : 'No news available',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── My Tools ──────────────────────────────────
                      _buildSectionHeader(
                        lang == 'si'
                            ? 'මගේ මෙවලම්'
                            : lang == 'ta'
                                ? 'என் கருவிகள்'
                                : 'My Tools',
                        lang,
                        isNews: false,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildToolsGrid(context, lang),
                      ),
                      const SizedBox(height: 30),
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

  Widget _buildWeatherSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String lang, {
    required bool isNews,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              isNews ? AppRoutes.news : AppRoutes.menu,
            ),
            child: Text(
              lang == 'si'
                  ? 'සියල්ල'
                  : lang == 'ta'
                      ? 'அனைத்தும்'
                      : 'See all',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingNews(NewsProvider newsProvider, String lang) {
    final newsList = newsProvider.latestNews;

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _newsPageController,
            itemCount: newsList.length,
            onPageChanged: (index) => setState(() => _currentNewsPage = index),
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppTheme.primaryGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (news.coverImage?.url != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
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
                            borderRadius: BorderRadius.circular(20),
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
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lang == 'si'
                                      ? '📰 නවතම පුවත්'
                                      : lang == 'ta'
                                          ? '📰 சமீபத்திய செய்திகள்'
                                          : '📰 Latest News',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 80),
                              Text(
                                news.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward,
                                      color: Colors.white, size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(newsList.length, (index) {
            final isActive = index == _currentNewsPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryGreen : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNewsSkeleton() {
    return Container(
      height: 210,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context, String lang) {
    final tools = [
      _ToolData(
        icon: Icons.local_hospital,
        labelEn: 'Crop\nDoctor',
        labelSi: 'බෝග\nවෛද්‍යය',
        labelTa: 'பயிர்\nமருத்துவர்',
        route: AppRoutes.cropDoctor,
        color: const Color(0xFF2E7D32),
      ),
      _ToolData(
        icon: Icons.menu_book_rounded,
        labelEn: 'Agri\nLibrary',
        labelSi: 'කෘෂි\nකෘතාගාරය',
        labelTa: 'விவசாய\nநூலகம்',
        route: AppRoutes.library,
        color: const Color(0xFF1565C0),
      ),
      _ToolData(
        icon: Icons.account_balance_wallet_outlined,
        labelEn: 'Profit\nPlanner',
        labelSi: 'ලාභ\nසැලසුම',
        labelTa: 'லாப\nதிட்டமிடல்',
        route: AppRoutes.profitPlanner,
        color: const Color(0xFF6A1B9A),
      ),
      _ToolData(
        icon: Icons.health_and_safety_outlined,
        labelEn: 'Safety\nAssist',
        labelSi: 'ආරක්ෂා\nසහාය',
        labelTa: 'பாதுகாப்பு\nஉதவி',
        route: AppRoutes.safetyAssist,
        color: const Color(0xFFAD1457),
      ),
      _ToolData(
        icon: Icons.forum_outlined,
        labelEn: 'Community',
        labelSi: 'ප්‍රජාව',
        labelTa: 'சமூகம்',
        route: AppRoutes.forum,
        color: const Color(0xFF00695C),
      ),
      _ToolData(
        icon: Icons.eco_outlined,
        labelEn: 'Crop\nInfo',
        labelSi: 'බෝග\nතොරතුරු',
        labelTa: 'பயிர்\nதகவல்',
        route: AppRoutes.library,
        color: const Color(0xFF558B2F),
      ),
      _ToolData(
        icon: Icons.shopping_basket_outlined,
        labelEn: 'Shop',
        labelSi: 'වෙළඳසැල',
        labelTa: 'கடை',
        route: AppRoutes.shop,
        color: const Color(0xFFE65100),
      ),
      _ToolData(
        icon: Icons.newspaper_rounded,
        labelEn: 'Agri\nNews',
        labelSi: 'කෘෂි\nපුවත්',
        labelTa: 'விவசாய\nசெய்திகள்',
        route: AppRoutes.news,
        color: const Color(0xFF00838F),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 8,
      children: tools.map((tool) {
        final label = lang == 'si'
            ? tool.labelSi
            : lang == 'ta'
                ? tool.labelTa
                : tool.labelEn;
        return _buildToolIcon(context, tool: tool, label: label);
      }).toList(),
    );
  }

  Widget _buildToolIcon(
    BuildContext context, {
    required _ToolData tool,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, tool.route),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 80,
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
                      color: tool.color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(tool.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
