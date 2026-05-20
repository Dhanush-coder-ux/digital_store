import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern Production-Ready Design System
/// Blue-muted gradient SaaS theme with glassmorphism
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════
  // COLORS - Modern Blue-Muted Gradient Palette
  // ═══════════════════════════════════════════════════════════════════

  // Primary Colors
  static const Color deepBlue = Color(0xFF0F172A); // Slate 900
  static const Color primaryBlue = Color(0xFF2563EB); // Vibrant Royal Blue (Top)
  static const Color softRoyalBlue = Color(0xFF1D4ED8); // Deep Vibrant Blue (Bottom)
  static const Color lightBlue = Color(0xFF4A7BA7); // Light blue
  static const Color skyBlue = Color(0xFF5E9BC3); // Sky blue
  
  // Accent Colors (Muted Cyan)
  static const Color mutedCyan = Color(0xFF4DB8A8); // Muted cyan
  static const Color softCyan = Color(0xFF5ED3C3); // Soft cyan
  static const Color paleCyan = Color(0xFF8FE4D9); // Pale cyan
  
  // Neutral Colors (Muted Grays)
  static const Color darkGray = Color(0xFF1A1D24); // Dark gray
  static const Color mediumGray = Color(0xFF4A4E57); // Medium gray
  static const Color lightGray = Color(0xFF8B8F99); // Light gray
  static const Color veryLightGray = Color(0xFFF0F3F7); // Very light gray
  static const Color ultraLightGray = Color(0xFFF9FAFB); // Ultra light gray
  static const Color white = Color(0xFFFFFFFF); // White
  
  // Status Colors
  static const Color successGreen = Color(0xFF22C55E); // Success
  static const Color warningOrange = Color(0xFFEA580C); // Warning
  static const Color errorRed = Color(0xFFEF4444); // Error
  static const Color infoBlue = Color(0xFF3B82F6); // Info
  
  // Semantic Colors
  static const Color textPrimary = Color(0xFF1A1D24); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray
  static const Color textInverse = Color(0xFFFFFFFF); // White
  
  // Background Colors
  static const Color bgPrimary = Color(0xFFF9FAFB); // Ultra light
  static const Color bgSecondary = Color(0xFFF0F3F7); // Very light
  static const Color bgTertiary = Color(0xFFE5ECF3); // Light blue tinted
  
  // Glass Colors (Glassmorphism)
  static const Color glassLight = Color(0xFFFFFFFF); // White with opacity
  static const Color glassDark = Color(0xFF1A3A52); // Blue with opacity
  
  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      softRoyalBlue.withOpacity(0.8),
      primaryBlue.withOpacity(0.9),
    ],
  );
  
  static LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      softCyan.withOpacity(0.7),
      mutedCyan.withOpacity(0.8),
    ],
  );
  
  static LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ultraLightGray,
      bgSecondary,
    ],
  );

  // ═══════════════════════════════════════════════════════════════════
  // SPACING SYSTEM
  // ═══════════════════════════════════════════════════════════════════
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  
  // ═══════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════════════════════════
  
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  
  // ═══════════════════════════════════════════════════════════════════
  // SHADOWS - Soft & Elegant
  // ═══════════════════════════════════════════════════════════════════
  
  static final List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: darkGray.withOpacity(0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  static final List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: darkGray.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static final List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: darkGray.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static final List<BoxShadow> shadowXlarge = [
    BoxShadow(
      color: darkGray.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Glass effect shadow
  static final List<BoxShadow> glassBoxShadow = [
    BoxShadow(
      color: darkGray.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════════════
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: mutedCyan,
        tertiary: skyBlue,
        surface: white,
        background: bgPrimary,
        error: errorRed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bgPrimary,
      
      // ─────────────────────────────────────────────────────────────────
      // TEXT THEME - Premium Typography
      // ─────────────────────────────────────────────────────────────────
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        // Display
        displayLarge: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.5,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        
        // Headline
        headlineLarge: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        
        // Title
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        
        // Body
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
        
        // Label
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textTertiary,
          letterSpacing: 0.5,
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // CARD THEME - Glass Morphism
      // ─────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: darkGray.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(
            color: veryLightGray.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // INPUT DECORATION THEME
      // ─────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: lg,
          vertical: md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(
            color: veryLightGray.withOpacity(0.7),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide(
            color: veryLightGray.withOpacity(0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(
            color: errorRed,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(
            color: errorRed,
            width: 1.5,
          ),
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return primaryBlue;
          }
          return lightGray;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return primaryBlue;
          }
          return lightGray;
        }),
        hintStyle: GoogleFonts.outfit(
          color: textTertiary,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // ELEVATED BUTTON THEME
      // ─────────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: lg,
            vertical: md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // OUTLINED BUTTON THEME
      // ─────────────────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(
            color: primaryBlue,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: lg,
            vertical: md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // TEXT BUTTON THEME
      // ─────────────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: lg,
            vertical: md,
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // APP BAR THEME
      // ─────────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
          size: 24,
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // BOTTOM SHEET THEME
      // ─────────────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXxl),
          ),
        ),
        elevation: 0,
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // DIALOG THEME
      // ─────────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // CHIP THEME
      // ─────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: veryLightGray,
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        side: BorderSide(
          color: veryLightGray.withOpacity(0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: md,
          vertical: xs,
        ),
      ),
      
      // ─────────────────────────────────────────────────────────────────
      // DIVIDER THEME
      // ─────────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: veryLightGray.withOpacity(0.7),
        thickness: 1,
        space: xl,
      ),
    );
  }
}
