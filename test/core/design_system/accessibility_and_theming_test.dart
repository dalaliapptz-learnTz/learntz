import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/core/design_system/components/components.dart';
import 'package:learntz/core/design_system/theme_mode_provider.dart';
import 'package:learntz/core/design_system/tokens/design_tokens.dart';

/// Relative luminance calculation per WCAG 2.2 specifications
double _calculateLuminance(Color color) {
  double transform(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Contrast ratio calculation: (L1 + 0.05) / (L2 + 0.05)
double _contrastRatio(Color c1, Color c2) {
  final l1 = _calculateLuminance(c1);
  final l2 = _calculateLuminance(c2);
  final brighter = max(l1, l2);
  final darker = min(l1, l2);
  return (brighter + 0.05) / (darker + 0.05);
}

void main() {
  group('LearnTZ Design System 2.0 Accessibility & WCAG 2.2 AA Contrast', () {
    test('textPrimary on surface achieves WCAG AA standard (>= 4.5:1)', () {
      final ratio = _contrastRatio(LearnTzColors.textPrimary, LearnTzColors.surface);
      expect(ratio >= 4.5, isTrue, reason: 'Actual ratio: $ratio');
      expect(ratio >= 10.0, isTrue); // High contrast ~15:1
    });

    test('textPrimary on background achieves WCAG AA standard (>= 4.5:1)', () {
      final ratio = _contrastRatio(LearnTzColors.textPrimary, LearnTzColors.background);
      expect(ratio >= 4.5, isTrue, reason: 'Actual ratio: $ratio');
    });

    test('primary brand color on white achieves WCAG AA standard (>= 4.5:1)', () {
      final ratio = _contrastRatio(LearnTzColors.primary, Colors.white);
      expect(ratio >= 4.5, isTrue, reason: 'Actual ratio: $ratio');
    });

    test('secondary progress color on white achieves WCAG AA standard (>= 4.5:1)', () {
      final ratio = _contrastRatio(LearnTzColors.secondary, Colors.white);
      expect(ratio >= 4.5, isTrue, reason: 'Actual ratio: $ratio');
    });

    test('error color on white achieves WCAG AA standard (>= 4.5:1)', () {
      final ratio = _contrastRatio(LearnTzColors.error, Colors.white);
      expect(ratio >= 4.5, isTrue, reason: 'Actual ratio: $ratio');
    });

    test('semantic badges text on background achieve WCAG AA standard (>= 4.5:1)', () {
      final successRatio = _contrastRatio(LearnTzColors.successText, LearnTzColors.successBg);
      expect(successRatio >= 4.5, isTrue, reason: 'Success badge ratio: $successRatio');

      final errorRatio = _contrastRatio(LearnTzColors.errorText, LearnTzColors.errorBg);
      expect(errorRatio >= 4.5, isTrue, reason: 'Error badge ratio: $errorRatio');
    });

    testWidgets('AppOfflineBanner renders offline mode and triggers retry', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppOfflineBanner(
              isOnline: false,
              pendingCount: 3,
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Mode — 3 activity changes saved locally'), findsOneWidget);
      expect(find.text('Retry Now'), findsOneWidget);

      await tester.tap(find.text('Retry Now'));
      expect(retried, isTrue);
    });

    test('ThemeModeNotifier toggles between light and dark modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).toggleDarkMode();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
