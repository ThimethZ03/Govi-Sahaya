import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../services/backend_support_service.dart';
import '../../providers/language_provider.dart';
import '../menu/language_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _darkMode = false;
  bool _locationAccess = true;
  bool _dataSync = true;
  bool _isSyncing = false;

  final BackendSupportService _supportService = BackendSupportService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _locationAccess = prefs.getBool('location_access') ?? true;
      _dataSync = prefs.getBool('data_sync') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _syncSettings() async {
    setState(() => _isSyncing = true);
    final success = await _supportService.updateSettings(
      pushNotifications: _pushNotifications,
      emailNotifications: _emailNotifications,
      locationAccess: _locationAccess,
      dataSync: _dataSync,
    );
    setState(() => _isSyncing = false);

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved locally. Will sync when online.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Watch language provider — subtitle updates live
    final langProvider = context.watch<LanguageProvider>();
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
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_isSyncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── White Sheet ───────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  children: [
                    // ── NOTIFICATIONS ─────────────────────────────────
                    _buildSectionLabel('NOTIFICATIONS'),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.notifications_active_outlined,
                      iconColor: const Color(0xFFE65100),
                      bgColor: const Color(0xFFFFF3E0),
                      title: 'Push Notifications',
                      subtitle: 'Receive alerts and reminders',
                      value: _pushNotifications,
                      onChanged: (val) {
                        setState(() => _pushNotifications = val);
                        _saveSetting('push_notifications', val);
                        _syncSettings();
                      },
                    ),
                    _buildToggleTile(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF1565C0),
                      bgColor: const Color(0xFFE3F2FD),
                      title: 'Email Notifications',
                      subtitle: 'Get updates via email',
                      value: _emailNotifications,
                      onChanged: (val) {
                        setState(() => _emailNotifications = val);
                        _saveSetting('email_notifications', val);
                        _syncSettings();
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── APPEARANCE ────────────────────────────────────
                    _buildSectionLabel('APPEARANCE'),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFF37474F),
                      bgColor: const Color(0xFFECEFF1),
                      title: 'Dark Mode',
                      subtitle: 'Switch to dark theme',
                      value: _darkMode,
                      onChanged: (val) {
                        setState(() => _darkMode = val);
                        _saveSetting('dark_mode', val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dark mode coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── LANGUAGE ──────────────────────────────────────
                    _buildSectionLabel('LANGUAGE'),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      context,
                      icon: Icons.language,
                      iconColor: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                      title: 'Language',
                      subtitle: langDisplay, // ✅ live current language
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── PRIVACY & DATA ────────────────────────────────
                    _buildSectionLabel('PRIVACY & DATA'),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFE8F5E9),
                      title: 'Location Access',
                      subtitle: 'Used for weather & farm tips',
                      value: _locationAccess,
                      onChanged: (val) {
                        setState(() => _locationAccess = val);
                        _saveSetting('location_access', val);
                        _syncSettings();
                      },
                    ),
                    _buildToggleTile(
                      icon: Icons.sync_outlined,
                      iconColor: const Color(0xFF6A1B9A),
                      bgColor: const Color(0xFFF3E5F5),
                      title: 'Background Sync',
                      subtitle: 'Sync data in the background',
                      value: _dataSync,
                      onChanged: (val) {
                        setState(() => _dataSync = val);
                        _saveSetting('data_sync', val);
                        _syncSettings();
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── ACCOUNT ───────────────────────────────────────
                    _buildSectionLabel('ACCOUNT'),
                    const SizedBox(height: 10),
                    _buildActionTile(
                      context,
                      icon: Icons.lock_reset_outlined,
                      iconColor: const Color(0xFF1565C0),
                      bgColor: const Color(0xFFE3F2FD),
                      title: 'Change Password',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Change password coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                    _buildActionTile(
                      context,
                      icon: Icons.delete_outline,
                      iconColor: const Color(0xFFC62828),
                      bgColor: const Color(0xFFFFEBEE),
                      title: 'Delete Account',
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

  // ── Delete Account Dialog ──────────────────────────────────────────
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppTheme.textLight.withOpacity(0.7),
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  // ── Toggle Tile ────────────────────────────────────────────────────
  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(11),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
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

  // ── Action Tile ────────────────────────────────────────────────────
  // ✅ subtitle added as optional parameter
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(11),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textDark,
                        ),
                      ),
                      // ✅ show subtitle if provided (e.g. current language)
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
