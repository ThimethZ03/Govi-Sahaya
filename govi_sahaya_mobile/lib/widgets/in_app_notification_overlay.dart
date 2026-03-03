import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ NEW
import '../../config/theme.dart';
import '../../providers/theme_provider.dart'; // ✅ NEW

class InAppNotificationOverlay extends StatefulWidget {
  final String title;
  final String message;
  final String type;
  final String priority;
  final VoidCallback? onTap;

  const InAppNotificationOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.priority = 'normal',
    this.onTap,
  });

  @override
  State<InAppNotificationOverlay> createState() =>
      _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState extends State<InAppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark; // ✅ NEW
    final config = _getTypeConfig(widget.type, widget.priority, isDark);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              // ✅ dark mode notification bg
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: config.color.withOpacity(isDark ? 0.45 : 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  // ✅ dark mode shadow
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: config.color.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left color accent bar
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: config.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      // ✅ dark mode icon bg
                      color: config.bgColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(config.icon, color: config.color, size: 16),
                  ),

                  const SizedBox(width: 8),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  // ✅ dark mode title text
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.priority == 'urgent') ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  // ✅ dark mode urgent badge bg
                                  color: isDark
                                      ? Colors.red.shade900.withOpacity(0.4)
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'URGENT',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    // ✅ dark mode urgent badge text
                                    color: isDark
                                        ? Colors.red.shade300
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 11,
                            // ✅ dark mode message text
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Chevron hint
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    // ✅ dark mode chevron
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Type Config ────────────────────────────────────────────────────
  _ToastConfig _getTypeConfig(String type, String priority, bool isDark) {
    if (priority == 'urgent') {
      return _ToastConfig(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFC62828),
        // ✅ dark mode urgent icon bg
        bgColor: isDark
            ? const Color(0xFFC62828).withOpacity(0.2)
            : const Color(0xFFFFEBEE),
      );
    }
    switch (type) {
      case 'weather_alert':
        return _ToastConfig(
          icon: Icons.wb_sunny_rounded,
          color: const Color(0xFF0277BD),
          bgColor: isDark
              ? const Color(0xFF0277BD).withOpacity(0.2)
              : const Color(0xFFE1F5FE),
        );
      case 'disease_detection':
        return _ToastConfig(
          icon: Icons.biotech_outlined,
          color: const Color(0xFF558B2F),
          bgColor: isDark
              ? const Color(0xFF558B2F).withOpacity(0.2)
              : const Color(0xFFF1F8E9),
        );
      case 'order_update':
        return _ToastConfig(
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFFE65100),
          bgColor: isDark
              ? const Color(0xFFE65100).withOpacity(0.2)
              : const Color(0xFFFFF3E0),
        );
      case 'forum_reply':
        return _ToastConfig(
          icon: Icons.forum_outlined,
          color: const Color(0xFF00695C),
          bgColor: isDark
              ? const Color(0xFF00695C).withOpacity(0.2)
              : const Color(0xFFE0F2F1),
        );
      case 'price_alert':
        return _ToastConfig(
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF6A1B9A),
          bgColor: isDark
              ? const Color(0xFF6A1B9A).withOpacity(0.2)
              : const Color(0xFFF3E5F5),
        );
      default:
        return _ToastConfig(
          icon: Icons.notifications_outlined,
          color: AppTheme.primaryGreen,
          bgColor: isDark
              ? AppTheme.primaryGreen.withOpacity(0.2)
              : const Color(0xFFE8F5E9),
        );
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _ToastConfig({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
