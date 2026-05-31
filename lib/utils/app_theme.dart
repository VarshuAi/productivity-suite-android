import 'package:flutter/material.dart';

/// App-wide design tokens
class AppTheme {
  // Colors
  static const Color bgPrimary   = Color(0xFF0A0A0F);
  static const Color bgSecondary = Color(0xFF12121A);
  static const Color bgCard      = Color(0xFF1A1A28);
  static const Color bgHover     = Color(0xFF22223A);
  static const Color bgInput     = Color(0xFF16162A);

  static const Color accent      = Color(0xFF6C63FF);
  static const Color accent2     = Color(0xFFA78BFA);
  static const Color accentLight = Color(0x1F6C63FF);
  static const Color accentGlow  = Color(0x406C63FF);

  static const Color success     = Color(0xFF22C55E);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color danger      = Color(0xFFEF4444);
  static const Color info        = Color(0xFF38BDF8);

  static const Color textPrimary   = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF9090B8);
  static const Color textMuted     = Color(0xFF5A5A7A);

  static const Color border        = Color(0x12FFFFFF);
  static const Color borderAccent  = Color(0x666C63FF);

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Priority colors
  static Color priorityColor(String p) {
    switch (p) {
      case 'urgent': case 'high': return danger;
      case 'medium': return warning;
      default: return success;
    }
  }

  // Border radius
  static const double radiusSm  = 6.0;
  static const double radius    = 10.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 24.0;

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> glowShadow = [
    BoxShadow(color: accentGlow, blurRadius: 20),
  ];

  // Text styles
  static const TextStyle labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
    color: bgCard,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: borderColor ?? border, width: 1),
    boxShadow: cardShadow,
  );
}
