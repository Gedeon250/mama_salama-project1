import 'package:flutter/material.dart';

/// Design tokens lifted directly from the Stitch "Nurturing Vitality"
/// design system (nurturing_vitality/DESIGN.md) so every screen in the
/// app shares one visual language.
class AppColors {
  AppColors._();

  static const surface = Color(0xFFF9F9F9);
  static const surfaceDim = Color(0xFFDADADA);
  static const surfaceBright = Color(0xFFF9F9F9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F3F3);
  static const surfaceContainer = Color(0xFFEEEEEE);
  static const surfaceContainerHigh = Color(0xFFE8E8E8);
  static const surfaceContainerHighest = Color(0xFFE2E2E2);

  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF40493D);
  static const inverseSurface = Color(0xFF2F3131);
  static const inverseOnSurface = Color(0xFFF1F1F1);

  static const outline = Color(0xFF707A6C);
  static const outlineVariant = Color(0xFFBFCABA);

  static const primary = Color(0xFF0D631B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2E7D32);
  static const onPrimaryContainer = Color(0xFFCBFFC2);
  static const inversePrimary = Color(0xFF88D982);
  static const primaryFixed = Color(0xFFA3F69C);
  static const primaryFixedDim = Color(0xFF88D982);

  static const secondary = Color(0xFF5F5E5E);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE5E2E1);
  static const onSecondaryContainer = Color(0xFF656464);

  static const tertiary = Color(0xFF4D5950);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF657167);
  static const onTertiaryContainer = Color(0xFFE8F5E9);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const background = Color(0xFFF9F9F9);
  static const onBackground = Color(0xFF1A1C1C);
  static const surfaceVariant = Color(0xFFE2E2E2);
}

class AppSpacing {
  AppSpacing._();
  static const base = 4.0;
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 48.0;
  static const edgeMargin = 20.0;
  static const gutter = 16.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 4.0;
  static const dflt = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 999.0;
}

class AppTheme {
  AppTheme._();

  // Headline font falls back to a hyper-legible system font if
  // "Atkinson Hyperlegible Next" isn't bundled; body text falls back to Inter
  // via the platform default. Swap these for google_fonts if you add the
  // package (see pubspec.yaml note).
  static const _headlineFont = 'AtkinsonHyperlegibleNext';
  static const _bodyFont = 'Inter';

  static ThemeData get light {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: _bodyFont,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 38 / 30,
          letterSpacing: -0.4,
          color: AppColors.onBackground,
        ),
        headlineMedium: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 32 / 24,
          color: AppColors.onBackground,
        ),
        headlineSmall: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 28 / 20,
          color: AppColors.onBackground,
        ),
        bodyLarge: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 28 / 18,
          color: AppColors.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: AppColors.onSurface,
        ),
        bodySmall: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
          color: AppColors.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          letterSpacing: 0.1,
          color: AppColors.onSurface,
        ),
        labelMedium: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.onSurface),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outlineVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.primaryContainer.withOpacity(0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.secondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.secondary,
          );
        }),
      ),
    );
  }
}
