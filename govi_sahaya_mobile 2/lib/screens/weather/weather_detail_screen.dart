import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';

class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<WeatherProvider>().fetchWeather('Colombo');
    });
  }

  // ── Translations ────────────────────────────────────────────────────
  String _t(String key, String lang) {
    const Map<String, Map<String, String>> strings = {
      'weather': {'en': 'Weather', 'si': 'කාලගුණය', 'ta': 'வானிலை'},
      'loading': {
        'en': 'Loading weather...',
        'si': 'කාලගුණය පූරණය වෙමින්...',
        'ta': 'வானிலை ஏற்றுகிறது...'
      },
      'error': {
        'en': 'Something went wrong',
        'si': 'දෝෂයක් සිදු විය',
        'ta': 'பிழை ஏற்பட்டது'
      },
      'no_data': {
        'en': 'No weather data available',
        'si': 'කාලගුණ දත්ත නොමැත',
        'ta': 'வானிலை தரவு இல்லை'
      },
      'retry': {
        'en': 'Retry',
        'si': 'නැවත උත්සාහ කරන්න',
        'ta': 'மீண்டும் முயற்சி'
      },
      'highlights': {
        'en': "Today's Highlights",
        'si': 'අද දිනයේ විශේෂාංග',
        'ta': "இன்றைய சிறப்பம்சங்கள்"
      },
      'forecast': {
        'en': '10-Day Forecast',
        'si': 'දින 10 පුරෝකථනය',
        'ta': '10 நாள் முன்னறிவிப்பு'
      },
      'wind': {'en': 'Wind Speed', 'si': 'සුළං වේගය', 'ta': 'காற்று வேகம்'},
      'humidity': {'en': 'Humidity', 'si': 'ආර්ද්‍රතාව', 'ta': 'ஈரப்பதம்'},
      'uv': {'en': 'UV Index', 'si': 'UV දර්ශකය', 'ta': 'UV குறியீடு'},
      'visibility': {
        'en': 'Visibility',
        'si': 'දෘශ්‍යතාව',
        'ta': 'தெரிவுத்திறன்'
      },
      'sunrise': {'en': 'Sunrise', 'si': 'සූර්යෝදය', 'ta': 'சூரிய உதயம்'},
      'sunset': {'en': 'Sunset', 'si': 'සූර්යාස්තය', 'ta': 'சூரிய அஸ்தமனம்'},
      'feels_like': {
        'en': 'Feels like',
        'si': 'දැනෙන ආකාරය',
        'ta': 'உணர்வு வெப்பநிலை'
      },
      'pressure': {'en': 'Pressure', 'si': 'පීඩනය', 'ta': 'அழுத்தம்'},
      'good_humidity': {
        'en': 'Comfortable',
        'si': 'සුවදායකයි',
        'ta': 'வசதியானது'
      },
      'moderate_uv': {'en': 'Moderate', 'si': 'මධ්‍යස්ථ', 'ta': 'மிதமான'},
      'last_updated': {
        'en': 'Last updated',
        'si': 'අවසන් යාවත්කාලීනය',
        'ta': 'கடைசியாக புதுப்பிக்கப்பட்டது'
      },
    };
    return strings[key]?[lang] ?? strings[key]?['en'] ?? key;
  }

  // ── Weather Icon ────────────────────────────────────────────────────
  IconData _getWeatherIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle')) {
      return Icons.grain_rounded;
    } else if (c.contains('thunder') || c.contains('storm')) {
      return Icons.thunderstorm_rounded;
    } else if (c.contains('snow')) {
      return Icons.ac_unit_rounded;
    } else if (c.contains('cloud')) {
      return Icons.cloud_rounded;
    } else if (c.contains('mist') || c.contains('fog') || c.contains('haze')) {
      return Icons.blur_on_rounded;
    } else if (c.contains('clear') || c.contains('sunny')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.cloud_queue_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;
    final lang = context.watch<LanguageProvider>().languageCode;
    final isDark = context.watch<ThemeProvider>().isDark;

    // ── Loading ─────────────────────────────────────────────────────
    if (weatherProvider.isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, lang, isDark, isLoading: true),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                      const SizedBox(height: 16),
                      Text(
                        _t('loading', lang),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
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

    // ── Error ───────────────────────────────────────────────────────
    if (weatherProvider.errorMessage != null) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, lang, isDark),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_off_rounded,
                              color: Colors.red, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _t('error', lang),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weatherProvider.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () =>
                              context.read<WeatherProvider>().refreshWeather(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 11),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _t('retry', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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

    // ── No Data ─────────────────────────────────────────────────────
    if (weather == null) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, lang, isDark),
              Expanded(
                child: Center(
                  child: Text(
                    _t('no_data', lang),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Main UI ─────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar (on green) ───────────────────────────────────
            _buildTopBar(context, lang, isDark),
            const SizedBox(height: 6),

            // ── Hero Card (on green) ─────────────────────────────────
            _buildHeroCard(weather, lang, isDark),
            const SizedBox(height: 6),

            // ── Scrollable White/Dark Bottom Section ─────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F0F0F)
                      : const Color(0xFFF5F7FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Highlights
                      _sectionLabel(_t('highlights', lang), isDark),
                      const SizedBox(height: 12),
                      _buildHighlightsGrid(weather, lang, isDark),
                      const SizedBox(height: 22),

                      // Forecast
                      _sectionLabel(_t('forecast', lang), isDark),
                      const SizedBox(height: 12),
                      _buildForecastRow(weather, isDark),
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

  // ── Top Bar ──────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, String lang, bool isDark,
      {bool isLoading = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t('weather', lang),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (!isLoading)
            GestureDetector(
              onTap: () => context.read<WeatherProvider>().refreshWeather(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25), width: 1),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ── Hero Card ────────────────────────────────────────────────────────
  Widget _buildHeroCard(dynamic weather, String lang, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location + unit
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  weather.location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '°C',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Day + Temp + Icon row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Day & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Helpers.getDayOfWeek(weather.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Helpers.formatDate(weather.date),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Weather icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getWeatherIcon(weather.condition),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),

                // Temp
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${weather.temperature.toInt()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      'min ${weather.minTemp.toInt()}°C',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Divider
            Container(height: 1, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 12),

            // Condition + description
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.condition,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weather.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Quick stats
                Row(
                  children: [
                    _quickStat(Icons.water_drop_rounded,
                        '${weather.humidity.toInt()}%'),
                    const SizedBox(width: 12),
                    _quickStat(Icons.air_rounded, '${weather.windSpeed}km/h'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 3),
        Text(value,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Section Label ────────────────────────────────────────────────────
  Widget _sectionLabel(String label, bool isDark) {
    return Row(
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
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color:
                isDark ? Colors.white38 : AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Highlights Grid ──────────────────────────────────────────────────
  Widget _buildHighlightsGrid(dynamic weather, String lang, bool isDark) {
    final tiles = [
      _HighlightData(
        icon: Icons.air_rounded,
        color: Colors.blue,
        title: _t('wind', lang),
        value: '${weather.windSpeed}',
        unit: 'km/h',
        subtitle: null,
      ),
      _HighlightData(
        icon: Icons.water_drop_rounded,
        color: Colors.cyan,
        title: _t('humidity', lang),
        value: '${weather.humidity.toInt()}',
        unit: '%',
        subtitle: _t('good_humidity', lang),
      ),
      _HighlightData(
        icon: Icons.wb_sunny_rounded,
        color: Colors.orange,
        title: _t('uv', lang),
        value: '${weather.uvIndex}',
        unit: 'UV',
        subtitle: _t('moderate_uv', lang),
      ),
      _HighlightData(
        icon: Icons.visibility_rounded,
        color: Colors.purple,
        title: _t('visibility', lang),
        value: '${weather.visibility}',
        unit: 'km',
        subtitle: null,
      ),
      _HighlightData(
        icon: Icons.wb_twilight_rounded,
        color: Colors.amber,
        title: _t('sunrise', lang),
        value: weather.sunriseTime,
        unit: '',
        subtitle: null,
      ),
      _HighlightData(
        icon: Icons.nights_stay_rounded,
        color: Colors.indigo,
        title: _t('sunset', lang),
        value: weather.sunsetTime,
        unit: '',
        subtitle: null,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) =>
          _buildHighlightTile(tiles[index], isDark),
    );
  }

  Widget _buildHighlightTile(_HighlightData data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + title row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.color, size: 15),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  height: 1,
                ),
              ),
              if (data.unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    data.unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Subtitle
          if (data.subtitle != null)
            Text(
              data.subtitle!,
              style: TextStyle(
                fontSize: 9,
                color: data.color,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ── Forecast Row ─────────────────────────────────────────────────────
  Widget _buildForecastRow(dynamic weather, bool isDark) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: weather.forecast.length > 10 ? 10 : weather.forecast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final forecast = weather.forecast[index];
          final isToday = index == 0;
          return Container(
            width: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              // ✅ Highlight today
              color: isToday
                  ? AppTheme.primaryGreen
                  : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday
                    ? AppTheme.primaryGreen
                    : (isDark ? Colors.white12 : Colors.grey.shade100),
              ),
              boxShadow: isDark || isToday
                  ? (isToday
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [])
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  forecast.day,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.grey.shade500),
                  ),
                ),
                Text(
                  forecast.icon,
                  style: const TextStyle(fontSize: 22),
                ),
                Text(
                  '${forecast.temperature.toInt()}°',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isToday
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Highlight Data Model ───────────────────────────────────────────────
class _HighlightData {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String unit;
  final String? subtitle;

  const _HighlightData({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
  });
}
