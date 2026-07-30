import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

/// Design tokens lifted directly from the Stitch "Nurturing Vitality"
/// design system (nurturing_vitality/DESIGN.md) so every screen in the
/// app shares one visual language.
///
/// Kept private: every other file in the app reads colors through the
/// dynamic `AppColors` getters below, which pick whichever of these two
/// palettes matches the user's current Dark Mode setting.
class _LightColors {
  _LightColors._();

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

/// Dark counterpart of [_LightColors], following Material 3's dark-theme
/// surface-tone ordering (surfaceContainerLowest is the darkest tone here,
/// vs. the brightest in light mode). `primaryFixed`/`primaryFixedDim` stay
/// identical to the light palette — M3 "fixed" roles are defined to not
/// change with brightness. `primary`/`inversePrimary` swap with what the
/// light palette calls `inversePrimary`/`primary`, since the brighter green
/// reads better against a dark background.
class _DarkColors {
  _DarkColors._();

  static const surface = Color(0xFF0F1210);
  static const surfaceDim = Color(0xFF0F1210);
  static const surfaceBright = Color(0xFF353A34);
  static const surfaceContainerLowest = Color(0xFF0A0C0A);
  static const surfaceContainerLow = Color(0xFF181B18);
  static const surfaceContainer = Color(0xFF1C1F1C);
  static const surfaceContainerHigh = Color(0xFF262A26);
  static const surfaceContainerHighest = Color(0xFF313530);

  static const onSurface = Color(0xFFE2E4DE);
  static const onSurfaceVariant = Color(0xFFC0CABA);
  static const inverseSurface = Color(0xFFE2E4DE);
  static const inverseOnSurface = Color(0xFF1A1C1C);

  static const outline = Color(0xFF8A9484);
  static const outlineVariant = Color(0xFF40493D);

  static const primary = Color(0xFF88D982);
  static const onPrimary = Color(0xFF05390A);
  static const primaryContainer = Color(0xFF1B5E20);
  static const onPrimaryContainer = Color(0xFFCBFFC2);
  static const inversePrimary = Color(0xFF0D631B);
  static const primaryFixed = Color(0xFFA3F69C);
  static const primaryFixedDim = Color(0xFF88D982);

  static const secondary = Color(0xFFC7C6C5);
  static const onSecondary = Color(0xFF2F2F2F);
  static const secondaryContainer = Color(0xFF464646);
  static const onSecondaryContainer = Color(0xFFE5E2E1);

  static const tertiary = Color(0xFFB4C1B7);
  static const onTertiary = Color(0xFF1F2A21);
  static const tertiaryContainer = Color(0xFF3B463D);
  static const onTertiaryContainer = Color(0xFFE8F5E9);

  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const background = Color(0xFF0F1210);
  static const onBackground = Color(0xFFE2E4DE);
  static const surfaceVariant = Color(0xFF313530);
}

/// Dynamic color tokens used throughout the app. Every getter picks the
/// light or dark value based on the user's current Dark Mode setting
/// (see ThemeModeProvider) — this works even outside a BuildContext
/// (static helpers, PDF generation is the one deliberate exception, see
/// AppBrandColors) because it reads a plain static flag rather than an
/// InheritedWidget lookup.
class AppColors {
  AppColors._();

  static bool get _dark => ThemeModeProvider.isDarkModeActive;

  static Color get surface => _dark ? _DarkColors.surface : _LightColors.surface;
  static Color get surfaceDim => _dark ? _DarkColors.surfaceDim : _LightColors.surfaceDim;
  static Color get surfaceBright => _dark ? _DarkColors.surfaceBright : _LightColors.surfaceBright;
  static Color get surfaceContainerLowest => _dark ? _DarkColors.surfaceContainerLowest : _LightColors.surfaceContainerLowest;
  static Color get surfaceContainerLow => _dark ? _DarkColors.surfaceContainerLow : _LightColors.surfaceContainerLow;
  static Color get surfaceContainer => _dark ? _DarkColors.surfaceContainer : _LightColors.surfaceContainer;
  static Color get surfaceContainerHigh => _dark ? _DarkColors.surfaceContainerHigh : _LightColors.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _dark ? _DarkColors.surfaceContainerHighest : _LightColors.surfaceContainerHighest;

