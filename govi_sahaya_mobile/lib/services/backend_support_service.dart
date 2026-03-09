import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackendSupportService {
  static const String baseUrl = 'http://192.168.8.127:5000/api/v1';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── GET Settings ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http
          .get(Uri.parse('$baseUrl/support/settings'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('❌ getSettings error: $e');
      return null;
    }
  }

  // ── PUT Settings ───────────────────────────────────────────────────────
  Future<bool> updateSettings({
    required bool pushNotifications,
    required bool emailNotifications,
    required bool locationAccess,
    required bool dataSync,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http
          .put(
            Uri.parse('$baseUrl/support/settings'),
            headers: _headers(token),
            body: jsonEncode({
              'pushNotifications': pushNotifications,
              'emailNotifications': emailNotifications,
              'locationAccess': locationAccess,
              'dataSync': dataSync,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ updateSettings error: $e');
      return false;
    }
  }

  // ── GET Language ───────────────────────────────────────────────────────
  Future<String?> getLanguage() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http
          .get(Uri.parse('$baseUrl/support/language'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

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

  // ── PUT Language ───────────────────────────────────────────────────────
  Future<bool> updateLanguage(String langCode) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http
          .put(
            Uri.parse('$baseUrl/support/language'),
            headers: _headers(token),
            body: jsonEncode({'language': langCode}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ updateLanguage error: $e');
      return false;
    }
  }

  // ── POST Rating ────────────────────────────────────────────────────────
  Future<bool> submitRating(int rating, String? feedback) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$baseUrl/support/rating'),
            headers: _headers(token),
            body: jsonEncode({'rating': rating, 'feedback': feedback ?? ''}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ submitRating error: $e');
      return false;
    }
  }

  // ── POST Report ────────────────────────────────────────────────────────
  Future<bool> submitReport(String category, String description) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse('$baseUrl/support/report'),
            headers: _headers(token),
            body:
                jsonEncode({'category': category, 'description': description}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ submitReport error: $e');
      return false;
    }
  }

  // ── GET Support Info ───────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getSupportInfo() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http
          .get(Uri.parse('$baseUrl/support'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print('❌ getSupportInfo error: $e');
      return null;
    }
  }

  // ── ✅ PUT Change Password ─────────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/auth/change-password'),
            headers: _headers(token),
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 changePassword: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      final body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': body['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print('❌ changePassword error: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  // ── ✅ DELETE Account ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> deleteAccount({required String password}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final request = http.Request(
        'DELETE',
        Uri.parse('$baseUrl/users/profile'),
      );
      request.headers.addAll(_headers(token));
      request.body = jsonEncode({'password': password});

      final streamed =
          await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamed);

      print('📡 deleteAccount: ${response.statusCode}');
      print('📡 Response: ${response.body}');

      final body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': body['message'] ?? 'Unknown error',
      };
    } catch (e) {
      print('❌ deleteAccount error: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }
}
