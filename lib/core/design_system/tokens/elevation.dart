import 'package:flutter/material.dart';

import 'colors.dart';

/// LearnTZ Design System 2.0 — Elevation & Shadow Tokens
/// Single Source of Truth: tokens/learntz_design_tokens.json
abstract final class LearnTzElevation {
  static const double flat = 0.0;
  static const double sm = 1.0;
  static const double md = 3.0;
  static const double lg = 6.0;
  static const double xl = 12.0;
}

abstract final class LearnTzShadows {
  static const List<BoxShadow> none = [];

  static final List<BoxShadow> sm = [
    BoxShadow(
      color: LearnTzColors.textPrimary.withValues(alpha: 0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> md = [
    BoxShadow(
      color: LearnTzColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: LearnTzColors.textPrimary.withValues(alpha: 0.03),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> lg = [
    BoxShadow(
      color: LearnTzColors.textPrimary.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: LearnTzColors.textPrimary.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> xl = [
    BoxShadow(
      color: LearnTzColors.textPrimary.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: LearnTzColors.textPrimary.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
