import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/user_provider.dart';

enum _Step { current, create, confirm }

class ChangePassphraseScreen extends StatefulWidget {
  const ChangePassphraseScreen({super.key});

  @override
  State<ChangePassphraseScreen> createState() =>
      _ChangePassphraseScreenState();
}

class _ChangePassphraseScreenState extends State<ChangePassphraseScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  late _Step _step;
  String? _newCode;
  bool _error = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // If no passphrase exists yet, skip straight to creating one.
    final hasExisting =
        (context.read<UserProvider>().passcode ?? '').length == 4;
    _step = hasExisting ? _Step.current : _Step.create;
    _requestFocusSoon();
  }

  void _requestFocusSoon() {
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

  void _onCodeEntered(String code) {
    final provider = context.read<UserProvider>();

    switch (_step) {
      case _Step.current:
        if (code == provider.passcode) {
          setState(() {
            _error = false;
            _step = _Step.create;
          });
          _controller.clear();
        } else {
          _fail();
        }
        break;

      case _Step.create:
        _newCode = code;
        setState(() {
          _error = false;
          _step = _Step.confirm;
        });
        _controller.clear();
        break;

      case _Step.confirm:
        if (code == _newCode) {
          _savePassphrase(code);
        } else {
          _newCode = null;
          setState(() {
            _error = false;
            _step = _Step.create;
          });
          _controller.clear();
          HapticFeedback.heavyImpact();
          _showToast("Passphrases didn't match. Let's try again.");
        }
        break;
    }
  }

  void _fail() {
    setState(() => _error = true);
    _controller.clear();
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _error = false);
    });
  }

  Future<void> _savePassphrase(String code) async {
    setState(() => _saving = true);
    final provider = context.read<UserProvider>();
    final previousCode = provider.passcode;
    provider.setPasscode(code);

    try {
      await provider.syncToApi();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      _showToast('Passphrase updated ✨');
    } catch (e) {
      // Roll back on failure so local state stays consistent with the server.
      provider.setPasscode(previousCode);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _step = _Step.create;
        _newCode = null;
      });
      _controller.clear();
      _showToast('Could not update passphrase. Check your connection.');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  String get _title {
    switch (_step) {
      case _Step.current:
        return 'Confirm It\'s You';
      case _Step.create:
        return 'New Passphrase';
      case _Step.confirm:
        return 'Confirm Passphrase';
    }
  }

  String get _subtitle {
    if (_error) return 'Incorrect passphrase. Try again. \u{1F30C}';
    switch (_step) {
      case _Step.current:
        return 'Enter your current 4-digit cosmic key to continue.';
      case _Step.create:
        return 'Choose a new 4-digit passphrase to protect your profile.';
      case _Step.confirm:
        return 'Enter your new passphrase one more time to confirm.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVeryLight,
      body: Stack(
        children: [
          // ── Decorative glow blobs, matching the onboarding security screen ──
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textDark,
                    ),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: Column(
                        children: [
                          16.verticalSpace,
                          _BadgeIcon(error: _error),
                          32.verticalSpace,
                          Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headingLarge.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 26.sp,
                            ),
                          ),
                          12.verticalSpace,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Text(
                              _subtitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _error
                                    ? AppColors.errorRed
                                    : AppColors.textGrey,
                                height: 1.5,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          40.verticalSpace,
                          GestureDetector(
                            onTap: _saving
                                ? null
                                : () => _focusNode.requestFocus(),
                            behavior: HitTestBehavior.opaque,
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _controller,
                              builder: (context, value, _) {
                                final String enteredText = value.text;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(4, (index) {
                                    final bool filled =
                                        enteredText.length > index;
                                    return _PinDot(
                                      filled: filled,
                                      error: _error,
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                          // Hidden TextField driving the PIN input
                          SizedBox(
                            height: 0,
                            width: 0,
                            child: TextField(
                              focusNode: _focusNode,
                              controller: _controller,
                              enabled: !_saving,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              onChanged: (val) {
                                if (val.length == 4) {
                                  // Let the 4th dot render before clearing/advancing.
                                  Future.delayed(
                                    const Duration(milliseconds: 150),
                                    () {
                                      if (mounted) _onCodeEntered(val);
                                    },
                                  );
                                }
                              },
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          28.verticalSpace,
                          if (_saving)
                            SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.purple,
                              ),
                            )
                          else
                            _StepDots(step: _step),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30.w, 0, 30.w, 24.h),
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
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final bool error;

  const _BadgeIcon({required this.error});

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
            child: Icon(
              error ? Icons.lock_open_rounded : Icons.key_rounded,
              size: 42.sp,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final bool filled;
  final bool error;

  const _PinDot({required this.filled, required this.error});

  @override
  Widget build(BuildContext context) {
    final Color activeColor = error ? AppColors.errorRed : AppColors.purple;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      width: 54.w,
      height: 62.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: filled ? activeColor : AppColors.borderVeryLight,
          width: (filled || error) ? 2.w : 1.w,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.1),
                  blurRadius: 10.r,
                  spreadRadius: 2.r,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          Icons.circle,
          size: 10.sp,
          color: filled ? activeColor : AppColors.transparent,
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final _Step step;

  const _StepDots({required this.step});

  @override
  Widget build(BuildContext context) {
    final steps = _Step.values;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.map((s) {
        final active = s == step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: active ? 22.w : 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: AppColors.primaryGradient)
                : null,
            color: active ? null : AppColors.stepDotInactive,
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      }).toList(),
    );
  }
}
