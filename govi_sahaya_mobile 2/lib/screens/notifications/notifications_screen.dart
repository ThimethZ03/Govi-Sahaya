// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_navigation_handler.dart'; // ✅ NEW

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Always refresh on open to keep data fresh
      context.read<NotificationProvider>().fetchNotifications(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().fetchOnScroll();
    }
  }

  // ✅ Single refresh method used by RefreshIndicator everywhere
  Future<void> _onRefresh() async {
    await context
        .read<NotificationProvider>()
        .fetchNotifications(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom AppBar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (provider.unreadCount > 0)
                          Text(
                            '${provider.unreadCount} unread',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Mark all read
                  if (provider.unreadCount > 0)
                    GestureDetector(
                      onTap: () => provider.markAllAsRead(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.done_all_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Read all',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Clear all
                  if (provider.notifications.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showClearConfirm(provider, isDark),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25), width: 1),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),

            // ── Body container ─────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : const Color(0xFFF6F8FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                // ✅ RefreshIndicator wraps ALL states — list, empty AND error
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppTheme.primaryGreen,
                  child: _buildBody(provider, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NotificationProvider provider, bool isDark) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      // ✅ Skeleton inside scrollable so pull-to-refresh works
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildSkeleton(isDark),
      );
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      // ✅ Error state inside scrollable so pull-to-refresh works
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: _buildError(provider, isDark),
          ),
        ],
      );
    }

    if (provider.notifications.isEmpty) {
      // ✅ Empty state inside scrollable so pull-to-refresh works
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: _buildEmpty(isDark),
          ),
        ],
      );
    }

    // ✅ Normal list — AlwaysScrollableScrollPhysics ensures drag works
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      itemCount: provider.notifications.length +
          (provider.hasMore || provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.notifications.length) {
          return provider.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }

        final notification = provider.notifications[index];
        final showDateHeader = index == 0 ||
            !_isSameDay(
              notification.createdAt,
              provider.notifications[index - 1].createdAt,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(
                  _formatDateHeader(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            _buildNotificationTile(notification, provider, isDark),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildNotificationTile(
    NotificationModel notification,
    NotificationProvider provider,
    bool isDark,
  ) {
    final config =
        _getTypeConfig(notification.type, notification.priority, isDark);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => provider.deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () async {
          // ✅ Mark as read if not already
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }

          // ✅ Navigate to relevant screen using handler
          await NotificationNavigationHandler.navigate(
            context,
            notification,
            markAsRead: true,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? AppTheme.darkCard : Colors.white)
                : config.bgColor.withOpacity(isDark ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? Colors.white12 : Colors.grey.shade100)
                  : config.color.withOpacity(isDark ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: config.bgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(config.icon, color: config.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: config.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: config.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (notification.priority == 'urgent' ||
                            notification.priority == 'high') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notification.priority == 'urgent'
                                  ? (isDark
                                      ? Colors.red.shade900.withOpacity(0.4)
                                      : Colors.red.shade50)
                                  : (isDark
                                      ? Colors.orange.shade900.withOpacity(0.4)
                                      : Colors.orange.shade50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: notification.priority == 'urgent'
                                    ? (isDark
                                        ? Colors.red.shade300
                                        : Colors.red.shade700)
                                    : (isDark
                                        ? Colors.orange.shade300
                                        : Colors.orange.shade700),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          timeago.format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.white24 : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Skeleton loading ───────────────────────────────────────────────
  Widget _buildSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 13,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSurface
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 11,
                        width: 180,
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppTheme.darkCard : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────
  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: AppTheme.primaryGreen.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Notifications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? AppTheme.darkTextPrimary : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!\nWe'll notify you when something new arrives.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // ✅ Pull down hint so user knows refresh works
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward_rounded,
                  size: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────
  Widget _buildError(NotificationProvider provider, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: isDark ? Colors.white24 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            provider.error ?? 'Something went wrong',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to retry',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => provider.fetchNotifications(refresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Clear confirmation dialog ──────────────────────────────────────
  void _showClearConfirm(NotificationProvider provider, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          'Clear All?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'All notifications will be permanently deleted.',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color:
                    isDark ? AppTheme.darkTextSecondary : Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'TODAY';
    if (d == yesterday) return 'YESTERDAY';
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int m) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m];
  }

  _TypeConfig _getTypeConfig(String type, String priority, bool isDark) {
    switch (type) {
      case 'weather_alert':
        return _TypeConfig(
          icon: Icons.cloud_outlined,
          color: const Color(0xFF1565C0),
          bgColor: isDark ? const Color(0xFF1A2744) : const Color(0xFFE3F2FD),
          label: 'Weather',
        );
      case 'disease_detection':
        return _TypeConfig(
          icon: Icons.biotech_outlined,
          color: const Color(0xFF558B2F),
          bgColor: isDark ? const Color(0xFF1A2A14) : const Color(0xFFF1F8E9),
          label: 'Crop Doctor',
        );
      case 'order_update':
        return _TypeConfig(
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFFE65100),
          bgColor: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF3E0),
          label: 'Order',
        );
      case 'forum_reply':
        return _TypeConfig(
          icon: Icons.forum_outlined,
          color: const Color(0xFF00695C),
          bgColor: isDark ? const Color(0xFF0A2420) : const Color(0xFFE0F2F1),
          label: 'Community',
        );
      case 'price_alert':
        return _TypeConfig(
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF6A1B9A),
          bgColor: isDark ? const Color(0xFF2A1A3A) : const Color(0xFFF3E5F5),
          label: 'Price',
        );
      default:
        return _TypeConfig(
          icon: Icons.notifications_outlined,
          color: AppTheme.primaryGreen,
          bgColor: isDark ? const Color(0xFF1A2A1A) : const Color(0xFFE8F5E9),
          label: 'General',
        );
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;

  const _TypeConfig({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
  });
}
