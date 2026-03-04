import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart' as app_user;
import '../core/network/api_client.dart';
import '../config/constants.dart';

class ProfileService {
  final ApiClient _api = ApiClient();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _base => AppConstants.baseApiUrl;

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
      default:
        return 'image/jpeg';
    }
  }

  // ── GET /api/v1/users/profile ──────────────────────────────────
  Future<app_user.User> getProfile(String uid) async {
    final res = await _api.get(
      '$_base/users/profile',
      requiresAuth: true,
    );
    return app_user.User.fromBackendJson(
        Map<String, dynamic>.from(res['data']), uid);
  }

  // ── PUT /api/v1/users/profile ──────────────────────────────────
  Future<app_user.User> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String address = '',
    String birthday = '',
    String gender = '',
    String farmLocation = '',
    String extraNotes = '',
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'location': {
        'district': address,
        'province': '',
      },
      'farmDetails': {
        'mainCrops': extraNotes.isNotEmpty ? [extraNotes] : [],
      },
      'birthday': birthday,
      'gender': gender,
      'farmLocation': farmLocation,
    };

    final res = await _api.put(
      '$_base/users/profile',
      body,
      requiresAuth: true,
    );

    final updated = app_user.User.fromBackendJson(
        Map<String, dynamic>.from(res['data']), uid);

    // ── Mirror to Firestore ────────────────────────────────────
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'name': name,
        'phone': phone,
        'address': address,
        'birthday': birthday,
        'gender': gender,
        'farmLocation': farmLocation,
        'extraNotes': extraNotes,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('✅ Firestore profile mirror updated');
    } catch (e) {
      debugPrint('⚠️ Firestore mirror failed (non-critical): $e');
    }

    return updated;
  }

  // ── POST /api/v1/users/profile-picture ────────────────────────
  // ✅ FIXED: field name changed to 'image' to match backend multer
  Future<String> uploadProfilePicture({
    required String uid,
    required File imageFile,
  }) async {
    try {
      final token = _api.token;
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated. Please login again.');
      }

      debugPrint('📡 Upload Request: $_base/users/profile-picture');
      debugPrint('📄 File: ${imageFile.path}');

      final mimeType = _getMimeType(imageFile.path);
      debugPrint('🖼️ MIME type: $mimeType');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_base/users/profile-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // ✅ Field name MUST be 'image' — matches uploadProfilePicture('image') in backend
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);
      debugPrint(
          '✅ File added: ${multipartFile.length} bytes, type: $mimeType');

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
            onTimeout: () =>
                throw Exception('Upload timeout. Please try again.'),
          );

      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('✅ Upload response: ${response.statusCode}');
      debugPrint('✅ Upload body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _decodeJson(response.body);
        final data = Map<String, dynamic>.from(body['data'] as Map);

        // ✅ Backend now returns full Cloudinary HTTPS URL
        final url = data['profilePicture'] as String;
        debugPrint('✅ Cloudinary URL: $url');

        // Mirror to Firestore
        try {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(uid)
              .update({
            'profileImageUrl': url,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });
          debugPrint('✅ Profile picture URL mirrored to Firestore: $url');
        } catch (e) {
          debugPrint('⚠️ Firestore picture mirror failed (non-critical): $e');
        }

        return url;
      } else {
        final body = _decodeJson(response.body);
        final msg = body['message'] ??
            body['error'] ??
            'Upload failed (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('❌ uploadProfilePicture error: $e');
      rethrow;
    }
  }

  // ── DELETE /api/v1/users/profile-picture ──────────────────────
  Future<void> deleteProfilePicture(String uid) async {
    await _api.delete(
      '$_base/users/profile-picture',
      requiresAuth: true,
    );

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'profileImageUrl': FieldValue.delete(),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('✅ Profile picture removed from Firestore');
    } catch (e) {
      debugPrint('⚠️ Firestore picture delete mirror failed: $e');
    }
  }

  // ── JSON decode helper ─────────────────────────────────────────
  Map<String, dynamic> _decodeJson(String body) {
    try {
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (_) {
      return {};
    }
  }
}
