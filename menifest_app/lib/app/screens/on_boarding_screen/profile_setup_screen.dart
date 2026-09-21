import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';

/// Shown right after the account's email is verified. This is where the
/// personal/family/professional profiling questions live now — moved out
/// of the pre-verification signup flow so a mistyped or wrong email can't
/// cost someone several minutes of answers before they find out the
/// account never got confirmed. Answers here are synced onto the
/// already-created, already-verified account (UserProvider.syncToApi
/// updates in place once _userId is set), so there's no equivalent
/// "lose everything" failure mode left on this screen.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
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

    // The name was already collected on the account-creation step —
    // carry it into the first question here instead of asking again.
    final provider = context.read<UserProvider>();
    if (provider.personalAnswers[0].trim().isEmpty &&
        provider.name.isNotEmpty) {
      provider.updateAnswer(0, 0, provider.name);
    }
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

  void _goHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _next(BuildContext context, UserProvider provider) async {
    if (!provider.isStepComplete(provider.onboardingStep + 1)) {
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

    if (provider.onboardingStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      try {
        // Last step — this is the call that marks the profile complete
        // and triggers the welcome push (see UserProvider.syncToApi).
        await provider.syncToApi(completeProfile: true);
        if (!context.mounted) return;
        _goHome(context);
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
        final bool isLast = provider.onboardingStep == 2;

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
                          GestureDetector(
                            onTap: () => _goHome(context),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.h,
                                horizontal: 4.w,
                              ),
                              child: Text(
                                'SKIP FOR NOW',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ),
                          10.horizontalSpace,
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
                              'Step ${provider.onboardingStep + 1} of 3',
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
                        children: List.generate(3, (i) {
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: EdgeInsets.only(right: i < 2 ? 8.w : 0),
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
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return _QuestionPage(
                            key: ValueKey('question_page_$index'),
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
        _Question.text(
          'What is your first name?',
          Icons.badge_outlined,
          'e.g. Alex',
        ),
        _Question.single(
          'How old are you?',
          Icons.cake_outlined,
          'Select your age range',
          ['Under 18', '18–24', '25–34', '35–44', '45–54', '55–64', '65+'],
        ),
        _Question.text(
          'Where are you from?',
          Icons.location_on_outlined,
          'e.g. Mumbai, India',
        ),
        _Question.multiline(
          'What are your top 3 personal goals?',
          Icons.flag_outlined,
          'e.g. Health, peace, growth',
        ),
        _Question.multiline(
          'What does a perfect day look like for you?',
          Icons.wb_sunny_outlined,
          'Describe it freely…',
        ),
      ],
    ),
    _PageData(
      icon: Icons.family_restroom_rounded,
      tag: 'FAMILY',
      title: 'Your Family\nLife',
      questions: [
        _Question.single(
          'Are you single, partnered, or married?',
          Icons.favorite_border_rounded,
          'Select your status',
          ['Single', 'Partnered', 'Married', 'Divorced', 'Widowed'],
        ),
        _Question.single(
          'Do you have children?',
          Icons.child_care_outlined,
          'Select an option',
          ['No', 'Yes, 1', 'Yes, 2', 'Yes, 3+'],
        ),
        _Question.multiline(
          'What is your biggest family dream?',
          Icons.home_outlined,
          'e.g. A happy home, travel together',
        ),
        _Question.single(
          'What family relationship do you most want to improve?',
          Icons.handshake_outlined,
          'Select a relationship',
          [
            'Parents',
            'Spouse / Partner',
            'Children',
            'Siblings',
            'In-laws',
            'Other',
          ],
        ),
        _Question.multi(
          'What family value matters most to you?',
          Icons.volunteer_activism_outlined,
          'Select all that apply',
          [
            'Loyalty',
            'Love',
            'Respect',
            'Honesty',
            'Support',
            'Communication',
            'Trust',
            'Other',
          ],
        ),
      ],
    ),
    _PageData(
      icon: Icons.work_outline_rounded,
      tag: 'PROFESSIONAL',
      title: 'Your Career\n& Ambitions',
      questions: [
        _Question.text(
          'What do you do for work?',
          Icons.business_center_outlined,
          'e.g. Software Engineer',
        ),
        _Question.single(
          'What is your biggest career goal right now?',
          Icons.trending_up_rounded,
          'Select a goal',
          [
            'Get promoted',
            'Start a business',
            'Switch careers',
            'Increase income',
            'Improve work-life balance',
            'Other',
          ],
        ),
        _Question.multi(
          'What skills do you want to develop?',
          Icons.school_outlined,
          'Select all that apply',
          [
            'Leadership',
            'Communication',
            'Coding / Tech',
            'Design',
            'Public speaking',
            'Financial literacy',
            'Time management',
            'Other',
          ],
        ),
        _Question.multiline(
          'What does financial freedom mean to you?',
          Icons.account_balance_wallet_outlined,
          'Describe your vision…',
        ),
        _Question.single(
          'Where do you see yourself professionally in 5 years?',
          Icons.star_outline_rounded,
          'Select a vision',
          [
            'Business owner',
            'Senior leadership role',
            'Financially independent',
            'Industry expert',
            'Work-life balance focus',
            'Other',
          ],
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

/// A question is either free text (single or multi-line) or a set of
/// selectable options (single- or multi-choice, chip UI). Choice questions
/// still store their answer as a plain String — single-choice stores the
/// picked label, multi-choice stores the picked labels joined by ", " —
/// so nothing downstream (UserProvider, the backend) needs to change.
enum _AnswerKind { text, multilineText, singleChoice, multiChoice }

class _Question {
  final String text;
  final IconData icon;
  final String hint;
  final _AnswerKind kind;
  final List<String>? options;

  const _Question.text(this.text, this.icon, this.hint)
    : kind = _AnswerKind.text,
      options = null;

  const _Question.multiline(this.text, this.icon, this.hint)
    : kind = _AnswerKind.multilineText,
      options = null;

  const _Question.single(this.text, this.icon, this.hint, this.options)
    : kind = _AnswerKind.singleChoice;

  const _Question.multi(this.text, this.icon, this.hint, this.options)
    : kind = _AnswerKind.multiChoice;

  bool get isMultiLine => kind == _AnswerKind.multilineText;
  bool get isChoice =>
      kind == _AnswerKind.singleChoice || kind == _AnswerKind.multiChoice;
}

class _QuestionPage extends StatefulWidget {
  final Animation<double> fadeAnim;
  final _PageData page;
  final List<String> answers;
  final void Function(int, String) onChanged;

  const _QuestionPage({
    super.key,
    required this.fadeAnim,
    required this.page,
    required this.answers,
    required this.onChanged,
  });

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<_QuestionPage> {
  // One FocusNode per free-text question on this page (null for choice
  // questions, which don't take keyboard focus). This is what lets hitting
  // "next"/"enter" on the keyboard jump straight into the next textbox.
  late final List<FocusNode?> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.page.questions.length,
      (i) => widget.page.questions[i].isChoice ? null : FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node?.dispose();
    }
    super.dispose();
  }

  bool _isLastTextQuestion(int index) {
    for (int i = index + 1; i < widget.page.questions.length; i++) {
      if (_focusNodes[i] != null) return false;
    }
    return true;
  }

  void _focusNext(int index) {
    for (int i = index + 1; i < _focusNodes.length; i++) {
      final node = _focusNodes[i];
      if (node != null) {
        FocusScope.of(context).requestFocus(node);
        return;
      }
    }
    // No more textboxes on this page — dismiss the keyboard.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnim,
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
                child: Icon(
                  widget.page.icon,
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
                      widget.page.tag,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      widget.page.title,
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
          ...List.generate(widget.page.questions.length, (i) {
            final q = widget.page.questions[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 20.h),
              child: _QuestionCard(
                index: i + 1,
                question: q,
                value: widget.answers[i],
                focusNode: _focusNodes[i],
                textInputAction: _isLastTextQuestion(i)
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: () => _focusNext(i),
                onChanged: (val) => widget.onChanged(i, val),
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
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.value,
    required this.focusNode,
    required this.textInputAction,
    required this.onSubmitted,
    required this.onChanged,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late TextEditingController _controller;
  // Only used for choice questions whose selected option is "Other" —
  // holds the free-text value the user typed in to replace it.
  late TextEditingController _otherController;
  // Whether "Other" is the active selection. Tracked explicitly (rather
  // than inferred from the stored value) so tapping "Other" reveals the
  // input box and stays selected even before anything's been typed into it.
  bool _otherActive = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.question.isChoice ? '' : widget.value,
    );
    _otherController = TextEditingController(text: _initialOtherText());
    _otherActive = widget.question.isChoice && _computeInitialOtherActive();
  }

  /// If the stored value doesn't match any of the question's known
  /// options, treat it as a custom "Other" answer the user typed earlier.
  String _initialOtherText() {
    if (!widget.question.isChoice) return '';
    final options = widget.question.options ?? const [];
    if (widget.question.kind == _AnswerKind.singleChoice) {
      final v = widget.value.trim();
      if (v.isEmpty || options.contains(v)) return '';
      return v;
    }
    // Multi-choice: anything in the comma-separated value that isn't a
    // known option is the custom "Other" text.
    final picked = _splitMulti(widget.value);
    final extra = picked.where((p) => !options.contains(p));
    return extra.isEmpty ? '' : extra.first;
  }

  bool _computeInitialOtherActive() {
    final options = widget.question.options ?? const [];
    if (!options.contains('Other')) return false;
    if (widget.question.kind == _AnswerKind.singleChoice) {
      final v = widget.value.trim();
      return v.isNotEmpty && !options.contains(v);
    }
    return _splitMulti(widget.value).any((p) => !options.contains(p));
  }

  List<String> _splitMulti(String value) {
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void didUpdateWidget(covariant _QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.question.isChoice &&
        oldWidget.value != widget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _onOtherTextChanged(String text) {
    final trimmed = text.trim();
    if (widget.question.kind == _AnswerKind.singleChoice) {
      widget.onChanged(trimmed);
      return;
    }
    final options = widget.question.options ?? const [];
    final picked = _splitMulti(
      widget.value,
    ).where((p) => options.contains(p)).toList();
    if (trimmed.isNotEmpty) picked.add(trimmed);
    widget.onChanged(picked.join(', '));
  }

  bool get _showOtherInput => widget.question.isChoice && _otherActive;

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
                if (widget.question.isChoice)
                  _buildChoices()
                else
                  _buildTextField(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoices() {
    final hasValue = widget.value.trim().isNotEmpty;
    final isMulti = widget.question.kind == _AnswerKind.multiChoice;
    final multiItems = isMulti ? _splitMulti(widget.value) : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openSelectionSheet(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasValue
                    ? AppColors.purple.withValues(alpha: 0.4)
                    : AppColors.transparent,
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.question.icon,
                  color: hasValue
                      ? AppColors.purple
                      : AppColors.purple.withValues(alpha: 0.5),
                  size: 18.sp,
                ),
                12.horizontalSpace,
                Expanded(
                  child: !hasValue
                      ? Text(
                          widget.question.hint,
                          style: AppTextStyles.hint.copyWith(
                            color: AppColors.textLightGrey,
                            fontSize: 14.sp,
                          ),
                        )
                      : isMulti
                      ? Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: multiItems.map((item) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.purple.withValues(alpha: 0.12),
                                    AppColors.pink.withValues(alpha: 0.12),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: AppColors.purple.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.purple,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      : Text(
                          widget.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textDark,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                8.horizontalSpace,
                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.purple,
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showOtherInput) ...[
          10.verticalSpace,
          TextField(
            controller: _otherController,
            onChanged: _onOtherTextChanged,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Please specify your details…',
              hintStyle: AppTextStyles.hint.copyWith(
                color: AppColors.textLightGrey,
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(
                Icons.edit_outlined,
                color: AppColors.purple.withValues(alpha: 0.5),
                size: 16.sp,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.purple.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppColors.purple.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppColors.purple,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openSelectionSheet(BuildContext context) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return _DropdownSelectionSheet(
          question: widget.question,
          value: widget.value,
          otherActive: _otherActive,
          otherText: _otherController.text,
          onSelectionChanged: (newVal, otherActiveState, otherTextState) {
            setState(() {
              _otherActive = otherActiveState;
              _otherController.text = otherTextState;
            });
            widget.onChanged(newVal);
          },
        );
      },
    );
  }

  Widget _buildTextField() {
    return Focus(
      onFocusChange: (f) {
        final provider = context.read<UserProvider>();
        if (f) {
          provider.setFocusedQuestion(widget.index);
        } else if (provider.focusedQuestionIndex == widget.index) {
          provider.setFocusedQuestion(null);
        }
      },
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        maxLines: widget.question.isMultiLine ? 3 : 1,
        minLines: 1,
        textInputAction: widget.question.isMultiLine
            ? TextInputAction.newline
            : widget.textInputAction,
        // Enter/return on the keyboard moves straight into the next
        // textbox on this page (or dismisses the keyboard after the last
        // one) instead of just adding a newline or doing nothing.
        onSubmitted: widget.question.isMultiLine
            ? null
            : (_) => widget.onSubmitted(),
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
    );
  }
}

class _DropdownSelectionSheet extends StatefulWidget {
  final _Question question;
  final String value;
  final bool otherActive;
  final String otherText;
  final void Function(String value, bool otherActive, String otherText)
  onSelectionChanged;

  const _DropdownSelectionSheet({
    required this.question,
    required this.value,
    required this.otherActive,
    required this.otherText,
    required this.onSelectionChanged,
  });

  @override
  State<_DropdownSelectionSheet> createState() =>
      _DropdownSelectionSheetState();
}

class _DropdownSelectionSheetState extends State<_DropdownSelectionSheet> {
  late String _currentValue;
  late bool _otherActive;
  late TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _otherActive = widget.otherActive;
    _otherController = TextEditingController(text: widget.otherText);
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  List<String> _splitMulti(String value) {
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool _isSelected(String option) {
    if (option == 'Other') return _otherActive;
    if (widget.question.kind == _AnswerKind.singleChoice) {
      return !_otherActive && _currentValue.trim() == option;
    }
    return _splitMulti(_currentValue).contains(option);
  }

  void _selectSingle(String option) {
    if (option == 'Other') {
      setState(() {
        _otherActive = true;
      });
      widget.onSelectionChanged(
        _otherController.text.trim(),
        true,
        _otherController.text,
      );
    } else {
      setState(() {
        _otherActive = false;
        _currentValue = option;
        _otherController.clear();
      });
      widget.onSelectionChanged(option, false, '');
      Navigator.of(context).pop();
    }
  }

  void _toggleMulti(String option) {
    final options = widget.question.options ?? const [];
    final picked = _splitMulti(
      _currentValue,
    ).where((p) => options.contains(p)).toList();

    if (option == 'Other') {
      if (_otherActive) {
        _otherActive = false;
        _otherController.clear();
      } else {
        _otherActive = true;
        if (_otherController.text.trim().isNotEmpty) {
          picked.add(_otherController.text.trim());
        }
      }
    } else {
      if (picked.contains(option)) {
        picked.remove(option);
      } else {
        picked.add(option);
      }
    }

    final newVal = picked.join(', ');
    setState(() {
      _currentValue = newVal;
    });
    widget.onSelectionChanged(newVal, _otherActive, _otherController.text);
  }

  void _onOtherTextChanged(String text) {
    final trimmed = text.trim();
    if (widget.question.kind == _AnswerKind.singleChoice) {
      setState(() {
        _currentValue = trimmed;
      });
      widget.onSelectionChanged(trimmed, true, text);
      return;
    }

    final options = widget.question.options ?? const [];
    final picked = _splitMulti(
      _currentValue,
    ).where((p) => options.contains(p)).toList();
    if (trimmed.isNotEmpty) picked.add(trimmed);
    final newVal = picked.join(', ');
    setState(() {
      _currentValue = newVal;
    });
    widget.onSelectionChanged(newVal, true, text);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options ?? const [];
    final isMulti = widget.question.kind == _AnswerKind.multiChoice;
    final selectedCount = isMulti
        ? _splitMulti(_currentValue).length
        : (_currentValue.isNotEmpty ? 1 : 0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.15),
            blurRadius: 30.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            12.verticalSpace,
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            16.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.purple.withValues(alpha: 0.15),
                          AppColors.pink.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      widget.question.icon,
                      color: AppColors.purple,
                      size: 22.sp,
                    ),
                  ),
                  14.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.question.text,
                          style: AppTextStyles.headingSmall.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        4.verticalSpace,
                        Text(
                          isMulti
                              ? 'Select all options that align with you'
                              : 'Choose an option from the list',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLightGrey,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textGrey,
                      size: 22.sp,
                    ),
                    splashRadius: 20.r,
                  ),
                ],
              ),
            ),
            12.verticalSpace,
            const Divider(color: AppColors.borderVeryLight, height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                itemCount: options.length,
                separatorBuilder: (context, index) => 8.verticalSpace,
                itemBuilder: (context, idx) {
                  final option = options[idx];
                  final selected = _isSelected(option);
                  final isOther = option == 'Other';

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.purple.withValues(alpha: 0.06)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: selected
                            ? AppColors.purple
                            : AppColors.borderFaded,
                        width: selected ? 1.5.w : 1.w,
                      ),
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (widget.question.kind ==
                              _AnswerKind.singleChoice) {
                            _selectSingle(option);
                          } else {
                            _toggleMulti(option);
                          }
                        },
                        borderRadius: BorderRadius.circular(14.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22.w,
                                    height: 22.w,
                                    decoration: BoxDecoration(
                                      shape: isMulti
                                          ? BoxShape.rectangle
                                          : BoxShape.circle,
                                      borderRadius: isMulti
                                          ? BorderRadius.circular(6.r)
                                          : null,
                                      gradient: selected
                                          ? const LinearGradient(
                                              colors: AppColors.primaryGradient,
                                            )
                                          : null,
                                      color: selected ? null : AppColors.white,
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.transparent
                                            : AppColors.borderFaded,
                                        width: 1.5.w,
                                      ),
                                    ),
                                    child: selected
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 14.sp,
                                            color: AppColors.white,
                                          )
                                        : null,
                                  ),
                                  14.horizontalSpace,
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: selected
                                            ? AppColors.purple
                                            : AppColors.textDark,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isOther && selected) ...[
                                12.verticalSpace,
                                TextField(
                                  controller: _otherController,
                                  autofocus: true,
                                  onChanged: _onOtherTextChanged,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: 14.sp,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type your custom answer…',
                                    hintStyle: AppTextStyles.hint.copyWith(
                                      color: AppColors.textLightGrey,
                                      fontSize: 13.sp,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.white,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: BorderSide(
                                        color: AppColors.purple.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: BorderSide(
                                        color: AppColors.purple.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: const BorderSide(
                                        color: AppColors.purple,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isMulti || _otherActive) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowPurple.withValues(alpha: 0.4),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isMulti
                            ? (selectedCount > 0
                                  ? 'Confirm ($selectedCount selected) ✨'
                                  : 'Done')
                            : 'Done',
                        style: AppTextStyles.buttonLarge.copyWith(
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
