import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display / Hero ────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    color: AppColors.white,
    letterSpacing: 10,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ── Heading ───────────────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    height: 1.4,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    height: 1.4,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.4,
  );

  // ── App Bar ───────────────────────────────────────────────────────────
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 1,
  );

  // ── Body ──────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    height: 1.4,
  );

  // ── Subtitle ──────────────────────────────────────────────────────────
  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    letterSpacing: 2.5,
    height: 1.4,
  );

  // ── Button ────────────────────────────────────────────────────────────
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // ── Label / Caption ───────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textGrey,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    letterSpacing: 0.2,
  );

  // ── Hint ──────────────────────────────────────────────────────────────
  static const TextStyle hint = TextStyle(
    fontSize: 14,
    color: AppColors.textLightGrey,
    fontWeight: FontWeight.w400,
  );
}
