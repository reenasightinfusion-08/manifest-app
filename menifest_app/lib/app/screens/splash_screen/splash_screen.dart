import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/splash_provider.dart';
import '../../services/user_provider.dart';

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

    // Start timer in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SplashProvider>().startSplashTimer();
      context.read<UserProvider>().init();
    });
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
            if (user.isLoggedIn) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
            }
          });
        }

        return Scaffold(
          backgroundColor: AppColors.white,
          body: Center(
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
