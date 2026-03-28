// lib/screens/community_forum/forum_screen_improved.dart
// ✅ IMPROVED VERSION: Better filtering, search, and interactive UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/forum_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../core/utils/helpers.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSending = false;
  bool _showSearchBar = false; // ✅ Toggle search visibility

  // ✅ NEW: Category filter options
  final List<Map<String, String>> _categories = [
    {'id': 'all', 'icon': '📌', 'label': 'All'},
    {'id': 'pest', 'icon': '🐛', 'label': 'Pest'},
    {'id': 'disease', 'icon': '🦠', 'label': 'Disease'},
    {'id': 'weather', 'icon': '☀️', 'label': 'Weather'},
    {'id': 'fertilizer', 'icon': '🌾', 'label': 'Fertilizer'},
    {'id': 'technique', 'icon': '🚜', 'label': 'Technique'},
    {'id': 'market', 'icon': '💹', 'label': 'Market'},
  ];

  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().fetchMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await context
          .read<ForumProvider>()
          .sendMessage(_messageController.text.trim());
      _messageController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _topBarButton({required Widget child}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: child,
    );
  }

  Widget _badge(int count) {
    return Positioned(
      top: -3,
      right: -3,
      child: Container(
        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1.1),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final authProvider = context.watch<AuthProvider>();
    final forumProvider = context.watch<ForumProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _topBarButton(
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'si'
                              ? 'ප්‍රජා සංසදය'
                              : lang == 'ta'
                                  ? 'சமூக மன்றம்'
                                  : 'Community Forum',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (forumProvider.messages.isNotEmpty)
                          Text(
                            lang == 'si'
                                ? '${forumProvider.messages.length} සක්‍රිය පළකිරීම්'
                                : lang == 'ta'
                                    ? '${forumProvider.messages.length} செயலுற்ற இடுகைகள்'
                                    : '${forumProvider.messages.length} active posts',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  // ✅ NEW: Search toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showSearchBar = !_showSearchBar),
                    child: _topBarButton(
                      child: const Icon(Icons.search_rounded,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.createPost);
                      if (mounted) forumProvider.fetchMessages();
                    },
                    child: _topBarButton(
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => forumProvider.fetchMessages(),
                    child: _topBarButton(
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _topBarButton(
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 18),
                        ),
                        if (unreadCount > 0) _badge(unreadCount),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ NEW: Animated Search Bar
            if (_showSearchBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search posts...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 16),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () =>
                                setState(() => _searchController.clear()),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 16),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),

            // ✅ NEW: Category Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Row(
                  children: _categories
                      .map(
                        (category) => GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategory = category['id']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedCategory == category['id']
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedCategory == category['id']
                                    ? Colors.transparent
                                    : Colors.white.withOpacity(0.2),
                              ),
                              boxShadow: _selectedCategory == category['id']
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category['icon']!,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  category['label']!,
                                  style: TextStyle(
                                    color: _selectedCategory == category['id']
                                        ? AppTheme.primaryGreen
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight:
                                        _selectedCategory == category['id']
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            // ── BODY CONTENT ──────────────────────────────────────────────
            Expanded(
              child: Container(
                color: isDark ? AppTheme.darkBackground : Colors.white,
                child: Column(
                  children: [
                    // ── Messages List ─────────────────────────────────────
                    Expanded(
                      child: Builder(builder: (context) {
                        final messages = forumProvider.messages;

                        if (forumProvider.isLoading && messages.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen),
                          );
                        }

                        if (messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.darkCard
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.forum_outlined,
                                        size: 28,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : Colors.grey.shade400),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    lang == 'si'
                                        ? 'තවම පළකිරීම් නැත'
                                        : lang == 'ta'
                                            ? 'இன்னும் இடுகைகள் இல்லை'
                                            : 'No posts yet',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lang == 'si'
                                        ? 'පළමු පළකිරීම කරන්න!'
                                        : lang == 'ta'
                                            ? 'முதல் இடுகையை உருவாக்குங்கள்!'
                                            : 'Be the first to post!',
                                    style: TextStyle(
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : Colors.grey.shade400,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () => forumProvider.fetchMessages(),
                          color: AppTheme.primaryGreen,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isCurrentUser =
                                  message.senderId == authProvider.user?.uid;
                              return _buildMessageCard(message, isCurrentUser,
                                  lang, isDark, context);
                            },
                          ),
                        );
                      }),
                    ),

                    // ── Message Input Bar ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color:
                                isDark ? Colors.white12 : Colors.grey.shade100,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black38
                                : Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppTheme.primaryGreen.withOpacity(0.15),
                            child: Text(
                              context
                                      .read<AuthProvider>()
                                      .user
                                      ?.name[0]
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textDark,
                              ),
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: lang == 'si'
                                    ? 'පණිවිඩයක් ටයිප් කරන්න...'
                                    : lang == 'ta'
                                        ? 'செய்தி தட்டச்சு செய்யுங்கள்...'
                                        : 'Type your message...',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor:
                                    isDark ? AppTheme.darkCard : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                      color: AppTheme.primaryGreen),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isSending ? null : _sendMessage,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _isSending
                                    ? (isDark
                                        ? AppTheme.darkCard
                                        : Colors.grey.shade300)
                                    : AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isSending
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppTheme.primaryGreen
                                              .withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: _isSending
                                  ? const Padding(
                                      padding: EdgeInsets.all(9),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ IMPROVED: Message Card with like/reply counts and action buttons
  Widget _buildMessageCard(
    dynamic message,
    bool isCurrentUser,
    String lang,
    bool isDark,
    BuildContext context,
  ) {
    final likeCount = message.likes ?? 0;
    final replyCount = message.comments ?? 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.postDetail,
        arguments: message,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? (isDark
                  ? AppTheme.primaryGreen.withOpacity(0.12)
                  : AppTheme.primaryGreen.withOpacity(0.05))
              : (isDark ? AppTheme.darkCard : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser
                ? AppTheme.primaryGreen.withOpacity(isDark ? 0.25 : 0.15)
                : (isDark ? Colors.white12 : Colors.grey.shade100),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isCurrentUser
                      ? AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.12)
                      : (isDark ? AppTheme.darkSurface : Colors.grey.shade200),
                  child: Text(
                    message.senderName[0].toUpperCase(),
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppTheme.primaryGreen
                          : (isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey.shade600),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            message.senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textDark,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen
                                    .withOpacity(isDark ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lang == 'si'
                                    ? 'ඔබ'
                                    : lang == 'ta'
                                        ? 'நீங்கள்'
                                        : 'You',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 10,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.getTimeAgo(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        size: 16,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textLight),
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded,
                                size: 15, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              lang == 'si'
                                  ? 'මකන්න'
                                  : lang == 'ta'
                                      ? 'நீக்கு'
                                      : 'Delete',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        context.read<ForumProvider>().deleteMessage(message.id);
                      }
                    },
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Content ────────────────────────────────────────────────────
            Text(
              message.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Image ──────────────────────────────────────────────────────
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey.shade400),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ✅ NEW: Action Bar (Like, Reply, Share buttons)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurface.withOpacity(0.5)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  // Like button
                  Expanded(
                    child: _actionButton(
                      icon: Icons.favorite_outline_rounded,
                      label: likeCount > 0 ? '$likeCount' : 'Like',
                      onTap: () {
                        // TODO: Implement like functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Like feature coming soon'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 16,
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                  // Reply button
                  Expanded(
                    child: _actionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: replyCount > 0 ? '$replyCount' : 'Reply',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.postDetail,
                        arguments: message,
                      ),
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 16,
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                  // Share button
                  Expanded(
                    child: _actionButton(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share feature coming soon'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Reusable action button widget
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
