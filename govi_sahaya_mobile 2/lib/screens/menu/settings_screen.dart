import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/settings_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/backend_support_service.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final lang = langProvider.languageCode;

    final langDisplay = lang == 'si'
        ? 'සිංහල'
        : lang == 'ta'
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
                  Expanded(
                    child: Text(
                      lang == 'si'
                          ? 'සැකසුම්'
                          : lang == 'ta'
                              ? 'அமைப்புகள்'
                              : 'Settings',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
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
                          color: Colors.white, strokeWidth: 2),
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
                            color: AppTheme.primaryGreen))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                        children: [
                          // ── NOTIFICATIONS ──────────────────────────
                          _buildSectionLabel(
                            lang == 'si'
                                ? 'දැනුම්දීම්'
                                : lang == 'ta'
                                    ? 'அறிவிப்புகள்'
                                    : 'NOTIFICATIONS',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildToggleTile(
                            icon: Icons.notifications_active_outlined,
                            iconColor: const Color(0xFFE65100),
                            bgColor: const Color(0xFFFFF3E0),
                            title: lang == 'si'
                                ? 'පුෂ් දැනුම්දීම්'
                                : lang == 'ta'
                                    ? 'புஷ் அறிவிப்புகள்'
                                    : 'Push Notifications',
                            subtitle: settings.pushNotifications
                                ? (lang == 'si'
                                    ? 'දැනුම්දීම් සක්‍රීය'
                                    : lang == 'ta'
                                        ? 'அறிவிப்புகள் இயக்கப்பட்டன'
                                        : 'Alerts are enabled')
                                : (lang == 'si'
                                    ? 'සියලු ඇඟවීම් නිහඬයි'
                                    : lang == 'ta'
                                        ? 'அனைத்து விழிப்பூட்டல்களும் நிறுத்தப்பட்டன'
                                        : 'All alerts are silenced'),
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
                            title: lang == 'si'
                                ? 'විද්‍යුත් දැනුම්දීම්'
                                : lang == 'ta'
                                    ? 'மின்னஞ்சல் அறிவிப்புகள்'
                                    : 'Email Notifications',
                            subtitle: lang == 'si'
                                ? 'විද්‍යුත් තැපෑලෙන් යාවත්කාලීන කරන්න'
                                : lang == 'ta'
                                    ? 'மின்னஞ்சல் மூலம் புதுப்பிப்புகள் பெறவும்'
                                    : 'Get updates via email',
                            value: settings.emailNotifications,
                            isDark: isDark,
                            onChanged: (val) => context
                                .read<SettingsProvider>()
                                .setEmailNotifications(val),
                          ),
                          const SizedBox(height: 20),

                          // ── APPEARANCE ─────────────────────────────
                          _buildSectionLabel(
                            lang == 'si'
                                ? 'පෙනුම'
                                : lang == 'ta'
                                    ? 'தோற்றம்'
                                    : 'APPEARANCE',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildToggleTile(
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            iconColor:
                                isDark ? Colors.deepPurple : Colors.orange,
                            bgColor: isDark
                                ? const Color(0xFFEDE7F6)
                                : const Color(0xFFFFF8E1),
                            title: lang == 'si'
                                ? 'අඳුරු මාදිලිය'
                                : lang == 'ta'
                                    ? 'இருண்ட பயன்முறை'
                                    : 'Dark Mode',
                            subtitle: isDark
                                ? (lang == 'si'
                                    ? 'අඳුරු තේමාව සක්‍රීයයි'
                                    : lang == 'ta'
                                        ? 'இருண்ட தீம் இயக்கப்பட்டது'
                                        : 'Dark theme is active')
                                : (lang == 'si'
                                    ? 'ආලෝකිත තේමාව සක්‍රීයයි'
                                    : lang == 'ta'
                                        ? 'ஒளி தீம் இயக்கப்பட்டது'
                                        : 'Light theme is active'),
                            value: isDark,
                            isDark: isDark,
                            onChanged: (val) => themeProvider.setDark(val),
                          ),
                          const SizedBox(height: 20),

                          // ── LANGUAGE ───────────────────────────────
                          _buildSectionLabel(
                            lang == 'si'
                                ? 'භාෂාව'
                                : lang == 'ta'
                                    ? 'மொழி'
                                    : 'LANGUAGE',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildActionTile(
                            icon: Icons.language_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                            title: lang == 'si'
                                ? 'යෙදුම් භාෂාව'
                                : lang == 'ta'
                                    ? 'பயன்பாட்டு மொழி'
                                    : 'App Language',
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
                          _buildSectionLabel(
                            lang == 'si'
                                ? 'රහස්‍යතාව සහ දත්ත'
                                : lang == 'ta'
                                    ? 'தனியுரிமை & தரவு'
                                    : 'PRIVACY & DATA',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildToggleTile(
                            icon: Icons.location_on_outlined,
                            iconColor: const Color(0xFF2E7D32),
                            bgColor: const Color(0xFFE8F5E9),
                            title: lang == 'si'
                                ? 'ස්ථාන ප්‍රවේශය'
                                : lang == 'ta'
                                    ? 'இடம் அணுகல்'
                                    : 'Location Access',
                            subtitle: lang == 'si'
                                ? 'කාලගුණ හා ගොවිතැන් ඉඟි සඳහා'
                                : lang == 'ta'
                                    ? 'வானிலை & பண்ணை குறிப்புகளுக்கு பயன்படுகிறது'
                                    : 'Used for weather & farm tips',
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
                            title: lang == 'si'
                                ? 'පසුබිම් සමමුහුර්තකරණය'
                                : lang == 'ta'
                                    ? 'பின்னணி ஒத்திசைவு'
                                    : 'Background Sync',
                            subtitle: settings.dataSync
                                ? (lang == 'si'
                                    ? 'සෑම මිනිත්තු 15 කට වරක් සමමුහුර්ත කෙරේ'
                                    : lang == 'ta'
                                        ? 'ஒவ்வொரு 15 நிமிடமும் ஒத்திசைக்கப்படுகிறது'
                                        : 'Syncing every 15 minutes')
                                : (lang == 'si'
                                    ? 'පසුබිම් සමමුහුර්තකරණය අක්‍රීයයි'
                                    : lang == 'ta'
                                        ? 'பின்னணி ஒத்திசைவு முடக்கப்பட்டது'
                                        : 'Background sync is off'),
                            value: settings.dataSync,
                            isDark: isDark,
                            onChanged: (val) => context
                                .read<SettingsProvider>()
                                .setDataSync(val),
                          ),
                          const SizedBox(height: 20),

                          // ── ACCOUNT ────────────────────────────────
                          _buildSectionLabel(
                            lang == 'si'
                                ? 'ගිණුම'
                                : lang == 'ta'
                                    ? 'கணக்கு'
                                    : 'ACCOUNT',
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildActionTile(
                            icon: Icons.lock_reset_outlined,
                            iconColor: const Color(0xFF1565C0),
                            bgColor: const Color(0xFFE3F2FD),
                            title: lang == 'si'
                                ? 'මුරපදය වෙනස් කරන්න'
                                : lang == 'ta'
                                    ? 'கடவுச்சொல் மாற்றவும்'
                                    : 'Change Password',
                            isDark: isDark,
                            onTap: () =>
                                _showChangePasswordDialog(context, lang),
                          ),
                          _buildActionTile(
                            icon: Icons.delete_outline_rounded,
                            iconColor: const Color(0xFFC62828),
                            bgColor: const Color(0xFFFFEBEE),
                            title: lang == 'si'
                                ? 'ගිණුම මකන්න'
                                : lang == 'ta'
                                    ? 'கணக்கை நீக்கு'
                                    : 'Delete Account',
                            isDark: isDark,
                            onTap: () =>
                                _showDeleteAccountDialog(context, lang),
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
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppTheme.textLight)),
                ],
              ),
            ),
            Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.primaryGreen),
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
                          offset: const Offset(0, 2))
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : AppTheme.textDark)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : AppTheme.textLight)),
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

  // ── Password Field Helper ────────────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }

  // ── Change Password Dialog ───────────────────────────────────────────
  void _showChangePasswordDialog(BuildContext context, String lang) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;
        bool showCurrent = false;
        bool showNew = false;
        bool showConfirm = false;
        String? errorMsg;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_outlined,
                      color: Color(0xFF1565C0), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  lang == 'si'
                      ? 'මුරපදය වෙනස් කරන්න'
                      : lang == 'ta'
                          ? 'கடவுச்சொல் மாற்றவும்'
                          : 'Change Password',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(
                    controller: currentCtrl,
                    label: lang == 'si'
                        ? 'වත්මන් මුරපදය'
                        : lang == 'ta'
                            ? 'தற்போதைய கடவுச்சொல்'
                            : 'Current Password',
                    show: showCurrent,
                    onToggle: () => setState(() => showCurrent = !showCurrent),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: newCtrl,
                    label: lang == 'si'
                        ? 'නව මුරපදය'
                        : lang == 'ta'
                            ? 'புதிய கடவுச்சொல்'
                            : 'New Password',
                    show: showNew,
                    onToggle: () => setState(() => showNew = !showNew),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: confirmCtrl,
                    label: lang == 'si'
                        ? 'මුරපදය තහවුරු කරන්න'
                        : lang == 'ta'
                            ? 'கடவுச்சொல்லை உறுதிப்படுத்தவும்'
                            : 'Confirm New Password',
                    show: showConfirm,
                    onToggle: () => setState(() => showConfirm = !showConfirm),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMsg!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text(
                  lang == 'si'
                      ? 'අවලංගු'
                      : lang == 'ta'
                          ? 'ரத்து'
                          : 'Cancel',
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final current = currentCtrl.text.trim();
                        final newPass = newCtrl.text.trim();
                        final confirm = confirmCtrl.text.trim();

                        if (current.isEmpty ||
                            newPass.isEmpty ||
                            confirm.isEmpty) {
                          setState(() => errorMsg = lang == 'si'
                              ? 'සියලු ක්ෂේත්‍ර පිරවිය යුතුය'
                              : lang == 'ta'
                                  ? 'அனைத்து புலங்களையும் நிரப்பவும்'
                                  : 'Please fill in all fields');
                          return;
                        }
                        if (newPass.length < 8) {
                          setState(() => errorMsg = lang == 'si'
                              ? 'මුරපදය අවම වශයෙන් අකුරු 8ක් විය යුතුය'
                              : lang == 'ta'
                                  ? 'கடவுச்சொல் குறைந்தது 8 எழுத்துக்கள் இருக்க வேண்டும்'
                                  : 'Password must be at least 8 characters');
                          return;
                        }
                        if (newPass != confirm) {
                          setState(() => errorMsg = lang == 'si'
                              ? 'නව මුරපද ගැළපෙන්නේ නැත'
                              : lang == 'ta'
                                  ? 'புதிய கடவுச்சொற்கள் பொருந்தவில்லை'
                                  : 'New passwords do not match');
                          return;
                        }
                        if (current == newPass) {
                          setState(() => errorMsg = lang == 'si'
                              ? 'නව මුරපදය පැරණි එකට සමාන නොවිය යුතුය'
                              : lang == 'ta'
                                  ? 'புதிய கடவுச்சொல் பழையதிலிருந்து வேறுபட வேண்டும்'
                                  : 'New password must differ from current');
                          return;
                        }

                        setState(() {
                          isLoading = true;
                          errorMsg = null;
                        });

                        final result =
                            await BackendSupportService().changePassword(
                          currentPassword: current,
                          newPassword: newPass,
                        );

                        if (!ctx.mounted) return;

                        if (result['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang == 'si'
                                    ? 'මුරපදය සාර්ථකව වෙනස් කරන ලදී'
                                    : lang == 'ta'
                                        ? 'கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது'
                                        : 'Password changed successfully',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        } else {
                          setState(() {
                            isLoading = false;
                            errorMsg = result['message'] ??
                                'Failed to change password';
                          });
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(lang == 'si'
                        ? 'වෙනස් කරන්න'
                        : lang == 'ta'
                            ? 'மாற்றவும்'
                            : 'Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Delete Account Dialog ────────────────────────────────────────────
  void _showDeleteAccountDialog(BuildContext context, String lang) {
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;
        bool showPassword = false;
        String? errorMsg;

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade700, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  lang == 'si'
                      ? 'ගිණුම මකන්න'
                      : lang == 'ta'
                          ? 'கணக்கை நீக்கு'
                          : 'Delete Account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lang == 'si'
                              ? 'ගිණුම සහ සියලු දත්ත ස්ථිරවම මකා දැමේ. මෙය අහෝසි කළ නොහැකිය.'
                              : lang == 'ta'
                                  ? 'கணக்கும் அனைத்து தரவும் நிரந்தரமாக நீக்கப்படும். இதை செயல்தவிர்க்க முடியாது.'
                                  : 'Your account and all data will be permanently deleted. This cannot be undone.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lang == 'si'
                      ? 'තහවුරු කිරීමට මුරපදය ඇතුළත් කරන්න:'
                      : lang == 'ta'
                          ? 'உறுதிப்படுத்த கடவுச்சொல்லை உள்ளிடவும்:'
                          : 'Enter your password to confirm:',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: passwordCtrl,
                  label: lang == 'si'
                      ? 'මුරපදය'
                      : lang == 'ta'
                          ? 'கடவுச்சொல்'
                          : 'Password',
                  show: showPassword,
                  onToggle: () => setState(() => showPassword = !showPassword),
                ),
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!,
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text(
                  lang == 'si'
                      ? 'අවලංගු'
                      : lang == 'ta'
                          ? 'ரத்து'
                          : 'Cancel',
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final password = passwordCtrl.text.trim();

                        if (password.isEmpty) {
                          setState(() => errorMsg = lang == 'si'
                              ? 'මුරපදය ඇතුළත් කරන්න'
                              : lang == 'ta'
                                  ? 'கடவுச்சொல்லை உள்ளிடவும்'
                                  : 'Please enter your password');
                          return;
                        }

                        setState(() {
                          isLoading = true;
                          errorMsg = null;
                        });

                        final result =
                            await BackendSupportService().deleteAccount(
                          password: password,
                        );

                        if (!ctx.mounted) return;

                        if (result['success'] == true) {
                          // Close dialog first
                          Navigator.pop(ctx);

                          if (!context.mounted) return;

                          // Sign out from Firebase + clear local token
                          await context.read<AuthProvider>().signOut();

                          if (!context.mounted) return;

                          // ✅ Clear entire navigation stack and go to login
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        } else {
                          setState(() {
                            isLoading = false;
                            errorMsg =
                                result['message'] ?? 'Failed to delete account';
                          });
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(lang == 'si'
                        ? 'ස්ථිරවම මකන්න'
                        : lang == 'ta'
                            ? 'நிரந்தரமாக நீக்கு'
                            : 'Permanently Delete'),
              ),
            ],
          ),
        );
      },
    );
  }
}
