import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class NeonToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const NeonToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value
              ? (LinearGradient(
            colors: [
              activeColor ?? AppColors.purple,
              activeColor ?? AppColors.pink,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ))
              : null,
          color: value ? null : AppColors.textMuted.withOpacity(0.3),
          boxShadow: value
              ? [
            BoxShadow(
              color: (activeColor ?? AppColors.purple).withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 0,
            )
          ]
              : [],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}