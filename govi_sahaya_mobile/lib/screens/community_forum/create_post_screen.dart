// lib/screens/forum/create_post_screen.dart
// COMMIT 1: refactor: extract language helper to reduce repetition

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/forum_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart'; // ✅
import '../../config/routes.dart';
import '../../config/theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isPosting = false;

  // ── Language helper ────────────────────────────────────────────────
  String _t(String en, String si, String ta) {
    final lang = context.read<LanguageProvider>().languageCode;
    if (lang == 'si') return si;
    if (lang == 'ta') return ta;
    return en;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Please write something',
              'කරුණාකර යමක් ලියන්න',
              'ஏதாவது எழுதுங்கள்',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      await context.read<ForumProvider>().sendMessage(
        _textController.text.trim(),
        imageFile: _selectedImage,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Post created successfully!',
                'පළකිරීම සාර්ථකව සෑදිණ!',
                'இடுகை வெற்றிகரமாக உருவாக்கப்பட்டது!',
              ),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Error creating post: $e',
                'පළකිරීම සෑදීම අසාර්ථකයි: $e',
                'இடுகை உருவாக்க முடியவில்லை: $e',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      _t('Create Post', 'පළකිරීමක් සාදන්න', 'இடுகை உருவாக்கு'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Notifications
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _topBarButton(
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 15,
                                minHeight: 15,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Post button
                  GestureDetector(
                    onTap: _isPosting ? null : _createPost,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _isPosting
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryGreen,
                              ),
                            )
                          : Text(
                              _t('Post', 'පළ කරන්න', 'இடுகையிடு'),
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Text Input ────────────────────────────────
                      _buildSectionLabel(
                        _t(
                          'YOUR THOUGHTS',
                          'ඔබේ සිතුවිල්ල',
                          'உங்கள் எண்ணங்கள்',
                        ),
                        isDark,
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: _textController,
                        maxLines: 7,
                        style: TextStyle(
                          fontSize: 13,
                          // ✅ darkTextPrimary = Color(0xFFE0E0E0)
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: _t(
                            "What's on your mind?",
                            'ඔබේ සිතේ ඇති දේ ලියන්න...',
                            'உங்கள் மனதில் உள்ளதை எழுதுங்கள்...',
                          ),
                          hintStyle: TextStyle(
                            fontSize: 12,
                            // ✅ darkTextSecondary = Color(0xFF9E9E9E)
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : Colors.grey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryGreen,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                          filled: true,
                          // ✅ darkCard = Color(0xFF2C2C2C)
                          fillColor: isDark
                              ? AppTheme.darkCard
                              : Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Image Preview ─────────────────────────────
                      if (_selectedImage != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Add Media ─────────────────────────────────
                      _buildSectionLabel(
                        _t('ADD MEDIA', 'මාධ්‍යය එකතු කරන්න', 'ஊடகம் சேர்க்க'),
                        isDark,
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMediaButton(
                              icon: Icons.photo_library_rounded,
                              iconColor: const Color(0xFF6A1B9A),
                              // ✅ darkSurface in dark mode
                              bgColor: isDark
                                  ? AppTheme.darkSurface
                                  : const Color(0xFFF3E5F5),
                              bgColorDark: isDark,
                              label: _t('Gallery', 'ගැලරිය', 'கேலரி'),
                              onTap: _isPosting
                                  ? null
                                  : () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMediaButton(
                              icon: Icons.camera_alt_rounded,
                              iconColor: const Color(0xFF1565C0),
                              bgColor: isDark
                                  ? AppTheme.darkSurface
                                  : const Color(0xFFE3F2FD),
                              bgColorDark: isDark,
                              label: _t('Camera', 'කැමරාව', 'கேமரா'),
                              onTap: _isPosting
                                  ? null
                                  : () => _pickImage(ImageSource.camera),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Create Post Button ────────────────────────
                      GestureDetector(
                        onTap: _isPosting ? null : _createPost,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            // ✅ darkCard for disabled state
                            color: _isPosting
                                ? (isDark
                                      ? AppTheme.darkCard
                                      : Colors.grey.shade300)
                                : AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isPosting
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isPosting)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isPosting
                                    ? _t(
                                        'Posting...',
                                        'පළ කරමින්...',
                                        'இடுகையிடுகிறது...',
                                      )
                                    : _t(
                                        'Create Post',
                                        'පළකිරීම සාදන්න',
                                        'இடுகை உருவாக்கு',
                                      ),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  // ✅ darkTextSecondary when disabled
                                  color: _isPosting
                                      ? (isDark
                                            ? AppTheme.darkTextSecondary
                                            : Colors.grey.shade500)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Community Guidelines ──────────────────────
                      _buildSectionLabel(
                        _t(
                          'COMMUNITY GUIDELINES',
                          'ප්‍රජා මාර්ගෝපදේශ',
                          'சமூக வழிகாட்டுதல்கள்',
                        ),
                        isDark,
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // ✅ darkSurface for guidelines card
                          color: isDark
                              ? AppTheme.darkSurface
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(14),
                          border: isDark
                              ? Border.all(color: Colors.white12)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_rounded,
                                  size: 14,
                                  // ✅ lighter blue in dark mode
                                  color: isDark
                                      ? const Color(0xFF90CAF9)
                                      : const Color(0xFF1565C0),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _t(
                                    'Please read before posting',
                                    'සහභාගිවීමට පෙර කරුණාකර කියවන්න',
                                    'பங்கேற்பதற்கு முன் படிக்கவும்',
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF90CAF9)
                                        : const Color(0xFF0D47A1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildGuideline(
                              Icons.favorite_rounded,
                              const Color(0xFFE91E63),
                              _t(
                                'Be respectful and kind to others',
                                'අන් අය කෙරෙහි ගෞරවයෙන් සහ කරුණාවෙන් සිටින්න',
                                'மற்றவர்களை மதித்து அன்பாக நடந்துகொள்ளுங்கள்',
                              ),
                              isDark,
                            ),
                            _buildGuideline(
                              Icons.agriculture_rounded,
                              AppTheme.primaryGreen,
                              _t(
                                'Share helpful farming tips and experiences',
                                'ප්‍රයෝජනවත් ගොවිතැන් ඉඟි සහ අත්දැකීම් බෙදාගන්න',
                                'பயனுள்ள விவசாய குறிப்புகளை பகிருங்கள்',
                              ),
                              isDark,
                            ),
                            _buildGuideline(
                              Icons.block_rounded,
                              Colors.orange,
                              _t(
                                'No spam or promotional content',
                                'ස්පෑම් හෝ ප්‍රවර්ධන අන්තර්ගතය නොකරන්න',
                                'ஸ்பேம் அல்லது விளம்பர உள்ளடக்கம் வேண்டாம்',
                              ),
                              isDark,
                            ),
                            _buildGuideline(
                              Icons.grass_rounded,
                              const Color(0xFF1565C0),
                              _t(
                                'Keep discussions relevant to agriculture',
                                'කෘෂිකර්මය හා සම්බන්ධ සාකච්ඡා රඳවාගන්න',
                                'விவசாயம் தொடர்பான விவாதங்களை வைத்திருங்கள்',
                              ),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
            fontSize: 9,
            fontWeight: FontWeight.w800,
            // ✅ darkTextSecondary for section labels
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Media Button ───────────────────────────────────────────────────
  Widget _buildMediaButton({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required bool bgColorDark,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            // ✅ subtle border in dark mode
            border: bgColorDark ? Border.all(color: Colors.white12) : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Guideline Row ──────────────────────────────────────────────────
  Widget _buildGuideline(IconData icon, Color color, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                // ✅ darkTextSecondary for guideline text
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
