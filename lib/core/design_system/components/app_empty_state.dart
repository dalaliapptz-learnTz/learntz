import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_button.dart';

/// LearnTZ Design System 2.0 — Canonical Empty State Placeholder
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconFg = iconColor ?? LearnTzColors.primary;
    final effectiveIconBg = iconBackgroundColor ?? LearnTzColors.primary50;

    return Center(
      child: Padding(
        padding: LearnTzSpacing.allXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: effectiveIconFg),
            ),
            const SizedBox(height: LearnTzSpacing.lg),
            Text(
              title,
              style: LearnTzTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: LearnTzColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LearnTzSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                style: LearnTzTypography.bodyRegular.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: LearnTzSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                size: AppButtonSize.md,
                variant: AppButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
