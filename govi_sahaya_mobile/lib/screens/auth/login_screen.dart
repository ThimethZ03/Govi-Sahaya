import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/validators.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kGreen700 = Color(0xFF1E4D2E);
const _kGreen500 = Color(0xFF2D6B42);
const _kGold     = Color(0xFFCFA843);
const _kCardBg   = Color(0xFFF7F6F2);
const _kBorder   = Color(0xFFE2E8E4);
const _kTextDark = Color(0xFF0F2318);
const _kTextMid  = Color(0xFF5A6B61);
const _kTextHint = Color(0xFFADB8B2);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoginSelected = true;

  // Loading state is read directly from AuthProvider.isLoading — no local bool needed.

  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Snack bar ─────────────────────────────────────────────────────────────────
  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: bg,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  // ── Login ─────────────────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoading) return;                    // prevent double-tap
    final ok = await auth.signIn(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      _snack('Welcome back! 🌾', AppTheme.successGreen);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      _snack(auth.errorMessage ?? 'Login failed', AppTheme.errorRed);
    }
  }

  // ── Google sign-in ────────────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoading) return;                    // prevent double-tap
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _snack('Welcome to Govi Sahaya! 🌾', AppTheme.successGreen);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (auth.errorMessage != null) {
      _snack(auth.errorMessage!, AppTheme.errorRed);
    }
  }

  // ── Field decoration ──────────────────────────────────────────────────────────
  InputDecoration _fieldDecoration({
    required String   hint,
    required IconData icon,
    Widget?           suffixIcon,
  }) {
    return InputDecoration(
      hintText:  hint,
      hintStyle: const TextStyle(
          fontSize: 13, color: _kTextHint, fontWeight: FontWeight.w400),
      isDense:   true,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child:   Icon(icon, size: 17, color: _kTextHint),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 46),
      suffixIcon:     suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled:         true,
      fillColor:      Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:  const BorderSide(color: _kBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:  const BorderSide(color: _kGreen500, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:  BorderSide(color: AppTheme.errorRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:  BorderSide(color: AppTheme.errorRed, width: 1.6),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final mq           = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 100;

    return Scaffold(
      // KEY: false — we manually handle keyboard inset via AnimatedPadding
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [

          // ── Background ───────────────────────────────────────────────
          SizedBox.expand(
            child: Image.asset(
              'assets/images/rice.jpg',
              fit:           BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth:    800,
            ),
          ),

          // ── Gradient overlay ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                stops:  [0.0, 0.40, 1.0],
                colors: [
                  Color(0x44000000),
                  Color(0x77000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),

          // ── Hero text (top area) ─────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Nav tabs row
                  Row(
                    children: [
                      _NavTab(
                        label:    'Login',
                        selected: _isLoginSelected,
                        onTap:    () =>
                            setState(() => _isLoginSelected = true),
                      ),
                      const SizedBox(width: 4),
                      _NavTab(
                        label:    'Sign Up',
                        selected: !_isLoginSelected,
                        onTap:    () => Navigator.pushNamed(
                            context, AppRoutes.register),
                      ),
                      const Spacer(),
                      Container(
                        width:  36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1.2,
                          ),
                          color: Colors.white.withOpacity(0.12),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size:  17,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Eyebrow
                  Row(
                    children: [
                      Container(width: 18, height: 1.5, color: _kGold),
                      const SizedBox(width: 8),
                      Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          color:         Colors.white.withOpacity(0.70),
                          fontSize:      10,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // App name
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Govi ',
                        style: TextStyle(
                          color:         Colors.white,
                          fontSize:      30,
                          fontWeight:    FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Sahaya',
                        style: TextStyle(
                          color:         Colors.white,
                          fontSize:      30,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text:  ' 🌾',
                        style: TextStyle(fontSize: 22),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Your smart farming companion',
                    style: TextStyle(
                      color:      Colors.white.withOpacity(0.55),
                      fontSize:   13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom card — DYNAMIC: sits at bottom, slides up with keyboard ──
          Positioned(
            left:   0,
            right:  0,
            bottom: 0,
            child: AnimatedPadding(
              // This is the magic — card rises exactly as keyboard height
              duration: const Duration(milliseconds: 300),
              curve:    Curves.easeOutCubic,
              padding:  EdgeInsets.only(bottom: mq.viewInsets.bottom),
              child: FadeTransition(
                opacity:  _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft:  Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        // Dynamic: sized by content, no fixed height
                        color: _kCardBg,
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                            child: Form(
                              key:   _formKey,
                              child: Column(
                                mainAxisSize:       MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                                  // Card header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize:      22,
                                              fontWeight:    FontWeight.w700,
                                              color:         _kTextDark,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Enter your credentials to continue',
                                            style: TextStyle(
                                              fontSize:   12,
                                              color:      _kTextMid,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width:  40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _kGreen700.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.eco_rounded,
                                          color: _kGreen700,
                                          size:  20,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Email
                                  const _FieldLabel(label: 'Email Address'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller:      _emailController,
                                    keyboardType:    TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    style: const TextStyle(
                                      fontSize:   14,
                                      color:      _kTextDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: _fieldDecoration(
                                      hint: 'you@example.com',
                                      icon: Icons.mail_outline_rounded,
                                    ),
                                    validator: Validators.validateEmail,
                                  ),

                                  const SizedBox(height: 14),

                                  // Password
                                  const _FieldLabel(label: 'Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller:       _passwordController,
                                    obscureText:      _obscurePassword,
                                    textInputAction:  TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      final auth = Provider.of<AuthProvider>(
                                          context, listen: false);
                                      if (!auth.isLoading) _handleLogin();
                                    },
                                    style: const TextStyle(
                                      fontSize:   14,
                                      color:      _kTextDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: _fieldDecoration(
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        splashRadius: 20,
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size:  18,
                                          color: _kTextHint,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: Validators.validatePassword,
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 6),
                                        minimumSize:   Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontSize:   12,
                                          color:      _kGreen500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                            color: _kBorder, thickness: 1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          'or continue with',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:    _kTextHint),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                            color: _kBorder, thickness: 1),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // Google + Login buttons
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      final loading = auth.isLoading;
                                      return Row(
                                        children: [

                                          // Google
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: loading
                                                  ? null
                                                  : _handleGoogleSignIn,
                                              icon: loading
                                                  ? const SizedBox(
                                                      width:  14,
                                                      height: 14,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: _kGreen500,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'assets/images/google_icon.png',
                                                      height: 17,
                                                      width:  17,
                                                    ),
                                              label: const Text(
                                                'Google',
                                                style: TextStyle(
                                                  color:      _kTextDark,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:   13,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets
                                                    .symmetric(vertical: 13),
                                                backgroundColor: Colors.white,
                                                side: const BorderSide(
                                                    color: _kBorder,
                                                    width: 1.3),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // Log In
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: loading
                                                  ? null
                                                  : _handleLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _kGreen700,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets
                                                    .symmetric(vertical: 14),
                                                elevation:   0,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: loading
                                                  ? const SizedBox(
                                                      height: 17,
                                                      width:  17,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color:       Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Log In',
                                                      style: TextStyle(
                                                        fontSize:      14,
                                                        fontWeight:    FontWeight.w700,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                            ),
                                          ),

                                        ],
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Sign up link
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                            fontSize: 12, color: _kTextMid),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          final auth = Provider.of<AuthProvider>(
                                              context, listen: false);
                                          if (!auth.isLoading) {
                                            Navigator.pushNamed(
                                                context, AppRoutes.register);
                                          }
                                        },
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontSize:   12,
                                            fontWeight: FontWeight.w700,
                                            color:      _kGreen500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                ],
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
          ),

        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve:    Curves.easeOut,
        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? Colors.white.withOpacity(0.30)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:         selected
                ? Colors.white
                : Colors.white.withOpacity(0.55),
            fontSize:      13,
            fontWeight:    selected ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize:      12,
        fontWeight:    FontWeight.w600,
        color:         _kTextDark,
        letterSpacing: 0.1,
      ),
    );
  }
}
