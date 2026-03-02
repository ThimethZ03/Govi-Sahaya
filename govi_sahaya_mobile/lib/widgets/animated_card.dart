import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final int delay;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.child,
    this.delay = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: delay),
      // ✅ FIX: Replaced Card (which inherits global elevation/shadow)
      // with a plain ClipRRect + Material — no shadow bleed into popup
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
