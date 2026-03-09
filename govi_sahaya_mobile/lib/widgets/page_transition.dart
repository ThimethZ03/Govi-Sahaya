import 'package:flutter/material.dart';

/// Enum for different transition types.
/// You can keep this for flexibility, but recommended default is [slide].
enum PageTransitionType {
  fade,
  scale,
  rotate,
  slide,
  slideUp,
  slideDown,
  slideLeft,
}

/// Lightweight, GPU‑friendly page transition.
/// Default: subtle slide‑from‑right + fade (good performance on low‑end devices).
class CustomPageTransition extends PageRouteBuilder {
  final Widget child;
  final PageTransitionType type;

  CustomPageTransition({
    required this.child,
    this.type = PageTransitionType.slide,
  }) : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use curved animations for smoother feel.
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: curved,
          child: child,
        );

      case PageTransitionType.scale:
        // Avoid scaling from 0 → 1 (expensive & can look janky).
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );

      case PageTransitionType.rotate:
        // Very subtle rotation to avoid motion sickness and jank.
        return FadeTransition(
          opacity: curved,
          child: RotationTransition(
            turns: Tween<double>(begin: -0.01, end: 0.0).animate(curved),
            child: child,
          ),
        );

      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );

      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -0.08),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );

      case PageTransitionType.slideLeft:
      case PageTransitionType.slide:
        // Recommended default: tiny horizontal slide + fade.
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
    }
  }
}

/// Simple “best default” route you can use directly if you don't need enum.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            );
          },
        );
}

// Custom Page Route with multiple effects (kept, but tuned to be lighter).
class FancyPageRoute extends PageRouteBuilder {
  final Widget child;

  FancyPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: curved,
        child: child,
      ),
    );
  }
}

// Hero Dialog Route (unchanged logic, already light).
class HeroDialogRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  HeroDialogRoute({
    required this.builder,
    super.settings,
  }) : super(fullscreenDialog: false);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: child,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  String? get barrierLabel => 'Dismiss';
}

// Shared Axis–style transition, also tuned for subtle motion.
class SharedAxisPageRoute extends PageRouteBuilder {
  final Widget child;

  SharedAxisPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
