import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/utils/helpers.dart';

class WeatherCard extends StatelessWidget {
  final dynamic weather;
  final String lang;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.lang,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen,
              AppTheme.primaryGreen.withOpacity(0.75),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 1: location + badge ──────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      weather.location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_outlined,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          lang == 'si'
                              ? 'කාලගුණය'
                              : lang == 'ta'
                                  ? 'வானிலை'
                                  : 'Weather',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Row 2: temp + condition + icon + pills ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Large temp
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          '°C',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Condition + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Helpers.formatDate(weather.date),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Weather icon + min/max pills
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildWeatherIcon(weather.condition),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _tempPill(
                            '↑ ${weather.maxTemp.toInt()}°',
                            Colors.orange.withOpacity(0.3),
                          ),
                          const SizedBox(width: 4),
                          _tempPill(
                            '↓ ${weather.minTemp.toInt()}°',
                            Colors.blue.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 8),

              // ── Row 3: 4 stats ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    Icons.thermostat_outlined,
                    lang == 'si'
                        ? 'පස් උෂ්ණය'
                        : lang == 'ta'
                            ? 'மண் வெப்பம்'
                            : 'Soil Temp',
                    '+${weather.minTemp.toInt()} C',
                  ),
                  _divider(),
                  _statItem(
                    Icons.water_drop_outlined,
                    lang == 'si'
                        ? 'ආර්ද්‍රතාවය'
                        : lang == 'ta'
                            ? 'ஈரப்பதம்'
                            : 'Humidity',
                    '${weather.humidity.toInt()}%',
                  ),
                  _divider(),
                  _statItem(
                    Icons.air_outlined,
                    lang == 'si'
                        ? 'සුළඟ'
                        : lang == 'ta'
                            ? 'காற்று'
                            : 'Wind',
                    '${weather.windSpeed.toInt()} m/s',
                  ),
                  _divider(),
                  _statItem(
                    Icons.water_outlined,
                    lang == 'si'
                        ? 'වර්ෂාව'
                        : lang == 'ta'
                            ? 'மழை'
                            : 'Perception',
                    '0 mm',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Icon mapping ──────────────────────────────────────────────────
  Widget _buildWeatherIcon(String condition) {
    IconData icon;
    final c = condition.toLowerCase();
    if (c.contains('thunder') || c.contains('storm')) {
      icon = Icons.thunderstorm_outlined;
    } else if (c.contains('rain') || c.contains('drizzle')) {
      icon = Icons.water_drop_outlined;
    } else if (c.contains('snow')) {
      icon = Icons.ac_unit_outlined;
    } else if (c.contains('fog') || c.contains('mist')) {
      icon = Icons.foggy;
    } else if (c.contains('cloud')) {
      icon = Icons.cloud_queue_outlined;
    } else {
      icon = Icons.wb_sunny_outlined;
    }
    return Icon(icon, size: 42, color: Colors.white.withOpacity(0.85));
  }

  Widget _tempPill(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 8,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.2),
    );
  }
}
