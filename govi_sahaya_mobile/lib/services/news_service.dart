import 'package:dio/dio.dart';
import '../models/news_model.dart';
import '../core/network/api_endpoints.dart';

class NewsService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl, // ✅ uses ApiEndpoints
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ✅ News path relative to baseUrl (since baseUrl is set in BaseOptions)
  static const String _newsPath = '/api/v1/news';

  // Get all news with filters
  Future<Map<String, dynamic>> getNews({
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
    String? language,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
        if (language != null && language.isNotEmpty) 'language': language,
      };

      final response = await _dio.get(
        '$_newsPath/latest',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> newsData = response.data['data'];
        final List<NewsModel> newsList =
            newsData.map((json) => NewsModel.fromJson(json)).toList();

        return {
          'success': true,
          'data': newsList,
          'pagination': response.data['pagination'],
        };
      } else {
        throw Exception('Failed to load news');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get news by ID
  Future<NewsModel> getNewsById(String id) async {
    try {
      final response = await _dio.get('$_newsPath/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return NewsModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load news details');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get featured news
  Future<List<NewsModel>> getFeaturedNews({int limit = 5}) async {
    try {
      final response = await _dio.get(
        '$_newsPath/featured',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> newsData = response.data['data'];
        return newsData.map((json) => NewsModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load featured news');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get latest news
  Future<List<NewsModel>> getLatestNews({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '$_newsPath/latest',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> newsData = response.data['data'];
        return newsData.map((json) => NewsModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load latest news');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Like news
  Future<Map<String, dynamic>> likeNews(String id, String token) async {
    try {
      final response = await _dio.post(
        '$_newsPath/$id/like',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception('Failed to like news');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Share news
  Future<Map<String, dynamic>> shareNews(String id, String token) async {
    try {
      final response = await _dio.post(
        '$_newsPath/$id/share',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception('Failed to share news');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get agriculture statistics (Admin)
  Future<Map<String, dynamic>> getAgricultureStats() async {
    try {
      final response = await _dio.get('$_newsPath/stats/agriculture');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception('Failed to load statistics');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sync Esana news (Admin)
  Future<Map<String, dynamic>> syncEsanaNews(String token) async {
    try {
      final response = await _dio.post(
        '$_newsPath/sync/esana',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception('Failed to sync Esana news');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Error handler
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        if (error.response?.data != null &&
            error.response?.data['message'] != null) {
          return error.response!.data['message'];
        }
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      default:
        return 'Network error. Please check your internet connection.';
    }
  }
}
