import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop, wide }

/// LearnTZ Design System 2.0 — Canonical Responsive Breakpoint Tokens
/// Single Source of Truth: tokens/learntz_design_tokens.json
abstract final class LearnTzBreakpoints {
  static const double mobileMax = 599.0;
  static const double tabletMin = 600.0;
  static const double tabletMax = 1023.0;
  static const double desktopMin = 1024.0;
  static const double desktopMax = 1439.0;
  static const double wideMin = 1440.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletMin && width <= tabletMax;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= desktopMin && width <= desktopMax;
  }

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideMin;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < desktopMin;

  static DeviceType deviceTypeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= mobileMax) return DeviceType.mobile;
    if (width <= tabletMax) return DeviceType.tablet;
    if (width <= desktopMax) return DeviceType.desktop;
    return DeviceType.wide;
  }
}
