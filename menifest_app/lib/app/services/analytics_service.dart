import 'package:flutter/foundation.dart';

/// Minimal, dependency-free usage-analytics logger.
///
/// This project doesn't have a real analytics SDK (Firebase Analytics,
/// Mixpanel, etc.) wired in, so there's nothing to forward events to yet.
/// What this DOES do honestly is respect the "Usage Analytics" toggle in
/// Privacy Settings: [enabled] is kept in sync with that switch by
/// UserProvider, and every call site below checks it before logging
/// anything — so turning the switch off actually stops events from being
/// recorded, instead of being a switch connected to nothing.
///
/// Swap the body of [logEvent] for a real SDK call (e.g.
/// `FirebaseAnalytics.instance.logEvent(...)`) if/when one is added; every
/// call site elsewhere in the app stays the same.
class AnalyticsService {
  static bool enabled = true;

  static void logEvent(String name, [Map<String, dynamic>? params]) {
    if (!enabled) return;
    debugPrint('[analytics] $name${params != null ? ' $params' : ''}');
  }
}
