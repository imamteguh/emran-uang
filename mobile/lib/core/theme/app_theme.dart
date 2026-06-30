import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Stitch Color Palette (WalletShare) ───────────────────────────────────
  static const Color primary = Color(0xFF004BC6);          // Royal Blue
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF2463EB); // Royal Blue Container
  static const Color onPrimaryContainer = Color(0xFFEEEFFF);
  static const Color inversePrimary = Color(0xFFB4C5FF);

  static const Color secondary = Color(0xFF246A52);        // Forest Mint
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFA8EECF); // Soft Mint
  static const Color onSecondaryContainer = Color(0xFF296E56);

  static const Color tertiary = Color(0xFF7E4726);         // Bronze Orange
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF9B5E3B);
  static const Color onTertiaryContainer = Color(0xFFFFEDE5);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color primaryFixedDim = Color(0xFFB4C5FF);
  static const Color onPrimaryFixed = Color(0xFF00174B);
  static const Color onPrimaryFixedVariant = Color(0xFF003EA7);

  static const Color secondaryFixed = Color(0xFFABF1D2);
  static const Color secondaryFixedDim = Color(0xFF90D5B7);
  static const Color onSecondaryFixed = Color(0xFF002116);
  static const Color onSecondaryFixedVariant = Color(0xFF00513B);

  static const Color tertiaryFixed = Color(0xFFFFDBCA);
  static const Color tertiaryFixedDim = Color(0xFFFFB68F);
  static const Color onTertiaryFixed = Color(0xFF331200);
  static const Color onTertiaryFixedVariant = Color(0xFF6D3919);

  static const Color background = Color(0xFFF7F9FB);
  static const Color onBackground = Color(0xFF191C1E);

  static const Color surface = Color(0xFFF7F9FB);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color onSurfaceVariant = Color(0xFF434655);

  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);
  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);
  static const Color surfaceTint = Color(0xFF0053DA);

  // Aliases for backward compatibility
  static const Color darkSlate = onBackground;
  static const Color darkSlateVariant = onSurfaceVariant;

  // ── Shapes & Roundedness (Stitch Guidelines) ─────────────────────────────
  static final BorderRadius radiusSm = BorderRadius.circular(8.0);         // sm: 0.5rem (8px)
  static final BorderRadius radiusDefault = BorderRadius.circular(16.0);    // DEFAULT: 1rem (16px)
  static final BorderRadius radiusMd = BorderRadius.circular(24.0);         // md: 1.5rem (24px)
  static final BorderRadius radiusLg = BorderRadius.circular(32.0);         // lg: 2rem (32px)
  static final BorderRadius radiusXl = BorderRadius.circular(48.0);         // xl: 3rem (48px)
  static final BorderRadius radiusFull = BorderRadius.circular(9999.0);     // full: 9999px

  // Aliases for backward compatibility
  static final BorderRadius roundedBorder = radiusLg; // Cards: rounded-xl (32px)
  static final BorderRadius inputBorderRadius = radiusMd; // Inputs: rounded-md (24px)

  // ── Spacing (Stitch Guidelines) ──────────────────────────────────────────
  static const double spaceBase = 4.0;
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceGutter = 16.0;
  static const double marginMobile = 20.0;
  
  // ── Soft Ambient Shadows ─────────────────────────────────────────────────
  // Card Level: Floating cards (Blur: 15px, Spread: 0, Opacity: 5%)
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: onSurface.withAlpha(13), // 5% opacity tinted shadow matching surface
      offset: const Offset(0, 4),
      blurRadius: 15,
      spreadRadius: 0,
    ),
  ];

  // Interactive Level: Buttons and active input fields
  static final List<BoxShadow> interactiveShadow = [
    BoxShadow(
      color: primary.withAlpha(38), // ~15% opacity primary blue shadow
      offset: const Offset(0, 8),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  // Aliases for backward compatibility
  static final List<BoxShadow> softShadow = cardShadow;

  // ── Typography Styles (Stitch Guidelines) ────────────────────────────────
  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.02 * 28,
      );

  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      );

  static TextStyle get headlineSm => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );

  static TextStyle get bodyLg => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      );

  static TextStyle get bodyMd => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );

  static TextStyle get labelMd => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.05 * 14,
      );

  static TextStyle get labelSm => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      );

  static TextStyle get priceDisplay => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 48 / 40,
        letterSpacing: -0.03 * 40,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surfaceContainerLowest,
        onSurface: onSurface,
        surfaceDim: surfaceDim,
        surfaceBright: surfaceBright,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
        surfaceTint: surfaceTint,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      
      // Card theme with 32px rounded corners and soft shadow
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: roundedBorder,
          side: const BorderSide(color: outlineVariant, width: 1.0),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: roundedBorder,
          side: const BorderSide(color: outlineVariant, width: 1.0),
        ),
      ),

      // Button Theme: Fully rounded (pill) ends (Stitch Style: min-height: 56px)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(), // Pill-shaped button
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          backgroundColor: surfaceContainerLowest,
          side: const BorderSide(color: outlineVariant, width: 2.0),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration (Floating label style with 2px borders and sunken BG)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow, // Sunken background
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: const BorderSide(color: outlineVariant, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: const BorderSide(color: outlineVariant, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: const BorderSide(color: primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: const BorderSide(color: error, width: 2.0),
        ),
        labelStyle: GoogleFonts.beVietnamPro(
          color: primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        hintStyle: GoogleFonts.beVietnamPro(
          color: outline,
        ),
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: priceDisplay.copyWith(color: onSurface),
        headlineLarge: headlineLg.copyWith(color: onSurface),
        headlineMedium: headlineMd.copyWith(color: onSurface),
        headlineSmall: headlineSm.copyWith(color: onSurface),
        bodyLarge: bodyLg.copyWith(color: onSurface),
        bodyMedium: bodyMd.copyWith(color: onSurfaceVariant),
        labelLarge: labelMd.copyWith(color: onSurface),
        labelSmall: labelSm.copyWith(color: onSurfaceVariant),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02 * 22,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02 * 18,
        ),
      ),
    );
  }
}
