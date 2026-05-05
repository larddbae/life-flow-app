import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// LifeFlow Design System — Core Theme
// Extracted from Google Stitch DESIGN.md & Tailwind config
// =============================================================================

/// All color tokens from the LifeFlow design system.
///
/// Usage: `AppColors.background`, `AppColors.accentIndigo`, etc.
/// These are intentionally static constants so they can be used in
/// constructors (e.g., BoxDecoration) and are tree-shaken in release.
abstract final class AppColors {
  // ── Surface & Background ──────────────────────────────────────────────────
  static const Color background = Color(0xFF191919);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353535);
  static const Color surfaceCard = Color(0xFF2D2D2D);
  static const Color surfaceVariant = Color(0xFF353535);
  static const Color surfaceNavigation = Color(0xFF1E1E1E);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF3A3A3A);
  static const Color outlineVariant = Color(0xFF454651);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF888888);
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFC6C5D3);

  // ── Primary (Indigo Accent) ───────────────────────────────────────────────
  static const Color accentIndigo = Color(0xFF5C6BC0);
  static const Color primary = Color(0xFFBAC3FF);
  static const Color primaryContainer = Color(0xFF5C6BC0);
  static const Color onPrimary = Color(0xFF15267B);
  static const Color onPrimaryContainer = Color(0xFFF8F6FF);
  static const Color inversePrimary = Color(0xFF4858AB);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFC6C6C7);
  static const Color onSecondary = Color(0xFF2F3131);
  static const Color secondaryContainer = Color(0xFF454747);
  static const Color onSecondaryContainer = Color(0xFFB4B5B5);

  // ── Tertiary ──────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFFF6BD58);
  static const Color onTertiary = Color(0xFF432C00);
  static const Color tertiaryContainer = Color(0xFF976900);
  static const Color onTertiaryContainer = Color(0xFFFFF6EE);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFFB300);
  static const Color statusDanger = Color(0xFFE53935);

  // ── Energy Levels ─────────────────────────────────────────────────────────
  static const Color energy1 = Color(0xFFFF5252);
  static const Color energy2 = Color(0xFFFFAB40); // interpolated orange
  static const Color energy3 = Color(0xFFFFD740);
  static const Color energy4 = Color(0xFF69F0AE); // light green (same as 5 toned)
  static const Color energy5 = Color(0xFF69F0AE);

  // ── Miscellaneous ─────────────────────────────────────────────────────────
  static const Color surfaceTint = Color(0xFFBAC3FF);
  static const Color inverseSurface = Color(0xFFE5E2E1);
  static const Color inverseOnSurface = Color(0xFF313030);
  static const Color outline = Color(0xFF8F909D);

  /// Returns the energy color for a given level (1–5).
  static Color energyColor(int level) {
    return switch (level) {
      1 => energy1,
      2 => energy2,
      3 => energy3,
      4 => energy4,
      5 => energy5,
      _ => textSecondary,
    };
  }
}

/// Typography presets matching the LifeFlow design system.
///
/// All styles use the Inter font family via Google Fonts.
/// Usage: `AppTextStyles.headlineXl`, `AppTextStyles.bodyMd`, etc.
abstract final class AppTextStyles {
  static TextStyle get headlineXl => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
        letterSpacing: -0.56, // -0.02em × 28px
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelCaps => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.96, // 0.08em × 12px
        color: AppColors.textSecondary,
      );

  static TextStyle get metadata => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: AppColors.textSecondary,
      );
}

/// Spacing tokens matching the design system.
abstract final class AppSpacing {
  static const double containerPadding = 20.0; // 1.25rem
  static const double stackGap = 16.0; // 1rem
  static const double itemGapSm = 8.0; // 0.5rem
  static const double cardInnerPadding = 16.0; // 1rem
  static const double sectionMargin = 32.0; // 2rem
}

/// Border radius tokens.
abstract final class AppRadius {
  static const double sm = 4.0; // 0.25rem
  static const double md = 8.0; // 0.5rem
  static const double lg = 12.0; // 0.75rem
  static const double xl = 16.0; // 1rem
  static const double xxl = 24.0; // 1.5rem
  static const double full = 9999.0;

  static final BorderRadius cardRadius = BorderRadius.circular(lg);
  static final BorderRadius chipRadius = BorderRadius.circular(full);
}

/// Global dark theme for the LifeFlow app.
abstract final class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accentIndigo,
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
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.surfaceTint,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headlineXl,
        headlineMedium: AppTextStyles.headlineLg,
        bodyLarge: AppTextStyles.bodyMd,
        bodyMedium: AppTextStyles.bodySm,
        labelSmall: AppTextStyles.labelCaps,
        bodySmall: AppTextStyles.metadata,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: AppTextStyles.headlineLg,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
    );
  }
}
