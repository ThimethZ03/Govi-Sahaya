import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_navigation_handler.dart';
import '../models/notification_model.dart';
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ── INITIALIZE ────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

  // ── HANDLE TAP ────────────────────────────────────────────────────────
  // ✅ Updated: Uses global navigator to route to relevant screen
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');

    try {
      // ✅ Parse payload to reconstruct notification details
      final payloadData =
          NotificationNavigationHandler.parsePayload(response.payload);

      // Build minimal notification model for routing
      final notification = NotificationModel(
        id: payloadData['id'] as String? ?? 'unknown',
        type: payloadData['type'] as String? ?? 'general',
        title: payloadData['title'] as String? ?? 'Notification',
        message: payloadData['message'] as String? ?? '',
        isRead: false,
        createdAt: DateTime.now(),
        actionUrl: payloadData['actionUrl'] as String?,
        priority: payloadData['priority'] as String? ?? 'medium',
        data: (payloadData['data'] as Map<String, dynamic>?),
      );

      // ✅ Navigate using the handler
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null && navigatorContext.mounted) {
        NotificationNavigationHandler.navigate(
          navigatorContext,
          notification,
          markAsRead: true,
        );
      } else {
        print('⚠️ Navigator context not available');
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }

  // ── REQUEST PERMISSIONS (Android 13+) ─────────────────────────────────
  Future<bool> requestPermissions() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return true;

    final enabled = await androidImpl.areNotificationsEnabled();
    if (enabled == true) return true;

    final granted = await androidImpl.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── CHECK PUSH ENABLED (reads user toggle from SharedPreferences) ─────
  // ✅ KEY FIX: Every show call goes through this guard
  Future<bool> _isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_notifications') ?? true;
  }

  // ── SHOW IMMEDIATE NOTIFICATION ────────────────────────────────────────
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'budget_alerts',
    String channelName = 'Budget Alerts',
    String channelDescription = 'Notifications for budget warnings and updates',
  }) async {
    // ✅ Respect push notifications toggle — silently skip if disabled
    final enabled = await _isPushEnabled();
    if (!enabled) {
      print('🔕 Push notifications disabled — skipping: $title');
      return;
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
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

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
    print('✅ Notification shown: $title');
  }

  // ── SHOW NOTIFICATION WITH CUSTOM CHANNEL ─────────────────────────────
  // ✅ Use this for agri-specific alerts (weather, price, crop doctor etc.)
  Future<void> showAgriNotification({
    required int id,
    required String title,
    required String body,
    required String type, // 'weather' | 'price' | 'crop' | 'order' | 'general'
    String? payload,
  }) async {
    final channelConfig = _getChannelConfig(type);
    await showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      channelId: channelConfig['id']!,
      channelName: channelConfig['name']!,
      channelDescription: channelConfig['description']!,
    );
  }

  Map<String, String> _getChannelConfig(String type) {
    switch (type) {
      case 'weather':
        return {
          'id': 'weather_alerts',
          'name': 'Weather Alerts',
          'description': 'Weather warnings and forecasts for your farm',
        };
      case 'price':
        return {
          'id': 'price_alerts',
          'name': 'Price Alerts',
          'description': 'Market price updates for crops',
        };
      case 'crop':
        return {
          'id': 'crop_alerts',
          'name': 'Crop Doctor',
          'description': 'Disease detection and crop health alerts',
        };
      case 'order':
        return {
          'id': 'order_updates',
          'name': 'Order Updates',
          'description': 'Status updates for your marketplace orders',
        };
      default:
        return {
          'id': 'general_alerts',
          'name': 'General Alerts',
          'description': 'General app notifications',
        };
    }
  }

  // ── CHECK BUDGET AND SEND ALERT ────────────────────────────────────────
  Future<void> checkBudgetAndNotify({
    required String fieldId,
    required String fieldName,
    required double budget,
    required double spent,
  }) async {
    if (budget <= 0) return;

    final percentage = ((spent / budget) * 100).round();
    final remaining = budget - spent;

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

    if (percentage > 100) {
      title = '🚨 Budget Exceeded!';
      body =
          '$fieldName is over budget by Rs. ${remaining.abs().toStringAsFixed(2)}. '
          'Total spent: Rs. ${spent.toStringAsFixed(2)}';
      notificationId += 1000;
    } else if (percentage >= 90 && percentage < 100) {
      title = '⚠️ Budget Warning!';
      body = '$fieldName has used $percentage% of budget. '
          'Only Rs. ${remaining.toStringAsFixed(2)} remaining.';
      notificationId += 900;
    } else if (percentage >= 75 && percentage < 90) {
      title = '💡 Budget Alert';
      body = '$fieldName has used $percentage% of budget. '
          'Rs. ${remaining.toStringAsFixed(2)} remaining.';
      notificationId += 750;
    }

    if (title != null && body != null) {
      // ✅ showNotification already checks _isPushEnabled internally
      await showNotification(
        id: notificationId,
        title: title,
        body: body,
        payload: 'field:$fieldId',
        channelId: 'budget_alerts',
        channelName: 'Budget Alerts',
        channelDescription: 'Notifications for budget warnings and updates',
      );

      // ✅ Only mark as notified if push was actually enabled
      final enabled = await _isPushEnabled();
      if (enabled) {
        await prefs.setBool(notifiedKey, true);
        print('✅ Notification sent for $fieldName at $percentage%');
      }
    }
  }

  // ── CLEAR NOTIFICATION FLAGS ───────────────────────────────────────────
  Future<void> clearNotificationFlags(String fieldId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('notified_$fieldId')) {
        await prefs.remove(key);
      }
    }
    print('✅ Cleared notification flags for field: $fieldId');
  }

  // ── CANCEL SPECIFIC ────────────────────────────────────────────────────
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('✅ Cancelled notification id: $id');
  }

  // ── CANCEL ALL ─────────────────────────────────────────────────────────
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('✅ All notifications cancelled');
  }
}
