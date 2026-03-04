import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/validators.dart';

// ── Design tokens (identical to login_screen.dart) ────────────────────────────
const _kGreen700 = Color(0xFF1E4D2E);
const _kGreen500 = Color(0xFF2D6B42);
const _kGold = Color(0xFFCFA843);
const _kCardBg = Color(0xFFF7F6F2);
const _kBorder = Color(0xFFE2E8E4);
const _kTextDark = Color(0xFF0F2318);
const _kTextMid = Color(0xFF5A6B61);
const _kTextHint = Color(0xFFADB8B2);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Controllers (DO NOT MODIFY) ───────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpSelected = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Validators (DO NOT MODIFY) ────────────────────────────────────────────────
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ── Backend logic (DO NOT MODIFY) ─────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoading) return;

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _snack('Account created successfully! 🌾', AppTheme.successGreen);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      _snack(authProvider.errorMessage ?? 'Registration failed',
          AppTheme.errorRed);
    }
  }

  // ── Snack bar helper ──────────────────────────────────────────────────────────
  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  // ── Field decoration (matches login_screen.dart exactly) ──────────────────────
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          fontSize: 13, color: _kTextHint, fontWeight: FontWeight.w400),
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, size: 17, color: _kTextHint),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 46),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kGreen500, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.errorRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.errorRed, width: 1.6),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 100;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Background image ─────────────────────────────────────────────────
          SizedBox.expand(
            child: Image.asset(
              'assets/images/rice.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth: 800,
            ),
          ),

          // ── Gradient overlay ─────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.40, 1.0],
                colors: [
                  Color(0x44000000),
                  Color(0x77000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),

          // ── Hero text (top area) ─────────────────────────────────────────────
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
                      // Login tab — inactive, goes back
                      _NavTab(
                        label: 'Login',
                        selected: false,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      // Sign Up tab — active
                      _NavTab(
                        label: 'Sign Up',
                        selected: _isSignUpSelected,
                        onTap: () => setState(() => _isSignUpSelected = true),
                      ),
                      const Spacer(),
                      Container(
                        width: 36,
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
                          size: 17,
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
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Sahaya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: ' 🌾',
                        style: TextStyle(fontSize: 22),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Join thousands of Sri Lankan farmers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom card — slides up with keyboard ────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        color: _kCardBg,
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // ── Card header ──────────────────────────
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
                                              'Sign Up',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                color: _kTextDark,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Fill in your details to get started',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _kTextMid,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _kGreen700.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.eco_rounded,
                                            color: _kGreen700,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 18),

                                    // ── Full Name ────────────────────────────
                                    const _FieldLabel(label: 'Full Name'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _kTextDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: 'Enter your full name',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      validator: (value) =>
                                          Validators.validateRequired(
                                              value, 'name'),
                                    ),

                                    const SizedBox(height: 12),

                                    // ── Email ────────────────────────────────
                                    const _FieldLabel(label: 'Email Address'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _kTextDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: 'you@example.com',
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      validator: Validators.validateEmail,
                                    ),

                                    const SizedBox(height: 12),

                                    // ── Phone ────────────────────────────────
                                    const _FieldLabel(label: 'Phone Number'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _kTextDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: '+94 7X XXX XXXX',
                                        icon: Icons.phone_outlined,
                                      ),
                                      validator: Validators.validatePhone,
                                    ),

                                    const SizedBox(height: 12),

                                    // ── Password ─────────────────────────────
                                    const _FieldLabel(label: 'Password'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _kTextDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: 'Create a strong password',
                                        icon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          splashRadius: 20,
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
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

                                    const SizedBox(height: 12),

                                    // ── Confirm Password ──────────────────────
                                    const _FieldLabel(
                                        label: 'Confirm Password'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) {
                                        final auth = Provider.of<AuthProvider>(
                                            context,
                                            listen: false);
                                        if (!auth.isLoading) _handleRegister();
                                      },
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _kTextDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: _fieldDecoration(
                                        hint: 'Re-enter your password',
                                        icon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          splashRadius: 20,
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: _kTextHint,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                          ),
                                        ),
                                      ),
                                      validator: _validateConfirmPassword,
                                    ),

                                    const SizedBox(height: 18),

                                    // ── Sign Up button ────────────────────────
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        final loading = authProvider.isLoading;
                                        return ElevatedButton(
                                          onPressed:
                                              loading ? null : _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _kGreen700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: loading
                                              ? const SizedBox(
                                                  height: 17,
                                                  width: 17,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'Create Account',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 14),

                                    // ── Log In link ───────────────────────────
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                              fontSize: 12, color: _kTextMid),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            final auth =
                                                Provider.of<AuthProvider>(
                                                    context,
                                                    listen: false);
                                            if (!auth.isLoading) {
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: const Text(
                                            'Log In',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _kGreen500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets (identical to login_screen.dart) ─────────────────────────

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
                selected ? Colors.white.withOpacity(0.30) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.55),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _kTextDark,
        letterSpacing: 0.1,
      ),
    );
  }
}
