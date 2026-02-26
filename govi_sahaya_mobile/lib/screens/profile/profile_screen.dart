import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../config/routes.dart'; // AppRoutes.login, AppRoutes.editProfile

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return const _ProfileView();
  }
}

// ── Stateful shell ──────────────────────────────────────────────────────────

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  File? _pickedImage;

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
              child: const SizedBox(width: 40, height: 4),
            ),
            const SizedBox(height: 16),
            const Text('Change Profile Photo',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, imageQuality: 85, maxWidth: 512);
      if (picked != null && mounted)
        setState(() => _pickedImage = File(picked.path));
      // TODO: upload to storage and update AuthProvider
    } on Exception catch (e) {
      if (mounted) _showError('Could not pick image: $e');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AuthProvider>().signOut();
        if (mounted)
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (_) => false);
      } on Exception catch (e) {
        if (mounted) _showError('Logout failed: $e');
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ProfileSliverAppBar(
                user: user,
                pickedImage: _pickedImage,
                onPickImage: _pickImage,
                onEdit: () =>
                    Navigator.pushNamed(context, AppRoutes.editProfile),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionLabel('Basic Info'),
                    const SizedBox(height: 12),
                    _InfoCard(items: [
                      _InfoItem(
                          Icons.person_outline_rounded, 'Name', user.name),
                      _InfoItem(Icons.cake_outlined, 'Birthday',
                          user.birthday ?? 'Not set'),
                      _InfoItem(
                          Icons.wc_rounded, 'Gender', user.gender ?? 'Not set'),
                      _InfoItem(Icons.location_on_outlined, 'Address',
                          user.address ?? 'Not set'),
                    ]),
                    const SizedBox(height: 28),
                    _SectionLabel('Contact'),
                    const SizedBox(height: 12),
                    _InfoCard(items: [
                      _InfoItem(
                          Icons.mail_outline_rounded, 'Email', user.email),
                      _InfoItem(Icons.phone_outlined, 'Phone', user.phone),
                    ]),
                    const SizedBox(height: 28),
                    _SectionLabel('Farm Details'),
                    const SizedBox(height: 12),
                    _InfoCard(items: [
                      _InfoItem(Icons.agriculture_outlined, 'Farm Location',
                          user.farmLocation ?? 'Not set'),
                      _InfoItem(Icons.notes_rounded, 'Extra Notes',
                          user.extraNotes ?? 'Not set'),
                    ]),
                    const SizedBox(height: 28),
                    _LogoutButton(onTap: _confirmLogout),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.35)),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sliver AppBar ───────────────────────────────────────────────────────────

class _ProfileSliverAppBar extends StatelessWidget {
  const _ProfileSliverAppBar({
    required this.user,
    required this.pickedImage,
    required this.onPickImage,
    required this.onEdit,
  });

  final dynamic user;
  final File? pickedImage;
  final VoidCallback onPickImage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: primary,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          tooltip: 'Edit Profile',
          onPressed: onEdit,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: _HeaderBackground(
            user: user, pickedImage: pickedImage, onPickImage: onPickImage),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground(
      {required this.user,
      required this.pickedImage,
      required this.onPickImage});

  final dynamic user;
  final File? pickedImage;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage!) as ImageProvider
                        : (user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null),
                    child: (pickedImage == null && user.profileImageUrl == null)
                        ? Icon(Icons.person_rounded,
                            size: 52, color: cs.primary)
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: onPickImage,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6)
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 18, color: cs.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2),
            ),
            const SizedBox(height: 4),
            Text(user.email,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 14)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
      );
}

// ── Info card ───────────────────────────────────────────────────────────────

class _InfoItem {
  const _InfoItem(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CardShell(
      isDark: isDark,
      cs: cs,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _TileIcon(icon: item.icon, cs: cs),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withOpacity(0.45))),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: item.value == 'Not set'
                                  ? cs.onSurface.withOpacity(0.3)
                                  : cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) _Divider(cs: cs),
            ],
          );
        }),
      ),
    );
  }
}

// ── Shared primitives ───────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell(
      {required this.isDark, required this.cs, required this.child});
  final bool isDark;
  final ColorScheme cs;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceVariant : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
        ),
        child: child,
      );
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon, required this.cs});
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: cs.primary),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Divider(
      height: 1,
      indent: 66,
      endIndent: 16,
      color: cs.onSurface.withOpacity(0.08));
}

// ── Logout button ───────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Log Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      );
}
