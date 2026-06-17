import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background  = Color(0xFF0D0F14);
  static const Color surface     = Color(0xFF161922);
  static const Color surface2    = Color(0xFF1E2330);
  static const Color surface3    = Color(0xFF252C3D);
  static const Color accent      = Color(0xFFFF6B35);
  static const Color accentAmber = Color(0xFFFFB347);
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textMuted   = Color(0xFF6B7280);
  static const Color border      = Color(0x18FFFFFF);

  static const Color statusPendente  = Color(0xFFF59E0B);
  static const Color statusConfirmado= Color(0xFF22C55E);
  static const Color statusCancelado = Color(0xFFEF4444);
  static const Color statusConcluido = Color(0xFF3B82F6);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A0D06), Color(0xFF2A1A0E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(50),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentAmber,
        surface: surface,
        surfaceContainer: surface2,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        outline: border,
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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface2,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withAlpha(45),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.outfit(color: textMuted, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent, size: 22);
          }
          return const IconThemeData(color: textMuted, size: 22);
        }),
      ),
      cardTheme: CardThemeData(
        color: surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusCancelado),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13),
        prefixIconColor: textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface2,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface3,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMADO': return AppTheme.statusConfirmado;
    case 'CANCELADO':  return AppTheme.statusCancelado;
    case 'CONCLUIDO':  return AppTheme.statusConcluido;
    default:           return AppTheme.statusPendente;
  }
}

String statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMADO': return 'Confirmado';
    case 'CANCELADO':  return 'Cancelado';
    case 'CONCLUIDO':  return 'Concluído';
    default:           return 'Pendente';
  }
}
