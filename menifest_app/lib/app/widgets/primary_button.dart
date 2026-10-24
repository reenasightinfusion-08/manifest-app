import 'package:flutter/material.dart';
import '../../core/common/core.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final double? fontSize;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final isTablet = context.isTablet;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.45,
      child: Container(
        width: double.infinity,
        height: height ?? (isTablet ? 56.0 : 64.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.glowPink.withValues(
                      alpha: isLoading ? 0.2 : 0.4,
                    ),
                    blurRadius: isTablet ? 16.0 : 16.r,
                    spreadRadius: isTablet ? -4.0 : -4.r,
                    offset: Offset(0, isTablet ? 8.0 : 8.h),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(isTablet ? 20.0 : 20.r),
            splashColor: AppColors.white.withValues(alpha: 0.2),
            highlightColor: AppColors.white.withValues(alpha: 0.1),
            child: Center(
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: isTablet ? 22.0 : 20.r,
                          child: const CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        if (label.isNotEmpty) ...[
                          SizedBox(width: isTablet ? 12.0 : 10.w),
                          Flexible(
                            child: Text(
                              label,
                              style: AppTextStyles.buttonLarge.copyWith(
                                color: AppColors.white,
                                fontSize: fontSize ?? (isTablet ? 16.0 : 16.sp),
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      label,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppColors.white,
                        fontSize: fontSize ?? (isTablet ? 16.0 : 16.sp),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
