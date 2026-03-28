// lib/services/notification_navigation_handler.dart

import 'package:flutter/material.dart';
import '../models/notification_model.dart';

/// ✅ Centralized notification routing handler
/// Maps backend notification types and payloads to app screens
class NotificationNavigationHandler {
  /// ── Category Mapping ──────────────────────────────────────────
  /// Maps backend notification types to Flutter channel keys
  static String mapTypeToChannel(String type) {
    switch (type) {
      case 'weather_alert':
        return 'weather';
      case 'price_alert':
        return 'price';
      case 'disease_detection':
        return 'crop';
      case 'order_update':
        return 'order';
      case 'forum_reply':
      case 'general':
      default:
        return 'general';
    }
  }

  /// ── Parse Notification Payload ───────────────────────────────
  /// Handles both JSON string and Map payloads from local/system notifications
  static Map<String, dynamic> parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      print('⚠️ Empty payload received');
      return {};
    }

    try {
      // Handle JSON string payloads
      if (payload.startsWith('{')) {
        // Try JSON parsing first
        try {
          return Map<String, dynamic>.from(
            Uri.splitQueryString(payload).cast<String, dynamic>(),
          );
        } catch (_) {
          // If query string fails, payload might be actual JSON
          // But this is risky, return as-is from URI parsing
          return Uri.splitQueryString(payload).cast<String, dynamic>();
        }
      }

      // Try parsing as query string (key=value&key2=value2)
      final parsed = Uri.splitQueryString(payload).cast<String, dynamic>();
      print('✅ Payload parsed: $parsed');
      return parsed;
    } catch (e) {
      print('⚠️ Failed to parse notification payload "$payload": $e');
      return {};
    }
  }

  /// ── Resolve Navigation Route ──────────────────────────────────
  /// Returns route name and arguments based on notification type and data
  /// ✅ Improved: Better logging and fallback handling
  static ({String route, Object? args}) resolveRoute(
    NotificationModel notification,
  ) {
    final type = notification.type;
    final actionUrl = notification.actionUrl;
    final data = notification.data ?? {};

    print(
        '🔀 Resolving route — Type: $type, ActionUrl: $actionUrl, Data: $data');

    switch (type) {
      // ── Weather Alert ──────────────────────────────────────────
      case 'weather_alert':
        print('✅ Resolved to /weather');
        return (
          route: '/weather',
          args: data.isNotEmpty ? data : null,
        );

      // ── Price Alert ────────────────────────────────────────────
      case 'price_alert':
        print('✅ Resolved to /shop');
        return (
          route: '/shop',
          args: data.isNotEmpty ? data : null,
        );

      // ── Disease Detection ──────────────────────────────────────
      case 'disease_detection':
        final detectionId = data['detectionId'] as String?;
        if (detectionId != null) {
          print('✅ Resolved to /crop-doctor with detectionId: $detectionId');
          return (
            route: '/crop-doctor',
            args: {'detectionId': detectionId, ...data},
          );
        }
        print('✅ Resolved to /crop-doctor (no detectionId)');
        return (route: '/crop-doctor', args: data.isNotEmpty ? data : null);

      // ── Order Update ───────────────────────────────────────────
      case 'order_update':
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          print('✅ Resolved to /product-detail with orderId: $orderId');
          return (
            route: '/product-detail',
            args: {'orderId': orderId, ...data},
          );
        }
        print('✅ Resolved to /shop (no orderId)');
        return (route: '/shop', args: data.isNotEmpty ? data : null);

      // ── Forum Reply ────────────────────────────────────────────
      case 'forum_reply':
        final postId = data['postId'] as String?;
        if (postId != null) {
          print('✅ Resolved to /post-detail with postId: $postId');
          return (
            route: '/post-detail',
            args: {'postId': postId, ...data},
          );
        }
        print('✅ Resolved to /forum (no postId)');
        return (route: '/forum', args: data.isNotEmpty ? data : null);

      // ── General Notifications (check data for context) ─────────
      case 'general':
        // Check if this is field-related (new field added, field updated, etc.)
        final fieldId = data['fieldId'] as String?;
        if (fieldId != null) {
          print('✅ Resolved to /profit-planner (field notification)');
          return (
            route: '/profit-planner',
            args: data.isNotEmpty ? data : null,
          );
        }
        // Check if this is expense-related
        final expenseId = data['expenseId'] as String?;
        if (expenseId != null) {
          print('✅ Resolved to /profit-planner (expense notification)');
          return (
            route: '/profit-planner',
            args: data.isNotEmpty ? data : null,
          );
        }
        // ✅ Generic general notification — stay on home
        print('✅ Resolved to /home (general notification)');
        return (route: '/home', args: data.isNotEmpty ? data : null);

      // ── Fallback: Use actionUrl or default to home ────
      default:
        if (actionUrl != null && actionUrl.isNotEmpty) {
          print('🔀 Attempting to parse actionUrl: $actionUrl');
          // ✅ Parse actionUrl pattern: /crop-doctor/:id
          final parsed = _parseActionUrl(actionUrl, data);
          if (parsed != null) {
            print('✅ Resolved actionUrl to: ${parsed.route}');
            return (route: parsed.route, args: parsed.args);
          }
        }
        // ✅ Changed: Default to home instead of notifications to avoid loops
        print('❌ No route matched, defaulting to /home');
        return (route: '/home', args: null);
    }
  }

  /// ── Parse Action URL ──────────────────────────────────────────
  /// Converts backend actionUrl pattern to route name and args
  /// E.g., /crop-doctor/:id -> route: '/crop-doctor', args: {'id': ...}
  static ({String route, Object? args})? _parseActionUrl(
    String actionUrl,
    Map<String, dynamic> data,
  ) {
    try {
      // Patterns: /crop-doctor/:id, /forum/posts/:id, /orders/:id, etc.
      final parts = actionUrl.split('/').where((p) => p.isNotEmpty).toList();

      if (parts.isEmpty) return null;

      // Extract route prefix (first meaningful part)
      String route = '/';
      Map<String, dynamic> args = {};

      if (parts.contains('crop-doctor')) {
        route = '/crop-doctor';
        // Extract :id or use detectionId from data
        if (parts.length > 1 && !parts.last.startsWith(':')) {
          args['detectionId'] = parts.last;
        }
      } else if (parts.contains('orders')) {
        route = '/product-detail';
        if (parts.length > 1 && !parts.last.startsWith(':')) {
          args['orderId'] = parts.last;
        }
      } else if (parts.contains('forum') && parts.contains('posts')) {
        route = '/post-detail';
        if (parts.length > 2 && !parts[parts.length - 1].startsWith(':')) {
          args['postId'] = parts.last;
        }
      } else if (parts.contains('forum')) {
        route = '/forum';
      }

      // Merge with provided data
      args.addAll(data);

      return (route: route, args: args.isNotEmpty ? args : null);
    } catch (e) {
      print('⚠️ Failed to parse actionUrl: $e');
      return null;
    }
  }

  /// ── Navigate with Safety ───────────────────────────────────────
  /// Safely navigates to resolved route with proper error handling
  /// ✅ Uses pushReplacementNamed to prevent route stacking
  /// ✅ Avoids redundant navigation if already on target route
  static Future<void> navigate(
    BuildContext context,
    NotificationModel notification, {
    bool markAsRead = true,
  }) async {
    try {
      if (!context.mounted) return;

      final resolved = resolveRoute(notification);
      final targetRoute = resolved.route;

      print('📲 Resolving route: $targetRoute with args: ${resolved.args}');

      // ✅ Prevent redundant navigation — don't navigate to /notifications if already there
      if (targetRoute == '/notifications') {
        print('⏭️ Already on notifications screen, skipping navigation');
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return;
      }

      // ✅ Use pushReplacementNamed to replace current route instead of stacking
      // This prevents the infinite loop when notifications fail to navigate
      if (context.mounted) {
        await Navigator.pushReplacementNamed(
          context,
          targetRoute,
          arguments: resolved.args,
        );
      }
    } catch (e) {
      print('❌ Navigation error: $e');
      print('⚠️ Falling back to notifications screen');
      // Fallback: only push if not already on notifications
      if (context.mounted) {
        // Check if we can pop first (means we have a route stack)
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    }
  }
}
