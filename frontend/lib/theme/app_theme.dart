import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg1 = Color(0xFF0A0F0A);
  static const Color bg2 = Color(0xFF0D1A0D);
  static const Color emerald = Color(0xFF10B981);
  static const Color lime = Color(0xFF84CC16);
  static const Color cardBg = Color(0x1410B981);
  static const Color warning = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color surface = Color(0xFF1A2E1A);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg1,
      colorScheme: const ColorScheme.dark(
        primary: emerald,
        secondary: lime,
        surface: surface,
        error: warning,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
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
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emerald,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: emerald,
        unselectedLabelColor: textSecondary,
        indicatorColor: emerald,
      ),
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
