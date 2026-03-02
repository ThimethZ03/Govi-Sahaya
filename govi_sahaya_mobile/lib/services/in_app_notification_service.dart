import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/in_app_notification_overlay.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  OverlayEntry? _currentEntry;
  bool _isShowing = false;

  Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required String type,
    String priority = 'normal',
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('push_notifications') ?? true;
    if (!pushEnabled) {
      print('🔕 In-app popup suppressed (push disabled): $title');
      return;
    }

    await dismiss();

    if (!context.mounted) return;

    final overlayState = Overlay.of(context);

    // ✅ Safe top offset: status bar + top bar (56px) + gap (8px)
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topOffset = statusBarHeight + 50 + 4;

    _currentEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: topOffset,
        left: 0,
        right: 0,
        // ✅ FIX: elevation: 8 forces its own GPU render layer
        // making the white Container fully opaque above all content
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          child: InAppNotificationOverlay(
            title: title,
            message: message,
            type: type,
            priority: priority,
            onTap: () {
              dismiss();
              onTap?.call();
            },
          ),
        ),
      ),
    );

    overlayState.insert(_currentEntry!);
    _isShowing = true;

    await Future.delayed(duration);
    await dismiss();
  }

  Future<void> dismiss() async {
    if (!_isShowing || _currentEntry == null) return;
    _isShowing = false;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
