import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4F8CFF);
  static const Color primaryLight = Color(0xFF70A7FF);
  static const Color primaryDark = Color(0xFF2864D7);

  // Accent
  static const Color cyan = Color(0xFF35D6FF);
  static const Color success = Color(0xFF35D39A);
  static const Color warning = Color(0xFFFFB84D);
  static const Color danger = Color(0xFFFF5C70);

  // Dark surfaces
  static const Color background = Color(0xFF070B14);
  static const Color backgroundSecondary = Color(0xFF0B1220);
  static const Color surface = Color(0xFF101927);
  static const Color surfaceElevated = Color(0xFF152238);
  static const Color surfaceLight = Color(0xFF1B2A42);

  // Borders
  static const Color border = Color(0xFF22344F);
  static const Color borderLight = Color(0xFF2D4260);

  // Text
  static const Color textPrimary = Color(0xFFF4F7FC);
  static const Color textSecondary = Color(0xFFA9B7CA);
  static const Color textMuted = Color(0xFF718198);

  // Light theme
  static const Color lightBackground = Color(0xFFF5F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF172033);
  static const Color lightTextSecondary = Color(0xFF667085);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),

      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.danger,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(
            color: AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(
          color: AppColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.lightSurface,
        error: AppColors.danger,
      ),

      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: AppColors.lightText,
        displayColor: AppColors.lightText,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFD8E0EA),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFD8E0EA),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}