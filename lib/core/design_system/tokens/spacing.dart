import 'package:flutter/material.dart';

/// LearnTZ Design System 2.0 — Canonical Spacing Tokens (8px Grid)
/// Single Source of Truth: tokens/learntz_design_tokens.json
abstract final class LearnTzSpacing {
  static const double grid = 8.0;

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Touch Target Standards (WCAG 2.2 AA)
  static const double mobileMinTouchTarget = 48.0;
  static const double webMinTouchTarget = 44.0;
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
  static const double inputHeight = 52.0;
  static const double appBarHeight = 72.0;
  static const double maxContentWidth = 1120.0;
  static const double maxWideContentWidth = 1440.0;

  // EdgeInsets Helpers
  static const EdgeInsets allXxs = EdgeInsets.all(xxs);
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingMobile = EdgeInsets.all(md);

  // SizedBox Spacing Widgets
  static const Widget gapXxs = SizedBox(height: xxs, width: xxs);
  static const Widget gapXs = SizedBox(height: xs, width: xs);
  static const Widget gapSm = SizedBox(height: sm, width: sm);
  static const Widget gapMd = SizedBox(height: md, width: md);
  static const Widget gapLg = SizedBox(height: lg, width: lg);
  static const Widget gapXl = SizedBox(height: xl, width: xl);
  static const Widget gapXxl = SizedBox(height: xxl, width: xxl);

  // Vertical Gaps
  static const Widget vGapXxs = SizedBox(height: xxs);
  static const Widget vGapXs = SizedBox(height: xs);
  static const Widget vGapSm = SizedBox(height: sm);
  static const Widget vGapMd = SizedBox(height: md);
  static const Widget vGapLg = SizedBox(height: lg);
  static const Widget vGapXl = SizedBox(height: xl);
  static const Widget vGapXxl = SizedBox(height: xxl);

  // Horizontal Gaps
  static const Widget hGapXxs = SizedBox(width: xxs);
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
  static const Widget hGapXl = SizedBox(width: xl);
  static const Widget hGapXxl = SizedBox(width: xxl);
}
