import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Google's official test ad units. Replace with your real AdMob unit IDs
/// before release (and the app IDs in AndroidManifest.xml / Info.plist).
class AdIds {
  static bool get _android => !kIsWeb && Platform.isAndroid;

  static String get banner => _android
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';

  static String get interstitial => _android
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get rewarded => _android
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  static String get rewardedInterstitial => _android
      ? 'ca-app-pub-3940256099942544/5354046379'
      : 'ca-app-pub-3940256099942544/6978759866';

  static String get native => _android
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986624511';

  static String get appOpen => _android
      ? 'ca-app-pub-3940256099942544/9257395921'
      : 'ca-app-pub-3940256099942544/5575463023';
}
