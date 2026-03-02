import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/language_provider.dart';
import '../menu/language_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final langProvider = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final langDisplay = langProvider.languageCode == 'si'
        ? 'සිංහල'
        : langProvider.languageCode == 'ta'
            ? 'தமிழ்'
            : 'English';

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  // ✅ Syncing indicator
                  if (settings.isSyncing)
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),

            // ── White Sheet ──────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F0F0F)
                      : const Color(0xFFF4F6FA),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: settings.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                        children: [
                          // ── NOTIFICATIONS ──────────────────────────
                          _buildSectionLabel('NOTIFICATIONS', isDark),
                          const SizedBox(height: 8),

                          _buildToggleTile(
                            icon: Icons.notifications_active_outlined,
                            iconColor: const Color(0xFFE65100),
                            bgColor: const Color(0xFFFFF3E0),
                            title: 'Push Notifications',
                            // ✅ Live status shown in subtitle
                            subtitle: settings.pushNotifications
                                ? 'Alerts are enabled'
                                : 'All alerts are silenced',
                            value: settings.pushNotifications,
                            isDark: isDark,
                            onChanged: (val) => context
                                .read<SettingsProvider>()
                                .setPushNotifications(val),
                          ),

                          _buildToggleTile(
                            icon: Icons.email_outlined,
                            iconColor: const Color(0xFF1565C0),
                            bgColor: const Color(0xFFE3F2FD),
                            title: 'Email Notifications',
                            subtitle: 'Get updates via email',
                            value: settings.emailNotifications,
                            isDark: isDark,
                            onChanged: (val) => context
                                .read<SettingsProvider>()
                                .setEmailNotifications(val),
                          ),

                          const SizedBox(height: 20),

                          // ── APPEARANCE ─────────────────────────────
                          _buildSectionLabel('APPEARANCE', isDark),
                          const SizedBox(height: 8),

                          _buildToggleTile(
                            icon: Icons.dark_mode_outlined,
                            iconColor: const Color(0xFF37474F),
                            bgColor: const Color(0xFFECEFF1),
                            title: 'Dark Mode',
                            subtitle: 'Switch to dark theme',
                            value: settings.darkMode,
                            isDark: isDark,
                            onChanged: (val) {
                              context.read<SettingsProvider>().setDarkMode(val);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Dark mode coming soon!'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── LANGUAGE ───────────────────────────────
                          _buildSectionLabel('LANGUAGE', isDark),
                          const SizedBox(height: 8),

                          _buildActionTile(
                            icon: Icons.language_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                            title: 'App Language',
                            subtitle: langDisplay,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LanguageScreen()),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── PRIVACY & DATA ─────────────────────────
                          _buildSectionLabel('PRIVACY & DATA', isDark),
                          const SizedBox(height: 8),

                          _buildToggleTile(
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                            title: 'Location Access',
                            subtitle: 'Used for weather & farm tips',
                            value: settings.locationAccess,
                            isDark: isDark,
                            onChanged: (val) => context
                                .read<SettingsProvider>()
                                .setLocationAccess(val),
                          ),

                          _buildToggleTile(
                            icon: Icons.sync_outlined,
                            iconColor: const Color(0xFF6A1B9A),
                            bgColor: const Color(0xFFF3E5F5),
                            title: 'Background Sync',
                            subtitle: 'Sync data in the background',
                            value: settings.dataSync,
                            isDark: isDark,
                            onChanged: (val) => context
                                .read<SettingsProvider>()
                                .setDataSync(val),
                          ),

                          const SizedBox(height: 20),

                          // ── ACCOUNT ────────────────────────────────
                          _buildSectionLabel('ACCOUNT', isDark),
                          const SizedBox(height: 8),

                          _buildActionTile(
                            icon: Icons.lock_reset_outlined,
                            iconColor: const Color(0xFF1565C0),
                            bgColor: const Color(0xFFE3F2FD),
                            title: 'Change Password',
                            isDark: isDark,
                            onTap: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Change password coming soon!'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),

                          _buildActionTile(
                            icon: Icons.delete_outline_rounded,
                            iconColor: const Color(0xFFC62828),
                            bgColor: const Color(0xFFFFEBEE),
                            title: 'Delete Account',
                            isDark: isDark,
                            onTap: () => _showDeleteAccountDialog(context),
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

  // ── Section Label ────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white38 : AppTheme.textLight.withOpacity(0.7),
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  // ── Toggle Tile ──────────────────────────────────────────────────────
  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  // ── Action Tile ──────────────────────────────────────────────────────
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    String? subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textLight),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete Account Dialog ────────────────────────────────────────────
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will permanently delete your account and all data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
