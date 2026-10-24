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
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

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
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollForAppBarTitle);
  }

  void _handleScrollForAppBarTitle() {
    final isTablet = mounted && context.isTablet;
    final isLandscape = mounted && context.isLandscape;
    final headerHeight = isTablet ? (isLandscape ? 180.0 : 210.0) : 210.h;
    final collapseDistance = headerHeight - kToolbarHeight;
    final shouldShow = _scrollController.offset >= collapseDistance;
    if (shouldShow != _showAppBarTitle) {
      setState(() => _showAppBarTitle = shouldShow);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final biometricLock = user.biometricLock;

    if (context.isTablet) {
      return _buildTabletLayout(context, user, biometricLock);
    }

    return _buildMobileLayout(context, user, biometricLock);
  }

  // ── Mobile Layout (unchanged) ──────────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    UserProvider user,
    bool biometricLock,
  ) {
    final headerHeight = 210.h;
    final leadingWidth = 68.w;
    final backPadding = 18.w;
    final backSize = 38.r;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: headerHeight,
            backgroundColor: AppColors.purple,
            surfaceTintColor: AppColors.white,
            elevation: 0,
            pinned: true,
            stretch: true,
            scrolledUnderElevation: 0,
            shadowColor: AppColors.transparent,
            centerTitle: true,
            title: AnimatedOpacity(
              opacity: _showAppBarTitle ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Text(
                'Privacy Setting',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
                  const _SectionHeader(
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
                      const _Divider(),
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
                      const _Divider(),
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
                  const _SectionHeader(
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
                      const _Divider(),
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
                      const _Divider(),
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
                  const _SectionHeader(
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

  // ── Tablet Layout ──────────────────────────────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    UserProvider user,
    bool biometricLock,
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
                                            'YOUR COSMIC SHIELD',
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
                                      'Privacy Settings',
                                      style: AppTextStyles.headingLarge
                                          .copyWith(
                                            color: AppColors.white,
                                            fontSize: 28.0,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Text(
                                      'Control your data and protect your energy',
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
                              const _SectionHeader(
                                icon: Icons.bar_chart_rounded,
                                label: 'DATA & ANALYTICS',
                                color: AppColors.purple,
                              ),
                              const SizedBox(height: 14.0),
                              _SettingsCard(
                                children: [
                                  _ToggleTile(
                                    icon: Icons.analytics_outlined,
                                    iconColor: AppColors.purple,
                                    title: 'Usage Analytics',
                                    subtitle:
                                        'Help us improve the app by sharing anonymous usage data',
                                    value: user.analyticsEnabled,
                                    onChanged: (v) => context
                                        .read<UserProvider>()
                                        .setAnalytics(v),
                                  ),
                                  const _Divider(),
                                  _ToggleTile(
                                    icon: Icons.auto_awesome_outlined,
                                    iconColor: AppColors.purple,
                                    title: 'AI Personalization',
                                    subtitle:
                                        'Allow AI to learn from your goals and improve suggestions',
                                    value: user.personalizationEnabled,
                                    onChanged: (v) => context
                                        .read<UserProvider>()
                                        .setPersonalization(v),
                                  ),
                                  const _Divider(),
                                  _ToggleTile(
                                    icon: Icons.bug_report_outlined,
                                    iconColor: AppColors.purple,
                                    title: 'Crash Reports',
                                    subtitle:
                                        'Automatically send crash logs to help fix bugs',
                                    value: user.crashReportsEnabled,
                                    onChanged: (v) => context
                                        .read<UserProvider>()
                                        .setCrashReports(v),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28.0),

                              const _SectionHeader(
                                icon: Icons.shield_outlined,
                                label: 'SECURITY',
                                color: AppColors.blue,
                              ),
                              const SizedBox(height: 14.0),
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
                                  const _Divider(),
                                  _ToggleTile(
                                    icon: Icons.lock_clock_outlined,
                                    iconColor: AppColors.blue,
                                    title: 'Auto-Lock Session',
                                    subtitle:
                                        'Automatically lock after 5 minutes of inactivity',
                                    value: user.autoLock,
                                    onChanged: (v) => context
                                        .read<UserProvider>()
                                        .setAutoLock(v),
                                  ),
                                  const _Divider(),
                                  _ActionTile(
                                    icon: Icons.key_outlined,
                                    iconColor: AppColors.blue,
                                    title: 'Change Password',
                                    subtitle: 'Update your cosmic security key',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ChangePassphraseScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28.0),

                              const _SectionHeader(
                                icon: Icons.storage_outlined,
                                label: 'DATA MANAGEMENT',
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(height: 14.0),
                              _SettingsCard(
                                children: [
                                  _ActionTile(
                                    icon: Icons.download_outlined,
                                    iconColor: AppColors.textGrey,
                                    title: 'Export My Data',
                                    subtitle:
                                        'Download a copy of all your manifestations',
                                    onTap: () => _exportMyData(context),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28.0),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5F5),
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: Border.all(
                                    color: AppColors.errorRed.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppColors.errorRed,
                                          size: 20.0,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Text(
                                          'DANGER ZONE',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.errorRed,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
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
                                        onConfirm: () =>
                                            _deleteAllManifestations(context),
                                        isDangerous: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12.0),
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
                                        onConfirm: () =>
                                            _deleteAccount(context),
                                        isDangerous: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 36.0),

                              Center(
                                child: Text(
                                  'Your data is protected under our Privacy Policy.\nWe never sell your information.',
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
  final isTablet = context.isTablet;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 360.0 : 320.0),
        child: Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 24.0 : 24.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24.0 : 28.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: isTablet ? 24.0 : 22.w,
                  height: isTablet ? 24.0 : 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.errorRed,
                  ),
                ),
                SizedBox(width: isTablet ? 16.0 : 16.w),
                Text(
                  'Working on it...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 15.5 : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showToast(BuildContext context, String message) {
  HapticFeedback.lightImpact();
  final isTablet = context.isTablet;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: isTablet ? const TextStyle(fontSize: 14.5) : null,
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
      ),
      margin: EdgeInsets.all(isTablet ? 20.0 : 16.r),
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
  final isTablet = context.isTablet;
  showDialog(
    context: context,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 420.0 : 340.0),
        child: AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 24.0 : 24.r),
          ),
          title: Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textDark,
              fontSize: isTablet ? 20.0 : 20.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGrey,
              height: 1.6,
              fontSize: isTablet ? 14.5 : 14.sp,
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
                  fontSize: isTablet ? 14.5 : null,
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
                  fontSize: isTablet ? 14.5 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 12.5,
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
    final isTablet = context.isTablet;
    if (!isTablet) {
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
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
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLightGrey,
              size: 24.0,
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
    final isTablet = context.isTablet;
    if (!isTablet) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppColors.errorRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: AppColors.errorRed.withValues(alpha: 0.15),
            ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.errorRed,
              size: 22.0,
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.errorRed.withValues(alpha: 0.7),
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.errorRed.withValues(alpha: 0.5),
              size: 22.0,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderVeryLight,
      indent: isTablet ? 20.0 : 16.w,
      endIndent: isTablet ? 20.0 : 16.w,
    );
  }
}
