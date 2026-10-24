import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:menifest_app/app/ads/ad_gate.dart';
import 'package:menifest_app/app/ads/banner_ad_widget.dart';
import 'package:menifest_app/app/ads/native_ad_widget.dart';
import 'package:menifest_app/app/screens/on_boarding_screen/profile_setup_screen.dart';
import 'package:menifest_app/app/services/manifest_provider.dart';
import 'package:menifest_app/app/services/user_provider.dart';
import 'package:menifest_app/core/common/core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openArchetype(BuildContext context) => AdGate.run(
    context,
    key: 'archetype',
    title: 'Unlock your Spiritual Archetype',
    message:
        'Watch a short ad to unlock your manifestation DNA. It stays unlocked for 24 hours.',
    onUnlocked: () =>
        Navigator.pushNamed(context, AppRoutes.spiritualArchetype),
  );

  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      if (user.userId != null) {
        context.read<ManifestProvider>().loadHistory(user.userId!);
        if (user.archetypeData == null) {
          user.fetchArchetype();
        }
      }
    });
    _scrollController.addListener(_handleScrollForAppBarTitle);
  }

  void _handleScrollForAppBarTitle() {
    final collapseDistance = 340.h - kToolbarHeight;
    final shouldShow = _scrollController.offset >= collapseDistance;
    if (shouldShow != _showAppBarTitle) {
      setState(() => _showAppBarTitle = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ManifestProvider>(
      builder: (context, userProvider, manifestProvider, _) {
        final isLoadingInitial =
            manifestProvider.isLoadingHistory &&
            manifestProvider.history.isEmpty;
        final manifestedCount = manifestProvider.manifestedCount.toString();
        final streakCount = manifestProvider.streakCount.toString();
        final goalsCount = manifestProvider.history.length.toString();
        final archetypeName =
            (userProvider.archetypeData?['archetype_name'] as String?) ??
            'Cosmic Visionary';

        if (context.isTablet) {
          return _buildTabletLayout(
            context,
            userProvider,
            manifestProvider,
            isLoadingInitial,
            manifestedCount,
            streakCount,
            goalsCount,
            archetypeName,
          );
        }

        return _buildPhoneLayout(
          context,
          userProvider,
          manifestProvider,
          isLoadingInitial,
          manifestedCount,
          streakCount,
          goalsCount,
          archetypeName,
        );
      },
    );
  }

  // ── Tablet Layout ──────────────────────────────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    UserProvider userProvider,
    ManifestProvider manifestProvider,
    bool isLoadingInitial,
    String manifestedCount,
    String streakCount,
    String goalsCount,
    String archetypeName,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
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
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildTabletTopBar(context),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              isLandscape ? 36.0 : 28.0,
                              24.0,
                              isLandscape ? 36.0 : 28.0,
                              32.0,
                            ),
                            child: _buildTabletPortraitBody(
                              context,
                              userProvider,
                              manifestProvider,
                              isLoadingInitial,
                              manifestedCount,
                              streakCount,
                              goalsCount,
                              archetypeName,
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
      ),
    );
  }

  Widget _buildTabletTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(22.0),
              child: Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark,
                  size: 16.0,
                ),
              ),
            ),
          ),
          Text(
            'Profile & Account',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textDark,
              fontSize: 18.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
              borderRadius: BorderRadius.circular(22.0),
              child: Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.textDark,
                  size: 18.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLandscapeBody(
    BuildContext context,
    UserProvider userProvider,
    ManifestProvider manifestProvider,
    bool isLoadingInitial,
    String manifestedCount,
    String streakCount,
    String goalsCount,
    String archetypeName,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabletIdentityCard(context, userProvider, archetypeName),
              const SizedBox(height: 20.0),
              _buildTabletStatsRow(
                isLoadingInitial: isLoadingInitial,
                manifestedCount: manifestedCount,
                streakCount: streakCount,
                goalsCount: goalsCount,
              ),
              const SizedBox(height: 28.0),
              _buildTabletLogoutSection(context, userProvider),
            ],
          ),
        ),
        const SizedBox(width: 32.0),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONAL DIMENSIONS',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.4),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(height: 16.0),
              _buildTabletMenuTiles(context),
              const SizedBox(height: 20.0),
              const NativeAdWidget(templateType: TemplateType.small),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletPortraitBody(
    BuildContext context,
    UserProvider userProvider,
    ManifestProvider manifestProvider,
    bool isLoadingInitial,
    String manifestedCount,
    String streakCount,
    String goalsCount,
    String archetypeName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabletIdentityCard(context, userProvider, archetypeName),
        const SizedBox(height: 24.0),
        _buildTabletStatsRow(
          isLoadingInitial: isLoadingInitial,
          manifestedCount: manifestedCount,
          streakCount: streakCount,
          goalsCount: goalsCount,
        ),
        const SizedBox(height: 32.0),
        Text(
          'PERSONAL DIMENSIONS',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textDark.withValues(alpha: 0.4),
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 12.0,
          ),
        ),
        const SizedBox(height: 16.0),
        _buildTabletMenuTiles(context),
        const SizedBox(height: 24.0),
        const NativeAdWidget(templateType: TemplateType.small),
        const SizedBox(height: 32.0),
        _buildTabletLogoutSection(context, userProvider),
        const SizedBox(height: 24.0),
      ],
    );
  }

  Widget _buildTabletIdentityCard(
    BuildContext context,
    UserProvider userProvider,
    String archetypeName,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECE4FA), Color(0xFFFBF4FA), AppColors.white],
          stops: [0.0, 0.7, 1.0],
        ),
        border: Border.all(
          color: AppColors.purpleLight.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.05),
            blurRadius: 18.0,
            offset: const Offset(0, 6.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showAvatarZoom(
              context,
              userProvider.profileImage,
              userProvider.name,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 124.0,
                  height: 124.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.22),
                        blurRadius: 28.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 8.0),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 124.0,
                  height: 124.0,
                  padding: const EdgeInsets.all(4.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        userProvider.profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.purple,
                            size: 54.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            userProvider.name,
            style: AppTextStyles.headingLarge.copyWith(
              fontSize: 26.0,
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10.0),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openArchetype(context),
              borderRadius: BorderRadius.circular(24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.08),
                      blurRadius: 14.0,
                      offset: const Offset(0, 4.0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.white,
                        size: 14.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      archetypeName,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.purpleLight,
                      size: 11.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletStatsRow({
    required bool isLoadingInitial,
    required String manifestedCount,
    required String streakCount,
    required String goalsCount,
  }) {
    return Row(
      children: [
        _ModernStatCard(
          label: 'MANIFESTED',
          value: manifestedCount,
          isLoading: isLoadingInitial,
          icon: Icons.auto_awesome_rounded,
          accentColor: AppColors.purple,
          bgColor: const Color(0xFFF5EEFF),
          borderColor: const Color(0xFFE8D8FF),
          gradientColors: const [Color(0xFF7B2FF7), Color(0xFFE91E8C)],
        ),
        const SizedBox(width: 12.0),
        _ModernStatCard(
          label: 'STREAK',
          value: streakCount,
          isLoading: isLoadingInitial,
          icon: Icons.local_fire_department_rounded,
          accentColor: const Color(0xFFFF5722),
          bgColor: const Color(0xFFFFF2EE),
          borderColor: const Color(0xFFFFDED4),
          gradientColors: const [Color(0xFFFF5722), Color(0xFFFF9800)],
        ),
        const SizedBox(width: 12.0),
        _ModernStatCard(
          label: 'GOALS',
          value: goalsCount,
          isLoading: isLoadingInitial,
          icon: Icons.track_changes_rounded,
          accentColor: AppColors.blue,
          bgColor: const Color(0xFFEEF5FF),
          borderColor: const Color(0xFFD6E6FF),
          gradientColors: const [Color(0xFF2979FF), Color(0xFF00E5FF)],
        ),
      ],
    );
  }

  Widget _buildTabletMenuTiles(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MenuTile(
          label: 'Edit Your Answers',
          subtitle: 'Update what you shared about yourself, family & career',
          icon: Icons.quiz_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProfileSetupScreen(isEditing: true),
            ),
          ),
        ),
        _MenuTile(
          label: 'Spiritual Archetype',
          subtitle: 'Your manifestation DNA and patterns',
          icon: Icons.psychology_rounded,
          onTap: () => _openArchetype(context),
        ),
        _MenuTile(
          label: 'Vision Board',
          subtitle: 'Active dream manifestations',
          icon: Icons.auto_graph_rounded,
          onTap: () => AdGate.run(
            context,
            key: 'vision_board',
            title: 'Support Manifest',
            message:
                'Watch a short ad to support Manifest. You won\'t be asked again for 24 hours.',
            interstitialStyle: true,
            blocking: false,
            onUnlocked: () =>
                Navigator.pushNamed(context, AppRoutes.visionBoard),
          ),
        ),
        _MenuTile(
          label: 'Privacy Settings',
          subtitle: 'Data protection and sphere visibility',
          icon: Icons.security_rounded,
          onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
        ),
        _MenuTile(
          label: 'App Notifications',
          subtitle: 'Manage push notifications and updates',
          icon: Icons.notifications_active_rounded,
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.notificationSettings),
        ),
      ],
    );
  }

  Widget _buildTabletLogoutSection(
    BuildContext context,
    UserProvider userProvider,
  ) {
    return Center(
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
              size: 20.0,
            ),
            label: Text(
              'DEACTIVATE CONNECTION',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pink,
                fontWeight: FontWeight.w900,
                fontSize: 13.0,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Version 2.4.0 (AI Enhanced)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textLightGrey,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone Layout (Preserved 100% Unchanged) ──────────────────────────────
  Widget _buildPhoneLayout(
    BuildContext context,
    UserProvider userProvider,
    ManifestProvider manifestProvider,
    bool isLoadingInitial,
    String manifestedCount,
    String streakCount,
    String goalsCount,
    String archetypeName,
  ) {
    return Scaffold(
      backgroundColor: AppColors.white,
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 340.h,
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            shadowColor: AppColors.purple.withValues(alpha: 0.08),
            elevation: 0,
            scrolledUnderElevation: 2,
            pinned: true,
            stretch: true,
            centerTitle: true,
            title: AnimatedOpacity(
              opacity: _showAppBarTitle ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Text(
                'Profile',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.textDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            leadingWidth: 68.w,
            leading: Padding(
              padding: EdgeInsets.only(left: 18.w),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(22.r),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1.2.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.08),
                            blurRadius: 10.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textDark,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 18.w),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.editProfile),
                      borderRadius: BorderRadius.circular(22.r),
                      child: Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 1.2.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.08),
                              blurRadius: 10.r,
                              offset: Offset(0, 3.h),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.textDark,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                alignment: Alignment.center,
                children: [
                  // Smooth cosmic atmospheric background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFECE4FA), // soft luminous lavender
                            Color(0xFFFBF4FA), // gentle blush
                            AppColors.white, // seamless blend into content
                          ],
                          stops: [0.0, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Soft ambient aura glows without harsh banding
                  Positioned(
                    top: -30.h,
                    right: -30.w,
                    child: Container(
                      width: 200.r,
                      height: 200.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.purpleLight.withValues(alpha: 0.12),
                            AppColors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 70.h,
                    left: -40.w,
                    child: Container(
                      width: 180.r,
                      height: 180.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.pinkLight.withValues(alpha: 0.10),
                            AppColors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Profile Identity Section
                  Positioned(
                    bottom: 10.h,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Big Glowing Avatar with Zoom on Tap ──
                        GestureDetector(
                          onTap: () => _showAvatarZoom(
                            context,
                            userProvider.profileImage,
                            userProvider.name,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer soft atmospheric glow
                              Container(
                                width: 124.r,
                                height: 124.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple.withValues(
                                        alpha: 0.20,
                                      ),
                                      blurRadius: 28.r,
                                      spreadRadius: 2.r,
                                      offset: Offset(0, 8.h),
                                    ),
                                  ],
                                ),
                              ),
                              // Gradient halo ring (original big size)
                              Container(
                                width: 124.r,
                                height: 124.r,
                                padding: EdgeInsets.all(4.r),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(3.r),
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      userProvider.profileImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, _) =>
                                          Container(
                                            color: AppColors.surfaceLight,
                                            child: const Icon(
                                              Icons.person_rounded,
                                              color: AppColors.purple,
                                              size: 54,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        14.verticalSpace,
                        // ── User Name ──
                        Text(
                          userProvider.name,
                          style: AppTextStyles.headingLarge.copyWith(
                            fontSize: 26.sp,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        8.verticalSpace,
                        // ── Interactive Spiritual Archetype Badge ──
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openArchetype(context),
                            borderRadius: BorderRadius.circular(24.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 7.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(24.r),
                                border: Border.all(
                                  color: AppColors.purple.withValues(
                                    alpha: 0.20,
                                  ),
                                  width: 1.2.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 14.r,
                                    offset: Offset(0, 4.h),
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
                                    archetypeName,
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.sp,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  6.horizontalSpace,
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.purpleLight,
                                    size: 10.sp,
                                  ),
                                ],
                              ),
                            ),
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
                    onTap: () => _openArchetype(context),
                  ),
                  _MenuTile(
                    label: 'Vision Board',
                    subtitle: 'Active dream manifestations',
                    icon: Icons.auto_graph_rounded,
                    onTap: () => AdGate.run(
                      context,
                      key: 'vision_board',
                      title: 'Support Manifest',
                      message:
                          'Watch a short ad to support Manifest. You won\'t be asked again for 24 hours.',
                      interstitialStyle: true,
                      blocking: false,
                      onUnlocked: () =>
                          Navigator.pushNamed(context, AppRoutes.visionBoard),
                    ),
                  ),
                  _MenuTile(
                    label: 'Privacy Settings',
                    subtitle: 'Data protection and sphere visibility',
                    icon: Icons.security_rounded,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.privacySettings),
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
                  32.verticalSpace,
                  const NativeAdWidget(templateType: TemplateType.small),
                  48.verticalSpace,
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
    final isTablet = context.isTablet;
    return Expanded(
      child: Container(
        padding: isTablet
            ? const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0)
            : EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isTablet ? 18.0 : 20.r),
          border: Border.all(color: borderColor, width: isTablet ? 1.2 : 1.2.w),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: isTablet ? 10.0 : 10.r,
              offset: Offset(0, isTablet ? 3.0 : 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 38.0 : 36.r,
              height: isTablet ? 38.0 : 36.r,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.16),
                    blurRadius: isTablet ? 6.0 : 6.r,
                    offset: Offset(0, isTablet ? 2.0 : 2.h),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: isTablet ? 20.0 : 19.sp,
              ),
            ),
            isTablet ? const SizedBox(height: 10.0) : 10.verticalSpace,
            SizedBox(
              height: isTablet ? 28.0 : 28.h,
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
                            fontSize: isTablet ? 24.0 : 24.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                ),
              ),
            ),
            isTablet ? const SizedBox(height: 4.0) : 4.verticalSpace,
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 10.0 : 9.5.sp,
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
    final isTablet = context.isTablet;
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 12.0 : 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isTablet ? 18.0 : 18.r),
          child: Container(
            padding: isTablet
                ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0)
                : EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(isTablet ? 18.0 : 18.r),
              border: Border.all(
                color: AppColors.borderLight,
                width: isTablet ? 1.0 : 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.03),
                  blurRadius: isTablet ? 10.0 : 10.r,
                  offset: Offset(0, isTablet ? 3.0 : 3.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 44.0 : 44.r,
                  height: isTablet ? 44.0 : 44.r,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: isTablet ? 1.0 : 1.w,
                    ),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ).createShader(bounds),
                    child: Icon(
                      icon,
                      color: AppColors.white,
                      size: isTablet ? 22.0 : 22.sp,
                    ),
                  ),
                ),
                isTablet ? const SizedBox(width: 16.0) : 16.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: isTablet ? 15.0 : 15.sp,
                        ),
                      ),
                      isTablet ? const SizedBox(height: 3.0) : 3.verticalSpace,
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                          fontSize: isTablet ? 12.0 : 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: isTablet ? 28.0 : 28.r,
                  height: isTablet ? 28.0 : 28.r,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLightGrey,
                    size: isTablet ? 18.0 : 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showAvatarZoom(BuildContext context, String imageUrl, String name) {
  HapticFeedback.lightImpact();
  final isTablet = context.isTablet;
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'DismissAvatarZoom',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16 * animation.value,
            sigmaY: 16 * animation.value,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.35, end: 1.0).animate(curved),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isTablet ? 280.0 : 260.r,
                        height: isTablet ? 280.0 : 260.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.45),
                              blurRadius: isTablet ? 40.0 : 40.r,
                              spreadRadius: isTablet ? 6.0 : 6.r,
                            ),
                            BoxShadow(
                              color: AppColors.pink.withValues(alpha: 0.35),
                              blurRadius: isTablet ? 60.0 : 60.r,
                              spreadRadius: isTablet ? 2.0 : 2.r,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 5.0 : 5.r),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 4.0 : 4.r),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, _) => Container(
                                  color: AppColors.surfaceLight,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: AppColors.purple,
                                    size: isTablet ? 110.0 : 110.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      isTablet
                          ? const SizedBox(height: 20.0)
                          : 20.verticalSpace,
                      Text(
                        name,
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.white,
                          fontSize: isTablet ? 26.0 : 24.sp,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
