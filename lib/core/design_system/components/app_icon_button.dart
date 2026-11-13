import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum AppIconButtonVariant { ghost, filled, outlined }

/// LearnTZ Design System 2.0 — Accessible Icon Button
/// Enforces WCAG 2.2 AA 48x48dp minimum touch target.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.variant = AppIconButtonVariant.ghost,
    this.size = 40.0,
    this.iconSize,
    this.color,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonVariant variant;
  final double size;
  final double? iconSize;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (size * 0.55);
    final isEnabled = onPressed != null;

    final (defaultBg, defaultFg, defaultBorder) = switch (variant) {
      AppIconButtonVariant.ghost => (
        Colors.transparent,
        color ?? LearnTzColors.textPrimary,
        Colors.transparent,
      ),
      AppIconButtonVariant.filled => (
        backgroundColor ?? LearnTzColors.primary50,
        color ?? LearnTzColors.primary,
        Colors.transparent,
      ),
      AppIconButtonVariant.outlined => (
        Colors.white,
        color ?? LearnTzColors.textPrimary,
        LearnTzColors.border,
      ),
    };

    final buttonCore = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isEnabled ? defaultBg : LearnTzColors.neutral100,
        shape: BoxShape.circle,
        border: Border.all(
          color: isEnabled ? defaultBorder : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: effectiveIconSize,
              color: isEnabled ? defaultFg : LearnTzColors.neutral400,
            ),
          ),
        ),
      ),
    );

    Widget widget = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: LearnTzSpacing.mobileMinTouchTarget,
        minHeight: LearnTzSpacing.mobileMinTouchTarget,
      ),
      child: Center(child: buttonCore),
    );

    if (tooltip != null) {
      widget = Tooltip(message: tooltip!, child: widget);
    }

    return widget;
  }
}
