import 'package:flutter/material.dart';

/// MaatriCare Design System - Color Tokens
/// Premium maternal healthcare color palette
class MaatriColors {
  MaatriColors._();

  // ─── Primary Palette ───────────────────────────────────────
  static const Color coral = Color(0xFFE8736C);
  static const Color coralLight = Color(0xFFF4A9A4);
  static const Color coralDark = Color(0xFFD4524B);
  static const Color blushPink = Color(0xFFFAD4D8);
  static const Color softRose = Color(0xFFFFF0F2);

  // ─── Background Palette ────────────────────────────────────
  static const Color warmCream = Color(0xFFFFF8F0);
  static const Color ivoryWhite = Color(0xFFFFFDF9);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ─── Accent Palette ────────────────────────────────────────
  static const Color teal = Color(0xFF5BBFBA);
  static const Color tealLight = Color(0xFFB8E8E5);
  static const Color tealDark = Color(0xFF3A9E99);
  static const Color lavender = Color(0xFFD4C5F9);
  static const Color lavenderLight = Color(0xFFEDE5FF);
  static const Color lavenderDark = Color(0xFF9B84D9);
  static const Color goldenAmber = Color(0xFFF5C842);
  static const Color goldenLight = Color(0xFFFFF3CD);
  static const Color mint = Color(0xFFA8E6CF);

  // ─── Neutral Palette ───────────────────────────────────────
  static const Color charcoal = Color(0xFF2D2D3A);
  static const Color darkGray = Color(0xFF4A4A5A);
  static const Color slate = Color(0xFF6B7280);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color lightGray = Color(0xFFD1D5DB);
  static const Color cloudGray = Color(0xFFF3F4F6);
  static const Color snowWhite = Color(0xFFF9FAFB);

  // ─── Semantic Colors ───────────────────────────────────────
  static const Color success = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ─── Glassmorphism ─────────────────────────────────────────
  static const Color glassWhite = Color(0x66FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x0D000000);

  // ─── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, Color(0xFFF4A9A4)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [warmCream, pureWhite],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4524B), coral, Color(0xFFF4A9A4)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, Color(0xFF7ED4D0)],
  );

  static const LinearGradient lavenderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lavender, Color(0xFFEDE5FF)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8F0), Color(0xFFFFFFFF)],
  );
}
