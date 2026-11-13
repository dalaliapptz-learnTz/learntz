import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_button.dart';

/// LearnTZ Design System 2.0 — Canonical Modal Dialog
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    super.key,
    this.icon,
    this.description,
    this.content,
    this.confirmLabel = 'Confirm',
    this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final String title;
  final IconData? icon;
  final String? description;
  final Widget? content;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool isLoading;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    IconData? icon,
    String? description,
    Widget? content,
    String confirmLabel = 'Confirm',
    VoidCallback? onConfirm,
    String? cancelLabel = 'Cancel',
    VoidCallback? onCancel,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppDialog(
        title: title,
        icon: icon,
        description: description,
        content: content,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm ?? () => Navigator.of(ctx).pop(true),
        cancelLabel: cancelLabel,
        onCancel: onCancel ?? () => Navigator.of(ctx).pop(false),
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: LearnTzRadii.borderXl),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: LearnTzSpacing.dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDestructive ? LearnTzColors.errorBg : LearnTzColors.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDestructive ? LearnTzColors.error : LearnTzColors.primary,
                  ),
                ),
                const SizedBox(height: LearnTzSpacing.md),
              ],
              Text(
                title,
                style: LearnTzTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LearnTzColors.textPrimary,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: LearnTzSpacing.xs),
                Text(
                  description!,
                  style: LearnTzTypography.bodyRegular.copyWith(
                    color: LearnTzColors.textSecondary,
                  ),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: LearnTzSpacing.md),
                content!,
              ],
              const SizedBox(height: LearnTzSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelLabel != null) ...[
                    AppButton(
                      label: cancelLabel!,
                      onPressed: isLoading ? null : onCancel,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.md,
                    ),
                    const SizedBox(width: LearnTzSpacing.sm),
                  ],
                  AppButton(
                    label: confirmLabel,
                    onPressed: onConfirm,
                    variant: isDestructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    size: AppButtonSize.md,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
