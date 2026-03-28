import 'package:dio/dio.dart';
import '../models/guide_model.dart';
import '../core/network/api_endpoints.dart';

class KnowledgeHubService {
  final Dio _dio = Dio();

  Future<List<GuideModel>> getGuides({
    String? category,
    String? search,
    String? language,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.knowledgeGuides, // -> '/api/v1/knowledge/guides'
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          if (language != null && language.isNotEmpty) 'language': language,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list =
            data is Map ? (data['data'] ?? []) : (data as List<dynamic>);
        return list.map((e) => GuideModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load guides');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<GuideModel>> getFeaturedGuides({
    String? language,
    int limit = 5,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.featuredGuides, // -> '/api/v1/knowledge/guides/featured'
      queryParameters: {
        if (language != null && language.isNotEmpty) 'language': language,
        'limit': limit,
      },
    );

    final data = response.data;
    final List<dynamic> list =
        data is Map ? (data['data'] ?? []) : (data as List<dynamic>);
    return list.map((e) => GuideModel.fromJson(e)).toList();
  }

  Future<List<GuideModel>> getPopularGuides({
    String? language,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.popularGuides, // -> '/api/v1/knowledge/guides/popular'
      queryParameters: {
        if (language != null && language.isNotEmpty) 'language': language,
        'limit': limit,
      },
    );

    final data = response.data;
    final List<dynamic> list =
        data is Map ? (data['data'] ?? []) : (data as List<dynamic>);
    return list.map((e) => GuideModel.fromJson(e)).toList();
  }

  Future<GuideModel> getGuideById(String id) async {
    final response = await _dio.get(
      ApiEndpoints.guideDetail(id), // -> '/api/v1/knowledge/guides/$id'
    );
    final data = response.data;
    final guideJson = data is Map ? (data['data'] ?? data) : data;
    return GuideModel.fromJson(guideJson);
  }

  Future<void> likeGuide(String id) async {
    await _dio.post(
      ApiEndpoints.likeGuide(id), // -> '/api/v1/knowledge/guides/$id/like'
    );
  }

  Future<List<String>> getCategories() async {
    final response = await _dio.get(
      ApiEndpoints.guideCategories, // -> '/api/v1/knowledge/categories'
    );
    final data = response.data;
    final List<dynamic> list =
        data is Map ? (data['data'] ?? []) : (data as List<dynamic>);
    return list
        .map((e) => e['_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
