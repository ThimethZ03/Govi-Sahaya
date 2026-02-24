import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignUpSelected = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully! 🌾'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ✅ same style idea as login (bigger typing + compact but readable)
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      isDense: true,
      prefixIcon: Icon(icon, size: 18),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ✅ Background image like login (blended)
          SizedBox.expand(
            child: Image.asset(
              'assets/images/rice.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: 720,
            ),
          ),

          // ✅ Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // ✅ Top bar (same size as login)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => setState(() => _isSignUpSelected = true),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: _isSignUpSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              decoration: _isSignUpSelected
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Header
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CREATE ACCOUNT\nGovi Sahaya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),

                  // ✅ Container can go UP (less gap)
                  SizedBox(height: size.height * 0.08),

                  // ✅ Bottom container (NO 30px down offset, so it sits higher)
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height:
                            size.height * 0.80, // a bit taller since it's up
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(26),
                            topRight: Radius.circular(26),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
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
                                padding:
                                    const EdgeInsets.fromLTRB(18, 14, 18, 10),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Name
                                      const Text(
                                        'Your Name',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _nameController,
                                        style: const TextStyle(fontSize: 15),
                                        decoration: _fieldDecoration(
                                          hint: 'Enter your full name',
                                          icon: Icons.person_outline,
                                        ),
                                        validator: (value) =>
                                            Validators.validateRequired(
                                                value, 'name'),
                                      ),
                                      const SizedBox(height: 10),

                                      // Email
                                      const Text(
                                        'Your Email',
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
                                          hint: 'Enter your email',
                                          icon: Icons.email_outlined,
                                        ),
                                        validator: Validators.validateEmail,
                                      ),
                                      const SizedBox(height: 10),

                                      // Phone
                                      const Text(
                                        'Phone Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(fontSize: 15),
                                        decoration: _fieldDecoration(
                                          hint: 'Enter your phone number',
                                          icon: Icons.phone_outlined,
                                        ),
                                        validator: Validators.validatePhone,
                                      ),
                                      const SizedBox(height: 10),

                                      // Password
                                      const Text(
                                        'Password',
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
                                        style: const TextStyle(fontSize: 15),
                                        decoration: _fieldDecoration(
                                          hint: 'Create a strong password',
                                          icon: Icons.lock_outline,
                                          suffixIcon: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
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
                                        validator: Validators.validatePassword,
                                      ),
                                      const SizedBox(height: 10),

                                      // Confirm password
                                      const Text(
                                        'Confirm Password',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        style: const TextStyle(fontSize: 15),
                                        decoration: _fieldDecoration(
                                          hint: 'Re-enter your password',
                                          icon: Icons.lock_outline,
                                          suffixIcon: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              size: 18,
                                            ),
                                            onPressed: () => setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            }),
                                          ),
                                        ),
                                        validator: _validateConfirmPassword,
                                      ),

                                      const SizedBox(height: 12),

                                      // ✅ ONLY Sign Up button (as you requested)
                                      Consumer<AuthProvider>(
                                        builder:
                                            (context, authProvider, child) {
                                          final loading =
                                              authProvider.isLoading;

                                          return ElevatedButton(
                                            onPressed: loading
                                                ? null
                                                : _handleRegister,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.primaryGreen,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                                                : const Text(
                                                    'Sign Up',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 6),

                                      // bottom link (kept)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Already have an account? ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Log In',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryGreen,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
