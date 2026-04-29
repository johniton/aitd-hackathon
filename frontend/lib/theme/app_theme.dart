import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg1 = Color(0xFF0F1A15);
  static const Color bg2 = Color(0xFF122018);
  static const Color emerald = Color(0xFF22C55E);
  static const Color lime = Color(0xFF86EFAC);
  static const Color cardBg = Color(0x1A22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color textPrimary = Color(0xFFE2F0E8);
  static const Color textSecondary = Color(0xFF6B9E82);
  static const Color surface = Color(0xFF162311);

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
        unselectedItemColor: Color(0xFF4B7A61),
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
        unselectedLabelColor: Color(0xFF4B7A61),
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
