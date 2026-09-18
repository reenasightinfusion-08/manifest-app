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

  void _verify() {
    final provider = context.read<UserProvider>();
    if (_controller.text.isEmpty) return;
    if (provider.password == _controller.text) {
      provider.setSecurityError(false);
      widget.onAuthenticated();
    } else {
      provider.setSecurityError(true);
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
                      ? 'Incorrect password. The cosmos remains closed. \u{1F30C}'
                      : 'Enter your password to access your private profile.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: provider.securityError
                        ? AppColors.errorRed
                        : AppColors.textGrey,
                  ),
                ),
              ),
              32.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: TextField(
                  focusNode: _focusNode,
                  controller: _controller,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: AppColors.surfaceVeryLight,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(
                        color: provider.securityError
                            ? AppColors.errorRed
                            : AppColors.transparent,
                        width: 1.5.w,
                      ),
                    ),
                  ),
                ),
              ),
              20.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Unlock',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppColors.white,
                      ),
                    ),
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
