import 'package:flutter/material.dart';

class CyberTheme {
  // Colores principales
  static const Color bg = Color(0xFF05080f);
  static const Color bgCard = Color(0xFF0a0e1a);
  static const Color accent = Color(0xFF4080ff);
  static const Color accentGlow = Color(0xFF00f0ff);
  static const Color textPrimary = Color(0xFF8ab4f8);
  static const Color textSecondary = Color(0xFF556688);
  static const Color dotOn = Color(0xFF00f0ff);
  static const Color dotOff = Color(0xFF112233);
  static const Color inputBg = Color(0xFF040810);
  static const Color inputBorder = Color(0xFF0d1a2e);
  static const Color danger = Color(0xFFff4466);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        fontFamily: 'ShareTechMono',
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentGlow,
          surface: bgCard,
          error: danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 5,
            color: textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: inputBorder),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: inputBorder,
          thumbColor: accentGlow,
          overlayColor: accentGlow.withValues(alpha: 0.2),
          trackHeight: 3,
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: textPrimary),
        ),
      );
}
