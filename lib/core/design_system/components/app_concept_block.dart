import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum ConceptBlockType { tip, note, warning, definition, example }

/// LearnTZ Design System 2.0 — Educational Concept Block
class AppConceptBlock extends StatelessWidget {
  const AppConceptBlock({
    required this.type,
    required this.content,
    super.key,
    this.title,
    this.term,
    this.pronunciation,
    this.steps = const [],
    this.takeaway,
  });

  final ConceptBlockType type;
  final String content;
  final String? title;
  final String? term;
  final String? pronunciation;
  final List<String> steps;
  final String? takeaway;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (type) {
      ConceptBlockType.tip => (
        LearnTzColors.primary50,
        LearnTzColors.primary200,
        LearnTzColors.primary700,
        Icons.lightbulb_outline_rounded,
      ),
      ConceptBlockType.note => (
        LearnTzColors.neutral100,
        LearnTzColors.neutral300,
        LearnTzColors.neutral800,
        Icons.info_outline_rounded,
      ),
      ConceptBlockType.warning => (
        LearnTzColors.warningBg,
        LearnTzColors.warningBorder,
        LearnTzColors.warningText,
        Icons.warning_amber_rounded,
      ),
      ConceptBlockType.definition => (
        LearnTzColors.secondary50,
        LearnTzColors.secondary200,
        LearnTzColors.secondary900,
        Icons.menu_book_rounded,
      ),
      ConceptBlockType.example => (
        Colors.white,
        LearnTzColors.border,
        LearnTzColors.textPrimary,
        Icons.psychology_outlined,
      ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: LearnTzSpacing.cardPaddingDense,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: LearnTzRadii.borderLg,
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                title ?? _defaultTitle(type),
                style: LearnTzTypography.bodyRegular.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (term != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: border),
                    borderRadius: LearnTzRadii.borderFull,
                  ),
                  child: Text(
                    term!,
                    style: LearnTzTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (pronunciation != null) ...[
            const SizedBox(height: 4),
            Text(
              '/$pronunciation/',
              style: LearnTzTypography.caption.copyWith(
                fontStyle: FontStyle.italic,
                color: LearnTzColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            content,
            style: LearnTzTypography.bodyRegular.copyWith(
              color: LearnTzColors.textPrimary,
              height: 1.55,
            ),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (int i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: fg.withValues(alpha: 0.15),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: LearnTzTypography.bodyRegular.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (takeaway != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.08),
                borderRadius: LearnTzRadii.borderMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Takeaway: $takeaway',
                      style: LearnTzTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _defaultTitle(ConceptBlockType type) => switch (type) {
    ConceptBlockType.tip => 'Learning Tip',
    ConceptBlockType.note => 'Important Note',
    ConceptBlockType.warning => 'Common Pitfall',
    ConceptBlockType.definition => 'Key Definition',
    ConceptBlockType.example => 'Worked Example',
  };
}
