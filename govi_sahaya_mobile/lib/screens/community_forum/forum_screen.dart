import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/forum_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
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
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final forumProvider = context.read<ForumProvider>();
    await forumProvider.sendMessage(_messageController.text.trim());
    _messageController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final forumProvider = context.watch<ForumProvider>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
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
                                ? '${forumProvider.messages.length} පළකිරීම්'
                                : lang == 'ta'
                                    ? '${forumProvider.messages.length} இடுகைகள்'
                                    : '${forumProvider.messages.length} posts',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Create post button
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.createPost),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Refresh button
                  GestureDetector(
                    onTap: () => forumProvider.fetchMessages(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification icon
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 18),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              constraints: const BoxConstraints(
                                  minWidth: 15, minHeight: 15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.primaryGreen, width: 1.5),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── White Body ────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    // ── Messages List ─────────────────────────────────
                    Expanded(
                      child: Builder(
                        builder: (context) {
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
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.forum_outlined,
                                          size: 28,
                                          color: Colors.grey.shade400),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      lang == 'si'
                                          ? 'තවම පළකිරීම් නැත'
                                          : lang == 'ta'
                                              ? 'இன்னும் இடுகைகள் இல்லை'
                                              : 'No posts yet',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
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
                                          color: Colors.grey.shade400,
                                          fontSize: 11),
                                    ),
                                    const SizedBox(height: 18),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                          context, AppRoutes.createPost),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          lang == 'si'
                                              ? 'පළකිරීමක් සාදන්න'
                                              : lang == 'ta'
                                                  ? 'இடுகை உருவாக்கு'
                                                  : 'Create Post',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
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
                              padding:
                                  const EdgeInsets.fromLTRB(16, 20, 16, 16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isCurrentUser =
                                    message.senderId == authProvider.user?.uid;
                                return _buildMessageCard(
                                    message, isCurrentUser, lang, context);
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // ── Message Input Bar ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade100)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
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
                              style: const TextStyle(fontSize: 12),
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: lang == 'si'
                                    ? 'පණිවිඩයක් ටයිප් කරන්න...'
                                    : lang == 'ta'
                                        ? 'செய்தி தட்டச்சு செய்யுங்கள்...'
                                        : 'Type your message...',
                                hintStyle: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
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
                            onTap: _sendMessage,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.send_rounded,
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

  // ── Message Card ───────────────────────────────────────────────────
  Widget _buildMessageCard(
      dynamic message, bool isCurrentUser, String lang, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.postDetail,
        arguments: message,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppTheme.primaryGreen.withOpacity(0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentUser
                ? AppTheme.primaryGreen.withOpacity(0.15)
                : Colors.grey.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCurrentUser
                      ? AppTheme.primaryGreen.withOpacity(0.2)
                      : Colors.grey.shade200,
                  child: Text(
                    message.senderName[0].toUpperCase(),
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppTheme.primaryGreen
                          : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            message.senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lang == 'si'
                                    ? 'ඔබ'
                                    : lang == 'ta'
                                        ? 'நீங்கள்'
                                        : 'You',
                                style: const TextStyle(
                                  fontSize: 9,
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
                              size: 9,
                              color: AppTheme.textLight.withOpacity(0.5)),
                          const SizedBox(width: 3),
                          Text(
                            Helpers.getTimeAgo(message.createdAt),
                            style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textLight.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 16, color: AppTheme.textLight),
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

            const SizedBox(height: 8),

            // ── Text Content ─────────────────────────────────────────
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppTheme.textDark,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Image ─────────────────────────────────────────────────
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              size: 28, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text(
                            lang == 'si'
                                ? 'රූපය ලබාගත නොහැකිය'
                                : lang == 'ta'
                                    ? 'படம் ஏற்ற முடியவில்லை'
                                    : 'Image failed to load',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── Like & Comment Row ────────────────────────────────────
            Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () =>
                      context.read<ForumProvider>().likeMessage(message.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined,
                            size: 13, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                          '${message.likes}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Comment
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 13, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        '${message.comments}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Read more hint
                Row(
                  children: [
                    Text(
                      lang == 'si'
                          ? 'තව කියවන්න'
                          : lang == 'ta'
                              ? 'மேலும் படிக்க'
                              : 'Read more',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 9, color: AppTheme.primaryGreen),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
