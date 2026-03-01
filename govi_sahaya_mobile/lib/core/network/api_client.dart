import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ MIME type fix
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;
  static const Duration _timeout = Duration(seconds: 30);

  // ── Init: load token from storage ─────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      debugPrint('✅ Token loaded from storage');
    } else {
      debugPrint('⚠️ No token found in storage');
    }
  }

  // ── Set token ──────────────────────────────────────────────────
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    debugPrint('✅ Token saved to storage');
  }

  // ── Clear token ────────────────────────────────────────────────
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    debugPrint('🗑️ Token cleared from storage');
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // ── MIME type helper ───────────────────────────────────────────
  String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  // ── Headers ────────────────────────────────────────────────────
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // ── GET ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String url, {
    bool requiresAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      debugPrint('📡 GET Request: $uri');
      if (requiresAuth) {
        debugPrint(
            '🔐 Auth required: ${_token != null ? "Token present" : "No token"}');
      }

      final response = await http
          .get(uri, headers: _getHeaders(includeAuth: requiresAuth))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
            'Connection timeout after ${_timeout.inSeconds}s');
      });

      debugPrint('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      debugPrint('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      debugPrint('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } on HttpException catch (e) {
      debugPrint('❌ HTTP Exception: $e');
      throw ApiException('Server not reachable');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // ── POST ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      debugPrint('📡 POST Request: $url');
      debugPrint('📦 Body: ${jsonEncode(body)}');
      if (requiresAuth) {
        debugPrint(
            '🔐 Auth required: ${_token != null ? "Token present" : "No token"}');
      }

      final response = await http
          .post(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      )
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
            'Connection timeout after ${_timeout.inSeconds}s');
      });

      debugPrint('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      debugPrint('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      debugPrint('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } on HttpException catch (e) {
      debugPrint('❌ HTTP Exception: $e');
      throw ApiException('Server not reachable');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // ── PUT ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      debugPrint('📡 PUT Request: $url');
      debugPrint('📦 Body: ${jsonEncode(body)}');

      final response = await http
          .put(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      )
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
            'Connection timeout after ${_timeout.inSeconds}s');
      });

      debugPrint('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      debugPrint('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      debugPrint('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // ── PATCH ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      debugPrint('📡 PATCH Request: $url');
      debugPrint('📦 Body: ${jsonEncode(body)}');

      final response = await http
          .patch(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      )
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
            'Connection timeout after ${_timeout.inSeconds}s');
      });

      debugPrint('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      debugPrint('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      debugPrint('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(
    String url, {
    bool requiresAuth = false,
  }) async {
    try {
      debugPrint('📡 DELETE Request: $url');

      final response = await http
          .delete(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
      )
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException(
            'Connection timeout after ${_timeout.inSeconds}s');
      });

      debugPrint('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      debugPrint('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      debugPrint('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // ── Upload single file ─────────────────────────────────────────
  Future<Map<String, dynamic>> uploadFile(
    String url,
    File file, {
    required String fieldName,
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
  }) async {
    try {
      debugPrint('📡 Upload Request: $url');
      debugPrint('📄 File: ${file.path}');
      debugPrint('📦 Field name: $fieldName');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        debugPrint('🔐 Auth token added');
      }

      // ✅ MIME type fix — prevents backend 400 "Invalid file type"
      final mimeType = _getMimeType(file.path);
      final multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);
      debugPrint(
          '✅ File added: ${multipartFile.length} bytes, type: $mimeType');

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
        debugPrint('📝 Additional fields: $additionalFields');
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('Upload timeout after 60s'),
          );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('✅ Upload complete: ${response.statusCode}');

      return _handleResponse(response);
    } on SocketException {
      debugPrint('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      debugPrint('❌ Upload timeout');
      throw ApiException('Upload timeout. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Upload error: $e');
      throw ApiException('File upload error: $e');
    }
  }

  // ── Upload multiple files ──────────────────────────────────────
  Future<Map<String, dynamic>> uploadMultipleFiles(
    String url,
    List<File> files, {
    required String fieldName,
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
  }) async {
    try {
      debugPrint('📡 Multiple Upload Request: $url (${files.length} files)');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // ✅ MIME type fix for each file
      for (var file in files) {
        final mimeType = _getMimeType(file.path);
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw TimeoutException('Upload timeout after 90s'),
          );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('✅ Multiple upload complete: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Multiple upload error: $e');
      throw ApiException('Multiple file upload error: $e');
    }
  }

  // ── Handle response ────────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Success response');
        return data;
      } else {
        debugPrint('❌ Error response: ${response.statusCode}');
        debugPrint('❌ Body: ${response.body}');

        switch (response.statusCode) {
          case 401:
            clearToken();
            throw ApiException(
              'Unauthorized. Please login again.',
              statusCode: 401,
            );
          case 403:
            throw ApiException('Access forbidden', statusCode: 403);
          case 404:
            throw ApiException('Resource not found', statusCode: 404);
          case 422:
            final msg = data['message'] ?? data['error'] ?? 'Validation failed';
            throw ApiException(msg.toString(), statusCode: 422);
          case 500:
            throw ApiException(
              'Server error. Please try again later.',
              statusCode: 500,
            );
          default:
            throw ApiException(
              data['message'] ?? 'Request failed',
              statusCode: response.statusCode,
            );
        }
      }
    } on FormatException {
      debugPrint('❌ Invalid JSON response');
      throw ApiException('Invalid server response');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Response handling error: $e');
      throw ApiException('Failed to process response: $e');
    }
  }
}

// ── Exceptions ─────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isNetworkError => statusCode == null;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
