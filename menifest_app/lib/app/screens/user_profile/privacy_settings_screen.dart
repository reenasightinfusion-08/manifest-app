import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/common/core.dart';
import '../../services/api_service.dart';
import '../../services/manifest_provider.dart';
import '../../services/user_provider.dart';
import '../security/change_passphrase_screen.dart';
import '../../services/biometric_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  Future<void> _onBiometricToggle(bool enable) async {
    final provider = context.read<UserProvider>();

    if (!enable) {
      provider.setBiometricLock(false);
      return;
    }

    final available = await BiometricService.isAvailable();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fingerprint or Face ID is set up on this device. '
            'Add one in your phone\'s settings first.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Confirm it actually works before relying on it to gate the app.
    final result = await BiometricService.authenticate(
      reason: 'Confirm to enable biometric lock',
    );
    if (result.success) {
      provider.setBiometricLock(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Could not verify biometrics.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final biometricLock = user.biometricLock;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────
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
                  // Gradient background
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
                  // Glow circles
                  Positioned(
                    top: -40.h,
                    right: -40.w,
                    child: Container(
                      width: 180.w,
                      height: 180.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30.h,
                    left: -30.w,
                    child: Container(
                      width: 130.w,
                      height: 130.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Title content
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
                            'YOUR COSMIC SHIELD',
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
                          'Privacy Settings',
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        6.verticalSpace,
                        Text(
                          'Control your data and protect your energy',
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

          // ── Body ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Data & Analytics ──────────────────────
                  _SectionHeader(
                    icon: Icons.bar_chart_rounded,
                    label: 'DATA & ANALYTICS',
                    color: AppColors.purple,
                  ),
                  16.verticalSpace,
                  _SettingsCard(
                    children: [
                      _ToggleTile(
                        icon: Icons.analytics_outlined,
                        iconColor: AppColors.purple,
                        title: 'Usage Analytics',
                        subtitle:
                            'Help us improve the app by sharing anonymous usage data',
                        value: user.analyticsEnabled,
                        onChanged: (v) =>
                            context.read<UserProvider>().setAnalytics(v),
                      ),
                      _Divider(),
                      _ToggleTile(
                        icon: Icons.auto_awesome_outlined,
                        iconColor: AppColors.purple,
                        title: 'AI Personalization',
                        subtitle:
                            'Allow AI to learn from your goals and improve suggestions',
                        value: user.personalizationEnabled,
                        onChanged: (v) =>
                            context.read<UserProvider>().setPersonalization(v),
                      ),
                      _Divider(),
                      _ToggleTile(
                        icon: Icons.bug_report_outlined,
                        iconColor: AppColors.purple,
                        title: 'Crash Reports',
                        subtitle:
                            'Automatically send crash logs to help fix bugs',
                        value: user.crashReportsEnabled,
                        onChanged: (v) =>
                            context.read<UserProvider>().setCrashReports(v),
                      ),
                    ],
                  ),

                  28.verticalSpace,

                  // ── Section 3: Security ──────────────────────────────
                  _SectionHeader(
                    icon: Icons.shield_outlined,
                    label: 'SECURITY',
                    color: AppColors.blue,
                  ),
                  16.verticalSpace,
                  _SettingsCard(
                    children: [
                      _ToggleTile(
                        icon: Icons.fingerprint_rounded,
                        iconColor: AppColors.blue,
                        title: 'Biometric Lock',
                        subtitle: 'Fingerprint to open the app',
                        value: biometricLock,
                        onChanged: _onBiometricToggle,
                      ),
                      _Divider(),
                      _ToggleTile(
                        icon: Icons.lock_clock_outlined,
                        iconColor: AppColors.blue,
                        title: 'Auto-Lock Session',
                        subtitle:
                            'Automatically lock after 5 minutes of inactivity',
                        value: user.autoLock,
                        onChanged: (v) =>
                            context.read<UserProvider>().setAutoLock(v),
                      ),
                      _Divider(),
                      _ActionTile(
                        icon: Icons.key_outlined,
                        iconColor: AppColors.blue,
                        title: 'Change Password',
                        subtitle: 'Update your cosmic security key',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePassphraseScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  28.verticalSpace,

                  // ── Section 4: Data Management ───────────────────────
                  _SectionHeader(
                    icon: Icons.storage_outlined,
                    label: 'DATA MANAGEMENT',
                    color: AppColors.textGrey,
                  ),
                  16.verticalSpace,
                  _SettingsCard(
                    children: [
                      _ActionTile(
                        icon: Icons.download_outlined,
                        iconColor: AppColors.textGrey,
                        title: 'Export My Data',
                        subtitle: 'Download a copy of all your manifestations',
                        onTap: () => _exportMyData(context),
                      ),
                    ],
                  ),

                  28.verticalSpace,

                  // ── Danger Zone ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.25),
                        width: 1.5.w,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.errorRed,
                              size: 18.sp,
                            ),
                            8.horizontalSpace,
                            Text(
                              'DANGER ZONE',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.errorRed,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                        16.verticalSpace,
                        _DangerTile(
                          title: 'Delete All Manifestations',
                          subtitle:
                              'Permanently erase all your goals and plans from the cosmos',
                          onTap: () => _confirmAction(
                            context,
                            title: 'Delete Everything?',
                            message:
                                'This will permanently delete all your manifestations, plans, and vision board. This cannot be undone.',
                            confirmLabel: 'Delete All',
                            onConfirm: () => _deleteAllManifestations(context),
                            isDangerous: true,
                          ),
                        ),
                        12.verticalSpace,
                        _DangerTile(
                          title: 'Delete My Account',
                          subtitle:
                              'Permanently remove your cosmic identity and all data',
                          onTap: () => _confirmAction(
                            context,
                            title: 'Delete Account?',
                            message:
                                'Your entire cosmic profile, manifestations, and archetype will be permanently destroyed. Are you absolutely sure?',
                            confirmLabel: 'Delete Account',
                            onConfirm: () => _deleteAccount(context),
                            isDangerous: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  40.verticalSpace,

                  // ── Footer note ──────────────────────────────────────
                  Center(
                    child: Text(
                      'Your data is protected under our Privacy Policy.\nWe never sell your information.',
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

  Future<void> _exportMyData(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId;
    if (userId == null || userId.isEmpty) {
      _showToast(context, 'You need to be signed in to do this.');
      return;
    }

    _showLoadingDialog(context);
    try {
      final apiService = ApiService();
      final history = await apiService.getManifestationHistory(userId);
      final archetype = userProvider.archetypeData;

      final export = <String, dynamic>{
        'exported_at': DateTime.now().toIso8601String(),
        'profile': {
          'id': userId,
          'name': userProvider.name,
          'avatar_url': userProvider.profileImage,
          'personal_answers': userProvider.personalAnswers,
          'family_answers': userProvider.familyAnswers,
          'professional_answers': userProvider.professionalAnswers,
        },
        'spiritual_archetype': archetype,
        'manifestations': history,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(export);

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/manifest_data_export_$timestamp.json');
      await file.writeAsString(jsonString);

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Manifest Data Export',
        text: 'Here\'s a full copy of your manifestations and profile data.',
      );
    } catch (e, st) {
      debugPrint('EXPORT ERROR: $e');
      debugPrint('EXPORT STACK: $st');
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog
      _showToast(context, 'Could not export your data. Try again.');
    }
  }

  Future<void> _deleteAllManifestations(BuildContext context) async {
    final userId = context.read<UserProvider>().userId;
    if (userId == null || userId.isEmpty) {
      _showToast(context, 'You need to be signed in to do this.');
      return;
    }

    _showLoadingDialog(context);
    try {
      await context.read<ManifestProvider>().deleteAllHistory(userId);
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog
      _showToast(context, 'All manifestations deleted ✨');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog
      _showToast(context, 'Could not clear manifestations. Try again.');
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final manifestProvider = context.read<ManifestProvider>();

    _showLoadingDialog(context);
    try {
      final success = await userProvider.deleteAccount();
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog

      if (success) {
        manifestProvider.resetForLogout();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (route) => false,
        );
      } else {
        _showToast(context, 'Could not delete your account. Try again.');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading dialog
      _showToast(context, 'Could not delete your account. Try again.');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.r),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.errorRed,
                ),
              ),
              16.horizontalSpace,
              Text(
                'Working on it...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
            height: 1.6,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDangerous ? AppColors.errorRed : AppColors.purple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ─────────────────────────────────────────────────────────

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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
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
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLightGrey,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.errorRed,
              size: 20.sp,
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.errorRed.withValues(alpha: 0.7),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.errorRed.withValues(alpha: 0.5),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderVeryLight,
      indent: 16.w,
      endIndent: 16.w,
    );
  }
}
