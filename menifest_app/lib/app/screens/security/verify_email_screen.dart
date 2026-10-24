import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/api_service.dart';
import '../../services/user_provider.dart';
import '../../widgets/solid_button.dart';
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
    final isTablet = context.isTablet;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12.0 : 12.r),
        ),
        margin: EdgeInsets.all(isTablet ? 16.0 : 16.r),
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
    debugPrint('[VerifyEmailScreen] User clicked "Resend Email" for: ${widget.email}');
    setState(() => _resending = true);
    try {
      final message = await _apiService.resendVerification(widget.email);
      debugPrint('[VerifyEmailScreen] Resend result message: "$message"');
      _toast(message);
    } catch (e) {
      debugPrint('❌ [VerifyEmailScreen] Error in _resend: $e');
      _toast('Failed to resend: $e');
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
    if (context.isTablet) {
      return _buildTabletLayout(context);
    }

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
                            SolidButton(
                              label: "I've Verified — Continue",
                              onPressed: _checkVerified,
                              isLoading: _checking,
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

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580.0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(36.0, 24.0, 36.0, 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!widget.finishesSignup)
                            Align(
                              alignment: Alignment.topLeft,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 38.0,
                                  height: 38.0,
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
                                    Icons.close_rounded,
                                    color: AppColors.textDark,
                                    size: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8.0),
                          Container(
                            width: 90.0,
                            height: 90.0,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.primaryGradient,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.glowPurple.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 24.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_rounded,
                              size: 42.0,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 28.0),
                          Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headingLarge.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 26.0,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            "We sent a verification link to",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textGrey,
                              height: 1.5,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            widget.email,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            'Tap the link in that email, then come back here and tap Continue.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textGrey,
                              height: 1.5,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 32.0),
                          SolidButton(
                            label: "I've Verified — Continue",
                            onPressed: _checkVerified,
                            isLoading: _checking,
                          ),
                          const SizedBox(height: 16.0),
                          TextButton(
                            onPressed: _resending ? null : _resend,
                            child: _resending
                                ? const SizedBox(
                                    width: 18.0,
                                    height: 18.0,
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
                                      fontSize: 14.5,
                                    ),
                                  ),
                          ),
                          if (widget.finishesSignup) ...[
                            const SizedBox(height: 8.0),
                            TextButton(
                              onPressed: () => _startOver(context),
                              child: Text(
                                'Wrong email? Start over',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textGrey,
                                  fontSize: 13.5,
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
            ),
          ],
        ),
      ),
    );
  }
}
