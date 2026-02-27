import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackendSupportService {
  static const String baseUrl = 'http://192.168.8.136:5000/api/v1';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_token');
  }

  // ── Update Language ────────────────────────────────────────────────
  Future<bool> updateLanguage(String langCode) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token for updateLanguage');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/support/language'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'language': langCode}),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 updateLanguage: ${response.statusCode}');
      print('📡 Response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ updateLanguage error: $e');
      return false;
    }
  }

  // ── Get Language ───────────────────────────────────────────────────
  Future<String?> getLanguage() async {
    // ✅ NEW
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token for getLanguage');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/support/language'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 getLanguage: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['language'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ getLanguage error: $e');
      return null;
    }
  }

  // ── Update Settings ────────────────────────────────────────────────
  Future<bool> updateSettings({
    required bool pushNotifications,
    required bool emailNotifications,
    required bool locationAccess,
    required bool dataSync,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token for updateSettings');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/support/settings'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'pushNotifications': pushNotifications,
              'emailNotifications': emailNotifications,
              'locationAccess': locationAccess,
              'dataSync': dataSync,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 updateSettings: ${response.statusCode}');
      print('📡 Response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ updateSettings error: $e');
      return false;
    }
  }

  // ── Submit Rating ──────────────────────────────────────────────────
  Future<bool> submitRating(int rating, String? feedback) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token for submitRating');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/support/rating'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'rating': rating,
              'feedback': feedback ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 submitRating: ${response.statusCode}');
      print('📡 Response: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ submitRating error: $e');
      return false;
    }
  }

  // ── Submit Problem Report ──────────────────────────────────────────
  Future<bool> submitReport(String category, String description) async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token for submitReport');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/support/report'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'category': category,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 submitReport: ${response.statusCode}');
      print('📡 Response: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ submitReport error: $e');
      return false;
    }
  }

  // ── Get Support Info ───────────────────────────────────────────────
  Future<Map<String, dynamic>?> getSupportInfo() async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('❌ No token for getSupportInfo');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/support'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 getSupportInfo: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('❌ getSupportInfo failed: ${response.body}');
    } catch (e) {
      print('❌ getSupportInfo error: $e');
    }
    return null;
  }
}
