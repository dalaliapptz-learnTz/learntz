import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum AppBadgeVariant { neutral, primary, success, warning, error, info, accent }

enum AppBadgeSize { sm, md }

/// LearnTZ Design System 2.0 — Canonical Badge / Tag Component
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.variant = AppBadgeVariant.neutral,
    this.size = AppBadgeSize.md,
    this.icon,
  });

  final String label;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppBadgeVariant.neutral => (
        LearnTzColors.neutral100,
        LearnTzColors.neutral700,
        LearnTzColors.neutral300,
      ),
      AppBadgeVariant.primary => (
        LearnTzColors.primary50,
        LearnTzColors.primary700,
        LearnTzColors.primary200,
      ),
      AppBadgeVariant.success => (
        LearnTzColors.successBg,
        LearnTzColors.successText,
        LearnTzColors.successBorder,
      ),
      AppBadgeVariant.warning => (
        LearnTzColors.warningBg,
        LearnTzColors.warningText,
        LearnTzColors.warningBorder,
      ),
      AppBadgeVariant.error => (
        LearnTzColors.errorBg,
        LearnTzColors.errorText,
        LearnTzColors.errorBorder,
      ),
      AppBadgeVariant.info => (
        LearnTzColors.infoBg,
        LearnTzColors.infoText,
        LearnTzColors.infoBorder,
      ),
      AppBadgeVariant.accent => (
        LearnTzColors.accent100,
        LearnTzColors.accent900,
        LearnTzColors.accent300,
      ),
    };

    final (hPadding, vPadding, fontSize, iconSize) = size == AppBadgeSize.sm
        ? (8.0, 2.0, 11.0, 12.0)
        : (10.0, 4.0, 12.0, 14.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: LearnTzRadii.borderFull,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fgColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: LearnTzTypography.caption.copyWith(
              color: fgColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
