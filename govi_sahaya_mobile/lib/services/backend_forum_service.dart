import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../core/network/api_endpoints.dart'; // ✅ no more hardcoded URLs

class BackendForumService {
  // ✅ No hardcoded baseUrl or serverUrl — all from ApiEndpoints

  // ── Auth token ───────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_token');
  }

  // ── Header helpers ───────────────────────────────────────────────
  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, String> _publicHeaders(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── Message parser — single helper, no duplication ───────────────
  Message _messageFromJson(Map<String, dynamic> post) {
    return Message(
      id: post['_id'] ?? '',
      senderId: post['author']?['_id'] ?? '',
      senderName: post['author']?['displayName'] ??
          post['author']?['name'] ??
          'Unknown',
      text: post['content'] ?? post['title'] ?? '',
      imageUrl: (post['images'] as List?)?.isNotEmpty == true
          ? ApiEndpoints.getImageUrl(post['images'][0]['url'])
          : null,
      createdAt: DateTime.parse(post['createdAt']),
      likes: post['likesCount'] ?? 0,
      comments: post['commentsCount'] ?? 0,
    );
  }

  // ── Fetch all posts ──────────────────────────────────────────────
  Future<List<Message>> fetchPosts({int page = 1, int limit = 10}) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiEndpoints.forumPosts}?page=$page&limit=$limit'),
        headers: _publicHeaders(token),
      );

      if (response.statusCode == 200) {
        final List posts = json.decode(response.body)['data'] ?? [];
        return posts
            .map((p) => _messageFromJson(p as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load posts: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // ── Create post ──────────────────────────────────────────────────
  Future<Message> createPost(String content, {File? image}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.createPost),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;
      request.fields['title'] =
          content.substring(0, content.length > 50 ? 50 : content.length);
      request.fields['category'] = 'general';

      if (image != null) {
        final ext = image.path.split('.').last.toLowerCase();
        final mime = (ext == 'png')
            ? 'png'
            : (ext == 'webp')
                ? 'webp'
                : 'jpeg';
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          image.path,
          contentType: MediaType('image', mime),
        ));
      }

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 201) {
        return _messageFromJson(
          json.decode(response.body)['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to create post: ${response.body}');
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // ── Get comments ─────────────────────────────────────────────────
  Future<List<dynamic>> getPostComments(String postId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.postComments(postId)),
        headers: _publicHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'] ?? [];
      }
      throw Exception('Failed to load comments: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  // ── Add comment ──────────────────────────────────────────────────
  Future<dynamic> addComment(String postId, String content) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse(ApiEndpoints.postComments(postId)),
        headers: _authHeaders(token),
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Failed to add comment: ${response.body}');
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // ── Delete comment ───────────────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse(ApiEndpoints.deleteComment(commentId)),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // ── Like post ────────────────────────────────────────────────────
  Future<void> likePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse(ApiEndpoints.likePost(postId)),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to like post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // ── Delete post ──────────────────────────────────────────────────
  Future<void> deletePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse(ApiEndpoints.postDetail(postId)),
        headers: _authHeaders(token),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
}
