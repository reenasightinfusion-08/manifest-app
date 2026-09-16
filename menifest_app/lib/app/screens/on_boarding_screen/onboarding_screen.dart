import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  void _onPageChanged(BuildContext context, int index) {
    context.read<OnboardingProvider>().updatePage(index);
    _animController.reset();
    _animController.forward();
  }

  void _next(BuildContext context) {
    final provider = context.read<OnboardingProvider>();
    if (!provider.isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.security);
    }
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.security);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        final bool isLast = provider.isLastPage;

        return Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => _onPageChanged(context, idx),
                itemCount: provider.pages.length,
                itemBuilder: (context, index) {
                  return _OnboardPage(
                    data: provider.pages[index],
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                  );
                },
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16.h,
                right: 24.w,
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: isLast ? null : () => _skip(context),
                    child: Text(
                      'Skip',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    32.w,
                    24.h,
                    32.w,
                    MediaQuery.of(context).padding.bottom + 32.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(provider.pages.length, (i) {
                          final bool active = i == provider.currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.only(right: 8.w),
                            width: active ? 28.w : 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.r),
                              gradient: active
                                  ? const LinearGradient(
                                      colors: AppColors.primaryGradient,
                                    )
                                  : null,
                              color: active ? null : AppColors.stepDotInactive,
                            ),
                          );
                        }),
                      ),
                      GestureDetector(
                        onTap: () => _next(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isLast ? 160.w : 56.w,
                          height: isLast ? 56.h : 56.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.glowPink,
                                blurRadius: 16.r,
                                spreadRadius: -4.r,
                                offset: Offset(0, 6.h),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isLast
                                ? Text(
                                    'Get Started ✨',
                                    style: AppTextStyles.buttonLarge.copyWith(
                                      color: AppColors.white,
                                      fontSize: 16.sp,
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.white,
                                    size: 24.sp,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final OnboardData data;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _OnboardPage({
    required this.data,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 0.55.sh,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.softGradient,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -40.h,
                right: -40.w,
                child: Container(
                  width: 180.w,
                  height: 180.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -20.h,
                left: -30.w,
                child: Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pink.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40.h),
                  child: Container(
                    height: 0.34.sh,
                    width: 0.34.sh,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.15),
                          blurRadius: 30.r,
                          spreadRadius: 5.r,
                          offset: Offset(0, 10.h),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(data.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: AppColors.white,
            padding: EdgeInsets.fromLTRB(32.w, 36.h, 32.w, 100.h),
            child: SlideTransition(
              position: slideAnim,
              child: FadeTransition(
                opacity: fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedTitle(
                      title: data.title,
                      highlight: data.highlight,
                    ),
                    16.verticalSpace,
                    Text(
                      data.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGrey,
                        height: 1.6,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HighlightedTitle extends StatelessWidget {
  final String title;
  final String highlight;

  const _HighlightedTitle({required this.title, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final parts = title.split(highlight);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.w800,
          height: 1.25,
          color: AppColors.textDark,
        ),
        children: [
          if (parts.isNotEmpty) TextSpan(text: parts[0]),
          WidgetSpan(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: AppColors.primaryGradient,
              ).createShader(bounds),
              child: Text(
                highlight,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}
