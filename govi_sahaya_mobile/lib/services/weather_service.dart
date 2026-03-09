import 'package:dio/dio.dart';
import '../models/weather_model.dart';
import '../core/network/api_endpoints.dart';
import '../services/backend_auth_service.dart';

class WeatherService {
  // ✅ Use BackendAuthService for auth token on weather fetch
  // so backend receives req.user and sends personal alerts
  final BackendAuthService _backendAuth = BackendAuthService();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<WeatherModel> getWeather(String city) async {
    try {
      // ✅ Attach token if available — triggers personal alert on backend
      final token = await _backendAuth.getBackendToken();

      final response = await _dio.get(
        ApiEndpoints.weatherCurrent,
        queryParameters: {'city': city},
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return WeatherModel.fromJson(
            Map<String, dynamic>.from(data['data']),
          );
        }

        return WeatherModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      throw Exception('Failed to load weather');
    } catch (e) {
      print('❌ WEATHER API ERROR: $e');
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
