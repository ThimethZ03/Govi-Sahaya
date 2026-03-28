import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/validators.dart';

// ── Design tokens ─────────────────────────────────────────────────
const _kGreen700 = Color(0xFF1E4D2E);
const _kGreen500 = Color(0xFF2D6B42);
const _kGold = Color(0xFFCFA843);
const _kCardBg = Color(0xFFF7F6F2);
const _kBorder = Color(0xFFE2E8E4);
const _kTextDark = Color(0xFF0F2318);
const _kTextMid = Color(0xFF5A6B61);
const _kTextHint = Color(0xFFADB8B2);

// ── Translation strings ───────────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'en': {
    'login': 'Login',
    'sign_up': 'Sign Up',
    'welcome_back': 'WELCOME BACK',
    'tagline': 'Your smart farming companion',
    'sign_in': 'Sign In',
    'subtitle': 'Enter your credentials to continue',
    'email_label': 'Email Address',
    'email_hint': 'you@example.com',
    'password_label': 'Password',
    'password_hint': '••••••••',
    'forgot': 'Forgot password?',
    'or_continue': 'or continue with',
    'google': 'Google',
    'log_in': 'Log In',
    'no_account': "Don't have an account? ",
    'reset_title': 'Reset Password',
    'reset_desc': "Enter your registered email. We'll send a reset link.",
    'reset_hint': 'Enter your email',
    'cancel': 'Cancel',
    'send_link': 'Send Link',
    'welcome_snack': 'Welcome back! 🌾',
    'google_snack': 'Welcome to Govi Sahaya! 🌾',
    'login_failed': 'Login failed',
    'reset_sent': '📧 Reset link sent to',
    'reset_inbox': '. Check your inbox.',
  },
  'si': {
    'login': 'පිවිසුම',
    'sign_up': 'ලියාපදිංචිය',
    'welcome_back': 'නැවත සාදරයෙන්',
    'tagline': 'ඔබේ සෙෙලෙකු ගොවිතැන් සහායකයා',
    'sign_in': 'ප්‍රවේශ වන්න',
    'subtitle': 'ඔබගේ අක්තපත්‍ර ඇතුළු කරන්න',
    'email_label': 'විද්‍යුත් තැපෑල',
    'email_hint': 'you@example.com',
    'password_label': 'මුරපදය',
    'password_hint': '••••••••',
    'forgot': 'මුරපදය අමතකද?',
    'or_continue': 'හෝ මේ ආකාරයෙන් ඉදිරියට යන්න',
    'google': 'ගූගල්',
    'log_in': 'ඇතුල් වන්න',
    'no_account': 'ගිණුමක් නැද්ද? ',
    'reset_title': 'මුරපදය යළි සකසන්න',
    'reset_desc': 'ලියාපදිංචි විද්‍යුත් තැපෑල ඇතුළු කරන්න.',
    'reset_hint': 'විද්‍යුත් තැපෑල ඇතුළු කරන්න',
    'cancel': 'අවලංගු කරන්න',
    'send_link': 'සබැඳිය යවන්න',
    'welcome_snack': 'නැවත සාදරයෙන් පිළිගනිමු! 🌾',
    'google_snack': 'ගොවි සහය වෙත සාදරයෙන්! 🌾',
    'login_failed': 'පිවිසීම අසාර්ථකයි',
    'reset_sent': '📧 සබැඳිය යවන ලදී',
    'reset_inbox': '. ඔබගේ inbox පරීක්ෂා කරන්න.',
  },
  'ta': {
    'login': 'உள்நுழைவு',
    'sign_up': 'பதிவு செய்க',
    'welcome_back': 'மீண்டும் வரவேற்கிறோம்',
    'tagline': 'உங்கள் விவசாய உதவியாளர்',
    'sign_in': 'உள்நுழைக',
    'subtitle': 'உங்கள் விவரங்களை உள்ளிடவும்',
    'email_label': 'மின்னஞ்சல்',
    'email_hint': 'you@example.com',
    'password_label': 'கடவுச்சொல்',
    'password_hint': '••••••••',
    'forgot': 'கடவுச்சொல் மறந்தீர்களா?',
    'or_continue': 'அல்லது தொடரவும்',
    'google': 'கூகிள்',
    'log_in': 'உள்நுழைக',
    'no_account': 'கணக்கு இல்லையா? ',
    'reset_title': 'கடவுச்சொல் மீட்டமைக்க',
    'reset_desc': 'பதிவு செய்த மின்னஞ்சலை உள்ளிடவும்.',
    'reset_hint': 'மின்னஞ்சல் உள்ளிடவும்',
    'cancel': 'ரத்து செய்',
    'send_link': 'இணைப்பு அனுப்பு',
    'welcome_snack': 'மீண்டும் வரவேற்கிறோம்! 🌾',
    'google_snack': 'கோவி சஹாயாவிற்கு வரவேற்கிறோம்! 🌾',
    'login_failed': 'உள்நுழைவு தோல்வியடைந்தது',
    'reset_sent': '📧 இணைப்பு அனுப்பப்பட்டது',
    'reset_inbox': '. உங்கள் inbox பார்க்கவும்.',
  },
};

