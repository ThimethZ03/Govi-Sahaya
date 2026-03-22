import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'නැණවත් ගොවිතැනක්\nසරුසාර හෙට දිනක්',
                    textAlign: TextAlign.right,
                    style: AppTheme.sinhalaText(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Items
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'ACCOUNT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      context,
                      icon: Icons.person,
                      title: 'My Profile',
                      route: AppRoutes.profile,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      context,
                      icon: Icons.language,
                      title: 'Language',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {},
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'HELP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      context,
                      icon: Icons.group_add,
                      title: 'Invite Friends',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.star,
                      title: 'Rate Us',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.privacy_tip,
                      title: 'Terms and Privacy',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.report_problem,
                      title: 'Report problem',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: 'Log out',
                      onTap: () async {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.login);
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        'Powerd by\nDARTIS Dynamics',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
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
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        } else if (onTap != null) {
          onTap();
        }
      },
    );
  }
}
