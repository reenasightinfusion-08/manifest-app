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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _saving ? null : () => Navigator.pop(context),
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: _error
                    ? AppColors.errorRed.withValues(alpha: 0.1)
                    : AppColors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _error ? Icons.lock_open_rounded : Icons.key_rounded,
                size: 60.sp,
                color: _error ? AppColors.errorRed : AppColors.blue,
              ),
            ),
            32.verticalSpace,
            Text(
              _title,
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            12.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _error ? AppColors.errorRed : AppColors.textGrey,
                ),
              ),
            ),
            40.verticalSpace,
            GestureDetector(
              onTap: _saving ? null : () => _focusNode.requestFocus(),
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
                            color: _error
                                ? AppColors.errorRed
                                : (filled
                                    ? AppColors.blue
                                    : AppColors.borderVeryLight),
                            width: (filled || _error) ? 2.w : 1.w,
                          ),
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.blue.withValues(alpha: 0.1),
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
                              color:
                                  _error ? AppColors.errorRed : AppColors.blue,
                            ),
                          ),
                        ),
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
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (mounted) _onCodeEntered(val);
                    });
                  }
                },
                decoration: const InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                ),
              ),
            ),
            24.verticalSpace,
            if (_saving)
              SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.blue,
                ),
              ),
            const Spacer(flex: 2),
            _StepDots(step: _step),
            40.verticalSpace,
          ],
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
          width: active ? 20.w : 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: active ? AppColors.blue : AppColors.stepDotInactive,
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      }).toList(),
    );
  }
}
