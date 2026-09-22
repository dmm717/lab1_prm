import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Claude-Inspired Premium Warm Editorial Light Theme ($150k Agency Tier)
class AppTheme {
  // Brand Color Palette (Claude Warm Terracotta & Editorial Slate)
  static const Color primary = Color(0xFFD96B43); // Claude Terracotta Amber
  static const Color primaryLight = Color(0xFFE57E5B); // Warm Coral Amber
  static const Color primaryDark = Color(0xFFB54F2B); // Deep Terracotta
  static const Color primarySubtle = Color(0xFFFDF2EE); // Soft Terracotta Wash

  static const Color secondary = Color(0xFF346538); // Forest Sage
  static const Color secondarySubtle = Color(0xFFEDF3EC); // Soft Sage Wash

  static const Color accent = Color(0xFF2B5885); // Slate Indigo
  static const Color accentSubtle = Color(0xFFEBF3FA); // Soft Blue Wash

  static const Color warning = Color(0xFF956400); // Warm Ochre
  static const Color warningSubtle = Color(0xFFFBF3DB); // Soft Ochre Wash

  static const Color error = Color(0xFF9F2F2D); // Crimson Red
  static const Color errorSubtle = Color(0xFFFDEBEC);

  // Claude Warm Ivory & Bone Surface Palette
  static const Color background = Color(0xFFF7F6F3); // Claude Warm Ivory Background
  static const Color backgroundSubtle = Color(0xFFF0EFEA); // Warm Porcelain Wash
  static const Color surface = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color surfaceVariant = Color(0xFFFAF9F5); // Warm Soft Card Variation
  static const Color border = Color(0xFFE6E4DF); // Hairline Warm Slate Border
  static const Color borderSubtle = Color(0x1A000000); // 10% Hairline

  // High-Contrast Warm Typography Colors
  static const Color textPrimary = Color(0xFF1F1E1B); // Deep Warm Charcoal
  static const Color textSecondary = Color(0xFF52514D); // Balanced Slate-Charcoal
  static const Color textMuted = Color(0xFF82817C); // Muted Sage-Gray

  // Decorative Gradients
  static const LinearGradient claudeGradient = LinearGradient(
    colors: [Color(0xFFD96B43), Color(0xFFC15C3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGlassGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF9F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    colors: [Color(0xFFD96B43), Color(0xFFE57E5B), Color(0xFF346538)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient terracottaPillGradient = LinearGradient(
    colors: [Color(0xFFFDF2EE), Color(0xFFFAF0EB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Soft Diffuse Box Shadows (< 0.05 Opacity)
  static List<BoxShadow> get softShadow => [
        const BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 16,
          offset: Offset(0, 3),
          spreadRadius: 0,
        ),
        const BoxShadow(
          color: Color(0x04000000),
          blurRadius: 4,
          offset: Offset(0, 1),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        const BoxShadow(
          color: Color(0x18000000), // 9.5% ambient shadow for floating effect
          blurRadius: 24,
          offset: Offset(0, 8),
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: Color(0x0C000000), // 4.5% contact shadow
          blurRadius: 8,
          offset: Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get claudeGlow => [
        BoxShadow(
          color: const Color(0xFFD96B43).withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 3),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardHoverShadow => [
        const BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 20,
          offset: Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  /// Claude Warm Light Theme Definition
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
        backgroundColor: surface.withValues(alpha: 0.95),
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
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
        labelStyle: GoogleFonts.plusJakartaSans(
            color: textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
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
