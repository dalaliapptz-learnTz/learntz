import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost, destructive }

enum AppButtonSize { sm, md, lg }

/// LearnTZ Design System 2.0 — Canonical Button Component
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final (height, horizontalPadding, fontSize) = switch (size) {
      AppButtonSize.sm => (LearnTzSpacing.buttonHeightSm, 12.0, 13.0),
      AppButtonSize.md => (LearnTzSpacing.buttonHeightMd, 16.0, 14.0),
      AppButtonSize.lg => (LearnTzSpacing.buttonHeightLg, 24.0, 15.0),
    };

    final isEnabled = onPressed != null && !isLoading;

    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppButtonVariant.primary => (
        isEnabled ? LearnTzColors.primary : LearnTzColors.neutral200,
        isEnabled ? Colors.white : LearnTzColors.neutral400,
        Colors.transparent,
      ),
      AppButtonVariant.secondary => (
        isEnabled ? LearnTzColors.secondary : LearnTzColors.neutral200,
        isEnabled ? Colors.white : LearnTzColors.neutral400,
        Colors.transparent,
      ),
      AppButtonVariant.outlined => (
        Colors.white,
        isEnabled ? LearnTzColors.textPrimary : LearnTzColors.neutral400,
        isEnabled ? LearnTzColors.border : LearnTzColors.neutral200,
      ),
      AppButtonVariant.ghost => (
        Colors.transparent,
        isEnabled ? LearnTzColors.textPrimary : LearnTzColors.neutral400,
        Colors.transparent,
      ),
      AppButtonVariant.destructive => (
        isEnabled ? LearnTzColors.error : LearnTzColors.neutral200,
        isEnabled ? Colors.white : LearnTzColors.neutral400,
        Colors.transparent,
      ),
    };

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: height * 0.4,
        height: height * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 4, color: fgColor),
            SizedBox(width: size == AppButtonSize.sm ? 6 : 8),
          ],
          Text(
            label,
            style: LearnTzTypography.button.copyWith(
              color: fgColor,
              fontSize: fontSize,
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: size == AppButtonSize.sm ? 6 : 8),
            Icon(trailingIcon, size: fontSize + 4, color: fgColor),
          ],
        ],
      );
    }

    final buttonWidget = AnimatedContainer(
      duration: LearnTzMotion.durationFast,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: LearnTzRadii.borderMd,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: LearnTzRadii.borderMd,
          child: Center(child: content),
        ),
      ),
    );

    // Ensure WCAG 2.2 AA mobile touch target minimum (48x48dp)
    final constrainedButton = isFullWidth
        ? SizedBox(width: double.infinity, child: buttonWidget)
        : buttonWidget;

    if (height < LearnTzSpacing.mobileMinTouchTarget) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: LearnTzSpacing.mobileMinTouchTarget,
        ),
        child: Center(child: constrainedButton),
      );
    }

    return constrainedButton;
  }
}
