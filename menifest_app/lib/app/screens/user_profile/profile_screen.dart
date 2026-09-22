import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';
import '../../services/manifest_provider.dart';
import '../on_boarding_screen/profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      if (user.userId != null) {
        context.read<ManifestProvider>().loadHistory(user.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ManifestProvider>(
      builder: (context, userProvider, manifestProvider, _) {
        final isLoadingInitial =
            manifestProvider.isLoadingHistory &&
            manifestProvider.history.isEmpty;
        final manifestedCount = manifestProvider.history.length.toString();
        final streakCount = manifestProvider.streakCount.toString();
        final goalsCount = manifestProvider.distinctGoalsCount.toString();

        return Scaffold(
          backgroundColor: AppColors.white,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 350.h,
                backgroundColor: AppColors.white,
                surfaceTintColor: AppColors.white,
                elevation: 0,
                pinned: true,
                stretch: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textDark,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings_suggest_rounded,
                      color: AppColors.textDark,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.editProfile),
                  ),
                  10.horizontalSpace,
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    alignment: Alignment.center,
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
                        top: -50.h,
                        right: -50.w,
                        child: _GlowCircle(
                          color: AppColors.purple.withValues(alpha: 0.08),
                          size: 280.r,
                        ),
                      ),
                      Positioned(
                        bottom: -20.h,
                        left: -30.w,
                        child: _GlowCircle(
                          color: AppColors.pink.withValues(alpha: 0.07),
                          size: 220.r,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          60.verticalSpace,
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: AppColors.primaryGradient,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 30.w,
                                  spreadRadius: 2.w,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60.w,
                              backgroundColor: AppColors.white,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      userProvider.profileImage,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 2.w,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          20.verticalSpace,
                          Text(
                            userProvider.name,
                            style: AppTextStyles.headingLarge.copyWith(
                              fontSize: 28.sp,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          8.verticalSpace,
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 8.r,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: AppColors.primaryGradient,
                                      ).createShader(bounds),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.white,
                                    size: 14.sp,
                                  ),
                                ),
                                8.horizontalSpace,
                                Text(
                                  'Cosmic Visionary',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.purple,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.sp,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // ── Upward circular corner sheet (from opposite side) ──
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 30.h,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30.r),
                              topRight: Radius.circular(30.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      10.verticalSpace,
                      Row(
                        children: [
                          _ModernStatCard(
                            label: 'MANIFESTED',
                            value: manifestedCount,
                            isLoading: isLoadingInitial,
                            icon: Icons.auto_awesome_rounded,
                            accentColor: AppColors.purple,
                            bgColor: const Color(0xFFF5EEFF),
                            borderColor: const Color(0xFFE8D8FF),
                            gradientColors: const [
                              Color(0xFF7B2FF7),
                              Color(0xFFE91E8C),
                            ],
                          ),
                          12.horizontalSpace,
                          _ModernStatCard(
                            label: 'STREAK',
                            value: streakCount,
                            isLoading: isLoadingInitial,
                            icon: Icons.local_fire_department_rounded,
                            accentColor: const Color(0xFFFF5722),
                            bgColor: const Color(0xFFFFF2EE),
                            borderColor: const Color(0xFFFFDED4),
                            gradientColors: const [
                              Color(0xFFFF5722),
                              Color(0xFFFF9800),
                            ],
                          ),
                          12.horizontalSpace,
                          _ModernStatCard(
                            label: 'GOALS',
                            value: goalsCount,
                            isLoading: isLoadingInitial,
                            icon: Icons.track_changes_rounded,
                            accentColor: AppColors.blue,
                            bgColor: const Color(0xFFEEF5FF),
                            borderColor: const Color(0xFFD6E6FF),
                            gradientColors: const [
                              Color(0xFF2979FF),
                              Color(0xFF00E5FF),
                            ],
                          ),
                        ],
                      ),
                      36.verticalSpace,
                      Text(
                        'PERSONAL DIMENSIONS',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.4),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.sp,
                        ),
                      ),
                      20.verticalSpace,
                      _MenuTile(
                        label: 'Edit Your Answers',
                        subtitle:
                            'Update what you shared about yourself, family & career',
                        icon: Icons.quiz_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileSetupScreen(isEditing: true),
                          ),
                        ),
                      ),
                      _MenuTile(
                        label: 'Spiritual Archetype',
                        subtitle: 'Your manifestation DNA and patterns',
                        icon: Icons.psychology_rounded,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.spiritualArchetype,
                        ),
                      ),
                      _MenuTile(
                        label: 'Vision Board',
                        subtitle: 'Active dream manifestations',
                        icon: Icons.auto_graph_rounded,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.visionBoard),
                      ),
                      _MenuTile(
                        label: 'Privacy Settings',
                        subtitle: 'Data protection and sphere visibility',
                        icon: Icons.security_rounded,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.privacySettings,
                        ),
                      ),
                      _MenuTile(
                        label: 'App Notifications',
                        subtitle: 'Manage push notifications and updates',
                        icon: Icons.notifications_active_rounded,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.notificationSettings,
                        ),
                      ),
                      40.verticalSpace,
                      Center(
                        child: Column(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                context
                                    .read<ManifestProvider>()
                                    .resetForLogout();
                                await userProvider.logout();
                                if (!context.mounted) return;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.welcome,
                                  (route) => false,
                                );
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.pink,
                              ),
                              label: Text(
                                'DEACTIVATE CONNECTION',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.pink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.sp,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            20.verticalSpace,
                            Text(
                              'Version 2.4.0 (AI Enhanced)',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textLightGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      100.verticalSpace,
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

class _ModernStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final List<Color> gradientColors;

  const _ModernStatCard({
    required this.label,
    required this.value,
    this.isLoading = false,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    this.gradientColors = AppColors.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: 1.2.w),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.16),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 19.sp),
            ),
            10.verticalSpace,
            SizedBox(
              height: 28.h,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.8,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: isLoading
                      ? _StatLoadingDots(
                          key: const ValueKey('loading_dots'),
                          gradientColors: gradientColors,
                        )
                      : Text(
                          value,
                          key: ValueKey<String>(value),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                ),
              ),
            ),
            4.verticalSpace,
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLoadingDots extends StatefulWidget {
  final List<Color> gradientColors;

  const _StatLoadingDots({
    super.key,
    this.gradientColors = AppColors.primaryGradient,
  });

  @override
  State<_StatLoadingDots> createState() => _StatLoadingDotsState();
}

class _StatLoadingDotsState extends State<_StatLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = ((_controller.value - (i * 0.22)) % 1.0);
            final wave = 1.0 - (phase - 0.5).abs() * 2;
            final scale = 0.75 + 0.35 * wave;
            final opacity = (0.35 + 0.65 * wave).clamp(0.2, 1.0);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6.5.r,
                    height: 6.5.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradientColors.first.withValues(
                            alpha: 0.35 * opacity,
                          ),
                          blurRadius: 4.r,
                          spreadRadius: 0.5.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.surfaceVeryLight,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.borderVeryLight),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.03),
                      blurRadius: 8.r,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ).createShader(bounds),
                  child: Icon(icon, color: AppColors.white, size: 24.sp),
                ),
              ),
              20.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                    4.verticalSpace,
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLightGrey,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
