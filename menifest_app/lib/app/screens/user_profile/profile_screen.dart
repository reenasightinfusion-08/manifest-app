import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';
import '../../services/manifest_provider.dart';

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
        final manifestedCount = manifestProvider.history.length.toString();
        // Mock streak logic: if they have manifestations, show a streak relative to count
        final streakCount = manifestProvider.history.isNotEmpty
            ? (manifestProvider.history.length + 3).toString()
            : '0';
        final goalsCount = manifestProvider.history.length.toString();

        return Scaffold(
          backgroundColor: AppColors.white,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 340.h,
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
                      30.verticalSpace,
                      Row(
                        children: [
                          _StatCard(
                            label: 'MANIFESTED',
                            value: manifestedCount,
                            icon: Icons.star_rounded,
                            color: AppColors.purple,
                          ),
                          16.horizontalSpace,
                          _StatCard(
                            label: 'STREAK',
                            value: streakCount,
                            icon: Icons.local_fire_department_rounded,
                            color: AppColors.pink,
                          ),
                          16.horizontalSpace,
                          _StatCard(
                            label: 'GOALS',
                            value: goalsCount,
                            icon: Icons.flag_rounded,
                            color: AppColors.blue,
                          ),
                        ],
                      ),
                      40.verticalSpace,
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
                        subtitle: 'Reminder frequency and cosmic timing',
                        icon: Icons.notifications_active_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notification settings coming soon! 🔔',
                              ),
                            ),
                          );
                        },
                      ),
                      40.verticalSpace,
                      Center(
                        child: Column(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                context.read<ManifestProvider>().resetForLogout();
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.borderVeryLight, width: 1.5.w),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            12.verticalSpace,
            Text(
              value,
              style: AppTextStyles.headingMedium.copyWith(
                fontSize: 22.sp,
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            4.verticalSpace,
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 9.sp,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
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
                  child: Icon(icon, color: AppColors.white, size: 20.sp),
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
