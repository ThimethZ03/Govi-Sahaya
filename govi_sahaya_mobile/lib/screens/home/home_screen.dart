import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/news_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchWeather('Colombo Sri-Lanka');
      context
          .read<NewsProvider>()
          .fetchLatestNews(limit: 5); // ✅ Use fetchLatestNews
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final weatherProvider = context.watch<WeatherProvider>();
    final newsProvider = context.watch<NewsProvider>();

    // Get user's name (fallback to 'User' if not available)
    final userName = authProvider.user?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Green header section with animation
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menu Icon Button
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.menu),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // User Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Good ${_getGreeting()}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Avatar
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      child: Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: AppTheme.primaryGreen,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content area
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
                      const SizedBox(height: 24),

                      // Weather Card
                      if (weatherProvider.weather != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildWeatherCard(weatherProvider),
                        ),

                      const SizedBox(height: 24),

                      // Agri News Section
                      _buildSectionHeader('Agri News'),
                      const SizedBox(height: 16),
                      // ✅ UPDATED: Check latestNews instead of newsList
                      if (newsProvider.latestNews.isNotEmpty)
                        _buildAgriNewsCard(newsProvider)
                      else if (newsProvider.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No news available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // My Tools Section
                      _buildSectionHeader('My Tools'),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildToolsGrid(context),
                      ),
                      const SizedBox(height: 24),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildWeatherCard(WeatherProvider weatherProvider) {
    final weather = weatherProvider.weather!;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.weather),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 18, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      weather.location,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '°C',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Helpers.getDayOfWeek(weather.date),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatDate(weather.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.cloud_queue,
                      size: 90,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${weather.temperature.toInt()}°C',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          '/${weather.minTemp.toInt()}°C',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop,
                            size: 18, color: Colors.blue[400]),
                        const SizedBox(width: 6),
                        Text(
                          'Feels like ${weather.minTemp.toInt()}°',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        weather.condition,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ✅ UPDATED: Use latestNews
  Widget _buildAgriNewsCard(NewsProvider newsProvider) {
    final news = newsProvider.latestNews.first;

    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.newsDetail,
          arguments: news.id, // ✅ Pass news ID instead of entire object
        ),
        child: Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.primaryGreen,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Image (if available)
              if (news.coverImage?.url != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    news.coverImage!.url,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
                  ),
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '📰 Latest News',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      news.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text(
                          'Read more',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
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
  }

  Widget _buildToolsGrid(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        children: [
          _buildToolIcon(
            context,
            icon: Icons.local_hospital,
            label: 'Crop\nDoctor',
            route: AppRoutes.cropDoctor,
            delay: 0,
          ),
          _buildToolIcon(
            context,
            icon: Icons.book,
            label: 'Agri\nLibrary',
            route: AppRoutes.library,
            delay: 100,
          ),
          _buildToolIcon(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Profit\nPlanner',
            route: AppRoutes.profitPlanner,
            delay: 200,
          ),
          _buildToolIcon(
            context,
            icon: Icons.health_and_safety,
            label: 'Safety\nAssist',
            route: AppRoutes.safetyAssist,
            delay: 300,
          ),
          _buildToolIcon(
            context,
            icon: Icons.forum,
            label: 'Community',
            route: AppRoutes.forum,
            delay: 400,
          ),
          _buildToolIcon(
            context,
            icon: Icons.wb_sunny,
            label: 'Crop\nInfo',
            route: AppRoutes.library,
            delay: 500,
          ),
          _buildToolIcon(
            context,
            icon: Icons.shopping_cart,
            label: 'Shop',
            route: AppRoutes.shop,
            delay: 600,
          ),
          _buildToolIcon(
            context,
            icon: Icons.newspaper, // ✅ Changed from Icons.info
            label: 'Agri\nNews', // ✅ Changed label
            route: AppRoutes.news, // ✅ Link to news screen
            delay: 700,
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required int delay,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 95,
            height: 95,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
