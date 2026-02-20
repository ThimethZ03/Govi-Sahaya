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

/// Govi Sahaya Login Screen Widget
///
/// [StatefulWidget] භාවිතා කරන්නේ:
///   - [_obscurePassword] → password පෙන්වීම/සැඟවීම
///   - [_isLoginSelected] → active tab highlight කිරීම
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Form ──────────────────────────────────────────────────
  /// Form validation සඳහා global key
  final _formKey = GlobalKey<FormState>();

  /// ✏️ EDIT: field controllers — email සහ password read කරන්න
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── UI State ──────────────────────────────────────────────
  /// true  = password characters සැඟවිලා (default)
  /// false = password plain text ලෙස පෙනෙනවා
  bool _obscurePassword = true;

  /// true = "Login" tab bold ලෙස පෙනෙනවා
  bool _isLoginSelected = true;

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    // ⚠️ IMPORTANT: Memory leak වලක්වා ගැනීමට
    // controllers dispose කිරීම අනිවාර්යයි
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // HANDLERS
  // ─────────────────────────────────────────────────────────

  /// Email + Password Login Handler
  ///
  /// ක්‍රියාවලිය:
  ///   1. Form validate කරනවා
  ///   2. AuthProvider.signIn() ඇමතෙනවා
  ///   3. Success → snackbar + home page
  ///   4. Failure → error snackbar
  ///
  /// ✏️ EDIT success message → 'Welcome back! 🌾'
  /// ✏️ EDIT redirect route  → AppRoutes.home
  Future<void> _handleLogin() async {
    // Validation fail වුනොත් ඉක්මනින් නවත්වන්න
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // Widget unmount වීමෙන් පසු context use නොකරන්න
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
      // ✏️ EDIT: login වීමෙන් පසු යන page වෙනස් කරන්න
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      // ✏️ EDIT: error message වෙනස් කරන්න
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

    // Google OAuth popup ඇමතෙනවා
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      // ✏️ EDIT: Google success message වෙනස් කරන්න
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

  /// සියලු form fields සඳහා එකම decoration ලබා දෙන helper
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
          // ✏️ EDIT: image path වෙනස් කරන්න
          // ✏️ EDIT: cacheWidth වැඩි කරන්න = image quality වැඩි
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
          // ✏️ EDIT: opacity වැඩි = අඳුරු | අඩු = පැහැදිලි
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
                        // ✏️ EDIT: 'Login' text වෙනස් කරන්න
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
                        // ✏️ EDIT: AppRoutes.register → ඔබගේ route
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
                  // ✏️ EDIT: App නම වෙනස් කරන්න
                  // ✏️ EDIT: fontSize: 20 → size වෙනස් කරන්න
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
                              // වැඩි = blur වැඩි | අඩු = clear
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
                                          builder: (
                                            context,
                                            authProvider,
                                            child,
                                          ) {
                                            final loading =
                                                authProvider.isLoading;

                                            return Row(
                                              children: [
                                                // Google Button (outlined)
                                                // ✏️ EDIT border color, label
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: loading
                                                        ? null
                                                        : _handleGoogleSignIn,
                                                    icon: loading
                                                        ? const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: AppTheme
                                                                  .primaryGreen,
                                                            ),
                                                          )
                                                        : Image.asset(
                                                            'assets/images/google_icon.png',
                                                            height: 18,
                                                            width: 18,
                                                          ),
                                                    label: const Text(
                                                      'Google', // ✏️ EDIT
                                                      style: TextStyle(
                                                        color:
                                                            AppTheme.textDark,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 11,
                                                      ),
                                                      side: const BorderSide(
                                                        color: AppTheme
                                                            .primaryGreen, // ✏️ EDIT
                                                        width: 1.2,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                // Login Button (filled)
                                                // ✏️ EDIT color, label
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: loading
                                                        ? null
                                                        : _handleLogin,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: AppTheme
                                                          .primaryGreen, // ✏️ EDIT
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 12,
                                                      ),
                                                      elevation: 2, // ✏️ shadow
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    // loading → spinner
                                                    child: loading
                                                        ? const SizedBox(
                                                            height: 16,
                                                            width: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          )
                                                        : const Text(
                                                            'Log In', // ✏️ EDIT
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ], // end Row children
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 6),

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

                  // Card clip නොවෙන්න bottom space
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
