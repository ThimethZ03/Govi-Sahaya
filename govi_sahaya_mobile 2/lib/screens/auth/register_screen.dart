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

// ── Translations ──────────────────────────────────────────────────
const Map<String, Map<String, String>> _tr = {
  'en': {
    'login': 'Login',
    'sign_up': 'Sign Up',
    'create_account': 'CREATE ACCOUNT',
    'tagline': 'Join the smart farming community',
    'register': 'Register',
    'subtitle': 'Fill in your details to get started',
    'name_label': 'Full Name',
    'name_hint': 'Enter your full name',
    'email_label': 'Email Address',
    'email_hint': 'you@example.com',
    'phone_label': 'Phone Number',
    'phone_hint': '+94 77 123 4567',
    'password_label': 'Password',
    'password_hint': 'Create a strong password',
    'confirm_label': 'Confirm Password',
    'confirm_hint': 'Re-enter your password',
    'submit': 'Create Account',
    'have_account': 'Already have an account? ',
    'log_in': 'Log In',
    'reg_failed': 'Registration failed',
    'verify_title': 'Verify Your Email',
    'verify_body': 'A verification link has been sent to:\n',
    'verify_body2':
        '\n\nClick the link to activate your account before logging in.',
    'go_login': 'Go to Login',
    'pw_mismatch': 'Passwords do not match',
    'pw_confirm_empty': 'Please confirm your password',
    'tap_to_expand': 'Tap to expand',
  },
  'si': {
    'login': 'පිවිසුම',
    'sign_up': 'ලියාපදිංචිය',
    'create_account': 'ගිණුම සාදන්න',
    'tagline': 'ස්මාර්ට් ගොවිතැන් ප්‍රජාවට සම්බන්ධ වන්න',
    'register': 'ලියාපදිංචි වන්න',
    'subtitle': 'ඔබගේ විස්තර ඇතුළු කරන්න',
    'name_label': 'සම්පූර්ණ නම',
    'name_hint': 'ඔබගේ නම ඇතුළු කරන්න',
    'email_label': 'විද්‍යුත් තැපෑල',
    'email_hint': 'you@example.com',
    'phone_label': 'දුරකතන අංකය',
    'phone_hint': '+94 77 123 4567',
    'password_label': 'මුරපදය',
    'password_hint': 'ශක්තිමත් මුරපදයක් සාදන්න',
    'confirm_label': 'මුරපදය තහවුරු කරන්න',
    'confirm_hint': 'මුරපදය නැවත ඇතුළු කරන්න',
    'submit': 'ගිණුම සාදන්න',
    'have_account': 'දැනටමත් ගිණුමක් තිබේද? ',
    'log_in': 'ඇතුල් වන්න',
    'reg_failed': 'ලියාපදිංචිය අසාර්ථකයි',
    'verify_title': 'ඔබගේ විද්‍යුත් තැපෑල තහවුරු කරන්න',
    'verify_body': 'සත්‍යාපන සබැඳිය යවන ලදී:\n',
    'verify_body2': '\n\nපිවිසීමට පෙර ගිණුම සක්‍රිය කරන්න.',
    'go_login': 'පිවිසීමට යන්න',
    'pw_mismatch': 'මුරපද ගැලපෙන්නේ නැත',
    'pw_confirm_empty': 'මුරපදය තහවුරු කරන්න',
    'tap_to_expand': 'ඔබීමට අතිරේකව',
  },
  'ta': {
    'login': 'உள்நுழைவு',
    'sign_up': 'பதிவு செய்க',
    'create_account': 'கணக்கு உருவாக்கு',
    'tagline': 'விவசாய சமூகத்தில் சேருங்கள்',
    'register': 'பதிவு செய்க',
    'subtitle': 'உங்கள் விவரங்களை உள்ளிடவும்',
    'name_label': 'முழு பெயர்',
    'name_hint': 'உங்கள் பெயரை உள்ளிடவும்',
    'email_label': 'மின்னஞ்சல்',
    'email_hint': 'you@example.com',
    'phone_label': 'தொலைபேசி எண்',
    'phone_hint': '+94 77 123 4567',
    'password_label': 'கடவுச்சொல்',
    'password_hint': 'வலுவான கடவுச்சொல் உருவாக்கவும்',
    'confirm_label': 'கடவுச்சொல் உறுதிப்படுத்தவும்',
    'confirm_hint': 'கடவுச்சொல்லை மீண்டும் உள்ளிடவும்',
    'submit': 'கணக்கு உருவாக்கு',
    'have_account': 'ஏற்கனவே கணக்கு உள்ளதா? ',
    'log_in': 'உள்நுழைக',
    'reg_failed': 'பதிவு தோல்வியடைந்தது',
    'verify_title': 'மின்னஞ்சலை சரிபார்க்கவும்',
    'verify_body': 'சரிபார்ப்பு இணைப்பு அனுப்பப்பட்டது:\n',
    'verify_body2': '\n\nஉள்நுழைவதற்கு முன் கணக்கை செயல்படுத்தவும்.',
    'go_login': 'உள்நுழைவுக்கு செல்லவும்',
    'pw_mismatch': 'கடவுச்சொற்கள் பொருந்தவில்லை',
    'pw_confirm_empty': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
    'tap_to_expand': 'விரிவாக அமுக்க',
  },
};