// ── Helper ────────────────────────────────────────────────────────
String _t(String lang, String key) => _tr[lang]?[key] ?? _tr['en']![key] ?? key;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoginSelected = true;

  AnimationController? _entryCtrl;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _entryCtrl!,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl!,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryCtrl?.dispose();
    super.dispose();
  }

  // ── Snackbar ────────────────────────────────────────────────────
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

  // ── Login ───────────────────────────────────────────────────────
  Future<void> _handleLogin(String lang) async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoading) return;
    final ok = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      _snack(_t(lang, 'welcome_snack'), AppTheme.successGreen);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      _snack(
        auth.errorMessage ?? _t(lang, 'login_failed'),
        AppTheme.errorRed,
      );
    }
  }

  // ── Google sign-in ──────────────────────────────────────────────
  Future<void> _handleGoogleSignIn(String lang) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoading) return;
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _snack(_t(lang, 'google_snack'), AppTheme.successGreen);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (auth.errorMessage != null) {
      _snack(auth.errorMessage!, AppTheme.errorRed);
    }
  }

  // ── Forgot password dialog ──────────────────────────────────────
  Future<void> _handleForgotPassword(String lang) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        final resetCtrl = TextEditingController(
          text: _emailController.text.trim(),
        );
        return AlertDialog(
          backgroundColor: _kCardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _t(lang, 'reset_title'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _kTextDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t(lang, 'reset_desc'),
                style: const TextStyle(fontSize: 13, color: _kTextMid),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: resetCtrl,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: const TextStyle(fontSize: 14, color: _kTextDark),
                decoration: InputDecoration(
                  hintText: _t(lang, 'reset_hint'),
                  hintStyle: const TextStyle(fontSize: 13, color: _kTextHint),
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    size: 17,
                    color: _kTextHint,
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t(lang, 'cancel'),
                  style: const TextStyle(color: _kTextMid)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen700,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final email = resetCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                final auth = Provider.of<AuthProvider>(context, listen: false);
                try {
                  await auth.sendPasswordResetEmail(email);
                  if (!mounted) return;
                  _snack(
                    '${_t(lang, 'reset_sent')} $email'
                    '${_t(lang, 'reset_inbox')}',
                    AppTheme.successGreen,
                  );
                } catch (e) {
                  if (!mounted) return;
                  _snack(
                    e.toString().replaceAll('Exception: ', ''),
                    AppTheme.errorRed,
                  );
                }
              },
              child: Text(_t(lang, 'send_link'),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  // ── Field decoration ────────────────────────────────────────────
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
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.6),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final mq = MediaQuery.of(context);
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset(
              'assets/images/rice.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth: 800,
            ),
          ),

          // Gradient overlay
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

          // Hero text + nav
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
                        label: _t(lang, 'login'),
                        selected: _isLoginSelected,
                        onTap: () => setState(() => _isLoginSelected = true),
                      ),
                      const SizedBox(width: 4),
                      _NavTab(
                        label: _t(lang, 'sign_up'),
                        selected: !_isLoginSelected,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                      ),
                      const Spacer(),

                      // Language selector (text pill, no icon)
                      _LangChip(
                        current: lang,
                        onChanged: (v) =>
                            context.read<LanguageProvider>().setLanguage(v),
                      ),

                      const SizedBox(width: 8),

                      // Profile avatar with image display
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final user = auth.user;
                          final userProfileImage = user?.profileImageUrl;
                          return Container(
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
                            child: userProfileImage != null &&
                                    userProfileImage.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      userProfileImage,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                        Icons.person_outline_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const Icon(
                                          Icons.person_outline_rounded,
                                          color: Colors.white,
                                          size: 17,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                          );
                        },
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
                        _t(lang, 'welcome_back'),
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

                  // App name (always fixed branding)
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
                    _t(lang, 'tagline'),
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

          // Bottom card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
              child: FadeTransition(
                opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
                child: SlideTransition(
                  position:
                      _slideAnim ?? const AlwaysStoppedAnimation(Offset.zero),
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
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
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
                                          Text(
                                            _t(lang, 'sign_in'),
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: _kTextDark,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _t(lang, 'subtitle'),
                                            style: const TextStyle(
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

                                  const SizedBox(height: 20),

                                  // Email
                                  _FieldLabel(label: _t(lang, 'email_label')),
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
                                      hint: _t(lang, 'email_hint'),
                                      icon: Icons.mail_outline_rounded,
                                    ),
                                    validator: Validators.validateEmail,
                                  ),

                                  const SizedBox(height: 14),

                                  // Password
                                  _FieldLabel(
                                      label: _t(lang, 'password_label')),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      final auth = Provider.of<AuthProvider>(
                                          context,
                                          listen: false);
                                      if (!auth.isLoading) _handleLogin(lang);
                                    },
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _kTextDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: _fieldDecoration(
                                      hint: _t(lang, 'password_hint'),
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
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    validator: Validators.validatePassword,
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () =>
                                          _handleForgotPassword(lang),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        _t(lang, 'forgot'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _kGreen500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Divider
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                            color: _kBorder, thickness: 1),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          _t(lang, 'or_continue'),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _kTextHint,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
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
                                                  : () =>
                                                      _handleGoogleSignIn(lang),
                                              icon: loading
                                                  ? const SizedBox(
                                                      width: 14,
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
                                                      width: 17,
                                                    ),
                                              label: Text(
                                                _t(lang, 'google'),
                                                style: const TextStyle(
                                                  color: _kTextDark,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 13),
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
                                                  : () => _handleLogin(lang),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _kGreen700,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                                  : Text(
                                                      _t(lang, 'log_in'),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _t(lang, 'no_account'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _kTextMid,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          final auth =
                                              Provider.of<AuthProvider>(context,
                                                  listen: false);
                                          if (!auth.isLoading) {
                                            Navigator.pushNamed(
                                                context, AppRoutes.register);
                                          }
                                        },
                                        child: Text(
                                          _t(lang, 'sign_up'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _kGreen500,
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

// ── Language chip ─────────────────────────────────────────────────
class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.current,
    required this.onChanged,
  });
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const langs = {'en': 'EN', 'si': 'සි', 'ta': 'த'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          icon: const SizedBox.shrink(),
          dropdownColor: _kGreen700,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          items: langs.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Nav tab ───────────────────────────────────────────────────────
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

// ── Field label ───────────────────────────────────────────────────
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
