import 'package:flutter/material.dart';

/// LearnTZ Design System 2.0 — Canonical Motion & Animation Tokens
/// Single Source of Truth: tokens/learntz_design_tokens.json
abstract final class LearnTzMotion {
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveAccelerate = Curves.easeInCubic;
}
