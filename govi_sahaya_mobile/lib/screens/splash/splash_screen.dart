import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/network/api_client.dart';
import '../../services/backend_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo animation ───────────────────────────────────────────
  late AnimationController _logoController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _rotateAnim;

  // ── Shimmer animation ────────────────────────────────────────
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  // ── Particle animation ───────────────────────────────────────
  late AnimationController _particleController;

  // ── Progress bar animation ───────────────────────────────────
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  // ── Ring pulse animation ─────────────────────────────────────
  late AnimationController _ringController;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _buildParticles();
    _initAnimations();
    _navigate();
  }

  void _buildParticles() {
    final rng = math.Random();
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 6 + 3,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.5 + 0.2,
        angle: rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _initAnimations() {
    // Logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _rotateAnim = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Shimmer
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Particles
    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    // Progress bar
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Ring pulse
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: false);
    _ringScale = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    // Start all
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;

    await ApiClient().init();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      try {
        await firebaseUser.reload();
      } catch (_) {}

      final refreshedUser = FirebaseAuth.instance.currentUser;

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

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20), // deep forest green
              Color(0xFF2E7D32), // AppTheme.darkGreen
              Color(0xFF388E3C), // mid green
              Color(0xFF1A237E), // deep blue-green at bottom
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Floating particles ──────────────────────────────
            AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                );
              },
            ),

            // ── Top decorative arc ──────────────────────────────
            Positioned(
              top: -size.width * 0.3,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 1.2,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // ── Bottom decorative arc ───────────────────────────
            Positioned(
              bottom: -size.width * 0.4,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 1.3,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // ── Main content ────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Logo section ────────────────────────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _logoController,
                      builder: (_, child) {
                        return Transform.rotate(
                          angle: _rotateAnim.value,
                          child: Transform.scale(
                            scale: _scaleAnim.value,
                            child: Opacity(
                              opacity: _fadeAnim.value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing ring
                          AnimatedBuilder(
                            animation: _ringController,
                            builder: (_, __) {
                              return Transform.scale(
                                scale: _ringScale.value,
                                child: Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white
                                          .withOpacity(_ringOpacity.value),
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Outer glow ring
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.04),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                          ),

                          // Inner circle with shimmer
                          ClipOval(
                            child: AnimatedBuilder(
                              animation: _shimmerAnim,
                              builder: (_, child) {
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: const [
                                        Colors.transparent,
                                        Colors.white24,
                                        Colors.transparent,
                                      ],
                                      stops: [
                                        (_shimmerAnim.value - 0.5)
                                            .clamp(0.0, 1.0),
                                        _shimmerAnim.value.clamp(0.0, 1.0),
                                        (_shimmerAnim.value + 0.5)
                                            .clamp(0.0, 1.0),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.srcATop,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 155,
                                height: 155,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.agriculture_rounded,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  // ── App name ────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    duration: const Duration(milliseconds: 700),
                    child: Text(
                      AppConstants.appNameSinhala,
                      style: AppTheme.sinhalaText(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── English subtitle ─────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    duration: const Duration(milliseconds: 700),
                    child: const Text(
                      'GOVI SAHAYA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                        letterSpacing: 6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Divider line ─────────────────────────────
                  FadeIn(
                    delay: const Duration(milliseconds: 1000),
                    child: Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Slogan ───────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 1100),
                    duration: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        AppConstants.appSlogan,
                        textAlign: TextAlign.center,
                        style: AppTheme.sinhalaText(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Progress bar ─────────────────────────────
                  FadeIn(
                    delay: const Duration(milliseconds: 1400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60.0),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (_, __) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _progressAnim.value,
                                  minHeight: 3,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.15),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (_, __) {
                              final pct = (_progressAnim.value * 100).toInt();
                              return Text(
                                '$pct%',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Powered by Dartis Dynamics ───────────────
                  FadeIn(
                    delay: const Duration(milliseconds: 1600),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28.0),
                      child: Column(
                        children: [
                          Text(
                            'POWERED BY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.35),
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF64B5F6),
                                      Color(0xFF1565C0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.code_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                'Dartis Dynamics',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
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
          ],
        ),
      ),
    );
  }
}

// ── Particle data model ──────────────────────────────────────────────
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double angle;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
  });
}

// ── Particle painter ─────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y + p.speed * progress) % 1.0;
      final dx = p.x + math.sin(progress * math.pi * 2 + p.angle) * 0.03;

      final paint = Paint()
        ..color = Colors.white.withOpacity(p.opacity * (1 - dy * 0.4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        p.size * (0.8 + math.sin(progress * math.pi * 2 + p.angle) * 0.2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
