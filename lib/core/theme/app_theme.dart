import 'package:flutter/material.dart';

import '../config/country_configuration.dart';
import '../design_system/tokens/design_tokens.dart';

/// Legacy AppColors aliases maintained for backwards-compatibility.
/// New code should reference LearnTzColors directly.
abstract final class AppColors {
  static const ink = LearnTzColors.textPrimary;
  static const muted = LearnTzColors.textSecondary;
  static const canvas = LearnTzColors.background;
  static const border = LearnTzColors.border;
}

/// ThemeExtension to pass Country Branding into BuildContext
class CountryThemeExtension extends ThemeExtension<CountryThemeExtension> {
  const CountryThemeExtension({
    required this.countryCode,
    required this.displayName,
    required this.primaryBrandColor,
    required this.accentBrandColor,
  });

  final String countryCode;
  final String displayName;
  final Color primaryBrandColor;
  final Color accentBrandColor;

  @override
  CountryThemeExtension copyWith({
    String? countryCode,
    String? displayName,
    Color? primaryBrandColor,
    Color? accentBrandColor,
  }) {
    return CountryThemeExtension(
      countryCode: countryCode ?? this.countryCode,
      displayName: displayName ?? this.displayName,
      primaryBrandColor: primaryBrandColor ?? this.primaryBrandColor,
      accentBrandColor: accentBrandColor ?? this.accentBrandColor,
    );
  }

  @override
  CountryThemeExtension lerp(
    ThemeExtension<CountryThemeExtension>? other,
    double t,
  ) {
    if (other is! CountryThemeExtension) return this;
    return CountryThemeExtension(
      countryCode: t < 0.5 ? countryCode : other.countryCode,
      displayName: t < 0.5 ? displayName : other.displayName,
      primaryBrandColor: Color.lerp(primaryBrandColor, other.primaryBrandColor, t)!,
      accentBrandColor: Color.lerp(accentBrandColor, other.accentBrandColor, t)!,
    );
  }
}

/// LearnTZ Design System 2.0 — Central Theme Engine
abstract final class AppTheme {
  /// Backwards-compatible alias for lightTheme
  static ThemeData forCountry(CountryConfiguration country) =>
      lightTheme(country);

  /// Light Theme (Default)
  static ThemeData lightTheme(CountryConfiguration country) {
    final countryPrimary = Color(country.primaryBrandColor);
    final countryAccent = Color(country.accentBrandColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: countryPrimary,
        primary: countryPrimary,
        onPrimary: Colors.white,
        primaryContainer: LearnTzColors.primary50,
        onPrimaryContainer: LearnTzColors.primary900,
        secondary: countryAccent,
        onSecondary: Colors.white,
        secondaryContainer: LearnTzColors.secondary50,
        onSecondaryContainer: LearnTzColors.secondary900,
        tertiary: LearnTzColors.accent,
        surface: LearnTzColors.surface,
        onSurface: LearnTzColors.textPrimary,
        error: LearnTzColors.error,
        onError: Colors.white,
        outline: LearnTzColors.border,
      ),
      scaffoldBackgroundColor: LearnTzColors.background,
      fontFamily: LearnTzTypography.bodyFontFamily,
      textTheme: LearnTzTypography.toTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: LearnTzColors.background,
        foregroundColor: LearnTzColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: LearnTzSpacing.appBarHeight,
        titleTextStyle: LearnTzTypography.h3,
      ),
      cardTheme: CardThemeData(
        color: LearnTzColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: LearnTzColors.border, width: 1.0),
          borderRadius: LearnTzRadii.borderLg,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LearnTzColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, LearnTzSpacing.buttonHeightLg),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: LearnTzRadii.borderMd,
          ),
          textStyle: LearnTzTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LearnTzColors.textPrimary,
          minimumSize: const Size(48, LearnTzSpacing.buttonHeightLg),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: LearnTzColors.border, width: 1.0),
          shape: const RoundedRectangleBorder(
            borderRadius: LearnTzRadii.borderMd,
          ),
          textStyle: LearnTzTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LearnTzColors.primary,
          shape: const RoundedRectangleBorder(
            borderRadius: LearnTzRadii.borderMd,
          ),
          textStyle: LearnTzTypography.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: LearnTzRadii.borderMd,
          borderSide: BorderSide(color: LearnTzColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: LearnTzRadii.borderMd,
          borderSide: BorderSide(color: LearnTzColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: LearnTzRadii.borderMd,
          borderSide: BorderSide(color: LearnTzColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: LearnTzRadii.borderMd,
          borderSide: BorderSide(color: LearnTzColors.error, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: LearnTzColors.primary50,
        labelTextStyle: WidgetStateProperty.all(
          LearnTzTypography.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: LearnTzRadii.borderXl),
        titleTextStyle: LearnTzTypography.h3,
      ),
      extensions: [
        CountryThemeExtension(
          countryCode: country.countryCode,
          displayName: country.displayName,
          primaryBrandColor: countryPrimary,
          accentBrandColor: countryAccent,
        ),
      ],
    );
  }

  /// Dark Theme
  static ThemeData darkTheme(CountryConfiguration country) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LearnTzColors.primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF60A5FA),
        onPrimary: const Color(0xFF061B30),
        primaryContainer: const Color(0xFF1E3A8A),
        surface: LearnTzColors.darkSurface,
        onSurface: LearnTzColors.darkTextPrimary,
        error: const Color(0xFFF87171),
        outline: LearnTzColors.darkBorder,
      ),
      scaffoldBackgroundColor: LearnTzColors.darkBackground,
      fontFamily: LearnTzTypography.bodyFontFamily,
      textTheme: LearnTzTypography.toTextTheme(
        textColor: LearnTzColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LearnTzColors.darkBackground,
        foregroundColor: LearnTzColors.darkTextPrimary,
        elevation: 0,
        toolbarHeight: LearnTzSpacing.appBarHeight,
        titleTextStyle: TextStyle(
          color: LearnTzColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: LearnTzColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: LearnTzColors.darkBorder, width: 1.0),
          borderRadius: LearnTzRadii.borderLg,
        ),
      ),
    );
  }

  /// High Contrast Theme (WCAG AAA)
  static ThemeData highContrastTheme(CountryConfiguration country) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.highContrastDark(
        primary: LearnTzColors.highContrastYellow,
        onPrimary: Colors.black,
        surface: LearnTzColors.highContrastSurface,
        onSurface: Colors.white,
        outline: Colors.white,
      ),
      scaffoldBackgroundColor: LearnTzColors.highContrastBackground,
      fontFamily: LearnTzTypography.bodyFontFamily,
      textTheme: LearnTzTypography.toTextTheme(textColor: Colors.white),
      cardTheme: CardThemeData(
        color: LearnTzColors.highContrastSurface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white, width: 2.0),
          borderRadius: LearnTzRadii.borderMd,
        ),
      ),
    );
  }
}
