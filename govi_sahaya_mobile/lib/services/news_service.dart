import 'package:dio/dio.dart';
import '../models/news_model.dart';
import '../config/constants.dart';

/// Service layer responsible for all news-related API calls.
/// All methods throw a [String] error message on failure so the calling
/// provider can surface it to the UI without exposing raw [DioException].
class NewsService {
    NewsService() {
        _dio.interceptors.add(
                LogInterceptor(
                        request: false,
                responseBody: false,
                error: true,
      ),
    );
    }

    final Dio _dio = Dio(
            BaseOptions(
                    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {
        'Content-Type': 'application/json',
                'Accept': 'application/json',
    },
            ),
            );

    // ---------------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------------

    Options _authOptions(String token) => Options(
            headers: {'Authorization': 'Bearer $token'},
            );

    bool _isSuccess(Response<dynamic> response) =>
    response.statusCode == 200 &&
            (response.data as Map<String, dynamic>?)?['success'] == true;

    // ---------------------------------------------------------------------------
    // Public API
    // ---------------------------------------------------------------------------

    /// Returns a paginated list of news plus pagination metadata.
    Future<Map<String, dynamic>> getNews({
        int page = 1,
        int limit = 10,
        String? category,
                String? search,
                String? language,
    }) async {
        try {
            final queryParams = <String, dynamic>{
                    'page': page,
                    'limit': limit,
            if (category != null && category.isNotEmpty) 'category': category,
            if (search != null && search.isNotEmpty) 'search': search,
            if (language != null && language.isNotEmpty) 'language': language,
      };

            final response = await _dio.get<Map<String, dynamic>>(
                    AppConstants.newsEndpoint,
                    queryParameters: queryParams,
      );

            if (_isSuccess(response)) {
                final data = response.data!;
                final List<NewsModel> newsList = (data['data'] as List)
            .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
                        .toList();

                return {
                        'success': true,
                        'data': newsList,
                        'pagination': data['pagination'] as Map<String, dynamic>? ??
              const {'pages': 1, 'total': 0},
        };
            }

            throw Exception('Failed to load news');
        } on DioException catch (e) {
        throw Exception(_handleDioError(e));
    } catch (e) {
        throw Exception('An unexpected error occurred: $e');
    }
    }

    /// Fetches a single [NewsModel] by its [id].
    Future<NewsModel> getNewsById(String id) async {
        assert(id.isNotEmpty, 'News id must not be empty');
        try {
            final response = await _dio.get<Map<String, dynamic>>(
                    '${AppConstants.newsEndpoint}/$id',
      );

            if (_isSuccess(response)) {
                return NewsModel.fromJson(
                        response.data!['data'] as Map<String, dynamic>);
            }

            throw Exception('Failed to load news details');
        } on DioException catch (e) {
        throw Exception(_handleDioError(e));
    } catch (e) {
        throw Exception('An unexpected error occurred: $e');
    }
    }

    /// Returns up to [limit] featured news items.
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

    /// Returns up to [limit] latest news items, sorted by publish date.
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

    /// Increments the like count for a news item and returns updated counts.
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

    /// Increments the share count for a news item and returns updated counts.
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

    /// Returns aggregated agriculture statistics (admin-only endpoint).
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

    /// Triggers a sync with the Esana news source (admin-only endpoint).
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
    // Error handling
    // ---------------------------------------------------------------------------

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
