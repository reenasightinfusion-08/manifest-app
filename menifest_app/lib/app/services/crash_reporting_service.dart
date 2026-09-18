import 'package:flutter/foundation.dart';

/// Minimal, dependency-free crash-reporting hook.
///
/// This project doesn't have a real crash-reporting SDK (Crashlytics,
/// Sentry, etc.) wired in, so there's nowhere to actually upload a crash
/// report to yet. What this DOES do honestly is respect the "Crash
/// Reports" toggle in Privacy Settings: [enabled] is kept in sync with
/// that switch by UserProvider, and main.dart's global error handlers
/// (installed on `FlutterError.onError` / `PlatformDispatcher.onError`)
/// check it before logging a caught error — so turning the switch off
/// actually stops the extra crash logging, instead of being a switch
/// connected to nothing. The default Flutter red-screen/console error
/// still always shows regardless of this flag — that's Flutter's own
/// developer-facing error output, not "crash reporting".
///
/// Swap [logCrash] for a real SDK call (e.g.
/// `FirebaseCrashlytics.instance.recordFlutterError(...)`) if/when one is
/// added; the call sites in main.dart stay the same.
class CrashReportingService {
  static bool enabled = true;

  static void logCrash(Object error, StackTrace? stackTrace, {String? context}) {
    if (!enabled) return;
    debugPrint('[crash-report]${context != null ? ' [$context]' : ''} $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
