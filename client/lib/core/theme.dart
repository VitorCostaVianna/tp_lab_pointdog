import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0D0F14);
  static const Color surface = Color(0xFF161922);
  static const Color surface2 = Color(0xFF1E2330);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentAmber = Color(0xFFFFB347);
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0x12FFFFFF);

  static const Color statusPendente = Color(0xFFF59E0B);
  static const Color statusConfirmado = Color(0xFF22C55E);
  static const Color statusCancelado = Color(0xFFEF4444);
  static const Color statusConcluido = Color(0xFF3B82F6);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentAmber,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textPrimary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardColor: surface2,
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted, fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface2,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMADO': return AppTheme.statusConfirmado;
    case 'CANCELADO': return AppTheme.statusCancelado;
    case 'CONCLUIDO': return AppTheme.statusConcluido;
    default: return AppTheme.statusPendente;
  }
}
