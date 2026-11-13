import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_badge.dart';
import 'app_card.dart';

/// LearnTZ Design System 2.0 — Educational Lesson Card
class AppLessonCard extends StatelessWidget {
  const AppLessonCard({
    required this.title,
    required this.subject,
    required this.durationMinutes,
    super.key,
    this.isCompleted = false,
    this.isFreePreview = false,
    this.isLocked = false,
    this.orderIndex,
    this.onTap,
  });

  final String title;
  final String subject;
  final int durationMinutes;
  final bool isCompleted;
  final bool isFreePreview;
  final bool isLocked;
  final int? orderIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.interactive,
      padding: LearnTzSpacing.cardPaddingDense,
      onTap: isLocked ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted
                  ? LearnTzColors.successBg
                  : (isLocked ? LearnTzColors.neutral100 : LearnTzColors.primary50),
              borderRadius: LearnTzRadii.borderMd,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : (isLocked ? Icons.lock_outline_rounded : Icons.menu_book_rounded),
              color: isCompleted
                  ? LearnTzColors.success
                  : (isLocked ? LearnTzColors.neutral400 : LearnTzColors.primary),
              size: 22,
            ),
          ),
          const SizedBox(width: LearnTzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      subject,
                      style: LearnTzTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: LearnTzColors.primary700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${durationMinutes}m',
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                    if (isFreePreview && !isCompleted) ...[
                      const SizedBox(width: 6),
                      const AppBadge(
                        label: 'Free',
                        variant: AppBadgeVariant.success,
                        size: AppBadgeSize.sm,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  orderIndex != null ? '$orderIndex. $title' : title,
                  style: LearnTzTypography.bodyRegular.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isLocked ? LearnTzColors.neutral400 : LearnTzColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isLocked ? LearnTzColors.neutral300 : LearnTzColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
