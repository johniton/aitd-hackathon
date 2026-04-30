import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Backgrounds — warm off-white / soft beige
  static const Color bg1 = Color(0xFFF5F0E8);       // warm cream
  static const Color bg2 = Color(0xFFEDE8DC);       // slightly deeper beige

  // Accent greens — muted, earthy
  static const Color emerald = Color(0xFF3A7D44);   // deep forest green
  static const Color lime = Color(0xFF6AAB5E);      // sage green

  // Surfaces
  static const Color cardBg = Color(0xFFF0EBE0);    // card background (tinted cream)
  static const Color surface = Color(0xFFE8E2D5);   // slightly deeper surface

  // Status
  static const Color warning = Color(0xFFB45309);   // warm amber-brown (readable on light bg)

  // Text
  static const Color textPrimary = Color(0xFF1C2B1F);   // near-black with green tint
  static const Color textSecondary = Color(0xFF6B7D64);  // muted sage-green

  // Semantic aliases (used by exchange, sensor, etc.)
  static const Color accentIndigo = Color(0xFF4A5785); // muted indigo for carbon/digital
  static const Color accentAmber = Color(0xFFB45309);  // warm amber for medium difficulty / warnings
  static const Color accentRed = Color(0xFF9B2335);    // deep red for errors / buyer verdict
  static const Color accentGold = Color(0xFF92750A);   // gold for Indian schemes / flags

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg1,
      colorScheme: const ColorScheme.light(
        primary: emerald,
        secondary: lime,
        surface: surface,
        error: warning,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        displaySmall: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 15),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        labelLarge: GoogleFonts.inter(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg1,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: emerald,
        unselectedItemColor: Color(0xFF9BAE94),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emerald,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: emerald,
        unselectedLabelColor: Color(0xFF9BAE94),
        indicatorColor: emerald,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emerald),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return emerald;
          return surface;
        }),
      ),
      dividerColor: Color(0xFFD4CCBD),
    );
  }

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg1, bg2],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [emerald, lime],
  );
}
