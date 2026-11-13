import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// LearnTZ Design System 2.0 — Canonical Brand Logo Component
/// Displays the official uploaded LearnTZ logo asset with optional product name and country badge.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.height = 38.0,
    this.productName,
    this.showTagline = false,
    this.countryBadge,
    this.onTap,
  });

  final double height;
  final String? productName;
  final bool showTagline;
  final String? countryBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final logoWidget = Image.asset(
      'assets/branding/learntz_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to stylized vector brandmark if asset fails to load
        return Container(
          height: height,
          width: height,
          decoration: BoxDecoration(
            color: LearnTzColors.primary,
            borderRadius: LearnTzRadii.borderMd,
          ),
          child: Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: height * 0.55,
          ),
        );
      },
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        if (productName != null) ...[
          const SizedBox(width: 10),
          Text(
            productName!,
            style: LearnTzTypography.h3.copyWith(
              color: LearnTzColors.textPrimary,
              fontSize: height * 0.55,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
        if (countryBadge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: LearnTzColors.primary50,
              border: Border.all(color: LearnTzColors.primary200),
              borderRadius: LearnTzRadii.borderFull,
            ),
            child: Text(
              countryBadge!,
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.primary700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    if (showTagline) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          const SizedBox(height: 2),
          Text(
            'Learn Anywhere, Anytime',
            style: LearnTzTypography.caption.copyWith(
              color: LearnTzColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: LearnTzRadii.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: content,
        ),
      );
    }

    return content;
  }
}
