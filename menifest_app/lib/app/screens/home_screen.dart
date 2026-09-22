import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/common/core.dart';
import '../services/manifest_provider.dart';
import '../services/user_provider.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _dreamController = TextEditingController();
  String? _lastHandledGoal;

  static const List<Map<String, String>> _promptCategories = [
    {
      'label': 'Career Growth',
      'icon': 'trending_up',
      'prompt':
          'I want to accelerate my career growth, step into leadership, and lead impactful initiatives with clarity and confidence.',
    },
    {
      'label': 'Financial Freedom',
      'icon': 'account_balance_wallet',
      'prompt':
          'I want to build lasting financial independence, unlock multiple income streams, and cultivate an abundance mindset.',
    },
    {
      'label': 'Clarity & Focus',
      'icon': 'psychology',
      'prompt':
          'I want to cultivate deep mental clarity, master my daily habits, and live with focused intent and inner calmness.',
    },
    {
      'label': 'Deep Connections',
      'icon': 'favorite',
      'prompt':
          'I want to attract and nurture authentic, meaningful relationships grounded in mutual respect, trust, and shared growth.',
    },
    {
      'label': 'Peak Health',
      'icon': 'bolt',
      'prompt':
          'I want to optimize my physical and mental energy through restorative sleep, disciplined movement, and vibrant wellness.',
    },
  ];

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
  void dispose() {
    _dreamController.dispose();
    super.dispose();
  }

  void _submitManifestation(ManifestProvider provider) {
    final text = _dreamController.text.trim();
    if (text.isEmpty || provider.isLoading) return;
    FocusScope.of(context).unfocus();
    final user = context.read<UserProvider>();
    provider.generateManifestationPlan(
      user.userId ?? '',
      _dreamController.text,
      personalize: user.personalizationEnabled,
    );
  }

  void _applyPrompt(String prompt) {
    _dreamController.text = prompt;
    _dreamController.selection = TextSelection.fromPosition(
      TextPosition(offset: prompt.length),
    );
    setState(() {});
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'favorite':
        return Icons.favorite_border_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManifestProvider>(
      builder: (context, provider, _) {
        if (provider.activeGoal.isNotEmpty &&
            provider.activeGoal != _lastHandledGoal) {
          _lastHandledGoal = provider.activeGoal;

          if (!provider.isFocused) {
            _dreamController.text = provider.activeGoal;
          }
        }

        // Show Toast if duplicate is detected
        if (provider.duplicateDetected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You have already manifested this vision! ✨',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
                backgroundColor: AppColors.purple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
            provider.clearDuplicateError();
          });
        }

        final user = context.watch<UserProvider>();
        final displayName = user.name.trim().isNotEmpty
            ? user.name.trim().split(' ').first
            : 'there';

        return Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              // Refined subtle atmospheric light gradients
              Positioned(
                top: -120.h,
                right: -80.w,
                child: Container(
                  width: 360.w,
                  height: 360.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.1),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 240.h,
                left: -100.w,
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.pink.withValues(alpha: 0.07),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: Modern, Crisp & Clean ─────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6.r,
                                      height: 6.r,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.purple,
                                      ),
                                    ),
                                    8.horizontalSpace,
                                    Text(
                                      'MANIFESTATION PLATFORM',
                                      style: TextStyle(
                                        color: AppColors.purple,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                        fontSize: 10.5.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                6.verticalSpace,
                                Text(
                                  '${_getGreeting()}, $displayName',
                                  style: AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          14.horizontalSpace,
                          // Refined Profile Avatar
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.profile),
                            child: Container(
                              padding: EdgeInsets.all(2.r),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: AppColors.primaryGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  image: DecorationImage(
                                    image: NetworkImage(user.profileImage),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      20.verticalSpace,

                      // ── Hero Banner: Vibrant, Sleek & Modern ──────────────
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.28),
                              blurRadius: 24.r,
                              offset: Offset(0, 10.h),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20.w,
                              top: -20.h,
                              child: Container(
                                width: 140.w,
                                height: 140.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 40.w,
                              bottom: -40.h,
                              child: Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(22.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                        ),
                                        child: Text(
                                          'VISION TO REALITY',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10.sp,
                                            letterSpacing: 1.4,
                                          ),
                                        ),
                                      ),
                                      if (provider.streakCount > 0)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .local_fire_department_rounded,
                                                color: Colors.white,
                                                size: 14.sp,
                                              ),
                                              4.horizontalSpace,
                                              Text(
                                                '${provider.streakCount} Day Streak',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  16.verticalSpace,
                                  Text(
                                    'What will you\ncreate today?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 25.sp,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  10.verticalSpace,
                                  Text(
                                    'Define your ambition with precision. The system translates your vision into an actionable daily roadmap.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13.5.sp,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      20.verticalSpace,

                      // ── Guided Focus Chips (Refined, Modern Category Pills) ─
                      Text(
                        'Focus Areas',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5.sp,
                        ),
                      ),
                      10.verticalSpace,
                      SizedBox(
                        height: 38.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _promptCategories.length,
                          separatorBuilder: (context, index) =>
                              8.horizontalSpace,
                          itemBuilder: (context, index) {
                            final cat = _promptCategories[index];
                            return InkWell(
                              onTap: () => _applyPrompt(cat['prompt']!),
                              borderRadius: BorderRadius.circular(18.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                    width: 1.w,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(cat['icon']!),
                                      size: 15.sp,
                                      color: AppColors.purple,
                                    ),
                                    8.horizontalSpace,
                                    Text(
                                      cat['label']!,
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      18.verticalSpace,

                      // ── Intention Canvas (Elevated, Crisp Writing Space) ───
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22.r),
                          border: Border.all(
                            color: provider.isFocused
                                ? AppColors.purple
                                : AppColors.borderLight,
                            width: provider.isFocused ? 1.8.w : 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: provider.isFocused
                                  ? AppColors.purple.withValues(alpha: 0.12)
                                  : AppColors.purple.withValues(alpha: 0.04),
                              blurRadius: provider.isFocused ? 18.r : 10.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                18.w,
                                14.h,
                                14.w,
                                4.h,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        color: AppColors.purple,
                                        size: 18.sp,
                                      ),
                                      8.horizontalSpace,
                                      Text(
                                        'YOUR GOAL',
                                        style: TextStyle(
                                          color: AppColors.purple,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.3,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _dreamController,
                                    builder: (context, value, _) {
                                      if (value.text.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                          _dreamController.clear();
                                          setState(() {});
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          child: Text(
                                            'Clear',
                                            style: TextStyle(
                                              color: AppColors.textGrey,
                                              fontSize: 11.5.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                18.w,
                                6.h,
                                18.w,
                                16.h,
                              ),
                              child: Focus(
                                onFocusChange: (focus) =>
                                    provider.setFocused(focus),
                                child: TextField(
                                  controller: _dreamController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) =>
                                      _submitManifestation(provider),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                    fontSize: 14.5.sp,
                                  ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    hintText:
                                        'Describe what you want to achieve with specific clarity and intention...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textLightGrey,
                                      fontSize: 13.5.sp,
                                      height: 1.45,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Submit / Generate Action Button ────────────────────
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _dreamController,
                        builder: (context, value, child) {
                          final currentText = value.text.trim();
                          final isUnchanged =
                              currentText == provider.activeGoal;
                          final isCardsPresent =
                              provider.actionCards.isNotEmpty;

                          if (((isUnchanged && isCardsPresent) ||
                                  currentText.isEmpty) &&
                              !provider.isLoading) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              16.verticalSpace,
                              PrimaryButton(
                                label: provider.isLoading
                                    ? 'Generating Action Roadmap... ✨'
                                    : 'Build My Action Plan ✨',
                                onPressed: () => _submitManifestation(provider),
                                isLoading: provider.isLoading,
                              ),
                            ],
                          );
                        },
                      ),

                      // ── Invalid Input Warning Card ────────────────────────
                      if (provider.invalidReason != null) ...[
                        20.verticalSpace,
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(18.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: const Color(0xFFFFCC02),
                              width: 1.5.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFCC02,
                                ).withValues(alpha: 0.15),
                                blurRadius: 12.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: const Color(0xFFE6A800),
                                    size: 20.sp,
                                  ),
                                  10.horizontalSpace,
                                  Text(
                                    'Refine your goal statement',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF7A5800),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                              12.verticalSpace,
                              Text(
                                provider.invalidReason!,
                                style: TextStyle(
                                  color: const Color(0xFF5C4000),
                                  height: 1.5,
                                  fontSize: 13.5.sp,
                                ),
                              ),
                              if (provider.invalidTip != null &&
                                  provider.invalidTip!.isNotEmpty) ...[
                                10.verticalSpace,
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFCC02,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    'Tip: ${provider.invalidTip!}',
                                    style: TextStyle(
                                      color: const Color(0xFF7A5800),
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // ── Active Cosmic Roadmap Section ──────────────────────
                      if (provider.actionCards.isNotEmpty) ...[
                        32.verticalSpace,

                        // Section Title
                        Row(
                          children: [
                            Container(
                              width: 4.w,
                              height: 22.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: AppColors.primaryGradient,
                                ),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            12.horizontalSpace,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Cosmic Roadmap',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20.sp,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'Actionable milestones to achieve your vision',
                                    style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        16.verticalSpace,

                        Builder(
                          builder: (context) {
                            final pillars = provider.fullAi?['pillars'];
                            final steps = provider.actionCards
                                .asMap()
                                .entries
                                .map(
                                  (entry) => {
                                    'day_number': entry.key + 1,
                                    'task_title': entry.value['task_title'],
                                    'task_description':
                                        entry.value['task_description'],
                                    'summary':
                                        (pillars != null &&
                                            entry.key <
                                                (pillars as List).length)
                                        ? pillars[entry.key]['summary']
                                        : 'Structuring milestone plan...',
                                  },
                                )
                                .toList();

                            return Column(
                              children: steps
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: EdgeInsets.only(bottom: 14.h),
                                      child: _ActionCard(
                                        index: entry.key + 1,
                                        title: entry.value['task_title'],
                                        summary: entry.value['summary'],
                                        steps: steps,
                                        stepIndex: entry.key,
                                        plan: provider.currentPlan!,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ] else ...[
                        // ── Modern Insight Banner (When no plan is active) ───
                        24.verticalSpace,
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(22.r),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1.w,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_rounded,
                                    color: AppColors.purple,
                                    size: 18.sp,
                                  ),
                                  8.horizontalSpace,
                                  Text(
                                    'HOW IT WORKS',
                                    style: TextStyle(
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.3,
                                      fontSize: 10.5.sp,
                                    ),
                                  ),
                                ],
                              ),
                              14.verticalSpace,
                              _ModernStepItem(
                                step: '01',
                                title: 'Define with Precision',
                                subtitle:
                                    'Articulate your goal clearly. Specificity drives strategic execution.',
                              ),
                              12.verticalSpace,
                              _ModernStepItem(
                                step: '02',
                                title: 'AI-Generated Roadmap',
                                subtitle:
                                    'Our system decomposes your goal into sequential, actionable pillars.',
                              ),
                              12.verticalSpace,
                              _ModernStepItem(
                                step: '03',
                                title: 'Track Daily Milestones',
                                subtitle:
                                    'Execute one focused step at a time until your vision materializes.',
                              ),
                            ],
                          ),
                        ),
                      ],

                      32.verticalSpace,
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

class _ModernStepItem extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _ModernStepItem({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.r,
          height: 28.r,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.borderLight),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              color: AppColors.purple,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5.sp,
                  color: AppColors.textDark,
                ),
              ),
              2.verticalSpace,
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final int index;
  final String title;
  final String? summary;
  final Map<String, dynamic> plan;
  final List<Map<String, dynamic>> steps;
  final int stepIndex;

  const _ActionCard({
    required this.index,
    required this.title,
    this.summary,
    required this.plan,
    required this.steps,
    required this.stepIndex,
  });

  void _showDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.actionDetail,
      arguments: {'steps': steps, 'initialIndex': stepIndex, 'plan': plan},
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.borderLight, width: 1.w),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.04),
              blurRadius: 12.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Modern Step Number Indicator
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.25),
                    blurRadius: 8.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
            14.horizontalSpace,
            // Title & Preview Summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILLAR $index',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontSize: 14.sp,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (summary != null && summary!.isNotEmpty) ...[
                    4.verticalSpace,
                    Text(
                      summary!,
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            8.horizontalSpace,
            // Directional Arrow
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.purple,
                size: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
