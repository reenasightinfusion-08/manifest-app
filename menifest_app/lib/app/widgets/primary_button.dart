import 'package:flutter/material.dart';
import '../../core/common/core.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: AppColors.glowPink.withValues(alpha: isLoading ? 0.2 : 0.4),
            blurRadius: 16.r,
            spreadRadius: -4.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(20.r),
          splashColor: AppColors.white.withValues(alpha: 0.2),
          highlightColor: AppColors.white.withValues(alpha: 0.1),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
