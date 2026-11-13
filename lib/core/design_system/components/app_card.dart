import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum AppCardVariant { flat, outlined, elevated, interactive }

/// LearnTZ Design System 2.0 — Canonical Card Component
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.variant = AppCardVariant.outlined,
    this.padding = LearnTzSpacing.cardPadding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? LearnTzRadii.borderLg;
    final isClickable = onTap != null || variant == AppCardVariant.interactive;

    final (bgColor, border, shadows) = switch (variant) {
      AppCardVariant.flat => (
        backgroundColor ?? Colors.white,
        Border.all(color: Colors.transparent),
        LearnTzShadows.none,
      ),
      AppCardVariant.outlined => (
        backgroundColor ?? Colors.white,
        Border.all(color: borderColor ?? LearnTzColors.border, width: 1.0),
        LearnTzShadows.none,
      ),
      AppCardVariant.elevated => (
        backgroundColor ?? Colors.white,
        Border.all(color: (borderColor ?? LearnTzColors.border).withValues(alpha: 0.5)),
        LearnTzShadows.md,
      ),
      AppCardVariant.interactive => (
        backgroundColor ?? Colors.white,
        Border.all(color: borderColor ?? LearnTzColors.border, width: 1.0),
        LearnTzShadows.sm,
      ),
    };

    final container = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: isClickable ? onTap : null,
          borderRadius: effectiveRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return container;
  }
}
