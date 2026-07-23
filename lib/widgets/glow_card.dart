import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? glowColor;
  final double borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlowCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
    this.borderRadius = 20,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient ??
              LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (glowColor ?? AppColors.purple).withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}