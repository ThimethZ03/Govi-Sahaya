import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../config/constants.dart';
import '../services/backend_auth_service.dart';
import '../services/in_app_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final BackendAuthService _backendAuth = BackendAuthService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _pollingTimer;

  // ✅ Global fetch lock — prevents ALL simultaneous calls (fixes 429)
  bool _isFetching = false;

  // ✅ Debounce timer for scroll-triggered pagination
  Timer? _scrollDebounce;

  // ✅ Context for in-app popups
  BuildContext? _context;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // ── Attach / Detach context ───────────────────────────────────────
  void attachContext(BuildContext context) {
    _context = context;
  }

  void detachContext() {
    _context = null;
  }

  // ── Push toggle check ─────────────────────────────────────────────
  Future<bool> _isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_notifications') ?? true;
  }

  // ── Start polling — 60s to avoid 429 ─────────────────────────────
  void startPolling() {
    stopPolling();
    fetchNotifications(refresh: true);
    // ✅ 60s instead of 30s — halves API call rate
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _pollUnreadCount();
    });
  }

  // ── Stop polling ──────────────────────────────────────────────────
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _scrollDebounce?.cancel();
    _scrollDebounce = null;
  }

  // ── Debounced scroll fetch — call this from scroll listener ───────
  // ✅ Prevents rapid API calls when user scrolls fast
  void fetchOnScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 600), () {
      fetchNotifications();
    });
  }

  // ── Lightweight poll ──────────────────────────────────────────────
  Future<void> _pollUnreadCount() async {
    // ✅ Skip if a fetch is already in progress
    if (_isFetching) return;

    try {
      final data = await _backendAuth.get('/notifications?page=1&limit=5');

      if (data != null && data['success'] == true) {
        final newCount = data['unreadCount'] ?? 0;

        if (newCount > _unreadCount) {
          await _showPopupForLatest(data);
          await fetchNotifications(refresh: true);
        } else if (newCount != _unreadCount) {
          _unreadCount = newCount;
          notifyListeners();
        }
      }
    } catch (_) {
      // Silent — polling failures never surface to user
    }
  }

  // ── Show in-app popup ─────────────────────────────────────────────
  Future<void> _showPopupForLatest(Map<String, dynamic> data) async {
    final pushEnabled = await _isPushEnabled();
    if (!pushEnabled) return;
    if (_context == null || !_context!.mounted) return;

    try {
      final List items = data['data'] as List? ?? [];
      if (items.isEmpty) return;

      final unreadItems =
          items.where((item) => item['isRead'] == false).toList();
      if (unreadItems.isEmpty) return;

      final latest = unreadItems.first;
      await InAppNotificationService().show(
        context: _context!,
        title: latest['title'] ?? 'New Notification',
        message: latest['message'] ?? '',
        type: latest['type'] ?? 'general',
        priority: latest['priority'] ?? 'normal',
        onTap: () {
          if (_context != null && _context!.mounted) {
            Navigator.pushNamed(_context!, '/notifications');
          }
        },
      );
    } catch (e) {
      print('❌ Failed to show in-app popup: $e');
    }
  }

  // ── Fetch notifications ───────────────────────────────────────────
  Future<void> fetchNotifications({bool refresh = false}) async {
    // ✅ CRITICAL: Single global lock prevents all simultaneous calls
    if (_isFetching) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _notifications = [];
    }

    // ✅ Guard: don't fetch if there's nothing more to load
    if (!_hasMore && !refresh) return;

    _isFetching = true;
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
      // ✅ Always release lock so future calls can proceed
      _isFetching = false;
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
      _notifications = backup;
      _unreadCount = backupCount;
      notifyListeners();
    }
  }

  // ── Auth header helper ────────────────────────────────────────────
  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── Login hook ────────────────────────────────────────────────────
  void onLoginSuccess() {
    _notifications = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _unreadCount = 0;
    _isFetching = false;
    notifyListeners();
    startPolling();
  }

  // ── Logout hook ───────────────────────────────────────────────────
  void onLogout() {
    stopPolling();
    detachContext();
    InAppNotificationService().dismiss();
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _isFetching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    detachContext();
    super.dispose();
  }
}
