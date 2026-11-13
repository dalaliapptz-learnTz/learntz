import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/design_system/tokens/design_tokens.dart';

void main() {
  group('LearnTZ Design System 2.0 Tokens', () {
    test('brand colors match canonical specification', () {
      expect(LearnTzColors.primary.toARGB32(), 0xFF0F4C81);
      expect(LearnTzColors.primaryVariant.toARGB32(), 0xFF1E3A8A);
      expect(LearnTzColors.secondary.toARGB32(), 0xFF15803D);
      expect(LearnTzColors.accent.toARGB32(), 0xFFF59E0B);
      expect(LearnTzColors.background.toARGB32(), 0xFFF8FAFC);
      expect(LearnTzColors.surface.toARGB32(), 0xFFFFFFFF);
      expect(LearnTzColors.border.toARGB32(), 0xFFE2E8F0);
      expect(LearnTzColors.textPrimary.toARGB32(), 0xFF0F172A);
      expect(LearnTzColors.textSecondary.toARGB32(), 0xFF64748B);
    });

    test('semantic colors provide proper contrast and background pairings', () {
      expect(LearnTzColors.success.toARGB32(), 0xFF15803D);
      expect(LearnTzColors.successBg.toARGB32(), 0xFFDCFCE7);
      expect(LearnTzColors.warning.toARGB32(), 0xFFD97706);
      expect(LearnTzColors.warningBg.toARGB32(), 0xFFFEF3C7);
      expect(LearnTzColors.error.toARGB32(), 0xFFDC2626);
      expect(LearnTzColors.errorBg.toARGB32(), 0xFFFEE2E2);
      expect(LearnTzColors.info.toARGB32(), 0xFF0284C7);
      expect(LearnTzColors.infoBg.toARGB32(), 0xFFE0F2FE);
    });

    test('spacing adheres to 8px grid and WCAG touch targets', () {
      expect(LearnTzSpacing.grid, 8.0);
      expect(LearnTzSpacing.xxs, 4.0);
      expect(LearnTzSpacing.xs, 8.0);
      expect(LearnTzSpacing.sm, 12.0);
      expect(LearnTzSpacing.md, 16.0);
      expect(LearnTzSpacing.lg, 24.0);
      expect(LearnTzSpacing.xl, 32.0);
      expect(LearnTzSpacing.xxl, 48.0);
      expect(LearnTzSpacing.xxxl, 64.0);

      // WCAG 2.2 AA touch targets
      expect(LearnTzSpacing.mobileMinTouchTarget, 48.0);
      expect(LearnTzSpacing.webMinTouchTarget, 44.0);
    });

    test('radii tokens follow hierarchy', () {
      expect(LearnTzRadii.none, 0.0);
      expect(LearnTzRadii.xs, 4.0);
      expect(LearnTzRadii.sm, 6.0);
      expect(LearnTzRadii.md, 8.0);
      expect(LearnTzRadii.lg, 16.0);
      expect(LearnTzRadii.xl, 20.0);
      expect(LearnTzRadii.xxl, 24.0);
      expect(LearnTzRadii.full, 9999.0);
    });

    test('typography scale initializes and generates TextTheme', () {
      final textTheme = LearnTzTypography.toTextTheme();
      expect(textTheme.headlineLarge?.fontSize, 36.0);
      expect(textTheme.headlineMedium?.fontSize, 28.0);
      expect(textTheme.titleLarge?.fontSize, 18.0);
      expect(textTheme.bodyLarge?.fontSize, 16.0);
      expect(textTheme.bodyMedium?.fontSize, 14.0);
    });

    testWidgets('breakpoints detect mobile, tablet, and desktop viewports', (tester) async {
      // Mobile test: 390 x 844
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(LearnTzBreakpoints.isMobile(context), isTrue);
              expect(LearnTzBreakpoints.isTablet(context), isFalse);
              expect(LearnTzBreakpoints.isDesktop(context), isFalse);
              expect(LearnTzBreakpoints.deviceTypeOf(context), DeviceType.mobile);
              return const SizedBox();
            },
          ),
        ),
      );

      // Tablet test: 768 x 1024
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(LearnTzBreakpoints.isMobile(context), isFalse);
              expect(LearnTzBreakpoints.isTablet(context), isTrue);
              expect(LearnTzBreakpoints.isDesktop(context), isFalse);
              expect(LearnTzBreakpoints.deviceTypeOf(context), DeviceType.tablet);
              return const SizedBox();
            },
          ),
        ),
      );

      // Desktop test: 1280 x 800
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(LearnTzBreakpoints.isMobile(context), isFalse);
              expect(LearnTzBreakpoints.isTablet(context), isFalse);
              expect(LearnTzBreakpoints.isDesktop(context), isTrue);
              expect(LearnTzBreakpoints.deviceTypeOf(context), DeviceType.desktop);
              return const SizedBox();
            },
          ),
        ),
      );

      // Reset
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
