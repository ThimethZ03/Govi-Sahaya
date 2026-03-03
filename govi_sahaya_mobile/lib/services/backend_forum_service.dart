import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class BackendForumService {
  static const String baseUrl = 'http://10.31.2.1:5000/api/v1/forum';
  static const String serverUrl = 'http://10.31.2.1:5000';

  // Get auth token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_token');
  }

  // Helper to get full image URL
  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    return '$serverUrl$imagePath';
  }

  // Get all posts
  Future<List<Message>> fetchPosts({int page = 1, int limit = 10}) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/posts?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📡 Fetch posts response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List posts = data['data'] ?? [];

        return posts
            .map((post) => Message(
                  id: post['_id'],
                  senderId: post['author']?['_id'] ?? '',
                  senderName: post['author']?['displayName'] ??
                      post['author']?['name'] ??
                      'Unknown',
                  text: post['content'] ?? post['title'] ?? '',
                  imageUrl: post['images']?.isNotEmpty == true
                      ? _getFullImageUrl(post['images'][0]['url'])
                      : null,
                  createdAt: DateTime.parse(post['createdAt']),
                  likes: post['likesCount'] ?? 0,
                  comments: post['commentsCount'] ?? 0,
                ))
            .toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch posts error: $e');
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // Create new post
  Future<Message> createPost(String content, {File? image}) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['content'] = content;
      request.fields['title'] =
          content.substring(0, content.length > 50 ? 50 : content.length);
      request.fields['category'] = 'general';

      if (image != null) {
        String extension = image.path.split('.').last.toLowerCase();

        String type = 'jpeg';
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            type = 'jpeg';
            break;
          case 'png':
            type = 'png';
            break;
          case 'webp':
            type = 'webp';
            break;
          default:
            type = 'jpeg';
        }

        print('📎 Adding image: ${image.path}');
        print('📎 File extension: $extension');
        print('📎 MIME type: image/$type');

        final multipartFile = await http.MultipartFile.fromPath(
          'images',
          image.path,
          contentType: MediaType('image', type),
        );

        request.files.add(multipartFile);
      }

      print('📤 Creating post...');
      print('📤 Content: $content');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Create post response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final post = data['data'];

        return Message(
          id: post['_id'],
          senderId: post['author']?['_id'] ?? '',
          senderName: post['author']?['displayName'] ??
              post['author']?['name'] ??
              'Unknown',
          text: post['content'] ?? post['title'] ?? '',
          imageUrl: post['images']?.isNotEmpty == true
              ? _getFullImageUrl(post['images'][0]['url'])
              : null,
          createdAt: DateTime.parse(post['createdAt']),
          likes: post['likesCount'] ?? 0,
          comments: post['commentsCount'] ?? 0,
        );
      } else {
        throw Exception('Failed to create post: ${response.body}');
      }
    } catch (e) {
      print('❌ Create post error: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // ============================================
  // ✅ COMMENT METHODS (ADD THESE)
  // ============================================

  // Get comments for a post
  Future<List<dynamic>> getPostComments(String postId) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get comments response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List comments = data['data'] ?? [];

        print('✅ Loaded ${comments.length} comments');
        return comments;
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get comments error: $e');
      throw Exception('Failed to get comments: $e');
    }
  }

  // Add comment to a post
  Future<dynamic> addComment(String postId, String content) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'content': content,
        }),
      );

      print('📡 Add comment response: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Comment added successfully');
        return data['data'];
      } else {
        throw Exception('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      print('❌ Add comment error: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Delete comment response: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment');
      }

      print('✅ Comment deleted successfully');
    } catch (e) {
      print('❌ Delete comment error: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  // ============================================
  // POST METHODS
  // ============================================

  // Like post
  Future<void> likePost(String postId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Like post response: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to like post');
      }
    } catch (e) {
      print('❌ Like post error: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Delete post response: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      print('❌ Delete post error: $e');
      throw Exception('Failed to delete post: $e');
    }
  }
}
