import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Resolves colors based on current brightness (dark/light).
class CT {
  static bool isDark = true;
  static void setBrightness(bool dark) => isDark = dark;

  // ── Backgrounds ──
  static Color get bg => isDark ? const Color(0xFF050810) : const Color(0xFFe8ecf4);
  static Color get bgCard => isDark ? const Color(0xFF0a0f1e) : const Color(0xFFf0f3fa);
  static Color get bgCardAlt => isDark ? const Color(0xFF08101e) : const Color(0xFFe4e8f2);

  // ── Borders ──
  static Color get borderPanel => isDark ? const Color(0xFF1a3a6e) : const Color(0xFFb0c0e0);
  static Color get borderPanelAlt => isDark ? const Color(0xFF112244) : const Color(0xFFc0cce0);
  static Color get borderCorner => isDark ? const Color(0xFF2060cc) : const Color(0xFF5090e0);

  // ── Accents ──
  static Color get accent => isDark ? const Color(0xFF4080ff) : const Color(0xFF2060cc);
  static Color get accentGlow => isDark ? const Color(0xFF00aaff) : const Color(0xFF0088dd);
  static Color get dotOn => isDark ? const Color(0xFF00aaff) : const Color(0xFF0080cc);
  static Color get dotOff => isDark ? const Color(0xFF1a3a6e) : const Color(0xFFc0cce0);

  // ── Text ──
  static Color get textHeader => isDark ? const Color(0xFF4080cc) : const Color(0xFF2a5090);
  static Color get textTitle => isDark ? const Color(0xFF88aaff) : const Color(0xFF1a3a70);
  static Color get textPrimary => isDark ? const Color(0xFF88aaff) : const Color(0xFF1a3a70);
  static Color get textSecondary => isDark ? const Color(0xFF2a4a80) : const Color(0xFF6080b0);
  static Color get textSys => isDark ? const Color(0xFF2a5090) : const Color(0xFF5070a0);
  static Color get textVol => isDark ? const Color(0xFF2a4a80) : const Color(0xFF6080b0);

  // ── Inputs ──
  static Color get inputBg => isDark ? const Color(0xFF040810) : const Color(0xFFffffff);
  static Color get inputBorder => isDark ? const Color(0xFF0f2040) : const Color(0xFFc0cce0);
  static Color get inputColor => isDark ? const Color(0xFF88aaff) : const Color(0xFF1a3060);
  static Color get inputPlaceholder => isDark ? const Color(0xFF0d1e3a) : const Color(0xFFa0b0c8);
  static Color get inputFocusBorder => isDark ? const Color(0xFF1a4aaa) : const Color(0xFF4080cc);

  // ── Progress ──
  static Color get progBg => isDark ? const Color(0xFF0a1530) : const Color(0xFFd0d8e8);
  static Color get progDot => isDark ? const Color(0xFF00aaff) : const Color(0xFF0088dd);

  // ── Buttons ──
  static Color get btnFill => isDark ? const Color(0xFF4070cc) : const Color(0xFF3060aa);
  static Color get btnHoverFill => isDark ? const Color(0xFF00aaff) : const Color(0xFF0080cc);
  static Color get btnActiveBorder => isDark ? const Color(0xFF0060ff) : const Color(0xFF3080ee);
  static Color get addBorder => isDark ? const Color(0xFF1a4090) : const Color(0xFF6090cc);
  static Color get addText => isDark ? const Color(0xFF4080ff) : const Color(0xFF2060bb);

  // ── Playlist items ──
  static Color get plBg => isDark ? const Color(0xFF060c1a) : const Color(0xFFf5f7fc);
  static Color get plBorder => isDark ? const Color(0xFF0f2040) : const Color(0xFFc8d4e8);
  static Color get plActiveBorder => isDark ? const Color(0xFF0055cc) : const Color(0xFF4090ee);
  static Color get plActiveBg => isDark ? const Color(0xFF08163a) : const Color(0xFFdce8ff);
  static Color get plName => isDark ? const Color(0xFF6090dd) : const Color(0xFF2a4a80);
  static Color get plNameActive => isDark ? const Color(0xFF88aaff) : const Color(0xFF1040a0);
  static Color get plIdColor => isDark ? const Color(0xFF1a3060) : const Color(0xFF8098c0);
  static Color get plBadgeBg => isDark ? const Color(0xFF040c1c) : const Color(0xFFe8eef8);
  static Color get plBadgeBorder => isDark ? const Color(0xFF0a1e40) : const Color(0xFFb8c8e0);
  static Color get plBadgeColor => isDark ? const Color(0xFF1a3a6e) : const Color(0xFF5070a0);

  // ── Volume ──
  static Color get volFill => isDark ? const Color(0xFF0060cc) : const Color(0xFF3080dd);
  static Color get volTrack => isDark ? const Color(0xFF0a1530) : const Color(0xFFd0d8e8);

