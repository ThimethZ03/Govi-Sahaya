// Import Dio package for HTTP requests
import 'package:dio/dio.dart';

// Import News model
import '../models/news_model.dart';

// Import constants for base URL and endpoints
import '../config/constants.dart';

/// Service layer responsible for all news-related API calls.
/// Throws [Exception] with error messages to be handled by the provider/UI.
class NewsService {

  // Constructor
  NewsService() {
    // Add a logging interceptor to see request/response errors in console
    _dio.interceptors.add(
      LogInterceptor(
        request: false, // Do not log request body
        responseBody: false, // Do not log response body
        error: true, // Log errors
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private members
  // ---------------------------------------------------------------------------

  // Dio instance for HTTP requests
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl, // API base URL
      connectTimeout: const Duration(seconds: 10), // 10 seconds to connect
      receiveTimeout: const Duration(seconds: 15), // 15 seconds to receive
      headers: const {
        'Content-Type': 'application/json', // JSON requests
        'Accept': 'application/json', // Accept JSON response
      },
    ),
  );

  // Helper to attach Authorization token in headers
  Options _authOptions(String token) => Options(
    headers: {'Authorization': 'Bearer $token'},
  );

  // Helper to check if API response is successful
  bool _isSuccess(Response<dynamic> response) =>
    response.statusCode == 200 &&
    (response.data as Map<String, dynamic>?)?['success'] == true;

  // ---------------------------------------------------------------------------
  // Public API methods
  // ---------------------------------------------------------------------------

  /// Fetch paginated news with optional filters: category, search text, language.
  Future<Map<String, dynamic>> getNews({
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
    String? language,
  }) async {
    try {
      // Build query parameters for GET request
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
        if (language != null && language.isNotEmpty) 'language': language,
      };

      // Perform GET request to fetch news
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.newsEndpoint,
        queryParameters: queryParams,
      );

      // If response is success
      if (_isSuccess(response)) {
        final data = response.data!;

        // Convert list of JSON news to NewsModel objects
        final List<NewsModel> newsList = (data['data'] as List)
            .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Return success map with data and pagination
        return {
          'success': true,
          'data': newsList,
          'pagination': data['pagination'] as Map<String, dynamic>? ??
              const {'pages': 1, 'total': 0},
        };
      }

      throw Exception('Failed to load news');

    } on DioException catch (e) {
      // Handle Dio-specific errors
      throw Exception(_handleDioError(e));
    } catch (e) {
      // Handle any other errors
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Fetch single news by ID
  Future<NewsModel> getNewsById(String id) async {
    assert(id.isNotEmpty, 'News id must not be empty');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.newsEndpoint}/$id',
      );

      if (_isSuccess(response)) {
        return NewsModel.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }

      throw Exception('Failed to load news details');

    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Fetch featured news (max [limit] items)
  Future<List<NewsModel>> getFeaturedNews({int limit = 5}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.newsEndpoint}/featured',
        queryParameters: {'limit': limit},
      );

      if (_isSuccess(response)) {
        return (response.data!['data'] as List)
            .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to load featured news');

    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Fetch latest news (max [limit] items)
  Future<List<NewsModel>> getLatestNews({int limit = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.newsEndpoint}/latest',
        queryParameters: {'limit': limit},
      );

      if (_isSuccess(response)) {
        return (response.data!['data'] as List)
            .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to load latest news');

    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Like a news item and return updated like count
  Future<Map<String, dynamic>> likeNews(String id, String token) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${AppConstants.newsEndpoint}/$id/like',
        options: _authOptions(token),
      );

      if (_isSuccess(response)) {
        return response.data!['data'] as Map<String, dynamic>;
      }

      throw Exception('Failed to like news');

    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Share a news item and return updated share count
  Future<Map<String, dynamic>> shareNews(String id, String token) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${AppConstants.newsEndpoint}/$id/share',
        options: _authOptions(token),
      );

      if (_isSuccess(response)) {
        return response.data!['data'] as Map<String, dynamic>;
      }

      throw Exception('Failed to share news');

    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Fetch aggregated agriculture statistics (admin-only)
  Future<Map<String, dynamic>> getAgricultureStats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${AppConstants.newsEndpoint}/stats/agriculture',
      );

      if (_isSuccess(response)) {
        return response.data!['data'] as Map<String, dynamic>;
      }

      throw Exception('Failed to load statistics');

    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Sync news from Esana source (admin-only)
  Future<Map<String, dynamic>> syncEsanaNews(String token) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${AppConstants.newsEndpoint}/sync/esana',
        options: _authOptions(token),
      );

      if (_isSuccess(response)) {
        return response.data!;
      }

      throw Exception('Failed to sync Esana news');

    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helper: error handling
  // ---------------------------------------------------------------------------

  /// Converts DioException to user-friendly messages
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final message = (error.response?.data as Map<String, dynamic>?)?['message'];
        if (message != null) return message.toString();
        return 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again.';
      default:
        return 'Network error. Please check your internet connection.';
    }
  }
}