  static Color get onSurface => _dark ? _DarkColors.onSurface : _LightColors.onSurface;
  static Color get onSurfaceVariant => _dark ? _DarkColors.onSurfaceVariant : _LightColors.onSurfaceVariant;
  static Color get inverseSurface => _dark ? _DarkColors.inverseSurface : _LightColors.inverseSurface;
  static Color get inverseOnSurface => _dark ? _DarkColors.inverseOnSurface : _LightColors.inverseOnSurface;

  static Color get outline => _dark ? _DarkColors.outline : _LightColors.outline;
  static Color get outlineVariant => _dark ? _DarkColors.outlineVariant : _LightColors.outlineVariant;

  static Color get primary => _dark ? _DarkColors.primary : _LightColors.primary;
  static Color get onPrimary => _dark ? _DarkColors.onPrimary : _LightColors.onPrimary;
  static Color get primaryContainer => _dark ? _DarkColors.primaryContainer : _LightColors.primaryContainer;
  static Color get onPrimaryContainer => _dark ? _DarkColors.onPrimaryContainer : _LightColors.onPrimaryContainer;
  static Color get inversePrimary => _dark ? _DarkColors.inversePrimary : _LightColors.inversePrimary;
  static Color get primaryFixed => _dark ? _DarkColors.primaryFixed : _LightColors.primaryFixed;
  static Color get primaryFixedDim => _dark ? _DarkColors.primaryFixedDim : _LightColors.primaryFixedDim;

  static Color get secondary => _dark ? _DarkColors.secondary : _LightColors.secondary;
  static Color get onSecondary => _dark ? _DarkColors.onSecondary : _LightColors.onSecondary;
  static Color get secondaryContainer => _dark ? _DarkColors.secondaryContainer : _LightColors.secondaryContainer;
  static Color get onSecondaryContainer => _dark ? _DarkColors.onSecondaryContainer : _LightColors.onSecondaryContainer;

  static Color get tertiary => _dark ? _DarkColors.tertiary : _LightColors.tertiary;
  static Color get onTertiary => _dark ? _DarkColors.onTertiary : _LightColors.onTertiary;
  static Color get tertiaryContainer => _dark ? _DarkColors.tertiaryContainer : _LightColors.tertiaryContainer;
  static Color get onTertiaryContainer => _dark ? _DarkColors.onTertiaryContainer : _LightColors.onTertiaryContainer;

  static Color get error => _dark ? _DarkColors.error : _LightColors.error;
  static Color get onError => _dark ? _DarkColors.onError : _LightColors.onError;
  static Color get errorContainer => _dark ? _DarkColors.errorContainer : _LightColors.errorContainer;
  static Color get onErrorContainer => _dark ? _DarkColors.onErrorContainer : _LightColors.onErrorContainer;

  static Color get background => _dark ? _DarkColors.background : _LightColors.background;
  static Color get onBackground => _dark ? _DarkColors.onBackground : _LightColors.onBackground;
  static Color get surfaceVariant => _dark ? _DarkColors.surfaceVariant : _LightColors.surfaceVariant;
}

/// Fixed brand colors for contexts that must look the same regardless of
/// the user's in-app Dark Mode setting — currently just generated PDFs
/// (see report_service.dart): a printed referral letter shouldn't flip to
/// a dark color scheme just because the phone's app theme did.
class AppBrandColors {
  AppBrandColors._();

