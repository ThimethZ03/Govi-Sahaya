// lib/screens/forum/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/forum_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart'; // ✅
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/helpers.dart';
import '../../services/backend_forum_service.dart';

class PostDetailScreen extends StatefulWidget {
  final dynamic post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final BackendForumService _forumService = BackendForumService();

  bool _isLiked = false;
  bool _isLoadingComments = false;
  bool _isPostingComment = false;
  List<dynamic> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── Top bar button — always on green header ─────────────────────
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

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final data = await _forumService.getPostComments(widget.post.id);
      if (mounted)
        setState(() {
          _comments = data;
          _isLoadingComments = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
        final lang = context.read<LanguageProvider>().languageCode;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            lang == 'si'
                ? 'අදහස් පූරණය අසාර්ථකයි'
                : lang == 'ta'
                    ? 'கருத்துகளை ஏற்ற முடியவில்லை'
                    : 'Failed to load comments',
          ),
        ));
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final commentText = _commentController.text.trim();
    final lang = context.read<LanguageProvider>().languageCode;

    setState(() => _isPostingComment = true);
    try {
      await _forumService.addComment(widget.post.id, commentText);
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            lang == 'si'
                ? 'අදහස් පළ කරන ලදී!'
                : lang == 'ta'
                    ? 'கருத்து இடப்பட்டது!'
                    : 'Comment posted!',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ));
        await _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            lang == 'si'
                ? 'අදහස් පළ කිරීම අසාර්ථකයි'
                : lang == 'ta'
                    ? 'கருத்து இட முடியவில்லை'
                    : 'Failed to post comment',
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark; // ✅
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _topBarButton(
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      lang == 'si'
                          ? 'පළකිරීමේ විස්තර'
                          : lang == 'ta'
                              ? 'இடுகை விவரங்கள்'
                              : 'Post Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Refresh
                  GestureDetector(
                    onTap: _loadComments,
                    child: _topBarButton(
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Share
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                        lang == 'si'
                            ? 'බෙදාගැනීම් විශේෂාංගය ඉක්මනින් පැමිණේ!'
                            : lang == 'ta'
                                ? 'பகிர்வு விரைவில் வரும்!'
                                : 'Share feature coming soon!',
                      )),
                    ),
                    child: _topBarButton(
                      child: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notifications
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

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // ✅ darkBackground = Color(0xFF121212)
                  color: isDark ? AppTheme.darkBackground : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Post Header ───────────────────────────
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.primaryGreen
                                            .withOpacity(0.3),
                                        width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        AppTheme.primaryGreen.withOpacity(0.15),
                                    child: Text(
                                      widget.post.senderName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.post.senderName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          // ✅ darkTextPrimary
                                          color: isDark
                                              ? AppTheme.darkTextPrimary
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time_rounded,
                                              size: 10,
                                              // ✅ darkTextSecondary
                                              color: isDark
                                                  ? AppTheme.darkTextSecondary
                                                  : AppTheme.textLight
                                                      .withOpacity(0.6)),
                                          const SizedBox(width: 3),
                                          Text(
                                            Helpers.getTimeAgo(
                                                widget.post.createdAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? AppTheme.darkTextSecondary
                                                  : AppTheme.textLight
                                                      .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.post.senderId ==
                                    authProvider.user?.uid)
                                  _buildPopupMenu(
                                    context: context,
                                    lang: lang,
                                    isDark: isDark,
                                    items: [
                                      _PopupItem(
                                        value: 'delete',
                                        icon: Icons.delete_rounded,
                                        color: Colors.red,
                                        label: lang == 'si'
                                            ? 'මකන්න'
                                            : lang == 'ta'
                                                ? 'நீக்கு'
                                                : 'Delete',
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _showDeleteDialog(context,
                                            forumProvider, lang, isDark);
                                      }
                                    },
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ── Post Content ──────────────────────────
                            Text(
                              widget.post.text,
                              style: TextStyle(
                                fontSize: 13, height: 1.6,
                                // ✅ darkTextPrimary
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textDark,
                              ),
                            ),

                            // ── Post Image ────────────────────────────
                            if (widget.post.imageUrl != null &&
                                widget.post.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 220,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.network(
                                      widget.post.imageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          // ✅ darkCard
                                          color: isDark
                                              ? AppTheme.darkCard
                                              : Colors.grey.shade50,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                              color: AppTheme.primaryGreen,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: isDark
                                              ? AppTheme.darkCard
                                              : Colors.grey.shade100,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_rounded,
                                                  size: 36,
                                                  color: isDark
                                                      ? AppTheme
                                                          .darkTextSecondary
                                                      : Colors.grey.shade400),
                                              const SizedBox(height: 6),
                                              Text(
                                                lang == 'si'
                                                    ? 'රූපය ලබාගත නොහැකිය'
                                                    : lang == 'ta'
                                                        ? 'படம் ஏற்ற முடியவில்லை'
                                                        : 'Failed to load image',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? AppTheme
                                                          .darkTextSecondary
                                                      : Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // ── Like & Comment Stats ──────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                // ✅ darkSurface = Color(0xFF1E1E1E)
                                color: isDark
                                    ? AppTheme.darkSurface
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _isLiked = !_isLiked);
                                      forumProvider.likeMessage(widget.post.id);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isLiked
                                              ? Icons.thumb_up_rounded
                                              : Icons.thumb_up_alt_outlined,
                                          color: _isLiked
                                              ? AppTheme.primaryGreen
                                              : (isDark
                                                  ? AppTheme.darkTextSecondary
                                                  : AppTheme.textLight),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${widget.post.likes + (_isLiked ? 1 : 0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _isLiked
                                                ? AppTheme.primaryGreen
                                                : (isDark
                                                    ? AppTheme.darkTextSecondary
                                                    : AppTheme.textLight),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.textLight,
                                      size: 16),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_comments.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    lang == 'si'
                                        ? '${widget.post.likes + (_isLiked ? 1 : 0)} දෙනෙකු කැමතිය'
                                        : lang == 'ta'
                                            ? '${widget.post.likes + (_isLiked ? 1 : 0)} பேர் விரும்புகிறார்கள்'
                                            : '${widget.post.likes + (_isLiked ? 1 : 0)} likes',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.textLight.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Comments Section ──────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSectionLabel(
                                    lang == 'si'
                                        ? 'අදහස්'
                                        : lang == 'ta'
                                            ? 'கருத்துகள்'
                                            : 'COMMENTS',
                                    isDark,
                                  ),
                                ),
                                if (_isLoadingComments)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryGreen),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_comments.isEmpty && !_isLoadingComments)
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 28),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          // ✅ darkCard
                                          color: isDark
                                              ? AppTheme.darkCard
                                              : Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 24,
                                            color: isDark
                                                ? AppTheme.darkTextSecondary
                                                : Colors.grey.shade400),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        lang == 'si'
                                            ? 'තවම අදහස් නැත'
                                            : lang == 'ta'
                                                ? 'இன்னும் கருத்துகள் இல்லை'
                                                : 'No comments yet',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppTheme.darkTextPrimary
                                              : Colors.grey.shade600,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        lang == 'si'
                                            ? 'පළමු අදහස ලියන්න!'
                                            : lang == 'ta'
                                                ? 'முதல் கருத்தை இடுங்கள்!'
                                                : 'Be the first to comment!',
                                        style: TextStyle(
                                            color: isDark
                                                ? AppTheme.darkTextSecondary
                                                : Colors.grey.shade400,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._comments.map((comment) {
                                final authorName = comment['author']
                                        ?['displayName'] ??
                                    comment['author']?['name'] ??
                                    'Unknown';
                                final authorId =
                                    comment['author']?['_id'] ?? '';
                                final content = comment['content'] ?? '';
                                final createdAt =
                                    DateTime.parse(comment['createdAt']);
                                final commentId = comment['_id'] ?? '';

                                return _buildComment(
                                  authorName,
                                  content,
                                  createdAt,
                                  commentId,
                                  authorId,
                                  authProvider.user?.uid ?? '',
                                  lang,
                                  isDark,
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),

                    // ── Comment Input Bar ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        // ✅ darkSurface
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
                              authProvider.user?.name[0].toUpperCase() ?? 'U',
                              style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: TextStyle(
                                fontSize: 12,
                                // ✅ darkTextPrimary
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textDark,
                              ),
                              enabled: !_isPostingComment,
                              onSubmitted: (_) => _postComment(),
                              decoration: InputDecoration(
                                hintText: lang == 'si'
                                    ? 'අදහසක් ලියන්න...'
                                    : lang == 'ta'
                                        ? 'கருத்து எழுதுங்கள்...'
                                        : 'Write a comment...',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  // ✅ darkTextSecondary
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : Colors.grey.shade400,
                                ),
                                filled: true,
                                // ✅ darkCard
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
                            onTap: _isPostingComment ? null : _postComment,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _isPostingComment
                                    ? (isDark
                                        ? AppTheme.darkCard
                                        : Colors.grey.shade300)
                                    : AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isPostingComment
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
                              child: _isPostingComment
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

  // ── Section Label ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w800,
            // ✅ darkTextSecondary
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Popup Menu Builder ─────────────────────────────────────────────
  Widget _buildPopupMenu({
    required BuildContext context,
    required String lang,
    required bool isDark,
    required List<_PopupItem> items,
    required void Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 18,
          // ✅ darkTextSecondary
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight),
      // ✅ darkSurface for popup background
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      itemBuilder: (context) => items
          .map((item) => PopupMenuItem<String>(
                value: item.value,
                child: Row(
                  children: [
                    Icon(item.icon, size: 16, color: item.color),
                    const SizedBox(width: 8),
                    Text(item.label,
                        style: TextStyle(color: item.color, fontSize: 13)),
                  ],
                ),
              ))
          .toList(),
      onSelected: onSelected,
    );
  }

  // ── Comment Card ───────────────────────────────────────────────────
  Widget _buildComment(
    String name,
    String text,
    DateTime time,
    String commentId,
    String authorId,
    String currentUserId,
    String lang,
    bool isDark,
  ) {
    final isOwnComment = authorId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // ✅ darkCard for comment cards
        color: isDark ? AppTheme.darkCard : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            // ✅ darkTextPrimary
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textDark)),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 9,
                            // ✅ darkTextSecondary
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textLight.withOpacity(0.5)),
                        const SizedBox(width: 3),
                        Text(
                          Helpers.getTimeAgo(time),
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textLight.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwnComment)
                _buildPopupMenu(
                  context: context,
                  lang: lang,
                  isDark: isDark,
                  items: [
                    _PopupItem(
                      value: 'delete',
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      label: lang == 'si'
                          ? 'මකන්න'
                          : lang == 'ta'
                              ? 'நீக்கு'
                              : 'Delete',
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'delete') {
                      try {
                        await _forumService.deleteComment(commentId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              lang == 'si'
                                  ? 'අදහස මකා දමන ලදී'
                                  : lang == 'ta'
                                      ? 'கருத்து நீக்கப்பட்டது'
                                      : 'Comment deleted',
                            ),
                          ));
                          await _loadComments();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              lang == 'si'
                                  ? 'අදහස මැකීම අසාර්ථකයි'
                                  : lang == 'ta'
                                      ? 'கருத்தை நீக்க முடியவில்லை'
                                      : 'Failed to delete comment',
                            ),
                          ));
                        }
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12, height: 1.4,
              // ✅ darkTextPrimary
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete Post Dialog ─────────────────────────────────────────────
  void _showDeleteDialog(BuildContext context, ForumProvider forumProvider,
      String lang, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        // ✅ darkSurface for dialog background
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                // ✅ dark red tint
                color: isDark
                    ? Colors.red.shade900.withOpacity(0.3)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              lang == 'si'
                  ? 'පළකිරීම මකන්න'
                  : lang == 'ta'
                      ? 'இடுகையை நீக்கு'
                      : 'Delete Post',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold,
                // ✅ darkTextPrimary
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          lang == 'si'
              ? 'ඔබට සැබවින්ම මෙම පළකිරීම මකා දැමීමට අවශ්‍යද?'
              : lang == 'ta'
                  ? 'இந்த இடுகையை நிச்சயமாக நீக்க விரும்புகிறீர்களா?'
                  : 'Are you sure you want to delete this post?',
          style: TextStyle(
            fontSize: 12,
            // ✅ darkTextSecondary
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang == 'si'
                  ? 'අවලංගු කරන්න'
                  : lang == 'ta'
                      ? 'ரத்து செய்'
                      : 'Cancel',
              style: TextStyle(
                // ✅ darkTextSecondary for cancel
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await forumProvider.deleteMessage(widget.post.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    lang == 'si'
                        ? 'පළකිරීම මකා දමන ලදී'
                        : lang == 'ta'
                            ? 'இடுகை நீக்கப்பட்டது'
                            : 'Post deleted',
                  ),
                  backgroundColor: AppTheme.primaryGreen,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              lang == 'si'
                  ? 'මකන්න'
                  : lang == 'ta'
                      ? 'நீக்கு'
                      : 'Delete',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper class for popup items ───────────────────────────────────────
class _PopupItem {
  final String value;
  final IconData icon;
  final Color color;
  final String label;

  const _PopupItem({
    required this.value,
    required this.icon,
    required this.color,
    required this.label,
  });
}