  // ── Misc ──
  static Color get counterColor => isDark ? const Color(0xFF1a3a6e) : const Color(0xFF6080b0);
  static Color get labelColor => isDark ? const Color(0xFF2a4a70) : const Color(0xFF5070a0);
  static Color get formBg => isDark ? const Color(0xFF060c1a) : const Color(0xFFf0f3fa);
  static Color get formBorder => isDark ? const Color(0xFF0f2040) : const Color(0xFFc0cce0);
  static Color get danger => isDark ? const Color(0xFF6a3a3a) : const Color(0xFFcc5555);
  static Color get dangerBright => const Color(0xFFff4444);

  // ── Scanlines ──
  static Color get scanlineColor => isDark ? const Color(0x0400AAFF) : const Color(0x06004488);

  // ── Auth ──
  static Color get authWarningBg => isDark ? const Color(0x10009BFF) : const Color(0x200070CC);
  static Color get authWarningBorder => isDark ? const Color(0x2600AAFF) : const Color(0x400070CC);

  // ── Bottom nav ──
  static Color get navBg => isDark ? const Color(0xFF060a14) : const Color(0xFFe0e6f0);
  static Color get navBorder => isDark ? const Color(0xFF1a3a6e) : const Color(0xFFb0c0e0);
  static Color get navActive => isDark ? const Color(0xFF00aaff) : const Color(0xFF0070cc);
  static Color get navInactive => isDark ? const Color(0xFF1a3a6e) : const Color(0xFF8098b8);
}

class CyberTheme {
  // ── Keep static const for backward compat in vinyl/tonearm painters ──
  static const Color borderPanel = Color(0xFF1a3a6e);
  static const Color borderCorner = Color(0xFF2060cc);
  static const Color labelBorder = Color(0xFF2a4aaf);
  static const Color textLabel = Color(0xFF88aaff);
  static const Color textLabelSub = Color(0xFF4466cc);
  static const Color axleBorder = Color(0xFF4060af);
  static const Color pivotBorder = Color(0xFF3060af);

  // Vinyl (always dark regardless of theme)
  static const Color vinylDark = Color(0xFF0c0c18);
  static const Color vinylLight = Color(0xFF131322);
  static const Color grooveColor = Color(0x10649BFF);
  static const Color labelBg = Color(0xFF0d1f5c);
  static const Color axleBg = Color(0xFF2a4aaf);

  // Tonearm (always dark)
  static const Color armColor = Color(0xFF3060af);
  static const Color headColor = Color(0xFF4080ff);
  static const Color needleTop = Color(0xFF88aaff);
  static const Color needleBottom = Color(0xFFcc44ff);
  static const Color pivotColor = Color(0xFF60a0ff);

  // Waveform (always dark)
  static const Color wfGradientBottom = Color(0xFF0040aa);
  static const Color wfGradientTop = Color(0xFF0088ff);
  static const Color wfActiveBottom = Color(0xFF0060dd);
  static const Color wfActiveTop = Color(0xFF00ccff);

  // Shadows
  static BoxShadow get panelShadow => BoxShadow(
    color: const Color(0xFF0078FF).withValues(alpha: 0.08),
    blurRadius: 60,
  );

  static BoxShadow glowShadow(Color color, {double blur = 12}) => BoxShadow(
    color: color.withValues(alpha: 0.3),
    blurRadius: blur,
  );

  // ── Text styles ──
  static TextStyle get orbitron => GoogleFonts.orbitron();
  static TextStyle get mono => GoogleFonts.shareTechMono();

  // ── Decorations (dynamic via CT) ──
  static BoxDecoration get panelDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: CT.isDark
          ? [const Color(0xFF0a0f1e), const Color(0xFF0d1528), const Color(0xFF080c18)]
          : [const Color(0xFFf0f3fa), const Color(0xFFe8ecf4), const Color(0xFFe4e8f0)],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: CT.borderPanel),
    boxShadow: [panelShadow],
  );

  static BoxDecoration get panelAltDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: CT.isDark
          ? [const Color(0xFF08101e), const Color(0xFF060c18)]
          : [const Color(0xFFe4e8f2), const Color(0xFFdce0ec)],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: CT.borderPanelAlt),
  );

  static BoxDecoration get inputDecoration => BoxDecoration(
    color: CT.inputBg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: CT.inputBorder),
  );

  // ── Theme data ──
  static ThemeData get darkTheme => _buildTheme(true);
  static ThemeData get lightTheme => _buildTheme(false);

  static ThemeData _buildTheme(bool dark) {
    CT.setBrightness(dark);
    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: CT.bg,
      fontFamily: GoogleFonts.shareTechMono().fontFamily,
      colorScheme: dark
          ? const ColorScheme.dark(
              primary: Color(0xFF4080ff),
              secondary: Color(0xFF00aaff),
              surface: Color(0xFF0a0f1e),
              error: Color(0xFFff4444),
            )
          : const ColorScheme.light(
              primary: Color(0xFF2060cc),
              secondary: Color(0xFF0088dd),
              surface: Color(0xFFf0f3fa),
              error: Color(0xFFff4444),
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: CT.bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 5,
          color: CT.textHeader,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: CT.accent,
        inactiveTrackColor: CT.inputBorder,
        thumbColor: CT.accentGlow,
        overlayColor: CT.accentGlow.withValues(alpha: 0.15),
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
    );
  }
}
