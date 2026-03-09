// lib/services/backend_auth_service.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';

class BackendAuthService {
  static const String baseUrl = 'http://192.168.8.127:5000/api/v1';

  String? _backendToken;
  String? _refreshToken;

  // ── Resolve endpoint: full URL or path → always full URL ──────────
  String _resolve(String endpointOrUrl) {
    if (endpointOrUrl.startsWith('http')) return endpointOrUrl; // ✅ full URL
    return '$baseUrl$endpointOrUrl'; // ✅ path only
  }

  // ── Get valid token (auto-refresh if expired) ──────────────────
  Future<String?> getBackendToken() async {
    if (ApiClient().isAuthenticated) {
      _backendToken = ApiClient().token;
      return _backendToken;
    }

    if (_backendToken != null && !await _isTokenExpired(_backendToken!)) {
      return _backendToken;
    }

    final prefs = await SharedPreferences.getInstance();
    _backendToken = prefs.getString('backend_token');
    _refreshToken = prefs.getString('refresh_token');

    if (_backendToken != null && !await _isTokenExpired(_backendToken!)) {
      await ApiClient().setToken(_backendToken!);
      return _backendToken;
    }

    if (_backendToken != null && await _isTokenExpired(_backendToken!)) {
      debugPrint('🔄 Access token expired, attempting auto-refresh...');

      if (_refreshToken != null) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          debugPrint('✅ Token refreshed automatically');
          return newToken;
        }
      }

