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

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 210.h,
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            elevation: 0,
            pinned: true,
            stretch: true,
            leadingWidth: 68.w,
            leading: Padding(
              padding: EdgeInsets.only(left: 18.w),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38.r,
                    height: 38.r,
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

                  _SectionHeader(
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
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 11.sp,
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
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            trackOutlineWidth: const WidgetStatePropertyAll(0.0),
          ),
        ],
      ),
    );
  }
}