String _t(String lang, String key) => _tr[lang]?[key] ?? _tr['en']![key] ?? key;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _expanded = false;

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
    _fadeAnim = CurvedAnimation(parent: _entryCtrl!, curve: Curves.easeOut);
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryCtrl?.dispose();
    super.dispose();
  }

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

  Future<void> _handleRegister(String lang) async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoading) return;

    final ok = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _kCardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: _kGreen700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(lang, 'verify_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kTextDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '${_t(lang, 'verify_body')}${_emailController.text.trim()}'
            '${_t(lang, 'verify_body2')}',
            style: const TextStyle(fontSize: 13, height: 1.5, color: _kTextMid),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: Text(
                _t(lang, 'go_login'),
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } else {
      _snack(auth.errorMessage ?? _t(lang, 'reg_failed'), AppTheme.errorRed);
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: _kTextHint,
        fontWeight: FontWeight.w400,
      ),
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, size: 16, color: _kTextHint),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 42),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kGreen500, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final mq = MediaQuery.of(context);
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  Row(
                    children: [
                      _NavTab(
                        label: _t(lang, 'login'),
                        selected: false,
                        onTap: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.login),
                      ),
                      const SizedBox(width: 4),
                      _NavTab(
                        label: _t(lang, 'sign_up'),
                        selected: true,
                        onTap: () {},
                      ),
                      const Spacer(),
                      _LangChip(
                        current: lang,
                        onChanged: (v) =>
                            context.read<LanguageProvider>().setLanguage(v),
                      ),
                      const SizedBox(width: 8),
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
                  Row(
                    children: [
                      Container(width: 18, height: 1.5, color: _kGold),
                      const SizedBox(width: 8),
                      Text(
                        _t(lang, 'create_account'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Govi ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.4,
                        ),
                      ),
                      TextSpan(
                        text: 'Sahaya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      TextSpan(
                        text: ' 🌾',
                        style: TextStyle(fontSize: 19),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(lang, 'tagline'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.52),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom expandable card
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: _expanded
                        ? mq.size.height * 0.85
                        : mq.size.height * 0.45,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          color: isDark
                              ? AppTheme.darkCard.withOpacity(0.95)
                              : _kCardBg,
                          child: Column(
                            children: [
                              // Header with expand button
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _expanded = !_expanded),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 16, 24, 12),
                                  child: Row(
                                    children: [
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
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _t(lang, 'register'),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: _kTextDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _t(lang, 'subtitle'),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: _kTextMid,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: _expanded ? 0.5 : 0.0,
                                        duration:
                                            const Duration(milliseconds: 250),
                                        child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 24,
                                          color: _kTextHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Form content (when expanded)
                              if (_expanded)
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 0, 24, 24),
                                    physics: const ClampingScrollPhysics(),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _FieldLabel(
                                              label: _t(lang, 'name_label')),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _nameController,
                                            textInputAction:
                                                TextInputAction.next,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _kTextDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: _fieldDecoration(
                                              hint: _t(lang, 'name_hint'),
                                              icon:
                                                  Icons.person_outline_rounded,
                                            ),
                                            validator: (v) =>
                                                Validators.validateRequired(
                                                    v, 'name'),
                                          ),
                                          const SizedBox(height: 14),
                                          _FieldLabel(
                                              label: _t(lang, 'email_label')),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            style: const TextStyle(
                                              fontSize: 13,
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
                                          _FieldLabel(
                                              label: _t(lang, 'phone_label')),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            textInputAction:
                                                TextInputAction.next,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _kTextDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: _fieldDecoration(
                                              hint: _t(lang, 'phone_hint'),
                                              icon: Icons.phone_outlined,
                                            ),
                                            validator: Validators.validatePhone,
                                          ),
                                          const SizedBox(height: 14),
                                          _FieldLabel(
                                              label:
                                                  _t(lang, 'password_label')),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            textInputAction:
                                                TextInputAction.next,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _kTextDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: _fieldDecoration(
                                              hint: _t(lang, 'password_hint'),
                                              icon: Icons.lock_outline_rounded,
                                              suffixIcon: IconButton(
                                                splashRadius: 18,
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  size: 16,
                                                  color: _kTextHint,
                                                ),
                                                onPressed: () => setState(() =>
                                                    _obscurePassword =
                                                        !_obscurePassword),
                                              ),
                                            ),
                                            validator:
                                                Validators.validatePassword,
                                          ),
                                          const SizedBox(height: 14),
                                          _FieldLabel(
                                              label: _t(lang, 'confirm_label')),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller:
                                                _confirmPasswordController,
                                            obscureText:
                                                _obscureConfirmPassword,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) =>
                                                _handleRegister(lang),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _kTextDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: _fieldDecoration(
                                              hint: _t(lang, 'confirm_hint'),
                                              icon: Icons.lock_outline_rounded,
                                              suffixIcon: IconButton(
                                                splashRadius: 18,
                                                icon: Icon(
                                                  _obscureConfirmPassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  size: 16,
                                                  color: _kTextHint,
                                                ),
                                                onPressed: () => setState(() =>
                                                    _obscureConfirmPassword =
                                                        !_obscureConfirmPassword),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return _t(
                                                    lang, 'pw_confirm_empty');
                                              }
                                              if (v !=
                                                  _passwordController.text) {
                                                return _t(lang, 'pw_mismatch');
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),
                                          Consumer<AuthProvider>(
                                            builder: (context, auth, _) {
                                              final loading = auth.isLoading;
                                              return ElevatedButton(
                                                onPressed: loading
                                                    ? null
                                                    : () =>
                                                        _handleRegister(lang),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _kGreen700,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 13),
                                                  elevation: 0,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: loading
                                                    ? const SizedBox(
                                                        height: 16,
                                                        width: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text(
                                                        _t(lang, 'submit'),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _t(lang, 'have_account'),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _kTextMid,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => Navigator
                                                    .pushReplacementNamed(
                                                        context,
                                                        AppRoutes.login),
                                                child: Text(
                                                  _t(lang, 'log_in'),
                                                  style: const TextStyle(
                                                    fontSize: 11,
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
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Tabs ───────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
                selected ? Colors.white.withOpacity(0.28) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withOpacity(0.52),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── Label ──────────────────────────────────────────────────────
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
