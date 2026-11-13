import 'package:flutter/material.dart';

import 'colors.dart';

/// LearnTZ Design System 2.0 — Canonical Typography Tokens
/// Single Source of Truth: tokens/learntz_design_tokens.json
abstract final class LearnTzTypography {
  static const headingFontFamily = 'Plus Jakarta Sans';
  static const bodyFontFamily = 'Inter';
  static const monoFontFamily = 'JetBrains Mono';

  static const display = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -1.0,
    color: LearnTzColors.textPrimary,
  );

  static const h1 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: LearnTzColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.25,
    color: LearnTzColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: LearnTzColors.textPrimary,
  );

  static const h4 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: LearnTzColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: LearnTzColors.textPrimary,
  );

  static const bodyRegular = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: LearnTzColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: LearnTzColors.textSecondary,
  );

  static const caption = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
    color: LearnTzColors.textSecondary,
  );

  static const button = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: LearnTzColors.textPrimary,
  );

  static const mathFormula = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: LearnTzColors.textPrimary,
  );

  /// Helper to convert tokens into Material 3 TextTheme
  static TextTheme toTextTheme({Color textColor = LearnTzColors.textPrimary}) {
    return TextTheme(
      displayLarge: display.copyWith(color: textColor),
      headlineLarge: h1.copyWith(color: textColor),
      headlineMedium: h2.copyWith(color: textColor),
      headlineSmall: h3.copyWith(color: textColor),
      titleLarge: h4.copyWith(color: textColor),
      titleMedium: h4.copyWith(fontSize: 16, color: textColor),
      titleSmall: h4.copyWith(fontSize: 14, color: textColor),
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyRegular.copyWith(color: textColor),
      bodySmall: bodySmall.copyWith(color: textColor.withValues(alpha: 0.8)),
      labelLarge: button,
      labelMedium: caption.copyWith(color: textColor.withValues(alpha: 0.7)),
      labelSmall: caption.copyWith(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
    );
  }
}
