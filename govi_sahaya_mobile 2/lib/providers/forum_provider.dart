import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/backend_forum_service.dart';

class ForumProvider with ChangeNotifier {
  final BackendForumService _backendService = BackendForumService();

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch posts from backend
  Future<void> fetchMessages() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _messages = await _backendService.fetchPosts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send message (create post)
  Future<void> sendMessage(String text,
      {String? imageUrl, File? imageFile}) async {
    try {
      final newMessage = await _backendService.createPost(
        text,
        image: imageFile,
      );

      _messages.insert(0, newMessage);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Like message
  Future<void> likeMessage(String messageId) async {
    try {
      await _backendService.likePost(messageId);

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = Message(
          id: _messages[index].id,
          senderId: _messages[index].senderId,
          senderName: _messages[index].senderName,
          text: _messages[index].text,
          imageUrl: _messages[index].imageUrl,
          createdAt: _messages[index].createdAt,
          likes: _messages[index].likes + 1,
          comments: _messages[index].comments,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _backendService.deletePost(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
