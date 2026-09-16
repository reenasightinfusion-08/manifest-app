import 'package:flutter/material.dart';
import '../../core/common/core.dart';

class SuggestionCard extends StatelessWidget {
  final int index;
  final String text;

  const SuggestionCard({super.key, required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderVeryLight, width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 15.r,
            spreadRadius: 2.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTextStyles.label.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14.sp,
              ),
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                height: 1.6,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
