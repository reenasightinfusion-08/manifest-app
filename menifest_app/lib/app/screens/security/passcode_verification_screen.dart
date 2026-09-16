import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';

class PasscodeVerificationScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const PasscodeVerificationScreen({super.key, required this.onAuthenticated});

  @override
  State<PasscodeVerificationScreen> createState() =>
      _PasscodeVerificationScreenState();
}

class _PasscodeVerificationScreenState
    extends State<PasscodeVerificationScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _verify(String enteredCode) {
    final provider = context.read<UserProvider>();
    if (provider.passcode == enteredCode) {
      provider.setSecurityError(false);
      widget.onAuthenticated();
    } else {
      provider.setSecurityError(true);
      _controller.clear();
      HapticFeedback.heavyImpact();

      // Reset error after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) provider.setSecurityError(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: provider.securityError
                      ? AppColors.errorRed.withValues(alpha: 0.1)
                      : AppColors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  provider.securityError
                      ? Icons.lock_open_rounded
                      : Icons.lock_person_rounded,
                  size: 60.sp,
                  color: provider.securityError ? AppColors.errorRed : AppColors.purple,
                ),
              ),
              32.verticalSpace,
              Text(
                'Security Required',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              12.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  provider.securityError
                      ? 'Incorrect passcode. The cosmos remains closed. ðŸŒŒ'
                      : 'Enter your 4-digit cosmic key to access your private profile.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: provider.securityError
                        ? AppColors.errorRed
                        : AppColors.textGrey,
                  ),
                ),
              ),
              40.verticalSpace,
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final String enteredText = value.text;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final bool filled = enteredText.length > index;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: 10.w),
                          width: 50.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: provider.securityError
                                  ? AppColors.errorRed
                                  : (filled
                                      ? AppColors.purple
                                      : AppColors.borderVeryLight),
                              width: (filled || provider.securityError) ? 2.w : 1.w,
                            ),
                            boxShadow: filled
                                ? [
                                    BoxShadow(
                                      color: AppColors.purple.withValues(alpha: 0.1),
                                      blurRadius: 10.r,
                                      spreadRadius: 2.r,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              filled ? 'â—' : '',
                              style: TextStyle(
                                fontSize: 24.sp,
                                color: provider.securityError
                                    ? AppColors.errorRed
                                    : AppColors.purple,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              // Hidden TextField
              SizedBox(
                height: 0,
                width: 0,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (val) {
                    if (val.length == 4) {
                      _verify(val);
                    }
                  },
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              Text(
                'PROTECTED BY COSMIC ENCRYPTION',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textLightGrey,
                  fontSize: 10.sp,
                  letterSpacing: 2,
                ),
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

