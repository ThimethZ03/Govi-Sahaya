// ============================================================
// File    : login_screen.dart
// Project : Govi Sahaya – Agricultural Assistant App
// Author  : [Your Name]
// GitHub  : https://github.com/[your-username]/govi-sahaya
// Version : 1.1.0
// Date    : 2026
// ------------------------------------------------------------
// DESCRIPTION
//   Govi Sahaya Login Screen
//   - Email + Password login
//   - Google Sign-In (OAuth)
//   - Forgot Password shortcut
//   - Navigate to RegisterScreen
//   - Frosted-glass card over rice-field background
//
// ✏️  QUICK EDIT GUIDE
//   🖼️  Background image .... 'assets/images/rice.jpg'
//   🎨  Overlay opacity ..... Colors.black.withOpacity(0.25 / 0.55)
//   📝  Welcome text ........ 'WELCOME BACK\nGovi Sahaya'
//   📐  Card height ......... size.height * 0.48
//   📐  Card offset ......... Offset(0, 30)
//   🌫️  Blur strength ....... sigmaX: 10, sigmaY: 10
//   💎  Card opacity ........ Colors.white.withOpacity(0.84)
//   📧  Email placeholder ... 'Enter your email'
//   🔒  Password placeholder  'Enter your password'
//   🔗  Forgot password ..... onPressed: () {}  ← route එකතු කරන්න
//   🟢  Button color ........ AppTheme.primaryGreen
//   ✉️  Success message ..... 'Welcome back! 🌾'
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/validators.dart';

