import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// LearnTZ Design System 2.0 — Canonical Linear Progress Bar
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    super.key,
    this.label,
    this.showPercentage = false,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
  });

  final double value; // 0.0 to 1.0
  final String? label;
  final bool showPercentage;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final effectiveColor = color ?? LearnTzColors.secondary;
    final effectiveBg = backgroundColor ?? LearnTzColors.neutral200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LearnTzColors.textPrimary,
                  ),
                ),
              if (showPercentage)
                Text(
                  '$percent%',
                  style: LearnTzTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: effectiveColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: LearnTzSpacing.xs),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: clamped,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              backgroundColor: effectiveBg,
            ),
          ),
        ),
      ],
    );
  }
}

/// LearnTZ Design System 2.0 — Canonical Circular Progress Dial
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    required this.value,
    super.key,
    this.size = 64.0,
    this.strokeWidth = 6.0,
    this.centerText,
    this.color,
    this.backgroundColor,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final String? centerText;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final effectiveColor = color ?? LearnTzColors.primary;
    final effectiveBg = backgroundColor ?? LearnTzColors.neutral200;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              backgroundColor: effectiveBg,
            ),
          ),
          if (centerText != null)
            Text(
              centerText!,
              style: LearnTzTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: LearnTzColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
