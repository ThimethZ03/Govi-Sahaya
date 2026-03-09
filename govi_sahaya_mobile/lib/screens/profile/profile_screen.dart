import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/network/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const _ProfileView();
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  AnimationController? _animCtrl;
  Animation<double>? _fadeAnim;

  File? _pickedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String lang) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(lang: lang),
    );

    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
      );

      if (picked == null || !mounted) return;

      final imageFile = File(picked.path);

      setState(() {
        _pickedImage = imageFile;
        _isUploading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final url = await authProvider.uploadProfilePicture(imageFile);

      if (!mounted) return;

      if (url != null) {
        setState(() {
          _pickedImage = null;
          _isUploading = false;
        });
        _showSuccess('Profile picture updated ✅');
      } else {
        setState(() {
          _pickedImage = null;
          _isUploading = false;
        });
        _showError(authProvider.errorMessage ?? 'Failed to upload picture');
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _pickedImage = null;
          _isUploading = false;
        });
        _showError('Could not pick image: $e');
      }
    }
  }

  Future<void> _goToEditProfile() async {
    final result = await Navigator.pushNamed(context, AppRoutes.editProfile);
    if (result == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;
      if (uid != null) {
        await authProvider.refreshProfile(uid);
      }
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final lang = context.watch<LanguageProvider>().languageCode;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _ProfileTranslations(lang);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF6F7FB),
        body: _fadeAnim != null
            ? FadeTransition(
                opacity: _fadeAnim!,
                child: _buildBody(context, user, cs, isDark, lang, t),
              )
            : _buildBody(context, user, cs, isDark, lang, t),
      ),
    );
  }

  Widget _buildBody(BuildContext context, dynamic user, ColorScheme cs,
      bool isDark, String lang, _ProfileTranslations t) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _ProfileSliverAppBar(
          user: user,
          pickedImage: _pickedImage,
          isUploading: _isUploading,
          onPickImage: () => _pickImage(lang),
          onEdit: _goToEditProfile,
          lang: lang,
          t: t,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionLabel(t.basicInfo),
              const SizedBox(height: 12),
              _InfoCard(items: [
                _InfoItem(
                    Icons.person_outline_rounded, t.name, user.name ?? ''),
                _InfoItem(
                    Icons.cake_outlined, t.birthday, user.birthday ?? t.notSet),
                _InfoItem(Icons.wc_rounded, t.gender, user.gender ?? t.notSet),
                _InfoItem(Icons.location_on_outlined, t.address,
                    user.address ?? t.notSet),
              ], notSetLabel: t.notSet),
              const SizedBox(height: 28),
              _SectionLabel(t.contact),
              const SizedBox(height: 12),
              _InfoCard(items: [
                _InfoItem(
                    Icons.mail_outline_rounded, t.email, user.email ?? ''),
                _InfoItem(
                  Icons.phone_outlined,
                  t.phone,
                  (user.phone != null && user.phone.isNotEmpty)
                      ? user.phone
                      : t.notSet,
                ),
              ], notSetLabel: t.notSet),
              const SizedBox(height: 28),
              _SectionLabel(t.farmDetails),
              const SizedBox(height: 12),
              _InfoCard(items: [
                _InfoItem(Icons.agriculture_outlined, t.farmLocation,
                    user.farmLocation ?? t.notSet),
                _InfoItem(Icons.notes_rounded, t.extraNotes,
                    user.extraNotes ?? t.notSet),
              ], notSetLabel: t.notSet),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Image Source Bottom Sheet ──────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final String lang;
  const _ImageSourceSheet({required this.lang});

  @override
  Widget build(BuildContext context) {
    final t = _ProfileTranslations(lang);
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(t.changePhoto,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.camera_alt_rounded, color: cs.primary, size: 20),
              ),
              title: Text(t.takePhoto,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library_rounded,
                    color: cs.primary, size: 20),
              ),
              title: Text(t.chooseGallery,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Sliver AppBar ──────────────────────────────────────────────────────
class _ProfileSliverAppBar extends StatelessWidget {
  const _ProfileSliverAppBar({
    required this.user,
    required this.pickedImage,
    required this.isUploading,
    required this.onPickImage,
    required this.onEdit,
    required this.lang,
    required this.t,
  });

  final dynamic user;
  final File? pickedImage;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onEdit;
  final String lang;
  final _ProfileTranslations t;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: cs.primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
          ),
          tooltip: t.editProfile,
          onPressed: onEdit,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: _HeaderBackground(
          user: user,
          pickedImage: pickedImage,
          isUploading: isUploading,
          onPickImage: onPickImage,
          isDark: isDark,
          t: t,
        ),
      ),
    );
  }
}

