import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final lang = context.watch<LanguageProvider>().languageCode;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // ✅ Modern hamburger menu icon button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 3 bars — hamburger
                            Container(
                              height: 2,
                              width: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              height: 2,
                              width: 14, // shorter middle bar
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              height: 2,
                              width: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Title
                  Expanded(
                    child: Text(
                      lang == 'si'
                          ? 'මෙනුව'
                          : lang == 'ta'
                              ? 'மெனு'
                              : 'Menu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // ✅ Notification icon (same style as before)
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Profile Card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            backgroundImage: user?.photoUrl != null
                                ? NetworkImage(user!.photoUrl!)
                                : null,
                            child: user?.photoUrl == null
                                ? Text(
                                    (user?.name?.isNotEmpty == true)
                                        ? user!.name[0].toUpperCase()
                                        : 'G',
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 24,
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
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 13,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Name + email
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 11,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 12,
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

                    // View Profile button
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── White Bottom Sheet ────────────────────────────────────
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
                    // ── SETTINGS ──────────────────────────────────────
                    _buildSectionLabel(
                      lang == 'si'
                          ? 'සැකසුම්'
                          : lang == 'ta'
                              ? 'அமைப்புகள்'
                              : 'SETTINGS',
                    ),
                    const SizedBox(height: 10),
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

                    const SizedBox(height: 24),

                    // ── HELP ──────────────────────────────────────────
                    _buildSectionLabel(
                      lang == 'si'
                          ? 'උදව්'
                          : lang == 'ta'
                              ? 'உதவி'
                              : 'HELP',
                    ),
                    const SizedBox(height: 10),
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

                    const SizedBox(height: 24),

                    _buildLogoutTile(context, lang),

                    const SizedBox(height: 36),

                    // ── Footer ────────────────────────────────────────
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == 1 ? 20 : 6,
                              height: 4,
                              decoration: BoxDecoration(
                                color: i == 1
                                    ? AppTheme.primaryGreen.withOpacity(0.4)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          lang == 'si'
                              ? 'බලය ලබා දෙන්නේ'
                              : lang == 'ta'
                                  ? 'இயக்கப்படுகிறது'
                                  : 'Powered by',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: 14,
                              color: AppTheme.primaryGreen.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'DARTIS Dynamics',
                              style: TextStyle(
                                fontSize: 12,
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

  // ── Section Label ──────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textLight.withOpacity(0.7),
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu Item ──────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout Tile ────────────────────────────────────────────────────
  Widget _buildLogoutTile(BuildContext context, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
                        borderRadius: BorderRadius.circular(10),
                      ),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade50,
                  Colors.red.shade50.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    lang == 'si'
                        ? 'පිටවීම'
                        : lang == 'ta'
                            ? 'வெளியேறு'
                            : 'Log Out',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
