import 'package:flutter/material.dart';
import 'package:menifest_app/app/services/user_provider.dart';
import 'package:menifest_app/app/widgets/primary_button.dart';
import 'package:menifest_app/core/common/core.dart';
import 'package:provider/provider.dart';

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
        final patternLabel =
            (data['pattern_label'] as String?) ?? 'The Pattern We Noticed';
        final patternText = (data['pattern_text'] as String?) ?? '';
        final strengthsLabel =
            (data['strengths_label'] as String?) ?? 'Your Strengths';
        final strengthsRaw = List.from(data['strengths'] as List? ?? []);
        // Supports both the new {title, description} shape and the older
        // plain-string shape, so cached/older responses still render.
        final strengths = strengthsRaw.map((s) {
          if (s is Map) {
            return _Strength(
              title: (s['title'] as String?) ?? '',
              description: (s['description'] as String?) ?? '',
            );
          }
          return _Strength(title: s.toString(), description: '');
        }).toList();
        final growthLabel =
            (data['growth_label'] as String?) ?? 'Your Growth Edge';
        final growthText = (data['growth_text'] as String?) ?? '';
        final visionLabel =
            (data['vision_label'] as String?) ?? 'What This Means For You';
        final visionText = (data['vision_text'] as String?) ?? '';
        final buttonLabel =
            (data['button_label'] as String?) ?? 'Continue My Journey';

        final palette = _getPalette(archetypeName);
        final icon = _getIcon(archetypeName);

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              headerLabel,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textGrey,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 40.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Simple identity header: icon + name, no gradients ──
                Row(
                  children: [
                    Container(
                      width: 56.r,
                      height: 56.r,
                      decoration: BoxDecoration(
                        color: palette[0].withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: palette[0], size: 28.sp),
                    ),
                    16.horizontalSpace,
                    Expanded(
                      child: Text(
                        archetypeName,
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.textDark,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                28.verticalSpace,

                // Essence section
                _SectionHeader(title: essenceLabel, icon: Icons.person_rounded),
                12.verticalSpace,
                Text(
                  essenceDesc,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textDark,
                    height: 1.6,
                  ),
                ),
                28.verticalSpace,

                // Pattern insight — the "what's new here" section, only
                // shown when the AI actually returned one.
                if (patternText.isNotEmpty) ...[
                  _SectionHeader(title: patternLabel, icon: Icons.hub_rounded),
                  12.verticalSpace,
                  _VisionCard(text: patternText, color: palette[1]),
                  28.verticalSpace,
                ],

                // Strengths section
                _SectionHeader(title: strengthsLabel, icon: Icons.bolt_rounded),
                12.verticalSpace,
                Column(
                  children: strengths
                      .map(
                        (s) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _StrengthCard(strength: s, color: palette[0]),
                        ),
                      )
                      .toList(),
                ),
                28.verticalSpace,

                // Growth edge section
                if (growthText.isNotEmpty) ...[
                  _SectionHeader(
                    title: growthLabel,
                    icon: Icons.trending_up_rounded,
                  ),
                  12.verticalSpace,
                  Text(
                    growthText,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textDark,
                      height: 1.6,
                    ),
                  ),
                  28.verticalSpace,
                ],

                // Vision / takeaway section
                _SectionHeader(
                  title: visionLabel,
                  icon: Icons.lightbulb_outline_rounded,
                ),
                12.verticalSpace,
                _VisionCard(text: visionText, color: palette[0]),
                36.verticalSpace,

                PrimaryButton(
                  label: buttonLabel,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Loading Screen ─────────────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return const _ArchetypeLoadingScreen();
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
        Icon(icon, color: AppColors.purple, size: 18.sp),
        8.horizontalSpace,
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Strength {
  final String title;
  final String description;

  const _Strength({required this.title, required this.description});
}

class _StrengthCard extends StatelessWidget {
  final _Strength strength;
  final Color color;

  const _StrengthCard({required this.strength, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              8.horizontalSpace,
              Expanded(
                child: Text(
                  strength.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
          if (strength.description.isNotEmpty) ...[
            8.verticalSpace,
            Text(
              strength.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                height: 1.4,
                fontSize: 13.sp,
              ),
            ),
          ],
        ],
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDark,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ArchetypeLoadingScreen extends StatefulWidget {
  const _ArchetypeLoadingScreen();

  @override
  State<_ArchetypeLoadingScreen> createState() =>
      _ArchetypeLoadingScreenState();
}

class _ArchetypeLoadingScreenState extends State<_ArchetypeLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _sparkle(double dx, double dy, double phase) {
    final t = (phase % 1.0);
    // Smooth triangular wave for breathing pulse
    final wave = 1.0 - (t - 0.5).abs() * 2;
    final opacity = (0.35 + 0.65 * wave).clamp(0.2, 1.0);
    final scale = 0.85 + 0.35 * wave;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Text(
            '✦',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFFAB6FF5)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // Gentle floating bob
            final floatOffset = -10.0 * (1.0 - (t - 0.5).abs() * 2);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _sparkle(-46, -18, (t + 0.1) % 1.0),
                    _sparkle(44, -26, (t + 0.4) % 1.0),
                    _sparkle(-34, 30, (t + 0.7) % 1.0),
                    _sparkle(40, 26, (t + 0.25) % 1.0),
                    Transform.translate(
                      offset: Offset(0, floatOffset),
                      child: Text('🚀', style: TextStyle(fontSize: 64.sp)),
                    ),
                  ],
                ),
                22.verticalSpace,
                Text(
                  'Reading Your Cosmic DNA... ✨',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w800,
                    fontSize: 22.sp,
                  ),
                ),
                10.verticalSpace,
                Text(
                  'The universe is crafting your unique\nspiritual archetype',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGrey,
                    height: 1.5,
                    fontSize: 13.sp,
                  ),
                ),
                40.verticalSpace,
              ],
            );
          },
        ),
      ),
    );
  }
}
