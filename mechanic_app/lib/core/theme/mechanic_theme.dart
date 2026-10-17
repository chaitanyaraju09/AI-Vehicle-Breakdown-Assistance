
import 'package:flutter/material.dart' as flutter;
import 'package:google_fonts/google_fonts.dart';

class MechanicTheme {
  MechanicTheme._();

  // Blue colour palette
  static const flutter.Color primary = flutter.Color(0xFF4D8DFF);
  static const flutter.Color primaryLight = flutter.Color(0xFF75ACFF);
  static const flutter.Color primaryDark = flutter.Color(0xFF2563EB);

  // Backgrounds and surfaces
  static const flutter.Color background = flutter.Color(0xFF0B1120);
  static const flutter.Color surface = flutter.Color(0xFF111C2E);
  static const flutter.Color surfaceElevated = flutter.Color(0xFF1A2940);
  static const flutter.Color elevated = surfaceElevated;
  static const flutter.Color border = flutter.Color(0xFF263954);

  // Text colours
  static const flutter.Color textPrimary = flutter.Color(0xFFF1F5F9);
  static const flutter.Color textSecondary = flutter.Color(0xFF94A3B8);
  static const flutter.Color textMuted = flutter.Color(0xFF64748B);

  // Status colours
  static const flutter.Color success = flutter.Color(0xFF22C55E);
  static const flutter.Color warning = flutter.Color(0xFFF59E0B);
  static const flutter.Color danger = flutter.Color(0xFFEF4444);
  static const flutter.Color info = flutter.Color(0xFF38BDF8);

  static flutter.TextTheme _textTheme() {
    final flutter.TextTheme base = flutter.ThemeData.dark().textTheme;

    // Start with Flutter's TextTheme and customise it.
    // This avoids the TextTheme type conflict.
    return base.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        textStyle: base.displayLarge,
        fontWeight: flutter.FontWeight.bold,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        textStyle: base.displayMedium,
        fontWeight: flutter.FontWeight.bold,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        textStyle: base.headlineLarge,
        fontWeight: flutter.FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        textStyle: base.headlineMedium,
        fontWeight: flutter.FontWeight.w600,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        textStyle: base.titleLarge,
        fontWeight: flutter.FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: base.bodyLarge,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: base.bodyMedium,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: base.bodySmall,
        color: textMuted,
      ),
    );
  }

  static flutter.ThemeData get themeData => darkTheme;

  static flutter.ThemeData get darkTheme {
    return flutter.ThemeData(
      useMaterial3: true,
      brightness: flutter.Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const flutter.ColorScheme.dark(
        primary: primary,
        onPrimary: flutter.Colors.white,
        secondary: primaryLight,
        onSecondary: flutter.Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
        onError: flutter.Colors.white,
      ),
      textTheme: _textTheme(),

      appBarTheme: const flutter.AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: flutter.CardThemeData(
        color: surface,
        elevation: 0,
        margin: flutter.EdgeInsets.zero,
        shape: flutter.RoundedRectangleBorder(
          borderRadius: flutter.BorderRadius.circular(20),
          side: const flutter.BorderSide(color: border),
        ),
      ),

      inputDecorationTheme: flutter.InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        hintStyle: const flutter.TextStyle(color: textSecondary),
        contentPadding: const flutter.EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: flutter.OutlineInputBorder(
          borderRadius: flutter.BorderRadius.circular(14),
          borderSide: const flutter.BorderSide(color: border),
        ),
        enabledBorder: flutter.OutlineInputBorder(
          borderRadius: flutter.BorderRadius.circular(14),
          borderSide: const flutter.BorderSide(color: border),
        ),
        focusedBorder: flutter.OutlineInputBorder(
          borderRadius: flutter.BorderRadius.circular(14),
          borderSide: const flutter.BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: flutter.ElevatedButtonThemeData(
        style: flutter.ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: flutter.Colors.white,
          elevation: 0,
          padding: const flutter.EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 16,
          ),
          shape: flutter.RoundedRectangleBorder(
            borderRadius: flutter.BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: flutter.OutlinedButtonThemeData(
        style: flutter.OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const flutter.BorderSide(color: border),
          shape: flutter.RoundedRectangleBorder(
            borderRadius: flutter.BorderRadius.circular(14),
          ),
        ),
      ),

      navigationBarTheme: const flutter.NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: surfaceElevated,
        labelTextStyle: flutter.WidgetStatePropertyAll(
          flutter.TextStyle(fontSize: 12),
        ),
      ),

      chipTheme: flutter.ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: flutter.Color(0xFF263F69),
        side: const flutter.BorderSide(color: border),
        labelStyle: const flutter.TextStyle(color: textSecondary),
        shape: flutter.RoundedRectangleBorder(
          borderRadius: flutter.BorderRadius.circular(12),
        ),
      ),

      dividerColor: border,
      progressIndicatorTheme: const flutter.ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}
