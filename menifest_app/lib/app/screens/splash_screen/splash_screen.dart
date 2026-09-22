import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/splash_provider.dart';
import '../../services/user_provider.dart';
import '../../services/notification_service.dart';
import '../../services/version_check_service.dart';
import '../../widgets/update_dialog.dart';
import '../security/verify_email_screen.dart';
import '../on_boarding_screen/profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  late Future<AppUpdateInfo> _updateCheckFuture;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Start version check Future concurrently with splash timer
    _updateCheckFuture = VersionCheckService.checkAppVersion();

    // Start timer in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashProvider>().startSplashTimer();
      context.read<UserProvider>().init();
    });
  }

  void _handleNavigation(UserProvider user) async {
    if (_navigated) return;
    _navigated = true;

    // Await version check to complete (has built-in 5s timeout and fail-open)
    AppUpdateInfo? updateInfo;
    try {
      updateInfo = await _updateCheckFuture;
    } catch (e) {
      debugPrint('Version check failed in splash: $e');
    }

    if (!mounted) return;

    // If force update is required, lock on splash and show non-dismissible dialog
    if (updateInfo != null && updateInfo.isForceUpdate) {
      UpdateDialog.show(context, updateInfo);
      return;
    }

    // Normal navigation
    if (user.isLoggedIn) {
      if (!user.emailVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              userId: user.userId ?? '',
              email: user.email ?? '',
              finishesSignup: true,
            ),
            settings: const RouteSettings(name: AppRoutes.verifyEmail),
          ),
        );
      } else {
        // isLoggedIn flips true at ACCOUNT CREATION (UserInfoScreen's
        // syncToApi call), well before ProfileSetupScreen's personal/
        // family/professional questions exist to be answered — so it
        // alone can't tell "finished everything" apart from "closed the
        // app partway through the profile form". Check the actual
        // answers (freshly fetched, since a background refresh from
        // init() may not have landed yet) before deciding — falling back
        // to the last confirmed state if this device is offline right
        // now, rather than wrongly treating "couldn't check" as
        // "incomplete" and bouncing an already-finished user backward.
        final reached = await user.refreshProfileAnswers();
        if (!mounted) return;
        final complete = reached
            ? user.isProfileComplete
            : user.cachedProfileComplete;
        if (complete) {
          // Fully set up — go straight to Home without demanding a
          // password every time.
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          );
        }
      }
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }

    // If an optional (flexible) update is available, prompt after landing on the next screen
    // If an optional (flexible) update is available, prompt after landing on the next screen
    if (updateInfo != null && updateInfo.isFlexibleUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = NotificationService.navigatorKey.currentContext;
        if (navContext != null) {
          UpdateDialog.show(navContext, updateInfo!);
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SplashProvider, UserProvider>(
      builder: (context, splash, user, _) {
        if (splash.shouldNavigate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNavigation(user);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.white,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      height: 220.w,
                      width: 220.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: 0.15),
                            blurRadius: 40.r,
                            spreadRadius: 10.r,
                            offset: Offset(0, 10.h),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/splash_warm.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                48.verticalSpace,
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value.h),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ).createShader(bounds),
                        child: Text(
                          'MANIFEST',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.white,
                            fontSize: 48.sp,
                          ),
                        ),
                      ),
                      12.verticalSpace,
                      Text(
                        'create your reality',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      48.verticalSpace,
                      const _LoadingDots(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final progress = (_dotController.value - delay).clamp(0.0, 1.0);
            final opacity =
                (0.3 +
                        0.7 *
                            (progress < 0.5
                                ? progress * 2
                                : (1 - progress) * 2))
                    .clamp(0.0, 1.0);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: AppColors.pinkLight.withValues(alpha: opacity),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glowPink,
                    blurRadius: 6.r,
                    spreadRadius: 1.r,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
