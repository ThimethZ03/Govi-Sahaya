class WeatherModel {
  final String location;
  final DateTime date;
  final double temperature;
  final double minTemp;
  final double maxTemp;
  final String condition;
  final String description;
  final double humidity;
  final double windSpeed;
  final int uvIndex;
  final int visibility;
  final String sunriseTime;
  final String sunsetTime;
  final List<DailyForecast> forecast;

  WeatherModel({
    required this.location,
    required this.date,
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.visibility,
    required this.sunriseTime,
    required this.sunsetTime,
    required this.forecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // ✅ If backend wraps data: { success: true, data: {...} }
    if (json['data'] is Map<String, dynamic>) {
      json = Map<String, dynamic>.from(json['data']);
    }

    // ✅ BACKEND (Mongo) format
    final bool isBackendFormat =
        json['current'] is Map<String, dynamic> || json['location'] is Map;

    if (isBackendFormat) {
      final locationObj = (json['location'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['location'])
          : <String, dynamic>{};

      final currentObj = (json['current'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['current'])
          : <String, dynamic>{};

      final city = (locationObj['city'] ?? 'Colombo').toString();

      // temperature may be nested: current.temperature.value
      double temp = 28.0;
      final tempObj = currentObj['temperature'];
      if (tempObj is Map<String, dynamic>) {
        temp = (tempObj['value'] ?? 28.0).toDouble();
      } else if (tempObj is num) {
        temp = tempObj.toDouble();
      }

      // forecast list: [{tempMax, tempMin, condition, icon, date, day}, ...]
      final rawForecast = (json['forecast'] is List)
          ? List<dynamic>.from(json['forecast'])
          : [];

      final parsedForecast = rawForecast
          .where((e) => e is Map<String, dynamic>)
          .map((e) => DailyForecast.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // min/max taken from first forecast item if exists
      double minT = temp;
      double maxT = temp;
      if (rawForecast.isNotEmpty && rawForecast[0] is Map<String, dynamic>) {
        final first = Map<String, dynamic>.from(rawForecast[0]);
        if (first['tempMin'] is num)
          minT = (first['tempMin'] as num).toDouble();
        if (first['tempMax'] is num)
          maxT = (first['tempMax'] as num).toDouble();
      }

      // date from lastUpdated
      final dt = DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ??
          DateTime.now();

      final sunrise = _formatTime(json['sunrise']);
      final sunset = _formatTime(json['sunset']);

      final cond = (currentObj['condition'] ?? 'Cloudy').toString();
      final desc = (currentObj['description'] ?? '').toString();

      return WeatherModel(
        location: city,
        date: dt,
        temperature: temp,
        minTemp: minT,
        maxTemp: maxT,
        condition: cond,
        description: desc.isNotEmpty ? desc : 'Feels like ${temp.toInt()}°',
        humidity: (currentObj['humidity'] ?? 0).toDouble(),
        windSpeed: (currentObj['windSpeed'] ?? 0).toDouble(),
        uvIndex: (currentObj['uvIndex'] ?? 0) is num
            ? (currentObj['uvIndex'] as num).toInt()
            : 0,
        visibility: (currentObj['visibility'] ?? 0) is num
            ? (currentObj['visibility'] as num).toInt()
            : 0,
        sunriseTime: sunrise,
        sunsetTime: sunset,
        forecast: parsedForecast,
      );
    }

    // ✅ OLD FLAT FORMAT (your previous expectation)
    return WeatherModel(
      location: (json['location'] ?? 'Colombo Sri-Lanka').toString(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      temperature: (json['temperature'] ?? 28.0).toDouble(),
      minTemp: (json['min_temp'] ?? 24.0).toDouble(),
      maxTemp: (json['max_temp'] ?? 31.0).toDouble(),
      condition: (json['condition'] ?? 'Heavy Rain').toString(),
      description: (json['description'] ?? 'Feels like 31°').toString(),
      humidity: (json['humidity'] ?? 85.0).toDouble(),
      windSpeed: (json['wind_speed'] ?? 7.9).toDouble(),
      uvIndex: (json['uv_index'] ?? 4) is num
          ? (json['uv_index'] as num).toInt()
          : 4,
      visibility: (json['visibility'] ?? 5) is num
          ? (json['visibility'] as num).toInt()
          : 5,
      sunriseTime: (json['sunrise_time'] ?? '4:50 AM').toString(),
      sunsetTime: (json['sunset_time'] ?? '6:45 PM').toString(),
      forecast: (json['forecast'] as List?)
              ?.map((e) => DailyForecast.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  static String _formatTime(dynamic value) {
    if (value == null) return '';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return value.toString();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}

class DailyForecast {
  final String day;
  final DateTime date;
  final double temperature;
  final String condition;
  final String icon;

  DailyForecast({
    required this.day,
    required this.date,
    required this.temperature,
    required this.condition,
    required this.icon,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    // ✅ BACKEND forecast format uses tempMax/tempMin
    if (json.containsKey('tempMax') || json.containsKey('tempMin')) {
      final dt =
          DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();
      final cond = (json['condition'] ?? 'Cloudy').toString();
      final iconCode = (json['icon'] ?? '').toString();

      final maxT = (json['tempMax'] ?? 0).toDouble();
      final minT = (json['tempMin'] ?? 0).toDouble();
      final displayTemp = maxT != 0 ? maxT : (minT != 0 ? minT : 28.0);

      return DailyForecast(
        day: (json['day'] ?? 'Today').toString(),
        date: dt,
        temperature: displayTemp,
        condition: cond,
        icon: _iconToEmoji(iconCode, cond),
      );
    }

    // ✅ OLD FLAT forecast format
    return DailyForecast(
      day: (json['day'] ?? 'Today').toString(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      temperature: (json['temperature'] ?? 28.0).toDouble(),
      condition: (json['condition'] ?? 'Rainy').toString(),
      icon: (json['icon'] ?? '🌧️').toString(),
    );
  }

  static String _iconToEmoji(String iconCode, String condition) {
    final c = condition.toLowerCase();
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('clear') || c.contains('sun')) return '☀️';

    if (iconCode.startsWith('01')) return '☀️';
    if (iconCode.startsWith('02')) return '⛅';
    if (iconCode.startsWith('03') || iconCode.startsWith('04')) return '☁️';
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return '🌧️';
    if (iconCode.startsWith('11')) return '⛈️';
    if (iconCode.startsWith('13')) return '❄️';
    if (iconCode.startsWith('50')) return '🌫️';

    return '🌤️';
  }
}
