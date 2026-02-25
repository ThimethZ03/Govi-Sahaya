import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';

// ─────────────────────────────────────────────
//  ProfileScreen — Entry point
// ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const _ProfileView();
  }
}

// ─────────────────────────────────────────────
//  _ProfileView — Stateful shell
// ─────────────────────────────────────────────
class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Image picker ──────────────────────────
  Future<void> _pickImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
        // TODO: upload to your storage and update AuthProvider
      }
    } on Exception catch (e) {
      if (mounted) _showError('Could not pick image: $e');
    }
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Profile Photo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
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
  }

  // ── Logout dialog ─────────────────────────
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context
            .read<AuthProvider>()
            .signOut(); // TODO: change to your actual logout method name
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (_) => false);
        }
      } on Exception catch (e) {
        if (mounted) _showError('Logout failed: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Collapsible header ──────────
              _ProfileSliverAppBar(
                user: user,
                pickedImage: _pickedImage,
                onPickImage: _pickImage,
                onEdit: () =>
                    Navigator.pushNamed(context, AppRoutes.editProfile),
              ),

              // ── Body content ────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic info
                      _SectionHeader(label: 'Basic Info'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        items: [
                          _InfoItem(
                              icon: Icons.person_outline_rounded,
                              label: 'Name',
                              value: user.name),
                          _InfoItem(
                              icon: Icons.cake_outlined,
                              label: 'Birthday',
                              value: user.birthday ?? 'Not set'),
                          _InfoItem(
                              icon: Icons.wc_rounded,
                              label: 'Gender',
                              value: user.gender ?? 'Not set'),
                          _InfoItem(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: user.address ?? 'Not set'),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Contact info
                      _SectionHeader(label: 'Contact'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        items: [
                          _InfoItem(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email',
                              value: user.email),
                          _InfoItem(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: user.phone),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Farm details
                      _SectionHeader(label: 'Farm Details'),
                      const SizedBox(height: 12),
                      _InfoCard(
                        items: [
                          _InfoItem(
                              icon: Icons.agriculture_outlined,
                              label: 'Farm Location',
                              value: user.farmLocation ?? 'Not set'),
                          _InfoItem(
                              icon: Icons.notes_rounded,
                              label: 'Extra Notes',
                              value: user.extraNotes ?? 'Not set'),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Settings tiles
                      _SectionHeader(label: 'Settings'),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        tiles: [
                          _SettingsTile(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () {},
                            trailing: Switch.adaptive(
                              value: true,
                              onChanged: (_) {},
                              activeColor: colorScheme.primary,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.dark_mode_outlined,
                            label: 'Dark Mode',
                            onTap: () {},
                            trailing: Switch.adaptive(
                              value: isDark,
                              onChanged: (_) {},
                              activeColor: colorScheme.primary,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                            onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes
                                    .editProfile), // TODO: change to correct route
                          ),
                          _SettingsTile(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & Support',
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Logout
                      _LogoutButton(onTap: _confirmLogout),

                      const SizedBox(height: 16),

                      // App version
                      Center(
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sliver AppBar with profile header
// ─────────────────────────────────────────────
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
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
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
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: _HeaderBackground(
          user: user,
          pickedImage: pickedImage,
          onPickImage: onPickImage,
        ),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({
    required this.user,
    required this.pickedImage,
    required this.onPickImage,
  });

  final dynamic user;
  final File? pickedImage;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),

            // Avatar with pick button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
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
                            size: 52, color: colorScheme.primary)
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 18, color: colorScheme.primary),
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
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Info card
// ─────────────────────────────────────────────
class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(item.icon, size: 18, color: colorScheme.primary),
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
                              color: colorScheme.onSurface.withOpacity(0.45),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: item.value == 'Not set'
                                  ? colorScheme.onSurface.withOpacity(0.3)
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 66,
                  endIndent: 16,
                  color: colorScheme.onSurface.withOpacity(0.08),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Settings card
// ─────────────────────────────────────────────
class _SettingsTile {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.tiles});
  final List<_SettingsTile> tiles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          final tile = tiles[i];
          final isLast = i == tiles.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: tile.onTap,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tile.icon,
                            size: 18, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          tile.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      tile.trailing ??
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 66,
                  endIndent: 16,
                  color: colorScheme.onSurface.withOpacity(0.08),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Logout button
// ─────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
