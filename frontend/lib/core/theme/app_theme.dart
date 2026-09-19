import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette (Pure White & Modern Emerald / Mint Green)
  static const Color primary = Color(0xFF059669); // Emerald 600 - Main Green
  static const Color primaryLight = Color(0xFF10B981); // Emerald 500 - Vibrant Mint
  static const Color primaryDark = Color(0xFF047857); // Emerald 700 - Deep Forest Green
  static const Color primarySubtle = Color(0xFFECFDF5); // Emerald 50 - Clean Mint Wash

  static const Color secondary = Color(0xFF0D9488); // Teal 600 - Harmonious Cyan-Green
  static const Color secondarySubtle = Color(0xFFF0FDFA); // Teal 50

  static const Color accent = Color(0xFF16A34A); // Green 600
  static const Color accentSubtle = Color(0xFFDCFCE7); // Green 100

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningSubtle = Color(0xFFFFFBEB); // Amber 50

  static const Color error = Color(0xFFE11D48); // Rose 600
  static const Color errorSubtle = Color(0xFFFFF1F2); // Rose 50

  // Bright, High-End Surface Colors (Porcelain & Pure White)
  static const Color background = Color(0xFFF7FAF8); // Clean Porcelain with hint of mint
  static const Color backgroundSubtle = Color(0xFFF0FDF4); // Emerald 50
  static const Color surface = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color surfaceVariant = Color(0xFFF5F9F6); // Soft Card Variation
  static const Color border = Color(0xFFE2EFE5); // Hairline Soft Green-Gray
  static const Color borderSubtle = Color(0x12059669); // 7% Emerald hairline

  // High-Contrast Typography Colors
  static const Color textPrimary = Color(0xFF0F1F17); // Deep Forest Charcoal
  static const Color textSecondary = Color(0xFF374E42); // Balanced Slate-Green
  static const Color textMuted = Color(0xFF7D9588); // Subtle Sage Gray

  // Decorative Gradients
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldShineGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBackgroundGradient = LinearGradient(
    colors: [Color(0xFFECFDF5), Color(0xFFF7FAF8), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient subtleCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FCFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient mintPillGradient = LinearGradient(
    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Soft Ambient Box Shadows with Emerald Tint
  static List<BoxShadow> get softShadow => [
    const BoxShadow(
      color: Color(0x0A0F1F17),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    const BoxShadow(
      color: Color(0x06059669),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get emeraldGlow => [
    BoxShadow(
      color: const Color(0xFF10B981).withValues(alpha: 0.25),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardHoverShadow => [
    const BoxShadow(
      color: Color(0x10059669),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
    const BoxShadow(
      color: Color(0x080F1F17),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Bright, Emerald & White High-End Modern Theme
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundSubtle,
        labelStyle: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
