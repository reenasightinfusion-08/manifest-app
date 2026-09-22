import 'package:flutter/material.dart';
import '../../core/common/core.dart';

/// Full-width solid-purple CTA ("Unlock", "Continue", "I've Verified…") used
/// across the security/auth screens. [PrimaryButton] covers the gradient
/// home-screen CTA; this covers the flat purple one, so both no longer get
/// re-declared per screen via `ElevatedButton.styleFrom`.
class SolidButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SolidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.buttonLarge.copyWith(color: AppColors.white),
              ),
      ),
    );
  }
}
