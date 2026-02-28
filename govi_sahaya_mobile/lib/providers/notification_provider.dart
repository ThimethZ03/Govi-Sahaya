import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../config/constants.dart';
import '../services/backend_auth_service.dart';

class NotificationProvider extends ChangeNotifier {
  final BackendAuthService _backendAuth = BackendAuthService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _pollingTimer; // ✅ polling timer

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // ── Start polling every 30 seconds ───────────────────────────────
  void startPolling() {
    stopPolling(); // cancel any existing timer first
    fetchNotifications(refresh: true); // immediate fetch on start
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollUnreadCount(); // lightweight — only fetches unread count
    });
  }

  // ── Stop polling (call on logout) ─────────────────────────────────
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ── Lightweight poll — only updates unread badge count ───────────
  // Does NOT rebuild the full list, avoids UI flicker
  Future<void> _pollUnreadCount() async {
    try {
      final data = await _backendAuth.get(
        '/notifications?page=1&limit=1',
      );
      if (data != null && data['success'] == true) {
        final newCount = data['unreadCount'] ?? 0;
        if (newCount != _unreadCount) {
          // ✅ Only rebuild if count actually changed
          _unreadCount = newCount;

          // ✅ If new notifications arrived, refresh the full list too
          if (newCount > _unreadCount) {
            await fetchNotifications(refresh: true);
          } else {
            notifyListeners(); // just update badge
          }
        }
      }
    } catch (_) {
      // silent — polling failures should never surface to user
    }
  }

  // ── Fetch notifications (full list) ──────────────────────────────
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _notifications = [];
    }
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _backendAuth.get(
        '/notifications?page=$_currentPage&limit=20',
      );

      if (data != null && data['success'] == true) {
        final List items = data['data'] as List;
        final pagination = data['pagination'];
        final fetched =
            items.map((e) => NotificationModel.fromJson(e)).toList();

        _notifications = refresh ? fetched : [..._notifications, ...fetched];
        _unreadCount = data['unreadCount'] ?? 0;
        _hasMore = _currentPage < (pagination['pages'] ?? 1);
        _currentPage++;
      } else {
        _error = data?['message'] ?? 'Failed to fetch notifications';
      }
    } catch (e) {
      _error = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mark single as read ───────────────────────────────────────────
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    try {
      final token = await _backendAuth.getBackendToken();
      if (token == null) return;
      await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/$id/read'),
        headers: _authHeaders(token),
      );
    } catch (_) {
      // ✅ Rollback on failure
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _unreadCount++;
      notifyListeners();
    }
  }

  // ── Mark all as read ──────────────────────────────────────────────
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      final token = await _backendAuth.getBackendToken();
      if (token == null) return;
      await http.put(
        Uri.parse('${AppConstants.baseUrl}/notifications/read-all'),
        headers: _authHeaders(token),
      );
    } catch (_) {}
  }

  // ── Delete single ─────────────────────────────────────────────────
  Future<void> deleteNotification(String id) async {
    final removedIndex = _notifications.indexWhere((n) => n.id == id);
    if (removedIndex == -1) return;

    final removed = _notifications[removedIndex];
    _notifications.removeAt(removedIndex);
    if (!removed.isRead) _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    try {
      final token = await _backendAuth.getBackendToken();
      if (token == null) return;
      await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notifications/$id'),
        headers: _authHeaders(token),
      );
    } catch (_) {
      // ✅ Rollback on failure
      _notifications.insert(removedIndex, removed);
      if (!removed.isRead) _unreadCount++;
      notifyListeners();
    }
  }

  // ── Clear all ─────────────────────────────────────────────────────
  Future<void> clearAll() async {
    final backup = [..._notifications];
    final backupCount = _unreadCount;

    _notifications = [];
    _unreadCount = 0;
    notifyListeners();

    try {
      final token = await _backendAuth.getBackendToken();
      if (token == null) return;
      await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notifications'),
        headers: _authHeaders(token),
      );
    } catch (_) {
      // ✅ Rollback on failure
      _notifications = backup;
      _unreadCount = backupCount;
      notifyListeners();
    }
  }

  // ── Header helper ─────────────────────────────────────────────────
  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── Called by AuthProvider after login ───────────────────────────
  void onLoginSuccess() {
    _notifications = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _unreadCount = 0;
    notifyListeners();
    startPolling(); // ✅ start polling immediately after login
  }

  // ── Called by AuthProvider on logout ─────────────────────────────
  void onLogout() {
    stopPolling(); // ✅ cancel timer
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling(); // ✅ prevent memory leak
    super.dispose();
  }
}
