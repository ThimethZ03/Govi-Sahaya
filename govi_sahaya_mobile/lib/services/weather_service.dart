import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../config/constants.dart';

class WeatherService {
  final Dio _dio = Dio();

  Future<WeatherModel> getWeather(String location) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.weatherEndpoint}',
        queryParameters: {'location': location},
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load weather');
      }
    } catch (e) {
      return _getDummyWeather();
    }
  }

  WeatherModel _getDummyWeather() {
    return WeatherModel(
      location: 'Colombo Sri-Lanka',
      date: DateTime.now(),
      temperature: 28.0,
      minTemp: 24.0,
      maxTemp: 31.0,
      condition: 'Heavy Rain',
      description: 'Feels like 31°',
      humidity: 85.0,
      windSpeed: 7.9,
      uvIndex: 4,
      visibility: 5,
      sunriseTime: '4:50 AM',
      sunsetTime: '6:45 PM',
      forecast: [
        DailyForecast(
          day: 'Today',
          date: DateTime.now(),
          temperature: 28,
          condition: 'Rainy',
          icon: '🌧️',
        ),
        DailyForecast(
          day: 'Mon',
          date: DateTime.now().add(const Duration(days: 1)),
          temperature: 31,
          condition: 'Partly Cloudy',
          icon: '⛅',
        ),
        DailyForecast(
          day: 'Tue',
          date: DateTime.now().add(const Duration(days: 2)),
          temperature: 27,
          condition: 'Rainy',
          icon: '🌧️',
        ),
        DailyForecast(
          day: 'Wed',
          date: DateTime.now().add(const Duration(days: 3)),
          temperature: 29,
          condition: 'Thunderstorm',
          icon: '⛈️',
        ),
        DailyForecast(
          day: 'Thu',
          date: DateTime.now().add(const Duration(days: 4)),
          temperature: 32,
          condition: 'Partly Cloudy',
          icon: '⛅',
        ),
      ],
    );
  }
}
