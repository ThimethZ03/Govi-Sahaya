import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackendAuthService {
  static const String baseUrl = 'http://192.168.8.127:5000/api/v1';

  String? _backendToken;
  String? _refreshToken;

  // ✅ Get valid token (auto-refresh if expired)
  Future<String?> getBackendToken() async {
    if (_backendToken != null && !await _isTokenExpired(_backendToken!)) {
      return _backendToken;
    }

    // Try to load from storage
    final prefs = await SharedPreferences.getInstance();
    _backendToken = prefs.getString('backend_token');
    _refreshToken = prefs.getString('refresh_token');

    // Check if expired
    if (_backendToken != null && await _isTokenExpired(_backendToken!)) {
      print('🔄 Access token expired, attempting auto-refresh...');

      // Try to refresh
      if (_refreshToken != null) {
        final newToken = await _refreshAccessToken();
        if (newToken != null) {
          print('✅ Token refreshed automatically');
          return newToken;
        }
      }

      print('❌ Unable to refresh token, user must login again');
      await clearBackendToken();
      return null;
    }

    return _backendToken;
  }

  // ✅ Check if token is expired
  Future<bool> _isTokenExpired(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      final exp = payload['exp'] as int;
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      // Consider expired 5 minutes before actual expiry
      final isExpired =
          DateTime.now().isAfter(expiryDate.subtract(Duration(minutes: 5)));

      if (isExpired) {
        print('⏰ Token expired at: $expiryDate');
      }

      return isExpired;
    } catch (e) {
      print('❌ Error checking token expiry: $e');
      return true;
    }
  }

  // ✅ Refresh access token using refresh token
  Future<String?> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) return null;

      print('🔄 Requesting new access token...');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Refresh response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'] ?? data['token'];

        if (newAccessToken != null) {
          _backendToken = newAccessToken;

          // Save new access token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('backend_token', newAccessToken);

          print('✅ New access token obtained');
          return newAccessToken;
        }
      } else {
        print('❌ Token refresh failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Token refresh error: $e');
    }
    return null;
  }

  // ✅ Store both tokens
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    _backendToken = accessToken;
    _refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Login or sync with backend after Firebase login
  Future<Map<String, dynamic>?> syncWithBackend({
    required String firebaseUid,
    required String email,
    required String name,
    String? phone,
  }) async {
    try {
      print('🔄 Syncing with backend...');
      print('🌐 URL: $baseUrl/auth/firebase-sync');
      print(
          '📦 Data: firebaseUid=$firebaseUid, email=$email, displayName=$name');

      final body = {
        'firebaseUid': firebaseUid,
        'email': email,
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      print('📦 Request body: ${jsonEncode(body)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/firebase-sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Extract tokens
        String? accessToken = data['token'] ?? data['accessToken'];
        String? refreshToken = data['refreshToken'];

        if (data['data'] != null) {
          accessToken ??= data['data']['token'] ?? data['data']['accessToken'];
          refreshToken ??= data['data']['refreshToken'];
        }

        if (accessToken != null) {
          // Store both tokens (refreshToken might be null if not implemented yet)
          if (refreshToken != null) {
            await _storeTokens(accessToken, refreshToken);
            print('✅ Backend sync successful with refresh token!');
          } else {
            _backendToken = accessToken;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('backend_token', accessToken);
            print('✅ Backend sync successful!');
          }

          print('🎫 Token: ${accessToken.substring(0, 20)}...');
          return data['data'] ?? data;
        } else {
          print('⚠️ No token in response');
          return data;
        }
      } else {
        print('❌ Backend sync failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } on SocketException catch (e) {
      print('❌ Network error: Cannot connect to backend at $baseUrl');
      print('💡 Make sure backend is running and accessible');
      print('🔍 Error: $e');
    } on TimeoutException {
      print('❌ Request timeout: Backend not responding');
    } catch (e) {
      print('❌ Backend sync error: $e');
    }
    return null;
  }

  // Make authenticated request to backend with auto-retry
  Future<Map<String, dynamic>?> get(String endpoint,
      {bool retry = true}) async {
    try {
      final token = await getBackendToken();
      if (token == null) {
        print('⚠️ No backend token available');
        return null;
      }

      print('📡 GET Request: $baseUrl$endpoint');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 && retry) {
        print('⚠️ 401 Unauthorized - attempting token refresh');
        await getBackendToken(); // Will trigger refresh
        return get(endpoint, retry: false); // Retry once
      } else {
        print('❌ GET $endpoint failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Backend GET failed: $e');
    }
    return null;
  }

  // POST request with auto-retry
  Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> body,
      {bool retry = true}) async {
    try {
      final token = await getBackendToken();
      if (token == null) {
        print('⚠️ No backend token available');
        return null;
      }

      print('📡 POST Request: $baseUrl$endpoint');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401 && retry) {
        print('⚠️ 401 Unauthorized - attempting token refresh');
        await getBackendToken(); // Will trigger refresh
        return post(endpoint, body, retry: false); // Retry once
      } else {
        print('❌ POST $endpoint failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Backend POST failed: $e');
    }
    return null;
  }

  // Upload image for disease detection
  Future<Map<String, dynamic>?> detectDisease(File imageFile) async {
    try {
      final token = await getBackendToken();
      if (token == null) {
        throw Exception('Not authenticated with backend');
      }

      print('🔍 Uploading image for disease detection...');
      print('📄 File: ${imageFile.path}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ml/detect-disease'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      print('📤 Sending request...');

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Detection response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Disease detection successful!');
        return jsonDecode(response.body);
      } else {
        print('❌ Detection failed: ${response.body}');
      }
    } on TimeoutException {
      print('❌ Disease detection timeout');
    } catch (e) {
      print('❌ Disease detection error: $e');
    }
    return null;
  }

  // Get crops (public endpoint)
  Future<List<dynamic>?> getCrops() async {
    try {
      print('📦 Fetching crops from backend...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/crops'),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            '✅ Crops loaded: ${data['count'] ?? data['data']?.length ?? 0} crops');
        return data['data'] ?? data['crops'] ?? [];
      } else {
        print('❌ Get crops failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Get crops error: $e');
    }
    return null;
  }

  // Get diseases (public endpoint)
  Future<List<dynamic>?> getDiseases() async {
    try {
      print('📦 Fetching diseases from backend...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/ml/diseases'),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            '✅ Diseases loaded: ${data['count'] ?? data['data']?.length ?? 0} diseases');
        return data['data'] ?? data['diseases'] ?? [];
      } else {
        print('❌ Get diseases failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Get diseases error: $e');
    }
    return null;
  }

  // Get weather
  Future<Map<String, dynamic>?> getWeather({
    required double lat,
    required double lon,
  }) async {
    try {
      print('🌤️ Fetching weather...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/weather/current?lat=$lat&lon=$lon'),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Weather response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Weather data received');
        return jsonDecode(response.body);
      } else {
        print('❌ Get weather failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Get weather error: $e');
    }
    return null;
  }

  // Get news
  Future<List<dynamic>?> getNews() async {
    try {
      print('📰 Fetching news from backend...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/news/latest'),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 News response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            '✅ News loaded: ${data['count'] ?? data['data']?.length ?? 0} articles');
        return data['data'] ?? data['news'] ?? [];
      } else {
        print('❌ Get news failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Get news error: $e');
    }
    return null;
  }

  // Get forum posts
  Future<List<dynamic>?> getForumPosts() async {
    try {
      print('💬 Fetching forum posts...');
      final token = await getBackendToken();

      final response = await http.get(
        Uri.parse('$baseUrl/forum/posts'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Forum response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            '✅ Forum posts loaded: ${data['count'] ?? data['data']?.length ?? 0} posts');
        return data['data'] ?? data['posts'] ?? [];
      } else {
        print('❌ Get forum posts failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Get forum posts error: $e');
    }
    return null;
  }

  // Clear backend token
  Future<void> clearBackendToken() async {
    _backendToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_token');
    await prefs.remove('refresh_token');
    print('🗑️ Backend tokens cleared');
  }

  // Check if authenticated
  bool isAuthenticated() {
    return _backendToken != null;
  }

  // Get token (for debugging)
  String? getToken() {
    return _backendToken;
  }
}
