import 'dart:io';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import 'backend_auth_service.dart';

class CropDoctorService {
  final Dio _dio;
  final BackendAuthService _backendAuth;

  CropDoctorService({
    Dio? dio,
    BackendAuthService? backendAuth,
  })  : _backendAuth = backendAuth ?? BackendAuthService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                validateStatus: (status) => status != null && status < 500,
              ),
            );

  /// POST /api/v1/crop-doctor/detect  (Protected)
  /// field name must be 'image'
  Future<Map<String, dynamic>> detect(File imageFile,
      {String? cropType, String? location, String? notes}) async {
    final token = await _backendAuth.getBackendToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }

    final fileName = imageFile.path.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      if (cropType != null) 'cropType': cropType,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
    });

    final response = await _dio.post(
      '/crop-doctor/detect',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );

    if (response.statusCode == 201 && response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }

    throw Exception(
        _extractError(response.data) ?? 'Crop doctor detect failed');
  }

  /// GET /api/v1/crop-doctor/history?limit=5
  Future<List<Map<String, dynamic>>> getRecent({int limit = 5}) async {
    final token = await _backendAuth.getBackendToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }

    final response = await _dio.get(
      '/crop-doctor/history',
      queryParameters: {'page': 1, 'limit': limit},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    }

    throw Exception(_extractError(response.data) ?? 'Failed to load history');
  }

  String? _extractError(dynamic data) {
    try {
      if (data == null) return null;
      if (data is String) return data;
      if (data is Map) {
        return data['message'] ??
            data['error'] ??
            data['details'] ??
            data['msg'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