/// [StatefulWidget] භාවිතා කරන්නේ:
///   - [_obscurePassword] → password පෙන්වීම/සැඟවීම
///   - [_isLoginSelected] → active tab highlight කිරීම
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  bool _isLoginSelected = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // ✏️ EDIT: success message වෙනස් කරන්න
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Welcome back! 🌾'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Google OAuth Sign-In Handler
  ///
  /// ✏️ EDIT success message → 'Welcome to Govi Sahaya! 🌾'
  /// ✏️ EDIT redirect route  → AppRoutes.home
  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Welcome to Govi Sahaya! 🌾'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  ///
  /// ✏️ EDIT border radius → BorderRadius.circular(10)
  /// ✏️ EDIT icon size     → size: 18
  /// ✏️ EDIT padding       → EdgeInsets.symmetric(...)
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      isDense: true,
      prefixIcon: Icon(icon, size: 18), // ✏️ EDIT icon size
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11, // ✏️ EDIT padding
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // ✏️ EDIT radius
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Keyboard පෙනෙද්දී card slide up වෙන්න
      resizeToAvoidBottomInset: true,

      body: Stack(
        children: [
          // ══════════════════════════════════════════════════
          // LAYER 1 — Background Image
          // ══════════════════════════════════════════════════
          SizedBox.expand(
            child: Image.asset(
              'assets/images/rice.jpg', // ✏️ EDIT image path
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: 720, // ✏️ EDIT quality
            ),
          ),

          // ══════════════════════════════════════════════════
          // LAYER 2 — Dark Gradient Overlay
          // ══════════════════════════════════════════════════
          //
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.25), // ✏️ ඉහළ අඳුර
                  Colors.black.withOpacity(0.55), // ✏️ පහළ අඳුර
                ],
              ),
            ),
          ),

          // ══════════════════════════════════════════════════
          // LAYER 3 — Foreground UI
          // ══════════════════════════════════════════════════
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top Navigation Bar ──────────────────
                  // Login / Sign Up tabs + avatar icon
                  // ✏️ EDIT padding → fromLTRB(14, 8, 14, 6)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                    child: Row(
                      children: [
                        // Login Tab (active state)

                        GestureDetector(
                          onTap: () => setState(
                            () => _isLoginSelected = true,
                          ),
                          child: Text(
                            'Login', // ✏️ EDIT tab label
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: _isLoginSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              decoration: _isLoginSelected
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationThickness: 2,
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Sign Up Tab → RegisterScreen

                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.register, // ✏️ EDIT route
                          ),
                          child: Text(
                            'Sign Up', // ✏️ EDIT tab label
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Avatar Icon (top-right corner)
                        // ✏️ EDIT: GestureDetector add කරන්න
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person, // ✏️ EDIT icon
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Welcome / Hero Text ─────────────────

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WELCOME BACK\nGovi Sahaya', // ✏️ EDIT text
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20, // ✏️ EDIT font size
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),

                  // Card ඉහළ gap
                  // ✏️ EDIT: 0.12 → card position වෙනස් වෙනවා
                  SizedBox(height: size.height * 0.12),

                  // ══════════════════════════════════════════
                  // LOGIN CARD — Frosted glass bottom sheet
                  // ══════════════════════════════════════════
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        // ✏️ EDIT: 30 → card පහළට slide pixels
                        offset: const Offset(0, 30),
                        child: SizedBox(
                          // ✏️ EDIT: 0.48 → card height %
                          height: size.height * 0.48,
                          width: double.infinity,
                          child: ClipRRect(
                            // ✏️ EDIT: 26 → card corner radius
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(26),
                              topRight: Radius.circular(26),
                            ),
                            child: BackdropFilter(
                              // ✏️ EDIT: sigma → blur intensity

                              filter: ImageFilter.blur(
                                sigmaX: 10, // ✏️ EDIT
                                sigmaY: 10, // ✏️ EDIT
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  // ✏️ EDIT: 0.84 → transparency
                                  // අඩු = see-through | වැඩි = solid
                                  color: Colors.white.withOpacity(0.84),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 16,
                                      offset: const Offset(0, -5),
                                      color: Colors.black.withOpacity(0.10),
                                    ),
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    14,
                                    18,
                                    10,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // ── Card Title ──────────
                                        // ✏️ EDIT: 'Log In' → title
                                        const Text(
                                          'Log In', // ✏️ EDIT
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // ── Email Field ─────────
                                        // ✏️ EDIT label + placeholder
                                        const Text(
                                          'Your Email', // ✏️ EDIT
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: const TextStyle(fontSize: 15),
                                          decoration: _fieldDecoration(
                                            hint: 'Enter your email', // ✏️ EDIT
                                            icon: Icons.email_outlined,
                                          ),
                                          validator: Validators.validateEmail,
                                        ),
                                        const SizedBox(height: 10),

                                        // ── Password Field ──────
                                        // ✏️ EDIT label + placeholder
                                        const Text(
                                          'Your Password', // ✏️ EDIT
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                          decoration: _fieldDecoration(
                                            hint:
                                                'Enter your password', // ✏️ EDIT
                                            icon: Icons.lock_outline,
                                            suffixIcon: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              // ✏️ EDIT show/hide icons
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              }),
                                            ),
                                          ),
                                          validator:
                                              Validators.validatePassword,
                                        ),

                                        const SizedBox(height: 4),

                                        // ── Forgot Password ─────
                                        // ✏️ EDIT: onPressed: () {} →
                                        // Navigator.pushNamed(context,
                                        //   AppRoutes.forgotPassword)
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {}, // ✏️ ADD route
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 2,
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Forget your password?', // ✏️ EDIT
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.primaryGreen,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // ── Button Row ──────────
                                        // Consumer → loading state watch
                                        Consumer<AuthProvider>(
                                          builder:
                                              (context, authProvider, child) {
                                            final loading =
                                                authProvider.isLoading;

                                            return Column(
                                              children: [
                                                // ───── Login Button (Primary Action) ─────
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 46,
                                                  child: ElevatedButton(
                                                    onPressed: loading
                                                        ? null
                                                        : _handleLogin,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppTheme.primaryGreen,
                                                      elevation: 4,
                                                      shadowColor: Colors.black
                                                          .withOpacity(0.25),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                      ),
                                                    ),
                                                    child: loading
                                                        ? const SizedBox(
                                                            height: 18,
                                                            width: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2.4,
                                                            ),
                                                          )
                                                        : const Text(
                                                            "SIGN IN",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  1.1,
                                                            ),
                                                          ),
                                                  ),
                                                ),

                                                const SizedBox(height: 12),

                                                // ───── Google Button (Secondary Action) ─────
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 46,
                                                  child: OutlinedButton.icon(
                                                    onPressed: loading
                                                        ? null
                                                        : _handleGoogleSignIn,
                                                    icon: Image.asset(
                                                      'assets/images/google_icon.png',
                                                      height: 20,
                                                      width: 20,
                                                    ),
                                                    label: const Text(
                                                      "Continue with Google",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      side: BorderSide(
                                                        color: AppTheme
                                                            .primaryGreen
                                                            .withOpacity(0.7),
                                                        width: 1.4,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),

                                        // ── Sign Up Footer ──────
                                        // ✏️ EDIT text + route
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Don't have an account? ", // ✏️ EDIT
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textLight,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pushNamed(
                                                context,
                                                AppRoutes.register, // ✏️ EDIT
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 2,
                                                ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Sign Up', // ✏️ EDIT
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ], // end Column children
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ], // end SafeArea Column children
              ),
            ),
          ),
        ], // end Stack children
      ),
    );
  }
}