// ── Header Background ──────────────────────────────────────────────────
class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({
    required this.user,
    required this.pickedImage,
    required this.isUploading,
    required this.onPickImage,
    required this.isDark,
    required this.t,
  });

  final dynamic user;
  final File? pickedImage;
  final bool isUploading;
  final VoidCallback onPickImage;
  final bool isDark;
  final _ProfileTranslations t;

  // ✅ Cloudinary URLs start with https:// — no need for getImageUrl() wrapper
  String? _getProfilePicture() {
    try {
      final pic = user.profilePicture;
      if (pic is String && pic.isNotEmpty) return pic;
    } catch (_) {}
    try {
      final pic = user.profileImageUrl;
      if (pic is String && pic.isNotEmpty) return pic;
    } catch (_) {}
    try {
      final pic = user.profileImage;
      if (pic is String && pic.isNotEmpty) return pic;
    } catch (_) {}
    return null;
  }

  // ✅ Returns usable image URL — Cloudinary URLs used directly, local paths wrapped
  String _resolveImageUrl(String url) {
    if (url.startsWith('http')) return url; // ✅ Cloudinary full URL
    return ApiEndpoints.getImageUrl(url); // fallback for old local paths
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profilePicPath = _getProfilePicture();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 44),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              // ✅ Local preview while uploading, else Cloudinary URL
                              backgroundImage: pickedImage != null
                                  ? FileImage(pickedImage!) as ImageProvider
                                  : profilePicPath != null
                                      ? NetworkImage(
                                          _resolveImageUrl(profilePicPath))
                                      : null,
                              child: (pickedImage == null &&
                                      profilePicPath == null)
                                  ? Icon(Icons.person_rounded,
                                      size: 50, color: cs.primary)
                                  : null,
                            ),
                            if (isUploading)
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isUploading)
                        GestureDetector(
                          onTap: onPickImage,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt_rounded,
                                size: 15, color: cs.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 12,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.agriculture_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          t.farmerBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF6F7FB),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: cs.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }
}

// ── Info Item Model ────────────────────────────────────────────────────
class _InfoItem {
  const _InfoItem(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

// ── Info Card ──────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items, required this.notSetLabel});
  final List<_InfoItem> items;
  final String notSetLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isNotSet = item.value == notSetLabel;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(item.icon, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withOpacity(0.45),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isNotSet
                                  ? cs.onSurface.withOpacity(0.28)
                                  : cs.onSurface,
                              fontStyle: isNotSet
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isNotSet)
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: cs.primary.withOpacity(0.5)),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: cs.onSurface.withOpacity(0.07),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Translations ───────────────────────────────────────────────────────
class _ProfileTranslations {
  final String lang;
  const _ProfileTranslations(this.lang);

  String get basicInfo => lang == 'si'
      ? 'මූලික තොරතුරු'
      : lang == 'ta'
          ? 'அடிப்படை தகவல்'
          : 'Basic Info';
  String get contact => lang == 'si'
      ? 'සම්බන්ධතා'
      : lang == 'ta'
          ? 'தொடர்பு'
          : 'Contact';
  String get farmDetails => lang == 'si'
      ? 'ගොවිතැන් විස්තර'
      : lang == 'ta'
          ? 'பண்ணை விவரங்கள்'
          : 'Farm Details';
  String get name => lang == 'si'
      ? 'නම'
      : lang == 'ta'
          ? 'பெயர்'
          : 'Name';
  String get birthday => lang == 'si'
      ? 'උපන් දිනය'
      : lang == 'ta'
          ? 'பிறந்த நாள்'
          : 'Birthday';
  String get gender => lang == 'si'
      ? 'ස්ත්‍රී පුරුෂ භාවය'
      : lang == 'ta'
          ? 'பாலினம்'
          : 'Gender';
  String get address => lang == 'si'
      ? 'ලිපිනය'
      : lang == 'ta'
          ? 'முகவரி'
          : 'Address';
  String get email => lang == 'si'
      ? 'විද්‍යුත් තැපෑල'
      : lang == 'ta'
          ? 'மின்னஞ்சல்'
          : 'Email';
  String get phone => lang == 'si'
      ? 'දුරකථන'
      : lang == 'ta'
          ? 'தொலைபேசி'
          : 'Phone';
  String get farmLocation => lang == 'si'
      ? 'ගොවිපළ ස්ථානය'
      : lang == 'ta'
          ? 'பண்ணை இடம்'
          : 'Farm Location';
  String get extraNotes => lang == 'si'
      ? 'අමතර සටහන්'
      : lang == 'ta'
          ? 'கூடுதல் குறிப்புகள்'
          : 'Extra Notes';
  String get notSet => lang == 'si'
      ? 'සකසා නැත'
      : lang == 'ta'
          ? 'அமைக்கப்படவில்லை'
          : 'Not set';
  String get editProfile => lang == 'si'
      ? 'පැතිකඩ සංස්කරණය'
      : lang == 'ta'
          ? 'சுயவிவரம் திருத்து'
          : 'Edit Profile';
  String get changePhoto => lang == 'si'
      ? 'පැතිකඩ ඡායාරූපය වෙනස් කරන්න'
      : lang == 'ta'
          ? 'சுயவிவர புகைப்படம் மாற்றவும்'
          : 'Change Profile Photo';
  String get takePhoto => lang == 'si'
      ? 'ඡායාරූප ගන්න'
      : lang == 'ta'
          ? 'புகைப்படம் எடுக்கவும்'
          : 'Take Photo';
  String get chooseGallery => lang == 'si'
      ? 'ගැලරියෙන් තෝරන්න'
      : lang == 'ta'
          ? 'கேலரியில் இருந்து தேர்ந்தெடுக்கவும்'
          : 'Choose from Gallery';
  String get farmerBadge => lang == 'si'
      ? 'ගොවියා'
      : lang == 'ta'
          ? 'விவசாயி'
          : 'Farmer';
}
