import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/constants_theme_color.dart';

/// Tema Material3 de la plataforma.
///
/// Uso en [MaterialApp.router]:
/// ```dart
/// MaterialApp.router(
///   theme: AppTheme.light,
/// )
/// ```
abstract final class AppTheme {
  // ──────────────────────────────────────────
  // TEMA CLARO (único para MVP)
  // ──────────────────────────────────────────
  static ThemeData light({Color primaryColor = AppColors.primary}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Esquema de colores
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          background: AppColors.background,
          surface: AppColors.surface,
          primary: primaryColor,
          onPrimary: AppColors.white,
          secondary: AppColors.accentPurple,
          error: AppColors.error,
        ),

        // Fondo del scaffold
        scaffoldBackgroundColor: AppColors.surfaceGrey,

        // Tipografía base: Inter para todo el cuerpo
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.25,
          ),
          headlineLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          headlineMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          headlineSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          bodyLarge: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
          bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: AppColors.textSecondary),
        ),

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ),
        ),

        // OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),

        // TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),

        // InputDecoration global
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceGrey,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        ),

        // Card
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
          margin: EdgeInsets.zero,
        ),

        // Divider
        dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),

        // Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? primaryColor : Colors.transparent),
          checkColor: WidgetStateProperty.all(AppColors.white),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
