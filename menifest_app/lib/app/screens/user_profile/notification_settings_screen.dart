import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/notification_service.dart';
import '../../services/user_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  Future<void> _onMasterToggle(bool enable) async {
    final provider = context.read<UserProvider>();

    if (!enable) {
      await provider.setNotificationsEnabled(false);
      return;
    }

    final granted = await NotificationService.requestPermission();
    await provider.setNotificationsEnabled(true);
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Notifications are blocked at the system level. '
            'Enable them for this app in your phone\'s settings too.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final notificationsEnabled = user.notificationsEnabled;

    if (context.isTablet) {
      return _buildTabletLayout(context, user, notificationsEnabled);
    }

    return _buildMobileLayout(context, user, notificationsEnabled);
  }

  // ── Mobile Layout (unchanged) ──────────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    UserProvider user,
    bool notificationsEnabled,
  ) {
    final headerHeight = 210.h;
    final leadingWidth = 68.w;
    final backPadding = 18.w;
    final backSize = 38.r;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: headerHeight,
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            elevation: 0,
            pinned: true,
            stretch: true,
            leadingWidth: leadingWidth,
            leading: Padding(
              padding: EdgeInsets.only(left: backPadding),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: backSize,
                    height: backSize,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.35),
                        width: 1.w,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4A00B8), Color(0xFF9B0060)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40.h,
                    right: -40.w,
                    child: Container(
                      width: 160.w,
                      height: 160.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24.h,
                    left: 24.w,
                    right: 24.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'COSMIC SIGNALS',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        10.verticalSpace,
                        Text(
                          'App Notifications',
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.white,
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        6.verticalSpace,
                        Text(
                          'Manage push notifications and updates',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.75),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsCard(
                    children: [
                      _ToggleTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppColors.purple,
                        title: 'Push Notifications',
                        subtitle: 'Master switch for everything below',
                        value: notificationsEnabled,
                        onChanged: _onMasterToggle,
                      ),
                    ],
                  ),
                  28.verticalSpace,
                  const _SectionHeader(
                    icon: Icons.tune_rounded,
                    label: 'CATEGORIES',
                    color: AppColors.blue,
                  ),
                  16.verticalSpace,
                  Opacity(
                    opacity: notificationsEnabled ? 1 : 0.4,
                    child: IgnorePointer(
                      ignoring: !notificationsEnabled,
                      child: _SettingsCard(
                        children: [
                          _ToggleTile(
                            icon: Icons.auto_awesome_outlined,
                            iconColor: AppColors.blue,
                            title: 'Manifestation Tips',
                            subtitle: 'Occasional insights and cosmic advice',
                            value: user.manifestationTips,
                            onChanged: (v) => context
                                .read<UserProvider>()
                                .setManifestationTips(v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  28.verticalSpace,
                  Center(
                    child: Text(
                      notificationsEnabled
                          ? 'You\'re all set to receive updates from the cosmos.'
                          : 'Notifications are off. You won\'t receive reminders or tips.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textLightGrey,
                        fontSize: 12.sp,
                        height: 1.6,
                      ),
                    ),
                  ),
                  60.verticalSpace,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tablet Layout ──────────────────────────────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    UserProvider user,
    bool notificationsEnabled,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBF8FE),
              Color(0xFFF3ECFA),
              Color(0xFFFCF0F5),
              Color(0xFFF4EDFE),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glow orbs
            Positioned(
              top: -60.0,
              right: -40.0,
              child: Container(
                width: 320.0,
                height: 320.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.10),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40.0,
              left: -30.0,
              child: Container(
                width: 280.0,
                height: 280.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.pink.withValues(alpha: 0.08),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? 820.0 : 720.0,
                ),
                child: Container(
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.08),
                        blurRadius: 32.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 10.0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tablet hero header
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4A00B8), Color(0xFF9B0060)],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -30.0,
                                right: -30.0,
                                child: Container(
                                  width: 220.0,
                                  height: 220.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white.withValues(
                                      alpha: 0.07,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -20.0,
                                left: -20.0,
                                child: Container(
                                  width: 160.0,
                                  height: 160.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isLandscape ? 36.0 : 28.0,
                                  24.0,
                                  isLandscape ? 36.0 : 28.0,
                                  28.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Semantics(
                                          label: 'Go back to profile',
                                          button: true,
                                          child: GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                color: AppColors.white
                                                    .withValues(alpha: 0.22),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.white
                                                      .withValues(alpha: 0.35),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    right: 2.0,
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .arrow_back_ios_new_rounded,
                                                    color: AppColors.white,
                                                    size: 18.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14.0,
                                            vertical: 5.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20.0,
                                            ),
                                          ),
                                          child: Text(
                                            'COSMIC SIGNALS',
                                            style: TextStyle(
                                              color: AppColors.white.withValues(
                                                alpha: 0.95,
                                              ),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24.0),
                                    Text(
                                      'App Notifications',
                                      style: AppTextStyles.headingLarge
                                          .copyWith(
                                            color: AppColors.white,
                                            fontSize: 28.0,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Text(
                                      'Manage push notifications and updates',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content body
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            isLandscape ? 36.0 : 28.0,
                            28.0,
                            isLandscape ? 36.0 : 28.0,
                            36.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SettingsCard(
                                children: [
                                  _ToggleTile(
                                    icon: Icons.notifications_active_rounded,
                                    iconColor: AppColors.purple,
                                    title: 'Push Notifications',
                                    subtitle:
                                        'Master switch for everything below',
                                    value: notificationsEnabled,
                                    onChanged: _onMasterToggle,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28.0),
                              const _SectionHeader(
                                icon: Icons.tune_rounded,
                                label: 'CATEGORIES',
                                color: AppColors.blue,
                              ),
                              const SizedBox(height: 14.0),
                              Opacity(
                                opacity: notificationsEnabled ? 1 : 0.4,
                                child: IgnorePointer(
                                  ignoring: !notificationsEnabled,
                                  child: _SettingsCard(
                                    children: [
                                      _ToggleTile(
                                        icon: Icons.auto_awesome_outlined,
                                        iconColor: AppColors.blue,
                                        title: 'Manifestation Tips',
                                        subtitle:
                                            'Occasional insights and cosmic advice',
                                        value: user.manifestationTips,
                                        onChanged: (v) => context
                                            .read<UserProvider>()
                                            .setManifestationTips(v),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36.0),
                              Center(
                                child: Text(
                                  notificationsEnabled
                                      ? 'You\'re all set to receive updates from the cosmos.'
                                      : 'Notifications are off. You won\'t receive reminders or tips.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textLightGrey,
                                    fontSize: 13.0,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40.0),
                            ],
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
      ),
    );
  }
}

// ── Reusable Widgets (mirrors PrivacySettingsScreen's style) ───────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    if (!isTablet) {
      return Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 14.sp),
          ),
          10.horizontalSpace,
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color, size: 16.0),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    if (!isTablet) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.borderVeryLight, width: 1.5.w),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.04),
              blurRadius: 16.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(children: children),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.borderVeryLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.04),
            blurRadius: 16.0,
            offset: const Offset(0, 4.0),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    if (!isTablet) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: iconColor, size: 18.sp),
            ),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 11.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            12.horizontalSpace,
            Switch.adaptive(
              value: value,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              activeThumbColor: AppColors.white,
              activeTrackColor: AppColors.purple,
              inactiveThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.borderLight,
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              trackOutlineWidth: const WidgetStatePropertyAll(0.0),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: iconColor, size: 20.0),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.purple,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.borderLight,
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            trackOutlineWidth: const WidgetStatePropertyAll(0.0),
          ),
        ],
      ),
    );
  }
}
