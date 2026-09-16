import 'package:flutter/material.dart';
import '../../../core/common/core.dart';
import '../../widgets/primary_button.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVeryLight,
      body: Stack(
        children: [
          Positioned(
            top: -100.h,
            right: -60.w,
            child: Container(
              width: 350.w,
              height: 350.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.purple.withValues(alpha: 0.08),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  80.verticalSpace,
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SizedBox(
                        width: 140.w,
                        height: 140.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 40.r,
                                    spreadRadius: 10.r,
                                  ),
                                ],
                              ),
                            ),
                            ...List.generate(2, (i) {
                              return Container(
                                margin: EdgeInsets.all((12.0 * (i + 1)).r),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.08 + (0.1 * i),
                                    ),
                                    width: 1.w,
                                  ),
                                ),
                              );
                            }),
                            Container(
                              padding: EdgeInsets.all(28.r),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(32.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.04,
                                    ),
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.verified_user_rounded,
                                size: 50.sp,
                                color: AppColors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  56.verticalSpace,
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Your Privacy, Guaranteed',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                            fontSize: 28.sp,
                          ),
                        ),
                        20.verticalSpace,
                        Text(
                          'We believe transparency is key. Your data is encrypted locally and never shared. We don’t just say it—we build for it.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textGrey,
                            height: 1.7,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  60.verticalSpace,
                  _SecurityDetail(
                    icon: Icons.shield_moon_outlined,
                    title: 'Vault-Level Protection',
                    desc: 'Military-grade encryption for all entries.',
                  ),
                  10.verticalSpace,
                  _SecurityDetail(
                    icon: Icons.cloud_off_rounded,
                    title: 'Offline-First Privacy',
                    desc: 'Your thoughts stay on your device by default.',
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: PrimaryButton(
                      label: 'Enter My Safe Space',
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.welcome,
                      ),
                    ),
                  ),
                  48.verticalSpace,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityDetail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _SecurityDetail({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.purple, size: 24.sp),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  desc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textFaded,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
