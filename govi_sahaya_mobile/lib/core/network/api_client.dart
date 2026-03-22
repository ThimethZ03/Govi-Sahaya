import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;

  // Request timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  // Initialize token from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      print('✅ Token loaded from storage');
    }
  }

  // Set token
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('✅ Token saved to storage');
  }

  // Clear token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('🗑️ Token cleared from storage');
  }

  // Get token
  String? get token => _token;

  // Check if user is authenticated
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // Get headers
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

  // GET request
  Future<Map<String, dynamic>> get(
    String url, {
    bool requiresAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      // Build URL with query parameters
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('📡 GET Request: $uri');
      if (requiresAuth) {
        print(
            '🔐 Auth required: ${_token != null ? "Token present" : "No token"}');
      }

      final response = await http
          .get(
        uri,
        headers: _getHeaders(includeAuth: requiresAuth),
      )
          .timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timeout after ${_timeout.inSeconds}s');
        },
      );

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      print('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      print('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      throw ApiException('Server not reachable');
    } catch (e) {
      print('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      print('📡 POST Request: $url');
      print('📦 Body: ${jsonEncode(body)}');
      if (requiresAuth) {
        print(
            '🔐 Auth required: ${_token != null ? "Token present" : "No token"}');
      }

      final response = await http
          .post(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      )
          .timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timeout after ${_timeout.inSeconds}s');
        },
      );

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      print('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      print('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      throw ApiException('Server not reachable');
    } catch (e) {
      print('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      print('📡 PUT Request: $url');
      print('📦 Body: ${jsonEncode(body)}');

      final response = await http
          .put(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      )
          .timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timeout after ${_timeout.inSeconds}s');
        },
      );

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      print('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      print('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      print('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      print('📡 PATCH Request: $url');
      print('📦 Body: ${jsonEncode(body)}');

      final response = await http
          .patch(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      )
          .timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timeout after ${_timeout.inSeconds}s');
        },
      );

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      print('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      print('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      print('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String url, {
    bool requiresAuth = false,
  }) async {
    try {
      print('📡 DELETE Request: $url');

      final response = await http
          .delete(
        Uri.parse(url),
        headers: _getHeaders(includeAuth: requiresAuth),
      )
          .timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timeout after ${_timeout.inSeconds}s');
        },
      );

      print('✅ Response ${response.statusCode}');
      return _handleResponse(response);
    } on SocketException {
      print('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      print('❌ Request timeout');
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      print('❌ Unknown error: $e');
      throw ApiException('Network error: $e');
    }
  }

  // Upload single file (multipart)
  Future<Map<String, dynamic>> uploadFile(
    String url,
    File file, {
    required String fieldName,
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
  }) async {
    try {
      print('📡 Upload Request: $url');
      print('📄 File: ${file.path}');
      print('📦 Field name: $fieldName');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('🔐 Auth token added');
      }

      // Add file
      var multipartFile = await http.MultipartFile.fromPath(
        fieldName,
        file.path,
      );
      request.files.add(multipartFile);
      print('✅ File added: ${multipartFile.length} bytes');

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
        print('📝 Additional fields: $additionalFields');
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Longer timeout for uploads
        onTimeout: () {
          throw TimeoutException('Upload timeout after 60s');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('✅ Upload complete: ${response.statusCode}');

      return _handleResponse(response);
    } on SocketException {
      print('❌ No internet connection');
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      print('❌ Upload timeout');
      throw ApiException('Upload timeout. Please try again.');
    } catch (e) {
      print('❌ Upload error: $e');
      throw ApiException('File upload error: $e');
    }
  }

  // Upload multiple files
  Future<Map<String, dynamic>> uploadMultipleFiles(
    String url,
    List<File> files, {
    required String fieldName,
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
  }) async {
    try {
      print('📡 Multiple Upload Request: $url');
      print('📄 Files count: ${files.length}');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Add all files
      for (var file in files) {
        var multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
        );
        request.files.add(multipartFile);
      }

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90), // Longer timeout for multiple files
        onTimeout: () {
          throw TimeoutException('Upload timeout after 90s');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);
      print('✅ Multiple upload complete: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Multiple upload error: $e');
      throw ApiException('Multiple file upload error: $e');
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Success response');
        return data;
      } else {
        print('❌ Error response: ${response.statusCode}');

        // Handle specific status codes
        switch (response.statusCode) {
          case 401:
            clearToken(); // Clear invalid token
            throw ApiException(
              'Unauthorized. Please login again.',
              statusCode: 401,
            );
          case 403:
            throw ApiException(
              'Access forbidden',
              statusCode: 403,
            );
          case 404:
            throw ApiException(
              'Resource not found',
              statusCode: 404,
            );
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
      print('❌ Invalid JSON response');
      throw ApiException('Invalid server response');
    } catch (e) {
      if (e is ApiException) rethrow;
      print('❌ Response handling error: $e');
      throw ApiException('Failed to process response: $e');
    }
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  // Check if error is due to authentication
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  // Check if error is due to network
  bool get isNetworkError => statusCode == null;

  // Check if error is due to server
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

// Timeout exception
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}
