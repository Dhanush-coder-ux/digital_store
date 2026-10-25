import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Local Commerce Design System — Warm Tangerine Theme
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════
  // CENTRALIZED COLOR TOKENS — Warm Tangerine Palette
  // ═══════════════════════════════════════════════════════════════════

  // Primary brand
  static const Color primary              = Color(0xFFF28C28); // Warm Tangerine
  static const Color primaryDark          = Color(0xFFD96B16); // Primary pressed/dark
  static const Color softPeach            = Color(0xFFFFF3E3); // Soft peach
  static const Color background           = Color(0xFFFCFAF6); // App background
  static const Color surface              = Color(0xFFFFFFFF); // Surface
  static const Color primaryText          = Color(0xFF493629); // Primary text
  static const Color secondaryText        = Color(0xFF8A7664); // Secondary text
  static const Color border               = Color(0xFFE9E2D8); // Border
  static const Color success              = Color(0xFF258A68); // Success
  static const Color successBackground    = Color(0xFFE9F7EF); // Soft success green bg
  static const Color error                = Color(0xFFDC2626); // Accessible red
  static const Color errorBackground      = Color(0xFFFEF2F2); // Pale red background
  static const Color information          = Color(0xFF2563EB); // Accessible blue
  static const Color informationBackground= Color(0xFFEFF6FF); // Pale blue background

  // Compatibility aliases
  static const Color bgPrimary    = background;
  static const Color bgSecondary  = Color(0xFFF7F1E7); // Warm cream
  static const Color bgTertiary   = border;
  static const Color white        = surface;

  // Tangerine Identity (retained as primaryBlue for backward compat)
  static const Color primaryBlue   = primary;     // 0xFFF28C28
  static const Color softRoyalBlue = primaryDark; // 0xFFD96B16
  static const Color lightBlue     = softPeach;   // 0xFFFFF3E3
  static const Color skyBlue       = softPeach;   // 0xFFFFF3E3

  // Legacy color names kept for compatibility
  static const Color deepBlue  = primaryText;
  static const Color mutedCyan = secondaryText;
  static const Color softCyan  = secondaryText;
  static const Color paleCyan  = softPeach;

  // Typography
  static const Color textPrimary   = primaryText;
  static const Color textSecondary = secondaryText;
  static const Color textTertiary  = Color(0xFFAFA293);
  static const Color textInverse   = surface;

  // Neutrals
  static const Color darkGray       = primaryText;
  static const Color mediumGray     = secondaryText;
  static const Color lightGray      = Color(0xFFAFA293);
  static const Color veryLightGray  = border;
  static const Color ultraLightGray = background;

  // Status
  static const Color successGreen  = success;
  static const Color successBg     = successBackground;
  static const Color warningOrange = primary;
  static const Color errorRed      = error;
  static const Color errorBg       = errorBackground;
  static const Color infoBlue      = information;
  static const Color infoBg        = informationBackground;

  // Glass (kept for compat)
  static const Color glassLight = surface;
  static const Color glassDark  = primaryText;

  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF28C28), Color(0xFFD96B16)],
  );
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCFAF6), Color(0xFFF7F1E7)],
  );
  static LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF3E3), Color(0xFFE9E2D8)],
  );

  // ═══════════════════════════════════════════════════════════════════
  // SPACING — 8-point system
  // ═══════════════════════════════════════════════════════════════════
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  // ═══════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 10.0;
  static const double radiusLg  = 12.0;
  static const double radiusXl  = 16.0;
  static const double radiusXxl = 20.0;

  // Semantic aliases for cohesive access
  static const Color primaryTangerine     = primary;
  static const Color primaryTangerineDark = primaryDark;
  static const Color softCream            = bgSecondary;
  static const Color sageGreen            = success;
  static const Color sageGreenBg          = successBackground;
  static const Color primaryAmber         = primary;

  // ═══════════════════════════════════════════════════════════════════
  // SHADOWS — Restrained Warm Elevation
  // ═══════════════════════════════════════════════════════════════════
  static final List<BoxShadow> shadowSmall = [
    BoxShadow(color: const Color(0xFF493629).withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
  ];
  static final List<BoxShadow> shadowMedium = [
    BoxShadow(color: const Color(0xFF493629).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
  ];
  static final List<BoxShadow> shadowLarge = [
    BoxShadow(color: const Color(0xFF493629).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4)),
  ];
  static final List<BoxShadow> shadowXlarge = [
    BoxShadow(color: const Color(0xFF493629).withValues(alpha: 0.10), blurRadius: 28, offset: const Offset(0, 6)),
  ];
  static final List<BoxShadow> glassBoxShadow = shadowMedium;

  // ═══════════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondaryText,
        tertiary: softPeach,
        surface: surface,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge:  GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w700, color: primaryText, letterSpacing: -1),
        displayMedium: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w700, color: primaryText),
        displaySmall:  GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: primaryText),
        headlineLarge:  GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: primaryText),
        headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: primaryText),
        headlineSmall:  GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: primaryText),
        titleLarge:  GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: primaryText),
        titleMedium: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
        titleSmall:  GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
        bodyLarge:  GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w400, color: primaryText),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: secondaryText),
        bodySmall:  GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: textTertiary),
        labelLarge:  GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
        labelMedium: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryText, letterSpacing: 0.4),
        labelSmall:  GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: textTertiary, letterSpacing: 0.5),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusLg), borderSide: const BorderSide(color: error, width: 1.5)),
        hintStyle: GoogleFonts.outfit(color: textTertiary, fontSize: 14),
        labelStyle: GoogleFonts.outfit(color: secondaryText, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: lg, vertical: md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: xs),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700, color: primaryText),
        iconTheme: IconThemeData(color: primaryText, size: 22),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXxl))),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgSecondary,
        selectedColor: softPeach,
        labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: primaryText),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        padding: const EdgeInsets.symmetric(horizontal: md, vertical: xs),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: lg),
    );
  }
}
