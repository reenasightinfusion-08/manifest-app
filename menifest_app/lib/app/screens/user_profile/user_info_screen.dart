import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';
import '../../widgets/primary_text_field.dart';
import '../security/verify_email_screen.dart';

/// Account creation only — name, email, password. Deliberately kept to a
/// single step: this used to be step 0 of a 4-step flow that also asked
/// the personal/family/professional profiling questions before the
/// account even existed, so someone who mistyped their email (or fat-
/// fingered someone else's) could sink several minutes into that survey
/// and then lose all of it to "email already exists" or an unverifiable
/// inbox at the very end. Now: create the account, verify the email
/// (VerifyEmailScreen), and only then ask the profiling questions
/// (ProfileSetupScreen) — see UserProvider.syncToApi for the account
/// creation call.
class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    final provider = context.read<UserProvider>();
    // 'Alex Manifestor' is UserProvider's placeholder default, not a real
    // saved name — don't prefill the field with it.
    _nameController.text = provider.name == 'Alex Manifestor'
        ? ''
        : provider.name;
    _emailController.text = provider.email ?? '';
    _passwordController.text = provider.password ?? '';

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
  }

  Future<void> _createAccount(
    BuildContext context,
    UserProvider provider,
  ) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final nameOk = name.isNotEmpty;
    final emailOk = email.contains('@') && email.contains('.');
    final passwordOk = password.length >= 6;

    if (!nameOk || !emailOk || !passwordOk) {
      setState(() => _showErrors = true);
      _showError(
        'The universe needs your name, email, and a 6+ character password ✨',
      );
      return;
    }

    provider.updateName(name);
    provider.setEmail(email);
    provider.setPassword(password);

    final emailAvailable = await provider.checkEmailAvailability();
    if (!emailAvailable) {
      if (!context.mounted) return;
      setState(() => _showErrors = true);
      _showError(provider.emailCheckError ?? "That email doesn't look right.");
      return;
    }

    try {
      await provider.syncToApi();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            userId: provider.userId!,
            email: provider.email ?? '',
            finishesSignup: true,
          ),
          settings: const RouteSettings(name: AppRoutes.verifyEmail),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Almost there — check your email to verify your account ✨',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(
        e
            .toString()
            .replaceAll('Exception: Server returned error: ', '')
            .replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final bool emailError =
            _showErrors &&
            (!(_emailController.text.contains('@') &&
                    _emailController.text.contains('.')) ||
                provider.emailCheckError != null);
        final bool passwordError =
            _showErrors && _passwordController.text.length < 6;
        final bool nameError =
            _showErrors && _nameController.text.trim().isEmpty;

        void handleBack() {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
          }
        }

        if (isTablet) {
          return _buildTabletLayout(
            context: context,
            provider: provider,
            handleBack: handleBack,
            nameError: nameError,
            emailError: emailError,
            passwordError: passwordError,
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            handleBack();
          },
          child: Scaffold(
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
                            GestureDetector(
                              onTap: handleBack,
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
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24.w,
                                20.h,
                                24.w,
                                40.h,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: AppColors.primaryGradient,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.glowPurple
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 12.r,
                                              spreadRadius: -2.r,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.lock_person_rounded,
                                          color: AppColors.white,
                                          size: 26.sp,
                                        ),
                                      ),
                                      14.horizontalSpace,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'CREATE YOUR ACCOUNT',
                                              style: AppTextStyles.label
                                                  .copyWith(
                                                    color: AppColors.purple,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 2,
                                                    fontSize: 12.sp,
                                                  ),
                                            ),
                                            Text(
                                              'Let\'s Get\nStarted',
                                              style: AppTextStyles.headingMedium
                                                  .copyWith(
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
                                  24.verticalSpace,
                                  Text(
                                    'Double-check your email — we\'ll send a verification link there, and you\'ll finish setting up your profile after confirming it.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textGrey,
                                      height: 1.6,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  32.verticalSpace,
                                  PrimaryTextField(
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _emailFocusNode.requestFocus(),
                                    hintText: 'Your Name',
                                    prefixIcon: Icons.badge_outlined,
                                    hasError: nameError,
                                    errorColor: AppColors.pink,
                                  ),
                                  16.verticalSpace,
                                  PrimaryTextField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        _passwordFocusNode.requestFocus(),
                                    onChanged: (_) {
                                      if (context
                                              .read<UserProvider>()
                                              .emailCheckError !=
                                          null) {
                                        context.read<UserProvider>().setEmail(
                                          _emailController.text.trim(),
                                        );
                                      }
                                    },
                                    hintText: 'Your Email',
                                    prefixIcon: Icons.alternate_email_rounded,
                                    hasError: emailError,
                                    errorColor: AppColors.pink,
                                  ),
                                  if (provider.emailCheckError != null) ...[
                                    8.verticalSpace,
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 4.w),
                                        child: Text(
                                          provider.emailCheckError!,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.pink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  16.verticalSpace,
                                  PrimaryTextField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    hintText: 'Password (min. 6 characters)',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    hasError: passwordError,
                                    errorColor: AppColors.pink,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                          onTap: () => _createAccount(context, provider),
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
                              child:
                                  (provider.isLoading || provider.checkingEmail)
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: const CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
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
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout({
    required BuildContext context,
    required UserProvider provider,
    required VoidCallback handleBack,
    required bool nameError,
    required bool emailError,
    required bool passwordError,
  }) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                  constraints: const BoxConstraints(maxWidth: 880.0),
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
                          offset: const Offset(0, 8.0),
                        ),
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.03),
                          blurRadius: 10.0,
                          offset: const Offset(0, 2.0),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40.0, 24.0, 40.0, 24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: handleBack,
                                  child: Container(
                                    width: 42.0,
                                    height: 42.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.white,
                                      border: Border.all(
                                        color: AppColors.borderFaded,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 8.0,
                                          offset: const Offset(0, 2.0),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: AppColors.textDark,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      20.0,
                                      0,
                                      24.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(
                                                14.0,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors:
                                                      AppColors.primaryGradient,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.glowPurple
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 12.0,
                                                    spreadRadius: -2.0,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.lock_person_rounded,
                                                color: AppColors.white,
                                                size: 28.0,
                                              ),
                                            ),
                                            const SizedBox(width: 16.0),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'CREATE YOUR ACCOUNT',
                                                    style: AppTextStyles.label
                                                        .copyWith(
                                                          color:
                                                              AppColors.purple,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 2,
                                                          fontSize: 13.0,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2.0),
                                                  Text(
                                                    'Let\'s Get Started',
                                                    style: AppTextStyles
                                                        .headingMedium
                                                        .copyWith(
                                                          fontSize: 26.0,
                                                          height: 1.15,
                                                          color:
                                                              AppColors.textDark,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20.0),
                                        Text(
                                          'Double-check your email — we\'ll send a verification link there, and you\'ll finish setting up your profile after confirming it.',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.textGrey,
                                                height: 1.6,
                                                fontSize: 15.0,
                                              ),
                                        ),
                                        const SizedBox(height: 28.0),
                                        PrimaryTextField(
                                          controller: _nameController,
                                          focusNode: _nameFocusNode,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) => _emailFocusNode
                                              .requestFocus(),
                                          hintText: 'Your Name',
                                          prefixIcon: Icons.badge_outlined,
                                          hasError: nameError,
                                          errorColor: AppColors.pink,
                                        ),
                                        const SizedBox(height: 16.0),
                                        PrimaryTextField(
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          onSubmitted: (_) => _passwordFocusNode
                                              .requestFocus(),
                                          onChanged: (_) {
                                            if (context
                                                    .read<UserProvider>()
                                                    .emailCheckError !=
                                                null) {
                                              context
                                                  .read<UserProvider>()
                                                  .setEmail(
                                                    _emailController.text
                                                        .trim(),
                                                  );
                                            }
                                          },
                                          hintText: 'Your Email',
                                          prefixIcon:
                                              Icons.alternate_email_rounded,
                                          hasError: emailError,
                                          errorColor: AppColors.pink,
                                        ),
                                        if (provider.emailCheckError !=
                                            null) ...[
                                          const SizedBox(height: 8.0),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 4.0,
                                              ),
                                              child: Text(
                                                provider.emailCheckError!,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color: AppColors.pink,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 16.0),
                                        PrimaryTextField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocusNode,
                                          obscureText: true,
                                          textInputAction: TextInputAction.done,
                                          hintText:
                                              'Password (min. 6 characters)',
                                          prefixIcon:
                                              Icons.lock_outline_rounded,
                                          hasError: passwordError,
                                          errorColor: AppColors.pink,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                0,
                                12.0,
                                0,
                                4.0,
                              ),
                              child: GestureDetector(
                                onTap: () => _createAccount(context, provider),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: double.infinity,
                                  height: 56.0,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: AppColors.primaryGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.glowPink,
                                        blurRadius: 20.0,
                                        spreadRadius: -4.0,
                                        offset: const Offset(0, 8.0),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child:
                                        (provider.isLoading ||
                                            provider.checkingEmail)
                                        ? const SizedBox(
                                            width: 24.0,
                                            height: 24.0,
                                            child: CircularProgressIndicator(
                                              color: AppColors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Create Account',
                                            style: AppTextStyles.buttonLarge
                                                .copyWith(fontSize: 16.5),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
