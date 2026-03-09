import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../services/backend_auth_service.dart';
import '../../core/network/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigate();
  }

  // ✅ FIX ISSUE 4: Check saved Firebase session before navigating
  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // ✅ Step 1: Init stored JWT from SharedPreferences
    await ApiClient().init();

    // ✅ Step 2: Check if Firebase still has a valid session
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      // ✅ Step 3: Reload to check if email is verified
      try {
        await firebaseUser.reload();
      } catch (_) {}

      final refreshedUser = FirebaseAuth.instance.currentUser;

      // ✅ Step 4: If JWT not in storage, refresh it from backend
      if (!ApiClient().isAuthenticated) {
        try {
          await refreshedUser!.getIdToken(true);
          await BackendAuthService().syncWithBackend(
            firebaseUid: refreshedUser.uid,
            email: refreshedUser.email ?? '',
            name: refreshedUser.displayName ?? 'User',
          );
        } catch (e) {
          print('⚠️ Token refresh on splash failed: $e');
        }
      }

      // ✅ Step 5: Route to home — session is valid
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      // ✅ No session — go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(opacity: _fadeAnimation.value, child: child),
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.agriculture, size: 100, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                duration: const Duration(milliseconds: 800),
                child: Text(
                  AppConstants.appNameSinhala,
                  style: AppTheme.sinhalaText(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 1200),
                duration: const Duration(milliseconds: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    AppConstants.appSlogan,
                    textAlign: TextAlign.center,
                    style: AppTheme.sinhalaText(
                        fontSize: 14, color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              FadeIn(
                delay: const Duration(milliseconds: 1500),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
