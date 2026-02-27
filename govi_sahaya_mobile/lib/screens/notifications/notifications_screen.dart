import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
    _scrollController.addListener(_onScroll);
  }

  // ✅ No token param — provider reads ApiClient internally
  void _loadNotifications({bool refresh = false}) {
    context.read<NotificationProvider>().fetchNotifications(refresh: refresh);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().fetchNotifications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    // ✅ No token variable needed anywhere in build

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
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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

                  // Mark all read — ✅ no token param
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
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
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

                  // Clear all — ✅ no token param
                  if (provider.notifications.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showClearConfirm(provider),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── White content ──────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _buildBody(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Removed String token param
  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return _buildSkeleton();
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return _buildError(provider);
    }

    if (provider.notifications.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        itemCount: provider.notifications.length +
            (provider.isLoading || provider.hasMore ? 1 : 0),
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
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              _buildNotificationTile(notification, provider),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  // ✅ Removed String token param
  Widget _buildNotificationTile(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    final config = _getTypeConfig(notification.type, notification.priority);

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
      // ✅ No token param
      onDismissed: (_) => provider.deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            // ✅ No token param
            provider.markAsRead(notification.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : config.bgColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade100
                  : config.color.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
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
              // Icon container
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

              // Text content
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
                              color: const Color(0xFF1A1A1A),
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
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Type badge
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
                        // Priority badge
                        if (notification.priority == 'urgent' ||
                            notification.priority == 'high') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notification.priority == 'urgent'
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: notification.priority == 'urgent'
                                    ? Colors.red.shade700
                                    : Colors.orange.shade700,
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
                            color: Colors.grey.shade400,
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
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
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
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 11,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
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
  Widget _buildEmpty() {
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
          const Text(
            'No Notifications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!\nWe'll notify you when something new arrives.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state — ✅ removed String token param ────────────────────
  Widget _buildError(NotificationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            provider.error ?? 'Something went wrong',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _loadNotifications(refresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Clear confirmation — ✅ removed String token param ─────────────
  void _showClearConfirm(NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear All?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'All notifications will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // ✅ No token param
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
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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

  _TypeConfig _getTypeConfig(String type, String priority) {
    switch (type) {
      case 'weather_alert':
        return _TypeConfig(
          icon: Icons.cloud_outlined,
          color: const Color(0xFF1565C0),
          bgColor: const Color(0xFFE3F2FD),
          label: 'Weather',
        );
      case 'disease_detection':
        return _TypeConfig(
          icon: Icons.biotech_outlined,
          color: const Color(0xFF558B2F),
          bgColor: const Color(0xFFF1F8E9),
          label: 'Crop Doctor',
        );
      case 'order_update':
        return _TypeConfig(
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
          label: 'Order',
        );
      case 'forum_reply':
        return _TypeConfig(
          icon: Icons.forum_outlined,
          color: const Color(0xFF00695C),
          bgColor: const Color(0xFFE0F2F1),
          label: 'Community',
        );
      case 'price_alert':
        return _TypeConfig(
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF6A1B9A),
          bgColor: const Color(0xFFF3E5F5),
          label: 'Price',
        );
      default:
        return _TypeConfig(
          icon: Icons.notifications_outlined,
          color: AppTheme.primaryGreen,
          bgColor: const Color(0xFFE8F5E9),
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
