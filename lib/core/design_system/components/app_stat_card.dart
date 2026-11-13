import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_card.dart';

/// LearnTZ Design System 2.0 — Canonical Metric / Statistics Card
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.trend,
    this.isTrendPositive = true,
    this.subtitle,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trend;
  final bool isTrendPositive;
  final String? subtitle;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveIconFg = iconColor ?? LearnTzColors.primary;
    final effectiveIconBg = iconBackgroundColor ?? LearnTzColors.primary50;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: LearnTzSpacing.cardPaddingDense,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LearnTzColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveIconBg,
                    borderRadius: LearnTzRadii.borderMd,
                  ),
                  child: Icon(icon, size: 20, color: effectiveIconFg),
                ),
              ],
            ],
          ),
          const SizedBox(height: LearnTzSpacing.sm),
          Text(
            value,
            style: LearnTzTypography.h2.copyWith(
              color: LearnTzColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (trend != null || subtitle != null) ...[
            const SizedBox(height: LearnTzSpacing.xs),
            Row(
              children: [
                if (trend != null) ...[
                  Icon(
                    isTrendPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isTrendPositive ? LearnTzColors.success : LearnTzColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend!,
                    style: LearnTzTypography.caption.copyWith(
                      color: isTrendPositive ? LearnTzColors.success : LearnTzColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
