import 'package:flutter/material.dart';

/// LearnTZ Design System 2.0 — Canonical Color Tokens
/// Single Source of Truth: tokens/learntz_design_tokens.json
abstract final class LearnTzColors {
  // Brand Foundation
  static const primary = Color(0xFF0F4C81);
  static const primaryVariant = Color(0xFF1E3A8A);
  static const secondary = Color(0xFF15803D);
  static const accent = Color(0xFFF59E0B);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);

  // Primary Scale (Pantone Classic Blue / Academic Navy)
  static const primary50 = Color(0xFFEFF6FF);
  static const primary100 = Color(0xFFDBEAFE);
  static const primary200 = Color(0xFFBFDBFE);
  static const primary300 = Color(0xFF93C5FD);
  static const primary400 = Color(0xFF60A5FA);
  static const primary500 = Color(0xFF0F4C81);
  static const primary600 = Color(0xFF0D3E6A);
  static const primary700 = Color(0xFF0B3154);
  static const primary800 = Color(0xFF1E3A8A);
  static const primary900 = Color(0xFF061B30);

  // Secondary Scale (Progress & Success Green)
  static const secondary50 = Color(0xFFF0FDF4);
  static const secondary100 = Color(0xFFDCFCE7);
  static const secondary200 = Color(0xFFBBF7D0);
  static const secondary300 = Color(0xFF86EFAC);
  static const secondary400 = Color(0xFF4ADE80);
  static const secondary500 = Color(0xFF22C55E);
  static const secondary600 = Color(0xFF16A34A);
  static const secondary700 = Color(0xFF15803D);
  static const secondary800 = Color(0xFF166534);
  static const secondary900 = Color(0xFF14532D);

  // Accent Scale (Achievements & Highlights Amber)
  static const accent50 = Color(0xFFFFFBEB);
  static const accent100 = Color(0xFFFEF3C7);
  static const accent200 = Color(0xFFFDE68A);
  static const accent300 = Color(0xFFFCD34D);
  static const accent400 = Color(0xFFFBBF24);
  static const accent500 = Color(0xFFF59E0B);
  static const accent600 = Color(0xFFD97706);
  static const accent700 = Color(0xFFB45309);
  static const accent800 = Color(0xFF92400E);
  static const accent900 = Color(0xFF78350F);

  // Neutral Scale (Slate)
  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF475569);
  static const neutral700 = Color(0xFF334155);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral900 = Color(0xFF0F172A);

  // Semantic: Success
  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFDCFCE7);
  static const successBorder = Color(0xFF86EFAC);
  static const successText = Color(0xFF14532D);

  // Semantic: Warning
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);
  static const warningBorder = Color(0xFFFCD34D);
  static const warningText = Color(0xFF78350F);

  // Semantic: Error
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEE2E2);
  static const errorBorder = Color(0xFFFCA5A5);
  static const errorText = Color(0xFF7F1D1D);

  // Semantic: Information
  static const info = Color(0xFF0284C7);
  static const infoBg = Color(0xFFE0F2FE);
  static const infoBorder = Color(0xFF7DD3FC);
  static const infoText = Color(0xFF0C4A6E);

  // Semantic: Disabled
  static const disabled = Color(0xFF94A3B8);
  static const disabledBg = Color(0xFFF1F5F9);
  static const disabledBorder = Color(0xFFCBD5E1);
  static const disabledText = Color(0xFF64748B);

  // Dark Mode Overrides
  static const darkBackground = Color(0xFF0B132B);
  static const darkSurface = Color(0xFF1C2541);
  static const darkSurfaceSubtle = Color(0xFF222F55);
  static const darkBorder = Color(0xFF3A4B75);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);

  // High Contrast Overrides
  static const highContrastBackground = Color(0xFF000000);
  static const highContrastSurface = Color(0xFF121212);
  static const highContrastBorder = Color(0xFFFFFFFF);
  static const highContrastText = Color(0xFFFFFFFF);
  static const highContrastYellow = Color(0xFFFFD700);
}
