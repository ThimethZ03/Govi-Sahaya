import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../core/network/api_endpoints.dart';

class WeatherService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<WeatherModel> getWeather(String city) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.weatherCurrent,
        queryParameters: {'city': city}, // ✅ backend expects city
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ If backend response is: { success: true, data: {...} }
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return WeatherModel.fromJson(
            Map<String, dynamic>.from(data['data']),
          );
        }

        // ✅ If backend response is flat: {...}
        return WeatherModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      throw Exception('Failed to load weather');
    } catch (e) {
      // ✅ IMPORTANT: print error so you can SEE why it fails on phone
      print("❌ WEATHER API ERROR: $e");

      // keep dummy fallback (as you want)
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
      forecast: [],
    );
  }
}
