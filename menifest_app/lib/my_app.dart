import 'dart:async';
import 'package:flutter/material.dart';
import 'core/common/core.dart';
import 'app/screens/splash_screen/splash_screen.dart';
import 'app/screens/on_boarding_screen/onboarding_screen.dart';
import 'app/screens/home_screen.dart';
import 'app/screens/on_boarding_screen/welcome_screen.dart';
import 'app/screens/on_boarding_screen/security_screen.dart';
import 'app/screens/security/app_lock_screen.dart';
import 'app/screens/user_profile/user_info_screen.dart';
import 'app/screens/user_profile/profile_screen.dart';
import 'app/screens/user_profile/edit_profile_screen.dart';
import 'app/screens/user_profile/action_detail_screen.dart';
import 'app/screens/user_profile/vision_board_screen.dart';
import 'app/screens/user_profile/spiritual_archetype_screen.dart';
import 'app/screens/user_profile/privacy_settings_screen.dart';
import 'app/screens/user_profile/notification_settings_screen.dart';

import 'package:provider/provider.dart';
import 'app/services/onboarding_provider.dart';
import 'app/services/splash_provider.dart';
import 'app/services/manifest_provider.dart';
import 'app/services/user_provider.dart';
import 'app/services/notification_service.dart';

// Routes that aren't "inside the app" yet (or already are the lock screen
// itself) — the idle timer and the background-return lock both skip these,
// otherwise the lock could fire over onboarding or double up on itself.
const _kLockExemptRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.welcome,
  AppRoutes.security,
  AppRoutes.userInfo,
  AppRoutes.appLock,
  AppRoutes.verifyEmail,
};

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Global so the lifecycle callback (which has no BuildContext of its own)
  // can reach the Navigator and, through it, the providers above it. Shared
  // with NotificationService so a notification tap can navigate too.
  GlobalKey<NavigatorState> get _navigatorKey => NotificationService.navigatorKey;

  // Set true the moment the app is backgrounded; consumed the moment it's
  // foregrounded again. This is what makes the lock re-trigger on every
  // return to the app, not just a full cold start.
  bool _shouldLockOnResume = false;

  // When the app was backgrounded. Resuming within [_autoLockAfter] (e.g.
  // a quick glance at a notification, a permission dialog, the share
  // sheet) skips the lock; resuming after that re-locks the session.
  DateTime? _pausedAt;
  static const _autoLockAfter = Duration(minutes: 5);

  // Foreground idle session timer: locks even if the app is never
  // backgrounded, just left sitting open and untouched. Any touch anywhere
  // in the app (via the Listener wrapping MaterialApp below) restarts the
  // clock. Rearms itself every time — after an unlock, the very next tap
  // starts the next 5-minute countdown, so it fires again and again.
  Timer? _idleTimer;
  static const _idleTimeout = Duration(minutes: 5);

  // Name of whatever route is currently on top, kept up to date by
  // _RouteNameObserver below. Used so the idle timer and background-resume
  // lock both know to stay quiet on onboarding/splash/the lock screen.
  String? _currentRoute;
  late final NavigatorObserver _routeObserver = _RouteNameObserver(
    onChanged: (name) => _currentRoute = name,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  void _armIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _onIdleTimeout);
  }

  void _onIdleTimeout() {
    _lock();
    // Rearm immediately: if nothing ever touches the app again the extra
    // timers are harmless (the exempt-route check below just no-ops once
    // we're sitting on the lock screen), but this guarantees the *next*
    // unlock still gets its own fresh 1-minute countdown even if no
    // interaction happens between the unlock and the next idle window.
    _armIdleTimer();
  }

  bool get _canAutoLock {
    final context = _navigatorKey.currentContext;
    if (context == null) return false;
    final user = context.read<UserProvider>();
    final hasPassword = (user.password ?? '').isNotEmpty;
    if (!user.isLoggedIn || !hasPassword || !user.autoLock) return false;
    return !_kLockExemptRoutes.contains(_currentRoute);
  }

  void _lock() {
    if (!_canAutoLock) return;
    _shouldLockOnResume = false;
    _pausedAt = null;
    // Wipe the stack so the lock can't be bypassed with the back button.
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.appLock,
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final user = context.read<UserProvider>();
    final hasPassword = (user.password ?? '').isNotEmpty;

    if (state == AppLifecycleState.paused) {
      // The idle timer is meaningless while backgrounded (no touches can
      // land) — the pause/resume check below takes over instead.
      _idleTimer?.cancel();
      // Only accounts that actually have a passcode need re-locking.
      _shouldLockOnResume = user.isLoggedIn && hasPassword;
      _pausedAt = _shouldLockOnResume ? DateTime.now() : null;
    } else if (state == AppLifecycleState.resumed) {
      if (_shouldLockOnResume) {
        final pausedAt = _pausedAt;
        _shouldLockOnResume = false;
        _pausedAt = null;

        // Only re-lock once the app has actually been away for a while —
        // a quick switch to a notification or the share sheet shouldn't
        // bounce the user back to the passcode screen.
        final awayLongEnough = pausedAt == null ||
            DateTime.now().difference(pausedAt) >= _autoLockAfter;
        if (awayLongEnough) {
          _lock();
        }
      }
      // Back in the foreground either way — start the idle clock fresh.
      _armIdleTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => ManifestProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852), // iPhone 14 Pro size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return Listener(
            // Any touch anywhere in the app restarts the 1-minute idle
            // clock. behavior: translucent so it sees the tap even where
            // nothing else claims it (e.g. blank background areas).
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _armIdleTimer(),
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              navigatorObservers: [_routeObserver],
              debugShowCheckedModeBanner: false,
              title: 'Manifest App',
              theme: AppTheme.lightTheme,
              initialRoute: AppRoutes.splash,
              routes: {
                AppRoutes.splash: (_) => const SplashScreen(),
                AppRoutes.onboarding: (_) => const OnboardingScreen(),
                AppRoutes.welcome: (_) => const WelcomeScreen(),
                AppRoutes.security: (_) => const SecurityScreen(),
                AppRoutes.userInfo: (_) => const UserInfoScreen(),
                AppRoutes.home: (_) => const HomeScreen(),
                AppRoutes.appLock: (_) => const AppLockScreen(),
                AppRoutes.profile: (_) => const ProfileScreen(),
                AppRoutes.editProfile: (_) => const EditProfileScreen(),
                AppRoutes.visionBoard: (_) => const VisionBoardScreen(),
                AppRoutes.spiritualArchetype: (_) =>
                    const SpiritualArchetypeScreen(),
                AppRoutes.privacySettings: (_) =>
                    const PrivacySettingsScreen(),
                AppRoutes.notificationSettings: (_) =>
                    const NotificationSettingsScreen(),
              },
              onGenerateRoute: (settings) {
                if (settings.name == AppRoutes.actionDetail) {
                  final args = settings.arguments as Map<String, dynamic>;
                  return MaterialPageRoute(
                    builder: (context) => ActionDetailScreen(
                      steps: List<Map<String, dynamic>>.from(args['steps']),
                      initialIndex: args['initialIndex'] ?? 0,
                      plan: args['plan'],
                    ),
                  );
                }
                return null;
              },
            ),
          );
        },
      ),
    );
  }
}

/// Tracks the name of whatever route is currently on top so the lock logic
/// can tell "we're already on the lock screen" or "still onboarding" apart
/// from "the user is genuinely inside the app and idle".
class _RouteNameObserver extends NavigatorObserver {
  _RouteNameObserver({required this.onChanged});

  final ValueChanged<String?> onChanged;

  @override
  void didPush(Route route, Route? previousRoute) {
    onChanged(route.settings.name);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    onChanged(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    onChanged(newRoute?.settings.name);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    onChanged(previousRoute?.settings.name);
  }
}
