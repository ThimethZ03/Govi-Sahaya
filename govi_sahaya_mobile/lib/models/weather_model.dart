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
    return WeatherModel(
      location: json['location'] ?? 'Colombo Sri-Lanka',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      temperature: (json['temperature'] ?? 28.0).toDouble(),
      minTemp: (json['min_temp'] ?? 24.0).toDouble(),
      maxTemp: (json['max_temp'] ?? 31.0).toDouble(),
      condition: json['condition'] ?? 'Heavy Rain',
      description: json['description'] ?? 'Feels like 31°',
      humidity: (json['humidity'] ?? 85.0).toDouble(),
      windSpeed: (json['wind_speed'] ?? 7.9).toDouble(),
      uvIndex: json['uv_index'] ?? 4,
      visibility: json['visibility'] ?? 5,
      sunriseTime: json['sunrise_time'] ?? '4:50 AM',
      sunsetTime: json['sunset_time'] ?? '6:45 PM',
      forecast: (json['forecast'] as List?)
              ?.map((e) => DailyForecast.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'date': date.toIso8601String(),
      'temperature': temperature,
      'min_temp': minTemp,
      'max_temp': maxTemp,
      'condition': condition,
      'description': description,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'uv_index': uvIndex,
      'visibility': visibility,
      'sunrise_time': sunriseTime,
      'sunset_time': sunsetTime,
      'forecast': forecast.map((e) => e.toJson()).toList(),
    };
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
    return DailyForecast(
      day: json['day'] ?? 'Today',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      temperature: (json['temperature'] ?? 28.0).toDouble(),
      condition: json['condition'] ?? 'Rainy',
      icon: json['icon'] ?? '🌧️',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'date': date.toIso8601String(),
      'temperature': temperature,
      'condition': condition,
      'icon': icon,
    };
  }
}
