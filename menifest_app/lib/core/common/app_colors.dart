import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Palette ───────────────────────────────────────────────────
  static const Color pink = Color(0xFFE91E8C);
  static const Color pinkLight = Color(0xFFFF6BC1);
  static const Color purple = Color(0xFF7B2FF7);
  static const Color purpleLight = Color(0xFFAB6FF5);
  static const Color blue = Color(0xFF2979FF);
  static const Color blueLight = Color(0xFF64B5F6);

  // ── Gradients ─────────────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF7B2FF7),
    Color(0xFFE91E8C),
  ];

  static const List<Color> softGradient = [
    Color(0xFFF3EEFF), // soft lavender
    Color(0xFFFFEEF7), // soft pink
  ];

  // ── Base Colors ───────────────────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ── Backgrounds & Surfaces ────────────────────────────────────────────
  static const Color background = Colors.white;
  static const Color surfaceLight = Color(0xFFF8F4FF);
  static const Color surfaceVeryLight = Color(0xFFFBF9FF);
  static const Color cardBg = Colors.white;

  // ── Borders ───────────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFEEE5FF);
  static const Color borderVeryLight = Color(0xFFF3EEFF);
  static const Color borderFaded = Color(0xFFE8E0F5);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF757585);
  static const Color textLightGrey = Color(0xFFBBB0CC);
  static const Color textFaded = Color(0xFF9E9EAE);

  // ── Glow & Shadows ────────────────────────────────────────────────────
  static const Color glowPink = Color(0x66E91E8C);
  static const Color glowPurple = Color(0x667B2FF7);
  static const Color glowBlue = Color(0x662979FF);

  // ── Success / Warning / Error ─────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE91E8C);
  static const Color errorRed = Color(0xFFFF5252);

  // ── Specific Components ───────────────────────────────────────────────
  static const Color inputFill = Color(0xFFF8F4FF);
  static const Color stepDotInactive = Color(0xFFDDD0F5);
}