      debugPrint('❌ Unable to refresh token, user must login again');
      await clearBackendToken();
      return null;
    }

    return _backendToken;
  }

  // ── Check if token is expired ──────────────────────────────────
  Future<bool> _isTokenExpired(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      final exp = payload['exp'] as int;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final isExpired = DateTime.now()
          .isAfter(expiryDate.subtract(const Duration(minutes: 5)));

      if (isExpired) debugPrint('⏰ Token expired at: $expiryDate');
      return isExpired;
    } catch (e) {
      debugPrint('❌ Error checking token expiry: $e');
      return true;
    }
  }

  // ── Refresh access token ───────────────────────────────────────
  Future<String?> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) return null;

      debugPrint('🔄 Requesting new access token...');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 Refresh response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'] ?? data['token'];

        if (newAccessToken != null) {
          _backendToken = newAccessToken;
          await ApiClient().setToken(newAccessToken);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('backend_token', newAccessToken);
          debugPrint('✅ New access token obtained and synced');
          return newAccessToken;
        }
      } else {
        debugPrint('❌ Token refresh failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
    }
    return null;
  }

  // ── Store tokens in both storages ──────────────────────────────
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    _backendToken = accessToken;
    _refreshToken = refreshToken;
    await ApiClient().setToken(accessToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // ── Sync with backend after Firebase login ─────────────────────
  Future<Map<String, dynamic>?> syncWithBackend({
    required String firebaseUid,
    required String email,
    required String name,
    String? phone,
  }) async {
    try {
      debugPrint('🔄 Syncing with backend...');
      debugPrint('🌐 URL: $baseUrl/auth/firebase-sync');
      debugPrint(
          '📦 Data: firebaseUid=$firebaseUid, email=$email, displayName=$name');

      final body = {
        'firebaseUid': firebaseUid,
        'email': email,
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      debugPrint('📦 Request body: ${jsonEncode(body)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/firebase-sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        String? accessToken = data['token'] ?? data['accessToken'];
        String? refreshToken = data['refreshToken'];

        if (data['data'] != null) {
          accessToken ??= data['data']['token'] ?? data['data']['accessToken'];
          refreshToken ??= data['data']['refreshToken'];
        }

        if (accessToken != null) {
          if (refreshToken != null) {
            await _storeTokens(accessToken, refreshToken);
            debugPrint('✅ Backend sync successful with refresh token!');
          } else {
            _backendToken = accessToken;
            await ApiClient().setToken(accessToken);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('backend_token', accessToken);
            debugPrint('✅ Backend sync successful!');
          }

          debugPrint('🎫 Token: ${accessToken.substring(0, 20)}...');
          return data['data'] ?? data;
        } else {
          debugPrint('⚠️ No token in response');
          return data;
        }
      } else {
        debugPrint('❌ Backend sync failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
      }
    } on SocketException catch (e) {
      debugPrint('❌ Network error: Cannot connect to backend at $baseUrl');
      debugPrint('🔍 Error: $e');
    } on TimeoutException {
      debugPrint('❌ Request timeout: Backend not responding');
    } catch (e) {
      debugPrint('❌ Backend sync error: $e');
    }
    return null;
  }

  // ── Authenticated GET ──────────────────────────────────────────
  Future<Map<String, dynamic>?> get(String endpoint,
      {bool retry = true}) async {
    try {
      final token = await getBackendToken();
      if (token == null) {
        debugPrint('⚠️ No backend token available');
        return null;
      }

      final url = _resolve(endpoint); // ✅ smart resolve
      debugPrint('📡 GET Request: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 && retry) {
        debugPrint('⚠️ 401 Unauthorized - attempting token refresh');
        await getBackendToken();
        return get(endpoint, retry: false);
      } else {
        debugPrint('❌ GET $endpoint failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Backend GET failed: $e');
    }
    return null;
  }

  // ── Authenticated POST ─────────────────────────────────────────
  Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> body,
      {bool retry = true}) async {
    try {
      final token = await getBackendToken();
      if (token == null) {
        debugPrint('⚠️ No backend token available');
        return null;
      }

      final url = _resolve(endpoint); // ✅ smart resolve
      debugPrint('📡 POST Request: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 && retry) {
        debugPrint('⚠️ 401 Unauthorized - attempting token refresh');
        await getBackendToken();
        return post(endpoint, body, retry: false);
      } else {
        debugPrint('❌ POST $endpoint failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Backend POST failed: $e');
    }
    return null;
  }

  // ── Authenticated PUT ──────────────────────────────────────────
  Future<Map<String, dynamic>?> put(String endpoint, Map<String, dynamic> body,
      {bool retry = true}) async {
    try {
      final token = await getBackendToken();
      if (token == null) {
        debugPrint('⚠️ No backend token available');
        return null;
      }

      final url = _resolve(endpoint); // ✅ smart resolve
      debugPrint('📡 PUT Request: $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {'success': true};
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 && retry) {
        debugPrint('⚠️ 401 Unauthorized - attempting token refresh');
        await getBackendToken();
        return put(endpoint, body, retry: false);
      } else {
        debugPrint('❌ PUT $endpoint failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Backend PUT failed: $e');
    }
    return null;
  }

  // ── Authenticated DELETE ───────────────────────────────────────
  Future<Map<String, dynamic>?> delete(String endpoint,
      {bool retry = true}) async {
    try {
      final token = await getBackendToken();
      if (token == null) {
        debugPrint('⚠️ No backend token available');
        return null;
      }

      final url = _resolve(endpoint); // ✅ smart resolve
      debugPrint('📡 DELETE Request: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) return {'success': true};
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 && retry) {
        debugPrint('⚠️ 401 Unauthorized - attempting token refresh');
        await getBackendToken();
        return delete(endpoint, retry: false);
      } else {
        debugPrint('❌ DELETE $endpoint failed: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Backend DELETE failed: $e');
    }
    return null;
  }

  // ── Disease detection ──────────────────────────────────────────
  Future<Map<String, dynamic>?> detectDisease(File imageFile) async {
    try {
      final token = await getBackendToken();
      if (token == null) throw Exception('Not authenticated with backend');

      debugPrint('🔍 Uploading image for disease detection...');
      debugPrint('📄 File: ${imageFile.path}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ml/detect-disease'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = _getMimeType(imageFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      debugPrint('📤 Sending request...');

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Detection response: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Disease detection successful!');
        return jsonDecode(response.body);
      } else {
        debugPrint('❌ Detection failed: ${response.body}');
      }
    } on TimeoutException {
      debugPrint('❌ Disease detection timeout');
    } catch (e) {
      debugPrint('❌ Disease detection error: $e');
    }
    return null;
  }

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
      default:
        return 'image/jpeg';
    }
  }

  // ── Public endpoints ───────────────────────────────────────────
  Future<List<dynamic>?> getCrops() async {
    try {
      debugPrint('📦 Fetching crops from backend...');
      final response = await http
          .get(Uri.parse('$baseUrl/crops'))
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data['crops'] ?? [];
      }
    } catch (e) {
      debugPrint('❌ Get crops error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getDiseases() async {
    try {
      debugPrint('📦 Fetching diseases from backend...');
      final response = await http
          .get(Uri.parse('$baseUrl/ml/diseases'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data['diseases'] ?? [];
      }
    } catch (e) {
      debugPrint('❌ Get diseases error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeather({
    required double lat,
    required double lon,
  }) async {
    try {
      debugPrint('🌤️ Fetching weather...');
      final response = await http
          .get(Uri.parse('$baseUrl/weather/current?lat=$lat&lon=$lon'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('❌ Get weather error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getNews() async {
    try {
      debugPrint('📰 Fetching news from backend...');
      final response = await http
          .get(Uri.parse('$baseUrl/news/latest'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data['news'] ?? [];
      }
    } catch (e) {
      debugPrint('❌ Get news error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> getForumPosts() async {
    try {
      debugPrint('💬 Fetching forum posts...');
      final token = await getBackendToken();

      final response = await http.get(
        Uri.parse('$baseUrl/forum/posts'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data['posts'] ?? [];
      }
    } catch (e) {
      debugPrint('❌ Get forum posts error: $e');
    }
    return null;
  }

  // ── Clear all tokens ───────────────────────────────────────────
  Future<void> clearBackendToken() async {
    _backendToken = null;
    _refreshToken = null;
    await ApiClient().clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_token');
    await prefs.remove('refresh_token');
    debugPrint('🗑️ Backend tokens cleared');
  }

  bool isAuthenticated() => _backendToken != null;
  String? getToken() => _backendToken;
}
