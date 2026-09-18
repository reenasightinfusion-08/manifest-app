import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/biometric_service.dart';
import '../../services/user_provider.dart';

/// The cold-start gate every returning, logged-in user passes through.
/// Everyone who reaches here already has a password from onboarding
/// (Step 4, "Your Login Credentials") — this screen is what finally makes
/// that password do something. Biometrics, when the user has turned the
/// toggle on in Privacy Settings and the device actually supports it, are
/// offered as a faster path on top; the password always remains available.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  bool _error = false;
  bool _checkingBiometric = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final provider = context.read<UserProvider>();

    // No password on this account at all (shouldn't happen for a normal
    // signup, but fail open rather than locking someone out forever).
    if ((provider.password ?? '').isEmpty) {
      _unlock();
      return;
    }

    if (provider.biometricLock) {
      _biometricAvailable = await BiometricService.isAvailable();
      if (mounted) setState(() {});
      if (_biometricAvailable) {
        // Firing the native prompt on the very first frame can race the
        // Activity transition on some OEM builds — the BiometricPrompt
        // silently never attaches, and the caller just sits on the
        // timeout. A short beat lets the Activity settle first.
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        _tryBiometric();
        return;
      }
    }

    _requestFocusSoon();
  }

  void _requestFocusSoon() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _tryBiometric() async {
    setState(() => _checkingBiometric = true);
    final result = await BiometricService.authenticate(
      reason: 'Unlock your manifestation profile',
    );
    if (!mounted) return;
    setState(() => _checkingBiometric = false);

    if (result.success) {
      _unlock();
    } else {
      // Cancelled, failed, or lockout — fall back to the password field, but
      // say why so a lockout doesn't look like the button is just broken.
      if (result.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _requestFocusSoon();
    }
  }

  void _unlock() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  void _submitPassword() {
    final provider = context.read<UserProvider>();
    if (_controller.text.isEmpty) return;
    if (_controller.text == provider.password) {
      HapticFeedback.mediumImpact();
      _unlock();
    } else {
      setState(() => _error = true);
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _error = false);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final biometricLock = context.watch<UserProvider>().biometricLock;

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
                    (_error ? AppColors.errorRed : AppColors.purple)
                        .withValues(alpha: 0.08),
                    AppColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80.h,
            left: -60.w,
            child: Container(
              width: 260.w,
              height: 260.w,
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
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LockBadge(error: _error, busy: _checkingBiometric),
                      32.verticalSpace,
                      Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 26.sp,
                        ),
                      ),
                      12.verticalSpace,
                      Text(
                        _error
                            ? 'Incorrect password. Try again. \u{1F30C}'
                            : 'Enter your password to continue.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _error
                              ? AppColors.errorRed
                              : AppColors.textGrey,
                          height: 1.5,
                          fontSize: 14.sp,
                        ),
                      ),
                      32.verticalSpace,
                      TextField(
                        focusNode: _focusNode,
                        controller: _controller,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitPassword(),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: AppColors.white,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: _error
                                  ? AppColors.errorRed
                                  : AppColors.transparent,
                              width: 1.5.w,
                            ),
                          ),
                        ),
                      ),
                      20.verticalSpace,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitPassword,
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
                      if (biometricLock && _biometricAvailable) ...[
                        20.verticalSpace,
                        TextButton.icon(
                          onPressed: _checkingBiometric ? null : _tryBiometric,
                          icon: Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.purple,
                            size: 22.sp,
                          ),
                          label: Text(
                            'Use Biometric Instead',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.purple,
                              fontWeight: FontWeight.bold,
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.h,
            child: Text(
              'PROTECTED BY COSMIC ENCRYPTION',
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textLightGrey,
                fontSize: 10.sp,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  final bool error;
  final bool busy;

  const _LockBadge({required this.error, required this.busy});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120.w,
      height: 120.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (error ? AppColors.errorRed : AppColors.purple)
                      .withValues(alpha: 0.12),
                  blurRadius: 36.r,
                  spreadRadius: 8.r,
                ),
              ],
            ),
          ),
          ...List.generate(2, (i) {
            return Container(
              margin: EdgeInsets.all((10.0 * (i + 1)).r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (error ? AppColors.errorRed : AppColors.purple)
                      .withValues(alpha: 0.08 + (0.1 * i)),
                  width: 1.w,
                ),
              ),
            );
          }),
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: error
                    ? [AppColors.errorRed, AppColors.errorRed.withValues(alpha: 0.7)]
                    : AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: (error ? AppColors.glowPurple : AppColors.glowPink)
                      .withValues(alpha: 0.3),
                  blurRadius: 16.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: busy
                ? SizedBox(
                    width: 28.sp,
                    height: 28.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : Icon(
                    error ? Icons.lock_open_rounded : Icons.lock_rounded,
                    size: 42.sp,
                    color: AppColors.white,
                  ),
          ),
        ],
      ),
    );
  }
}
