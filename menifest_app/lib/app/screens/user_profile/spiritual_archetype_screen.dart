import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';
import '../../widgets/primary_button.dart';

class SpiritualArchetypeScreen extends StatefulWidget {
  const SpiritualArchetypeScreen({super.key});

  @override
  State<SpiritualArchetypeScreen> createState() =>
      _SpiritualArchetypeScreenState();
}

class _SpiritualArchetypeScreenState extends State<SpiritualArchetypeScreen> {
  static const List<Color> _primaryPalette = [
    Color(0xFF7B2FF7), // Purple
    Color(0xFFE91E8C), // Pink
  ];

  static const List<IconData> _icons = [
    Icons.auto_awesome_rounded,
    Icons.palette_rounded,
    Icons.architecture_rounded,
    Icons.explore_rounded,
    Icons.psychology_rounded,
    Icons.diamond_rounded,
  ];

  /// Returns the standard brand palette
  List<Color> _getPalette(String name) {
    return _primaryPalette;
  }

  IconData _getIcon(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _icons.length;
    return _icons[idx];
  }

  @override
  void initState() {
    super.initState();
    // Fetch fresh AI-generated archetype after the frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      if (user.userId != null) {
        user.fetchArchetype();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final isLoading = userProvider.isFetchingArchetype;
        final data = userProvider.archetypeData;

        if (isLoading) return _buildLoadingScreen();
        if (data == null) return _buildErrorScreen(context, userProvider);

        final archetypeName =
            (data['archetype_name'] as String?) ?? 'The Manifesting Mystic';
        final headerLabel =
            (data['header_label'] as String?) ?? 'COSMIC FOOTPRINT';
        final essenceLabel =
            (data['essence_label'] as String?) ?? 'The Soul Essence';
        final essenceDesc = (data['essence_description'] as String?) ?? '';
        final strengthsLabel =
            (data['strengths_label'] as String?) ?? 'Core Strengths';
        final strengths = List<String>.from(data['strengths'] as List? ?? []);
        final visionLabel =
            (data['vision_label'] as String?) ?? 'Spiritual Vision';
        final visionText = (data['vision_text'] as String?) ?? '';
        final buttonLabel =
            (data['button_label'] as String?) ?? 'Continue My Journey';

        final palette = _getPalette(archetypeName);
        final icon = _getIcon(archetypeName);

        return Scaffold(
          backgroundColor: AppColors.white,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.h,
                pinned: true,
                backgroundColor: palette[0],
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Refresh button — re-generate archetype on demand
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.white,
                    ),
                    tooltip: 'Regenerate',
                    onPressed: () {
                      if (userProvider.userId != null) {
                        userProvider.fetchArchetype();
                      }
                    },
                  ),
                  10.horizontalSpace,
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette[0].withValues(alpha: 0.85),
                              palette[1].withValues(alpha: 0.95),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Aura glow top-left
                      Positioned(
                        top: -100.h,
                        left: -100.w,
                        child: Container(
                          width: 400.r,
                          height: 400.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.white.withValues(alpha: 0.15),
                                AppColors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Aura glow bottom-right
                      Positioned(
                        bottom: 0,
                        right: -150.w,
                        child: Container(
                          width: 500.r,
                          height: 500.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                palette[0].withValues(alpha: 0.3),
                                palette[0].withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Large icon watermark
                      Positioned(
                        bottom: -30.h,
                        right: -20.w,
                        child: Icon(
                          icon,
                          size: 260.sp,
                          color: AppColors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      // Text content
                      Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header label badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(30.r),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                headerLabel.toUpperCase(),
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.white,
                                  letterSpacing: 2.0,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            16.verticalSpace,
                            Text(
                              archetypeName,
                              style: AppTextStyles.headingLarge.copyWith(
                                color: AppColors.white,
                                fontSize: 38.sp,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.1,
                                    ),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Essence section
                      _SectionHeader(
                        title: essenceLabel,
                        icon: Icons.auto_awesome,
                      ),
                      16.verticalSpace,
                      Text(
                        essenceDesc,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGrey,
                          height: 1.6,
                        ),
                      ),
                      32.verticalSpace,

                      // Strengths section
                      _SectionHeader(title: strengthsLabel, icon: Icons.bolt),
                      16.verticalSpace,
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: strengths
                            .map(
                              (s) => _StrengthChip(label: s, color: palette[0]),
                            )
                            .toList(),
                      ),
                      32.verticalSpace,

                      // Vision section
                      _SectionHeader(
                        title: visionLabel,
                        icon: Icons.remove_red_eye,
                      ),
                      16.verticalSpace,
                      _VisionCard(text: visionText, color: palette[0]),
                      40.verticalSpace,

                      PrimaryButton(
                        label: buttonLabel,
                        onPressed: () => Navigator.pop(context),
                      ),
                      40.verticalSpace,
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

  // ── Loading Screen ─────────────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Gradient header placeholder
          Container(
            height: 250.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFFE91E8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  100.verticalSpace,
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLight,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.purple,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  32.verticalSpace,
                  Text(
                    'Reading Your Cosmic DNA...',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  12.verticalSpace,
                  Text(
                    'The universe is crafting your unique\nspiritual archetype',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGrey,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Screen ───────────────────────────────────────────────────────
  Widget _buildErrorScreen(BuildContext context, UserProvider userProvider) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: AppColors.purple,
                  size: 48.sp,
                ),
              ),
              24.verticalSpace,
              Text(
                'Cosmic Signal Lost',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textDark,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              12.verticalSpace,
              Text(
                'Unable to generate your spiritual archetype right now. Make sure your profile answers are complete and try again.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
              ),
              32.verticalSpace,
              PrimaryButton(
                label: 'Try Again ✨',
                onPressed: () {
                  if (userProvider.userId != null) {
                    userProvider.fetchArchetype();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets (unchanged UI) ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.purple, size: 24.sp),
        12.horizontalSpace,
        Text(
          title.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: AppColors.textDark,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StrengthChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StrengthChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _VisionCard extends StatelessWidget {
  final String text;
  final Color color;

  const _VisionCard({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Expanded(
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
