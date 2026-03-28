import 'dart:io';
import 'package:dio/dio.dart';
import '../models/disease_model.dart';
import '../core/network/api_endpoints.dart'; // ✅ replaced constants.dart
import 'backend_auth_service.dart';

class MLService {
  final Dio _dio;
  final BackendAuthService _backendAuth;

  MLService({
    Dio? dio,
    BackendAuthService? backendAuth,
  })  : _backendAuth = backendAuth ?? BackendAuthService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl:
                    ApiEndpoints.baseApiUrl, // ✅ FIXED: http://IP:5000/api/v1
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                validateStatus: (status) => status != null && status < 500,
              ),
            );

  /// POST /api/v1/ml/detect-disease
  Future<DiseaseModel> predictDisease(File imageFile) async {
    final token = await _backendAuth.getBackendToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }

    try {
      final fileName = imageFile.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/ml/detect-disease', // ✅ relative — /api/v1 already in baseUrl
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );

      // ignore: avoid_print
      print('ML BACKEND RAW RESPONSE => ${response.data}');

      if (response.statusCode != 200 || response.data == null) {
        final msg = _extractErrorMessage(response.data) ?? 'Prediction failed';
        throw Exception(msg);
      }

      final normalized = _normalizeBackendResponse(response.data);

      // ignore: avoid_print
      print('ML NORMALIZED => $normalized');

      return DiseaseModel.fromJson(normalized);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final serverMsg = _extractErrorMessage(e.response?.data);

      if (status == 401) {
        await _backendAuth.clearBackendToken();
        throw Exception('Unauthorized (401). Please login again.');
      }

      throw Exception(serverMsg ?? 'Network/Server error: ${e.message}');
    } catch (e) {
      throw Exception('ML Error: $e');
    }
  }

  /// Normalizes ANY backend shape → DiseaseModel-compatible map
  Map<String, dynamic> _normalizeBackendResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Shape: { predictions: [...], diseaseDetails: {...} }
      if (data.containsKey('predictions')) {
        final preds = data['predictions'];
        final top = (preds is List && preds.isNotEmpty && preds[0] is Map)
            ? Map<String, dynamic>.from(preds[0])
            : <String, dynamic>{};

        final details = (data['diseaseDetails'] is Map)
            ? Map<String, dynamic>.from(data['diseaseDetails'])
            : <String, dynamic>{};

        return {
          'id': top['id'] ?? top['rawPrediction'] ?? top['class'] ?? '',
          'name': top['name'] ?? top['disease'] ?? '',
          'name_sinhala': top['name_sinhala'] ?? '',
          'crop_name': top['crop_name'] ?? top['crop'] ?? '',
          'description': details['symptoms'] ?? top['description'] ?? '',
          'cause': details['cause'] ?? top['cause'] ?? '',
          'solution': details['solution'] ?? top['solution'] ?? '',
          'prevention': details['prevention'] ?? top['prevention'] ?? '',
          'recommendations': top['recommendations'] ?? [],
          'image_url': top['image_url'] ?? '',
          'confidence': top['confidence'] ?? 0.0,
          'risk_level': top['risk_level'] ?? top['severity'] ?? 'Medium',
        };
      }

      // Shape: direct flat object from mlController.mapDiseaseToFlutterModel
      return {
        'id': data['id'] ?? data['rawPrediction'] ?? data['class'] ?? '',
        'name': data['name'] ?? data['disease'] ?? '',
        'name_sinhala': data['name_sinhala'] ?? '',
        'crop_name': data['crop_name'] ?? data['crop'] ?? '',
        'description': data['description'] ?? data['symptoms'] ?? '',
        'cause': data['cause'] ?? '',
        'solution': data['solution'] ?? '',
        'prevention': data['prevention'] ?? '',
        'recommendations': data['recommendations'] ?? [],
        'image_url': data['image_url'] ?? '',
        'confidence': data['confidence'] ?? 0.0,
        'risk_level': data['risk_level'] ?? data['severity'] ?? 'Medium',
      };
    }

    // Fallback — unexpected format
    return {
      'id': '',
      'name': '',
      'name_sinhala': '',
      'crop_name': '',
      'description': '',
      'cause': '',
      'solution': '',
      'prevention': '',
      'recommendations': [],
      'image_url': '',
      'confidence': 0.0,
      'risk_level': 'Medium',
    };
  }

  String? _extractErrorMessage(dynamic data) {
    try {
      if (data == null) return null;
      if (data is String) return data;
      if (data is Map<String, dynamic>) {
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
