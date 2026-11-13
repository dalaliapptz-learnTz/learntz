import 'package:flutter/material.dart';

/// LearnTZ Design System 2.0 — Canonical Border Radii Tokens
/// Single Source of Truth: tokens/learntz_design_tokens.json
abstract final class LearnTzRadii {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;     // Buttons, text fields, checkboxes
  static const double lg = 16.0;    // Standard cards
  static const double xl = 20.0;    // Elevated panels
  static const double xxl = 24.0;   // Large containers, bottom sheets
  static const double full = 9999.0;// Pills, badges, avatars

  // BorderRadius Helpers
  static const BorderRadius borderNone = BorderRadius.zero;
  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));

  // Specialized Shapes
  static const BorderRadius topXxl = BorderRadius.vertical(top: Radius.circular(xxl));
  static const BorderRadius bottomXxl = BorderRadius.vertical(bottom: Radius.circular(xxl));
}
