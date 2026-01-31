import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ✅ INITIALIZE NOTIFICATIONS
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  // ✅ HANDLE NOTIFICATION TAP
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // TODO: Navigate to field detail screen using payload
  }

  // ✅ REQUEST PERMISSIONS (Android 13+)
  Future<bool> requestPermissions() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return true;

    final enabled = await androidImpl.areNotificationsEnabled();
    if (enabled == true) return true;

    final granted = await androidImpl.requestNotificationsPermission();
    return granted ?? false;
  }

  // ✅ SHOW IMMEDIATE NOTIFICATION
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications for budget warnings and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
    print('✅ Notification shown: $title');
  }

  // ✅ CHECK BUDGET AND SEND ALERT
  Future<void> checkBudgetAndNotify({
    required String fieldId,
    required String fieldName,
    required double budget,
    required double spent,
  }) async {
    if (budget <= 0) return;

    final percentage = ((spent / budget) * 100).round();
    final remaining = budget - spent;

    // Check if we already sent notification for this threshold
    final prefs = await SharedPreferences.getInstance();
    final notifiedKey = 'notified_${fieldId}_$percentage';
    final alreadyNotified = prefs.getBool(notifiedKey) ?? false;

    if (alreadyNotified) {
      print('⏭️ Already notified for $fieldName at $percentage%');
      return;
    }

    String? title;
    String? body;
    int notificationId = fieldId.hashCode;

    // ⚠️ CRITICAL: Over Budget (>100%)
    if (percentage > 100) {
      title = '🚨 Budget Exceeded!';
      body =
          '$fieldName is over budget by Rs. ${remaining.abs().toStringAsFixed(2)}. Total spent: Rs. ${spent.toStringAsFixed(2)}';
      notificationId += 1000;
    }
    // ⚠️ WARNING: 90% Used
    else if (percentage >= 90 && percentage < 100) {
      title = '⚠️ Budget Warning!';
      body =
          '$fieldName has used $percentage% of budget. Only Rs. ${remaining.toStringAsFixed(2)} remaining.';
      notificationId += 900;
    }
    // ⚠️ CAUTION: 75% Used
    else if (percentage >= 75 && percentage < 90) {
      title = '💡 Budget Alert';
      body =
          '$fieldName has used $percentage% of budget. Rs. ${remaining.toStringAsFixed(2)} remaining.';
      notificationId += 750;
    }

    // Send notification if threshold reached
    if (title != null && body != null) {
      await showNotification(
        id: notificationId,
        title: title,
        body: body,
        payload: 'field:$fieldId',
      );

      // Mark as notified for this threshold
      await prefs.setBool(notifiedKey, true);
      print('✅ Notification sent for $fieldName at $percentage%');
    }
  }

  // ✅ CLEAR NOTIFICATION FLAGS (call when budget is updated/reset)
  Future<void> clearNotificationFlags(String fieldId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('notified_$fieldId')) {
        await prefs.remove(key);
      }
    }
    print('✅ Cleared notification flags for field: $fieldId');
  }

  // ✅ CANCEL SPECIFIC NOTIFICATION
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // ✅ CANCEL ALL NOTIFICATIONS
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
