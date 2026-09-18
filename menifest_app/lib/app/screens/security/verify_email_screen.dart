import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/api_service.dart';
import '../../services/user_provider.dart';
import '../on_boarding_screen/profile_setup_screen.dart';

/// Shown right after signup (finishesSignup: true, the account already
/// exists and is logged in — just unverified) and after a login attempt
/// that was blocked because the email link was never tapped
/// (finishesSignup: false — that attempt never set provider state, so this
/// screen works off the id/email the backend handed back instead).
class VerifyEmailScreen extends StatefulWidget {
  final String userId;
  final String email;
  final bool finishesSignup;

  const VerifyEmailScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.finishesSignup,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final ApiService _apiService = ApiService();
  bool _checking = false;
  bool _resending = false;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      if (widget.finishesSignup) {
        final verified = await context.read<UserProvider>().refreshEmailVerified();
        if (!mounted) return;
        if (verified) {
          // Verified — now (and only now) ask the profiling questions,
          // instead of Home directly.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ProfileSetupScreen(),
            ),
          );
        } else {
          _toast("Not verified yet — check your inbox (and spam folder).");
        }
      } else {
        final status = await _apiService.checkVerificationStatus(widget.userId);
        if (!mounted) return;
        if (status.verified) {
          _toast('Verified! Please log in again.');
          Navigator.of(context).pop();
        } else {
          _toast("Not verified yet — check your inbox (and spam folder).");
        }
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final message = await _apiService.resendVerification(widget.email);
      _toast(message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  /// For the signup path only: the account this screen is waiting on was
  /// just created with whatever email was typed a moment ago, and if that
  /// was wrong (typo, someone else's address, doesn't exist) there was
  /// previously no way out except abandoning the app — the account stays
  /// logged-in-but-unverified locally, so relaunching just lands back
  /// here forever. This clears that local state and sends them back to
  /// create the account again with the right email. The stray unverified
  /// row is left in the database (harmless — it can never log in, and
  /// deleting it isn't safe to do unprompted from here), but nothing
  /// blocks trying again with the same email later since verification
  /// tokens are per-row, not per-email.
  Future<void> _startOver(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Start Over?',
          style: AppTextStyles.headingMedium.copyWith(fontSize: 18.sp),
        ),
        content: Text(
          "You'll go back to account creation so you can enter the correct email.",
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'START OVER',
              style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await context.read<UserProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.welcome,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVeryLight,
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
                    AppColors.purple.withValues(alpha: 0.08),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (!widget.finishesSignup)
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100.w,
                              height: 100.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.primaryGradient,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.glowPurple.withValues(alpha: 0.3),
                                    blurRadius: 24.r,
                                    spreadRadius: 2.r,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.mark_email_unread_rounded,
                                size: 44.sp,
                                color: AppColors.white,
                              ),
                            ),
                            32.verticalSpace,
                            Text(
                              'Verify Your Email',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headingLarge.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 26.sp,
                              ),
                            ),
                            12.verticalSpace,
                            Text(
                              "We sent a verification link to",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textGrey,
                                height: 1.5,
                                fontSize: 14.sp,
                              ),
                            ),
                            6.verticalSpace,
                            Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                              ),
                            ),
                            12.verticalSpace,
                            Text(
                              'Tap the link in that email, then come back here and tap Continue.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textGrey,
                                height: 1.5,
                                fontSize: 14.sp,
                              ),
                            ),
                            36.verticalSpace,
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _checking ? null : _checkVerified,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                ),
                                child: _checking
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: const CircularProgressIndicator(
                                          color: AppColors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "I've Verified — Continue",
                                        style: AppTextStyles.buttonLarge.copyWith(
                                          color: AppColors.white,
                                        ),
                                      ),
                              ),
                            ),
                            16.verticalSpace,
                            TextButton(
                              onPressed: _resending ? null : _resend,
                              child: _resending
                                  ? SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: CircularProgressIndicator(
                                        color: AppColors.purple,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Resend Email',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            if (widget.finishesSignup) ...[
                              8.verticalSpace,
                              TextButton(
                                onPressed: () => _startOver(context),
                                child: Text(
                                  'Wrong email? Start over',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textGrey,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
  }
}
