// lib/providers/settings_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backend_support_service.dart';
import '../services/notification_service.dart';
import 'safety_provider.dart';

class SettingsProvider extends ChangeNotifier {
  final BackendSupportService _supportService = BackendSupportService();
  final NotificationService _notificationService = NotificationService();

  SafetyProvider? _safetyProvider;

  // ✅ Background sync timer
  Timer? _syncTimer;

  void setSafetyProvider(SafetyProvider provider) {
    _safetyProvider = provider;
  }

  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _darkMode = false;
  bool _locationAccess = true;
  bool _dataSync = true;
  bool _isSyncing = false;
  bool _isLoading = false;

  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get darkMode => _darkMode;
  bool get locationAccess => _locationAccess;
  bool get dataSync => _dataSync;
  bool get isSyncing => _isSyncing;
  bool get isLoading => _isLoading;

  // ── Load settings from SharedPreferences on app start ────────────
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool('push_notifications') ?? true;
    _emailNotifications = prefs.getBool('email_notifications') ?? false;
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _locationAccess = prefs.getBool('location_access') ?? true;
    _dataSync = prefs.getBool('data_sync') ?? true;

    _isLoading = false;
    notifyListeners();

    // ✅ Start background sync timer if enabled
    if (_dataSync) _startBackgroundSync();

    await _fetchFromBackend();
  }

  // ── Fetch current settings from backend ──────────────────────────
  Future<void> _fetchFromBackend() async {
    try {
      final data = await _supportService.getSettings();
      if (data == null) return;

      final prefs = await SharedPreferences.getInstance();

      _pushNotifications = data['pushNotifications'] ?? _pushNotifications;
      _emailNotifications = data['emailNotifications'] ?? _emailNotifications;
      _locationAccess = data['locationAccess'] ?? _locationAccess;
      _dataSync = data['dataSync'] ?? _dataSync;

      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('location_access', _locationAccess);
      await prefs.setBool('data_sync', _dataSync);

      await _applyPushNotificationState(_pushNotifications);
      _safetyProvider?.onLocationAccessChanged(_locationAccess);

      // ✅ Restart timer based on backend value
      if (_dataSync) {
        _startBackgroundSync();
      } else {
        _stopBackgroundSync();
      }

      notifyListeners();
    } catch (_) {}
  }

  // ── Toggle Push Notifications ─────────────────────────────────────
  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();
    await _saveLocal('push_notifications', value);
    await _applyPushNotificationState(value);
    await _syncToBackend();
  }

  // ── Toggle Email Notifications ────────────────────────────────────
  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    notifyListeners();
    await _saveLocal('email_notifications', value);
    await _syncToBackend();
  }

  // ── Toggle Dark Mode (local only) ─────────────────────────────────
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    await _saveLocal('dark_mode', value);
  }

  // ── Toggle Location Access ────────────────────────────────────────
  Future<void> setLocationAccess(bool value) async {
    _locationAccess = value;
    notifyListeners();
    await _saveLocal('location_access', value);
    _safetyProvider?.onLocationAccessChanged(value);
    await _syncToBackend();
  }

  // ── ✅ Toggle Background Sync — starts/stops timer ────────────────
  Future<void> setDataSync(bool value) async {
    _dataSync = value;
    notifyListeners();
    await _saveLocal('data_sync', value);

    if (value) {
      _startBackgroundSync();
    } else {
      _stopBackgroundSync();
    }

    await _syncToBackend();
  }

  // ── ✅ Start periodic background sync (every 15 min) ──────────────
  void _startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _fetchFromBackend();
    });
    print('✅ Background sync started (every 15 min)');
  }

  // ── ✅ Stop background sync ───────────────────────────────────────
  void _stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('🛑 Background sync stopped');
  }

  // ── Apply push state to NotificationService ───────────────────────
  Future<void> _applyPushNotificationState(bool enabled) async {
    if (!enabled) {
      await _notificationService.cancelAllNotifications();
    }
  }

  // ── Sync all settings to backend ──────────────────────────────────
  Future<void> _syncToBackend() async {
    _isSyncing = true;
    notifyListeners();

    await _supportService.updateSettings(
      pushNotifications: _pushNotifications,
      emailNotifications: _emailNotifications,
      locationAccess: _locationAccess,
      dataSync: _dataSync,
    );

    _isSyncing = false;
    notifyListeners();
  }

  // ── Save single value to SharedPreferences ────────────────────────
  Future<void> _saveLocal(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ── Called on logout — reset to defaults ──────────────────────────
  void onLogout() {
    _stopBackgroundSync(); // ✅ Stop timer on logout
    _pushNotifications = true;
    _emailNotifications = false;
    _darkMode = false;
    _locationAccess = true;
    _dataSync = true;
    _safetyProvider?.onLocationAccessChanged(true);
    notifyListeners();
  }

  // ── ✅ Dispose timer when provider is destroyed ───────────────────
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
