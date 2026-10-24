import 'package:flutter/material.dart';

/// Helper for responsive breakpoints and screen classification.
class AppResponsive {
  AppResponsive._();

  /// Tablets typically have a shortest screen dimension of 600dp or greater.
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// Whether device is currently in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
}

extension AppResponsiveExtension on BuildContext {
  bool get isTablet => AppResponsive.isTablet(this);
  bool get isLandscape => AppResponsive.isLandscape(this);
  double get screenWidth => AppResponsive.screenWidth(this);
  double get screenHeight => AppResponsive.screenHeight(this);
}
