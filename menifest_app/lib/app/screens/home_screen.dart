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
                  borderRadius: BorderRadius.circular(12.r),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
            provider.clearDuplicateError();
          });
        }
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              Positioned(
                top: -100.h,
                right: -80.w,
                child: Container(
                  width: 350.w,
                  height: 350.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.08),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 150.h,
                left: -120.w,
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.pink.withValues(alpha: 0.06),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WELCOME BACK',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  fontSize: 12.sp,
                                ),
                              ),
                              Text(
                                'Your Journey ✨',
                                style: AppTextStyles.headingLarge.copyWith(
                                  color: AppColors.textDark,
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.profile),
                            child: Consumer<UserProvider>(
                              builder: (context, userProvider, _) {
                                return Container(
                                  width: 48.w,
                                  height: 48.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceLight,
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                      width: 1.5.w,
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        userProvider.profileImage,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      32.verticalSpace,

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30.w,
                              top: -30.h,
                              child: Container(
                                width: 120.w,
                                height: 120.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -20.w,
                              bottom: -20.h,
                              child: Container(
                                width: 80.w,
                                height: 80.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      'MANIFEST TODAY',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  16.verticalSpace,
                                  Text(
                                    'What will you\ncreate today?',
                                    style: AppTextStyles.headingLarge.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                      fontSize: 24.sp,
                                    ),
                                  ),
                                  12.verticalSpace,
                                  Text(
                                    'Describe your vision clearly. The universe is listening and ready to help you plan.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      height: 1.5,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      22.verticalSpace,

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: provider.isFocused
                                ? AppColors.pink
                                : AppColors.borderLight,
                            width: provider.isFocused ? 1.5.w : 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: provider.isFocused
                                  ? AppColors.glowPink.withValues(alpha: 0.15)
                                  : AppColors.black.withValues(alpha: 0.02),
                              blurRadius: provider.isFocused ? 16.r : 8.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Focus(
                            onFocusChange: (focus) =>
                                provider.setFocused(focus),
                            child: TextField(
                              controller: _dreamController,
                              maxLines: 5,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                                fontSize: 14.sp,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.transparent,
                                hintText:
                                    'E.g., I want to become a successful entrepreneur and build my own startup that helps people...',
                                hintStyle: AppTextStyles.hint.copyWith(
                                  color: AppColors.textLightGrey,
                                  fontSize: 14.sp,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 20.h,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

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
                              32.verticalSpace,
                              PrimaryButton(
                                label: 'Get My Action Plan ✨',
                                onPressed: () {
                                  final user = context.read<UserProvider>();
                                  provider.generateManifestationPlan(
                                    user.userId ?? '',
                                    _dreamController.text,
                                  );
                                },
                                isLoading: provider.isLoading,
                              ),
                            ],
                          );
                        },
                      ),

                      // ── Invalid Input Info Card ───────────────────────────
                      if (provider.invalidReason != null) ...[
                        24.verticalSpace,
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.r),
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
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFFCC02,
                                      ).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline_rounded,
                                      color: const Color(0xFFE6A800),
                                      size: 20.sp,
                                    ),
                                  ),
                                  12.horizontalSpace,
                                  Text(
                                    'Not a valid manifestation goal',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF7A5800),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                              16.verticalSpace,
                              Text(
                                provider.invalidReason!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: const Color(0xFF5C4000),
                                  height: 1.6,
                                  fontSize: 14.sp,
                                ),
                              ),
                              if (provider.invalidTip != null &&
                                  provider.invalidTip!.isNotEmpty) ...[
                                12.verticalSpace,
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFCC02,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '💡 ',
                                        style: TextStyle(fontSize: 14.sp),
                                      ),
                                      Expanded(
                                        child: Text(
                                          provider.invalidTip!,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: const Color(0xFF7A5800),
                                                fontSize: 13.sp,
                                                height: 1.5,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      if (provider.actionCards.isNotEmpty) ...[
                        48.verticalSpace,
                        Row(
                          children: [
                            Container(
                              width: 4.w,
                              height: 24.h,
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
                            Text(
                              'Your Cosmic Roadmap',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 22.sp,
                              ),
                            ),
                          ],
                        ),
                        20.verticalSpace,
                        ...provider.actionCards.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: _ActionCard(
                              index: entry.key + 1,
                              title: entry.value['task_title'],
                              description: entry.value['task_description'],
                              plan: provider.currentPlan!,
                              summary: provider.fullAi?['pillars'] != null
                                  ? provider.fullAi!['pillars'][entry
                                        .key]['summary']
                                  : 'Harnessing cosmic intent...',
                            ),
                          ),
                        ),
                      ],

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
}

class _ActionCard extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final Map<String, dynamic> plan;
  final String summary;

  const _ActionCard({
    required this.index,
    required this.title,
    required this.description,
    required this.plan,
    required this.summary,
  });

  void _showDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.actionDetail,
      arguments: {
        'cardData': {
          'day_number': index,
          'task_title': title,
          'task_description': description,
          'summary': summary,
        },
        'plan': plan,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.borderVeryLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
            20.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  4.verticalSpace,
                  Text(
                    'Tap to view cosmic details',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textLightGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
