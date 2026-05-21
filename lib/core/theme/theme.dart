import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';

/// MaatriCare App Theme
class MaatriTheme {
  MaatriTheme._();

  // ─── Spacing Tokens ────────────────────────────────────────
  static const double spacingXxs = 2;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;
  static const double spacing3xl = 64;

  // ─── Radius Tokens ─────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ─── Elevation / Shadow Tokens ─────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowCoral => [
        BoxShadow(
          color: MaatriColors.coral.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowTeal => [
        BoxShadow(
          color: MaatriColors.teal.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Theme Data ────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: MaatriTypography.fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MaatriColors.warmCream,
      primaryColor: MaatriColors.coral,
      colorScheme: const ColorScheme.light(
        primary: MaatriColors.coral,
        onPrimary: Colors.white,
        secondary: MaatriColors.teal,
        onSecondary: Colors.white,
        tertiary: MaatriColors.lavender,
        surface: MaatriColors.pureWhite,
        onSurface: MaatriColors.charcoal,
        error: MaatriColors.danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: MaatriTypography.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: MaatriColors.charcoal,
        ),
        iconTheme: IconThemeData(color: MaatriColors.charcoal),
      ),
      textTheme: const TextTheme(
        displayLarge: MaatriTypography.displayLarge,
        displayMedium: MaatriTypography.displayMedium,
        displaySmall: MaatriTypography.displaySmall,
        headlineLarge: MaatriTypography.headlineLarge,
        headlineMedium: MaatriTypography.headlineMedium,
        headlineSmall: MaatriTypography.headlineSmall,
        titleLarge: MaatriTypography.titleLarge,
        titleMedium: MaatriTypography.titleMedium,
        titleSmall: MaatriTypography.titleSmall,
        bodyLarge: MaatriTypography.bodyLarge,
        bodyMedium: MaatriTypography.bodyMedium,
        bodySmall: MaatriTypography.bodySmall,
        labelLarge: MaatriTypography.labelLarge,
        labelMedium: MaatriTypography.labelMedium,
        labelSmall: MaatriTypography.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MaatriColors.coral,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: MaatriTypography.labelLarge.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MaatriColors.coral,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          side: const BorderSide(color: MaatriColors.coral, width: 1.5),
          textStyle: MaatriTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MaatriColors.coral,
          textStyle: MaatriTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MaatriColors.pureWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: MaatriColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: MaatriColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: MaatriColors.coral, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: MaatriColors.danger),
        ),
        hintStyle: MaatriTypography.bodyMedium.copyWith(
          color: MaatriColors.mediumGray,
        ),
      ),
      cardTheme: CardThemeData(
        color: MaatriColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MaatriColors.pureWhite,
        selectedItemColor: MaatriColors.coral,
        unselectedItemColor: MaatriColors.mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: MaatriTypography.labelSmall,
        unselectedLabelStyle: MaatriTypography.labelSmall,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MaatriColors.coral,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: MaatriColors.cloudGray,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: MaatriColors.cloudGray,
        selectedColor: MaatriColors.coralLight,
        labelStyle: MaatriTypography.chipText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
