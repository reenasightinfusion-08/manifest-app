import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onPageChanged(BuildContext context, int index) {
    context.read<UserProvider>().setOnboardingStep(index);
    _animController.reset();
    _animController.forward();
  }

  void _next(BuildContext context, UserProvider provider) async {
    if (!provider.isStepComplete(provider.onboardingStep)) {
      provider.setShowOnboardingErrors(true);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The universe needs more info to align your reality! ✨',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 120.h,
            left: 24.w,
            right: 24.w,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (provider.onboardingStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      try {
        await provider.syncToApi();
        if (!context.mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your Cosmic Profile is Ready! ✨',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e
                  .toString()
                  .replaceAll('Exception: Server returned error: ', '')
                  .replaceAll('Exception: ', ''),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.pink,
          ),
        );
      }
    }
  }

  void _back(UserProvider provider) {
    if (provider.onboardingStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final bool isLast = provider.onboardingStep == 3;

        return Scaffold(
          backgroundColor: AppColors.white,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Positioned(
                top: -100.h,
                right: -60.w,
                child: Container(
                  width: 320.w,
                  height: 320.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.06),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50.h,
                left: -40.w,
                child: Container(
                  width: 280.w,
                  height: 280.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.pink.withValues(alpha: 0.05),
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                      child: Row(
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: provider.onboardingStep > 0 ? 1.0 : 0.0,
                            child: GestureDetector(
                              onTap: () => _back(provider),
                              child: Container(
                                width: 44.w,
                                height: 44.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  border: Border.all(
                                    color: AppColors.borderFaded,
                                    width: 1.5.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 8.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.textDark,
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.borderVeryLight,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: AppColors.borderFaded,
                                width: 1.w,
                              ),
                            ),
                            child: Text(
                              'Step ${provider.onboardingStep + 1} of 4',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Row(
                        children: List.generate(4, (i) {
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: EdgeInsets.only(right: i < 3 ? 8.w : 0),
                              height: 4.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2.r),
                                gradient: i <= provider.onboardingStep
                                    ? const LinearGradient(
                                        colors: AppColors.primaryGradient,
                                      )
                                    : null,
                                color: i > provider.onboardingStep
                                    ? AppColors.stepDotInactive
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (idx) => _onPageChanged(context, idx),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          if (index == 3) {
                            return _SecurityStep(fadeAnim: _fadeAnim);
                          }
                          return _QuestionPage(
                            fadeAnim: _fadeAnim,
                            page: _pages[index],
                            answers: provider.getAnswersFor(index),
                            onChanged: (qIndex, val) {
                              provider.updateAnswer(index, qIndex, val);
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24.w,
                        0,
                        24.w,
                        MediaQuery.of(context).padding.bottom + 32.h,
                      ),
                      child: GestureDetector(
                        onTap: () => _next(context, provider),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 64.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.glowPink,
                                blurRadius: 20.r,
                                spreadRadius: -4.r,
                                offset: Offset(0, 10.h),
                              ),
                            ],
                          ),
                          child: Center(
                            child: provider.isLoading
                                ? SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isLast
                                        ? 'Complete My Profile ✨'
                                        : 'Continue',
                                    style: AppTextStyles.buttonLarge.copyWith(
                                      fontSize: 16.sp,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_PageData> get _pages => const [
    _PageData(
      icon: Icons.person_outline_rounded,
      tag: 'ABOUT YOU',
      title: 'Tell Us\nAbout Yourself',
      questions: [
        _Question(
          'What is your first name?',
          Icons.badge_outlined,
          'e.g. Alex',
          false,
        ),
        _Question('How old are you?', Icons.cake_outlined, 'e.g. 25', false),
        _Question(
          'Where are you from?',
          Icons.location_on_outlined,
          'e.g. Mumbai, India',
          false,
        ),
        _Question(
          'What are your top 3 personal goals?',
          Icons.flag_outlined,
          'e.g. Health, peace, growth',
          true,
        ),
        _Question(
          'What does a perfect day look like for you?',
          Icons.wb_sunny_outlined,
          'Describe it freely…',
          true,
        ),
      ],
    ),
    _PageData(
      icon: Icons.family_restroom_rounded,
      tag: 'FAMILY',
      title: 'Your Family\nLife',
      questions: [
        _Question(
          'Are you single, partnered, or married?',
          Icons.favorite_border_rounded,
          'e.g. Married',
          false,
        ),
        _Question(
          'Do you have children?',
          Icons.child_care_outlined,
          'e.g. Yes, 2 kids',
          false,
        ),
        _Question(
          'What is your biggest family dream?',
          Icons.home_outlined,
          'e.g. A happy home, travel together',
          true,
        ),
        _Question(
          'What family relationship do you most want to improve?',
          Icons.handshake_outlined,
          'e.g. With my parents',
          true,
        ),
        _Question(
          'What family value matters most to you?',
          Icons.volunteer_activism_outlined,
          'e.g. Loyalty, love, respect',
          false,
        ),
      ],
    ),
    _PageData(
      icon: Icons.work_outline_rounded,
      tag: 'PROFESSIONAL',
      title: 'Your Career\n& Ambitions',
      questions: [
        _Question(
          'What do you do for work?',
          Icons.business_center_outlined,
          'e.g. Software Engineer',
          false,
        ),
        _Question(
          'What is your biggest career goal right now?',
          Icons.trending_up_rounded,
          'e.g. Get promoted, start a business',
          true,
        ),
        _Question(
          'What skills do you want to develop?',
          Icons.school_outlined,
          'e.g. Leadership, coding, design',
          true,
        ),
        _Question(
          'What does financial freedom mean to you?',
          Icons.account_balance_wallet_outlined,
          'Describe your vision…',
          true,
        ),
        _Question(
          'Where do you see yourself professionally in 5 years?',
          Icons.star_outline_rounded,
          'Dream big!',
          true,
        ),
      ],
    ),
  ];
}

class _PageData {
  final IconData icon;
  final String tag;
  final String title;
  final List<_Question> questions;

  const _PageData({
    required this.icon,
    required this.tag,
    required this.title,
    required this.questions,
  });
}

class _Question {
  final String text;
  final IconData icon;
  final String hint;
  final bool isMultiLine;

  const _Question(this.text, this.icon, this.hint, this.isMultiLine);
}

class _QuestionPage extends StatelessWidget {
  final Animation<double> fadeAnim;
  final _PageData page;
  final List<String> answers;
  final Function(int, String) onChanged;

  const _QuestionPage({
    required this.fadeAnim,
    required this.page,
    required this.answers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: ListView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 40.h),
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.glowPurple.withValues(alpha: 0.5),
                      blurRadius: 12.r,
                      spreadRadius: -2.r,
                    ),
                  ],
                ),
                child: Icon(page.icon, color: AppColors.white, size: 26.sp),
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.tag,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      page.title,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 22.sp,
                        height: 1.1,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          32.verticalSpace,
          ...List.generate(page.questions.length, (i) {
            final q = page.questions[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: _QuestionCard(
                index: i + 1,
                question: q,
                value: answers[i],
                onChanged: (val) => onChanged(i, val),
              ),
            );
          }),
          8.verticalSpace,
        ],
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final int index;
  final _Question question;
  final String value;
  final ValueChanged<String> onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final bool isFocused = provider.focusedQuestionIndex == widget.index;
        final bool isError =
            provider.showOnboardingErrors && widget.value.trim().isEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isError
                  ? AppColors.pink
                  : isFocused
                  ? AppColors.pink
                  : AppColors.borderVeryLight,
              width: (isFocused || isError) ? 1.5.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isError
                    ? AppColors.pink.withValues(alpha: 0.1)
                    : isFocused
                    ? AppColors.glowPink.withValues(alpha: 0.12)
                    : AppColors.black.withValues(alpha: 0.04),
                blurRadius: (isFocused || isError) ? 16.r : 8.r,
                spreadRadius: -2.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.purple.withValues(alpha: 0.6),
                            AppColors.pink.withValues(alpha: 0.6),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index}',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: Text(
                        widget.question.text,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                Focus(
                  onFocusChange: (f) {
                    if (f) {
                      provider.setFocusedQuestion(widget.index);
                    } else if (provider.focusedQuestionIndex == widget.index) {
                      provider.setFocusedQuestion(null);
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    onChanged: widget.onChanged,
                    maxLines: widget.question.isMultiLine ? 3 : 1,
                    minLines: 1,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.question.hint,
                      hintStyle: AppTextStyles.hint.copyWith(
                        color: AppColors.textLightGrey,
                        fontSize: 14.sp,
                      ),
                      prefixIcon: Icon(
                        widget.question.icon,
                        color: AppColors.purple.withValues(alpha: 0.5),
                        size: 18.sp,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SecurityStep extends StatefulWidget {
  final Animation<double> fadeAnim;

  const _SecurityStep({required this.fadeAnim});

  @override
  State<_SecurityStep> createState() => _SecurityStepState();
}

class _SecurityStepState extends State<_SecurityStep> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-focus after a short delay to allow page transition to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnim,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 40.h),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowPurple.withValues(alpha: 0.5),
                          blurRadius: 12.r,
                          spreadRadius: -2.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: AppColors.white,
                      size: 26.sp,
                    ),
                  ),
                  14.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROTECT THE COSMOS',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          'Your Secret\nPassphrase',
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 22.sp,
                            height: 1.1,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              40.verticalSpace,
              Center(
                child: Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVeryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 60.sp,
                    color: AppColors.purple.withValues(alpha: 0.3),
                  ),
                ),
              ),
              32.verticalSpace,
              Text(
                'To protect your manifestations, set a 4-digit code. This will be required when accessing your profile from any device.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                  height: 1.6,
                  fontSize: 14.sp,
                ),
              ),
              40.verticalSpace,
              // Wrap in GestureDetector to ensure keyboard opens on tap
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Consumer<UserProvider>(
                  builder: (context, provider, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final String code = provider.passcode ?? '';
                      final bool filled = code.length > index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.symmetric(horizontal: 6.w),
                        width: 45.w,
                        height: 55.h,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: filled
                                ? AppColors.purple
                                : AppColors.borderVeryLight,
                            width: filled ? 2.w : 1.w,
                          ),
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 10.r,
                                    spreadRadius: 2.r,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            filled ? '●' : '',
                            style: TextStyle(
                              fontSize: 24.sp,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              24.verticalSpace,
              Text(
                'TAP TO ENTER CODE',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textLightGrey,
                  fontSize: 10.sp,
                  letterSpacing: 2,
                ),
              ),
              // The actual hidden TextField
              SizedBox(
                height: 0,
                width: 0,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) {
                    context.read<UserProvider>().setPasscode(val);
                  },
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