  static const primary = _LightColors.primary;
  static const secondary = _LightColors.secondary;
  static const outlineVariant = _LightColors.outlineVariant;
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
    const colorScheme = ColorScheme.light(
      primary: _LightColors.primary,
      onPrimary: _LightColors.onPrimary,
      primaryContainer: _LightColors.primaryContainer,
      onPrimaryContainer: _LightColors.onPrimaryContainer,
      secondary: _LightColors.secondary,
      onSecondary: _LightColors.onSecondary,
      secondaryContainer: _LightColors.secondaryContainer,
      onSecondaryContainer: _LightColors.onSecondaryContainer,
      tertiary: _LightColors.tertiary,
      onTertiary: _LightColors.onTertiary,
      tertiaryContainer: _LightColors.tertiaryContainer,
      onTertiaryContainer: _LightColors.onTertiaryContainer,
      error: _LightColors.error,
      onError: _LightColors.onError,
      errorContainer: _LightColors.errorContainer,
      onErrorContainer: _LightColors.onErrorContainer,
      surface: _LightColors.surface,
      onSurface: _LightColors.onSurface,
      surfaceContainerHighest: _LightColors.surfaceContainerHighest,
      onSurfaceVariant: _LightColors.onSurfaceVariant,
      outline: _LightColors.outline,
      outlineVariant: _LightColors.outlineVariant,
      inverseSurface: _LightColors.inverseSurface,
      onInverseSurface: _LightColors.inverseOnSurface,
      inversePrimary: _LightColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _LightColors.background,
      fontFamily: _bodyFont,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 38 / 30,
          letterSpacing: -0.4,
          color: _LightColors.onBackground,
        ),
        headlineMedium: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 32 / 24,
          color: _LightColors.onBackground,
        ),
        headlineSmall: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 28 / 20,
          color: _LightColors.onBackground,
        ),
        bodyLarge: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 28 / 18,
          color: _LightColors.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: _LightColors.onSurface,
        ),
        bodySmall: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
          color: _LightColors.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          letterSpacing: 0.1,
          color: _LightColors.onSurface,
        ),
        labelMedium: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: _LightColors.onSurfaceVariant,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _LightColors.surface,
        foregroundColor: _LightColors.primary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: _LightColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: _LightColors.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _LightColors.primary,
          foregroundColor: _LightColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _LightColors.onSurface,
          side: const BorderSide(color: _LightColors.onSurface),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _LightColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _LightColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _LightColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _LightColors.primary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _LightColors.outlineVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _LightColors.surfaceContainerLowest,
        indicatorColor: _LightColors.primaryContainer.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _LightColors.primary : _LightColors.secondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _LightColors.primary : _LightColors.secondary,
          );
        }),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: _DarkColors.primary,
      onPrimary: _DarkColors.onPrimary,
      primaryContainer: _DarkColors.primaryContainer,
      onPrimaryContainer: _DarkColors.onPrimaryContainer,
      secondary: _DarkColors.secondary,
      onSecondary: _DarkColors.onSecondary,
      secondaryContainer: _DarkColors.secondaryContainer,
      onSecondaryContainer: _DarkColors.onSecondaryContainer,
      tertiary: _DarkColors.tertiary,
      onTertiary: _DarkColors.onTertiary,
      tertiaryContainer: _DarkColors.tertiaryContainer,
      onTertiaryContainer: _DarkColors.onTertiaryContainer,
      error: _DarkColors.error,
      onError: _DarkColors.onError,
      errorContainer: _DarkColors.errorContainer,
      onErrorContainer: _DarkColors.onErrorContainer,
      surface: _DarkColors.surface,
      onSurface: _DarkColors.onSurface,
      surfaceContainerHighest: _DarkColors.surfaceContainerHighest,
      onSurfaceVariant: _DarkColors.onSurfaceVariant,
      outline: _DarkColors.outline,
      outlineVariant: _DarkColors.outlineVariant,
      inverseSurface: _DarkColors.inverseSurface,
      onInverseSurface: _DarkColors.inverseOnSurface,
      inversePrimary: _DarkColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _DarkColors.background,
      fontFamily: _bodyFont,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 38 / 30,
          letterSpacing: -0.4,
          color: _DarkColors.onBackground,
        ),
        headlineMedium: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 32 / 24,
          color: _DarkColors.onBackground,
        ),
        headlineSmall: TextStyle(
          fontFamily: _headlineFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 28 / 20,
          color: _DarkColors.onBackground,
        ),
        bodyLarge: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 28 / 18,
          color: _DarkColors.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: _DarkColors.onSurface,
        ),
        bodySmall: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
          color: _DarkColors.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          letterSpacing: 0.1,
          color: _DarkColors.onSurface,
        ),
        labelMedium: TextStyle(
          fontFamily: _bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: _DarkColors.onSurfaceVariant,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _DarkColors.surface,
        foregroundColor: _DarkColors.primary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: _DarkColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: _DarkColors.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _DarkColors.primary,
          foregroundColor: _DarkColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _DarkColors.onSurface,
          side: const BorderSide(color: _DarkColors.onSurface),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _DarkColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _DarkColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _DarkColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: _DarkColors.primary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _DarkColors.outlineVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _DarkColors.surfaceContainerLowest,
        indicatorColor: _DarkColors.primaryContainer.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _DarkColors.primary : _DarkColors.secondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _DarkColors.primary : _DarkColors.secondary,
          );
        }),
      ),
    );
  }
}
