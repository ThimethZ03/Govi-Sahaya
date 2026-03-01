import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_endpoints.dart'; // ✅ add this
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  // ✅ Safely get profile picture from User model
  String? _getProfilePicture(dynamic user) {
    if (user == null) return null;
    try {
      final pic = user.profilePicture;
      if (pic is String && pic.isNotEmpty) return pic;
    } catch (_) {}
    try {
      final pic = user.profileImageUrl;
      if (pic is String && pic.isNotEmpty) return pic;
    } catch (_) {}
    try {
      final pic = user.photoUrl;
      if (pic is String && pic.isNotEmpty) return pic;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final lang = context.watch<LanguageProvider>().languageCode;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final profilePicPath = _getProfilePicture(user);

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
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
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
                      lang == 'si'
                          ? 'මෙනුව'
                          : lang == 'ta'
                              ? 'மெனு'
                              : 'Menu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
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
                              width: 1,
                            ),
                          ),
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
                                  minWidth: 15, minHeight: 15),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
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
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Profile Card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // ── Avatar ────────────────────────────────────────
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            // ✅ Use getImageUrl to build full URL
                            backgroundImage: profilePicPath != null
                                ? NetworkImage(
                                    ApiEndpoints.getImageUrl(profilePicPath))
                                : null,
                            child: profilePicPath == null
                                ? Text(
                                    (user?.name?.isNotEmpty == true)
                                        ? user!.name[0].toUpperCase()
                                        : 'G',
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.editProfile),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.edit,
                                  size: 11, color: AppTheme.primaryGreen),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // ── Name + Email ──────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ??
                                (lang == 'si'
                                    ? 'ගොවියා'
                                    : lang == 'ta'
                                        ? 'விவசாயி'
                                        : 'Farmer'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 10,
                                  color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ── View Profile Button ───────────────────────────
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          lang == 'si'
                              ? 'බලන්න'
                              : lang == 'ta'
                                  ? 'காண்க'
                                  : 'View',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── White Bottom Sheet ────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
                  children: [
                    _buildSectionLabel(
                      lang == 'si'
                          ? 'සැකසුම්'
                          : lang == 'ta'
                              ? 'அமைப்புகள்'
                              : 'SETTINGS',
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF1565C0),
                      bgColor: const Color(0xFFE3F2FD),
                      title: lang == 'si'
                          ? 'භාෂාව'
                          : lang == 'ta'
                              ? 'மொழி'
                              : 'Language',
                      route: AppRoutes.language,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_rounded,
                      iconColor: const Color(0xFF546E7A),
                      bgColor: const Color(0xFFECEFF1),
                      title: lang == 'si'
                          ? 'සැකසුම්'
                          : lang == 'ta'
                              ? 'அமைப்புகள்'
                              : 'Settings',
                      route: AppRoutes.settings,
                    ),

                    const SizedBox(height: 18),

                    _buildSectionLabel(
                      lang == 'si'
                          ? 'උදව්'
                          : lang == 'ta'
                              ? 'உதவி'
                              : 'HELP',
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.group_add_rounded,
                      iconColor: const Color(0xFF6A1B9A),
                      bgColor: const Color(0xFFF3E5F5),
                      title: lang == 'si'
                          ? 'මිතුරන් ආරාධනා කරන්න'
                          : lang == 'ta'
                              ? 'நண்பர்களை அழைக்கவும்'
                              : 'Invite Friends',
                      route: AppRoutes.inviteFriends,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF57F17),
                      bgColor: const Color(0xFFFFFDE7),
                      title: lang == 'si'
                          ? 'අපට ඇගයීමක් දෙන්න'
                          : lang == 'ta'
                              ? 'எங்களை மதிப்பிடுங்கள்'
                              : 'Rate Us',
                      route: AppRoutes.rateUs,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xFF00695C),
                      bgColor: const Color(0xFFE0F2F1),
                      title: lang == 'si'
                          ? 'නියම සහ පෞද්ගලිකත්වය'
                          : lang == 'ta'
                              ? 'விதிமுறைகள் மற்றும் தனியுரிமை'
                              : 'Terms and Privacy',
                      route: AppRoutes.termsPrivacy,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.report_problem_rounded,
                      iconColor: const Color(0xFFC62828),
                      bgColor: const Color(0xFFFFEBEE),
                      title: lang == 'si'
                          ? 'ගැටළුවක් වාර්තා කරන්න'
                          : lang == 'ta'
                              ? 'சிக்கலை புகாரளிக்கவும்'
                              : 'Report Problem',
                      route: AppRoutes.reportProblem,
                    ),

                    const SizedBox(height: 18),

                    _buildLogoutTile(context, lang),

                    const SizedBox(height: 28),

                    // ── Footer ────────────────────────────────────────
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == 1 ? 16 : 5,
                              height: 3,
                              decoration: BoxDecoration(
                                color: i == 1
                                    ? AppTheme.primaryGreen.withOpacity(0.4)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lang == 'si'
                              ? 'බලය ලබා දෙන්නේ'
                              : lang == 'ta'
                                  ? 'இயக்கப்படுகிறது'
                                  : 'Powered by',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco_rounded,
                                size: 12,
                                color: AppTheme.primaryGreen.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'DARTIS Dynamics',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen.withOpacity(0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
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
              color: AppTheme.textLight.withOpacity(0.7),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (route != null) {
              Navigator.pushNamed(context, route);
            } else {
              onTap?.call();
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.grey, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(
                  lang == 'si'
                      ? 'පිටවීම'
                      : lang == 'ta'
                          ? 'வெளியேறு'
                          : 'Log Out',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  lang == 'si'
                      ? 'ඔබට සැබවින්ම පිටවීමට අවශ්‍යද?'
                      : lang == 'ta'
                          ? 'நீங்கள் வெளியேற விரும்புகிறீர்களா?'
                          : 'Are you sure you want to log out?',
                  style: const TextStyle(color: AppTheme.textLight),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      lang == 'si'
                          ? 'අවලංගු කරන්න'
                          : lang == 'ta'
                              ? 'ரத்து செய்'
                              : 'Cancel',
                      style: const TextStyle(color: AppTheme.textLight),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      lang == 'si'
                          ? 'පිටවීම'
                          : lang == 'ta'
                              ? 'வெளியேறு'
                              : 'Log Out',
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await context.read<AuthProvider>().signOut();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade50,
                  Colors.red.shade50.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang == 'si'
                        ? 'පිටවීම'
                        : lang == 'ta'
                            ? 'வெளியேறு'
                            : 'Log Out',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.red, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
