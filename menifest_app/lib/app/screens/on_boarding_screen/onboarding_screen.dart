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
    final isTablet = context.isTablet;
    final isLandscape = isTablet && context.isLandscape;

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
                    isTablet: isTablet,
                    isLandscape: isLandscape,
                  );
                },
              ),
              // Skip button
              Positioned(
                top: MediaQuery.of(context).padding.top +
                    (isTablet ? (isLandscape ? 16.0 : 20.0) : 16.h),
                right: isTablet ? (isLandscape ? 40.0 : 36.0) : 24.w,
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
                        fontSize: isTablet ? 16.0 : 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom controls (Dots & Next/Get Started button)
              if (!isTablet)
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
                        AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, _) {
                            double page = provider.currentPage.toDouble();
                            if (_pageController.hasClients &&
                                _pageController.page != null) {
                              page = _pageController.page!;
                            }
                            return Row(
                              children: List.generate(provider.pages.length, (i) {
                                final diff = (page - i).abs();
                                final t = (1.0 - diff).clamp(0.0, 1.0);
                                final width = 12.w + (12.w * t);
                                return Container(
                                  margin: EdgeInsets.only(
                                    right: i == provider.pages.length - 1
                                        ? 0
                                        : 5.w,
                                  ),
                                  width: width,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4.r),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.lerp(
                                          AppColors.stepDotInactive,
                                          AppColors.primaryGradient[0],
                                          t,
                                        )!,
                                        Color.lerp(
                                          AppColors.stepDotInactive,
                                          AppColors.primaryGradient[1],
                                          t,
                                        )!,
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
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
                )
              else
                Positioned(
                  bottom: 0,
                  left: isLandscape
                      ? MediaQuery.of(context).size.width * 0.5
                      : 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isLandscape ? 480.0 : 580.0,
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          isLandscape ? 40.0 : 36.0,
                          16.0,
                          isLandscape ? 40.0 : 36.0,
                          MediaQuery.of(context).padding.bottom +
                              (isLandscape ? 24.0 : 32.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, _) {
                                double page = provider.currentPage.toDouble();
                                if (_pageController.hasClients &&
                                    _pageController.page != null) {
                                  page = _pageController.page!;
                                }
                                return Row(
                                  children: List.generate(provider.pages.length, (i) {
                                    final diff = (page - i).abs();
                                    final t = (1.0 - diff).clamp(0.0, 1.0);
                                    final width = 14.0 + (14.0 * t);
                                    return Container(
                                      margin: EdgeInsets.only(
                                        right: i == provider.pages.length - 1
                                            ? 0
                                            : 6.0,
                                      ),
                                      width: width,
                                      height: 8.0,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.lerp(
                                              AppColors.stepDotInactive,
                                              AppColors.primaryGradient[0],
                                              t,
                                            )!,
                                            Color.lerp(
                                              AppColors.stepDotInactive,
                                              AppColors.primaryGradient[1],
                                              t,
                                            )!,
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: () => _next(context),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isLast ? 180.0 : 56.0,
                                height: 56.0,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.glowPink,
                                      blurRadius: 16.0,
                                      spreadRadius: -2.0,
                                      offset: Offset(0, 6.0),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isLast
                                      ? Text(
                                          'Get Started ✨',
                                          style:
                                              AppTextStyles.buttonLarge.copyWith(
                                            color: AppColors.white,
                                            fontSize: 16.0,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: AppColors.white,
                                          size: 24.0,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
  final bool isTablet;
  final bool isLandscape;

  const _OnboardPage({
    required this.data,
    required this.fadeAnim,
    required this.slideAnim,
    this.isTablet = false,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTablet) {
      // 100% original layout for phones
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
                        isTablet: false,
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

    if (isLandscape) {
      // Premium side-by-side layout for tablet landscape
      final double screenHeight = MediaQuery.of(context).size.height;
      final double imageSize = (screenHeight * 0.44).clamp(220.0, 320.0);

      return Row(
        children: [
          // Left: Artwork and atmosphere
          Expanded(
            child: SizedBox.expand(
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
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purple.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pink.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      height: imageSize,
                      width: imageSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 4,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage(data.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right: Content
          Expanded(
            child: Container(
              color: AppColors.white,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(40, 72, 40, 120),
                  child: SlideTransition(
                    position: slideAnim,
                    child: FadeTransition(
                      opacity: fadeAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HighlightedTitle(
                            title: data.title,
                            highlight: data.highlight,
                            isTablet: true,
                          ),
                          const SizedBox(height: 18.0),
                          Text(
                            data.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textGrey,
                              height: 1.6,
                              fontSize: 16.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Tablet portrait layout: balanced top artwork & centered readable content
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topHeight = (screenHeight * 0.46).clamp(320.0, 440.0);
    final double imageSize = (topHeight * 0.65).clamp(220.0, 290.0);

    return Column(
      children: [
        SizedBox(
          height: topHeight,
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
                top: -30,
                right: -30,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.pink.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    height: imageSize,
                    width: imageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 4,
                          offset: const Offset(0, 10),
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
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(36, 36, 36, 120),
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
                          isTablet: true,
                        ),
                        const SizedBox(height: 18.0),
                        Text(
                          data.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGrey,
                            height: 1.6,
                            fontSize: 17.0,
                          ),
                        ),
                      ],
                    ),
                  ),
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
  final bool isTablet;

  const _HighlightedTitle({
    required this.title,
    required this.highlight,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = title.split(highlight);
    final double fontSize = isTablet ? 34.0 : 32.sp;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
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
                  fontSize: fontSize,
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

