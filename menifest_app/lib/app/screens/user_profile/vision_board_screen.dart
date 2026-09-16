import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../services/manifest_provider.dart';
import '../../services/user_provider.dart';
import '../../widgets/primary_button.dart';

class VisionBoardScreen extends StatefulWidget {
  const VisionBoardScreen({super.key});

  @override
  State<VisionBoardScreen> createState() => _VisionBoardScreenState();
}

class _VisionBoardScreenState extends State<VisionBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      if (user.userId != null) {
        context.read<ManifestProvider>().loadHistory(user.userId!);
      }
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ManifestProvider provider,
    dynamic item,
  ) async {
    final id = item['id'].toString();
    final title = item['goal_title'] ?? 'this manifestation';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.r),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.15),
                blurRadius: 40.r,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45.r,
                height: 45.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.pink.withValues(alpha: 0.15),
                      AppColors.purple.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_delete_rounded,
                  color: AppColors.pink,
                  size: 25.sp,
                ),
              ),
              24.verticalSpace,
              Text(
                'Release to Cosmos?',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textDark,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              16.verticalSpace,
              Text(
                'Are you sure you want to release "$title"?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                  height: 1.6,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              32.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 64.h,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                            side: BorderSide(
                              color: AppColors.borderLight,
                              width: 1.5.w,
                            ),
                          ),
                        ),
                        child: Text(
                          'Keep',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  16.horizontalSpace,
                  Expanded(
                    child: PrimaryButton(
                      label: 'Release',
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteHistoryItem(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✨ Manifestation released to the cosmos.'
                  : '❌ Failed to delete. Please try again.',
            ),
            backgroundColor: success ? AppColors.purple : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cosmic Vision Board',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Consumer<ManifestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            );
          }

          if (provider.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 64.sp,
                    color: AppColors.textLightGrey,
                  ),
                  16.verticalSpace,
                  Text(
                    'No manifestations yet.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(24.r),
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final item = provider.history[index];
              final dateStr = item['created_at'] != null
                  ? DateTime.parse(
                      item['created_at'].toString(),
                    ).toLocal().toString().split(' ')[0]
                  : 'Unknown date';

              return Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                // ── Swipe RIGHT to reveal delete background ──
                child: Dismissible(
                  key: ValueKey(item['id']),
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (_) async {
                    await _confirmDelete(context, provider, item);
                    // We handle deletion inside _confirmDelete → never auto-dismiss
                    return false;
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 24.w),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.red,
                          size: 28.sp,
                        ),
                        12.horizontalSpace,
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      provider.restoreHistoricalPlan(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Restored manifesto for: ${item['goal_title']} ✨',
                          ),
                          backgroundColor: AppColors.purple,
                        ),
                      );
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(24.r),
                    child: Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            blurRadius: 15.r,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  dateStr,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.white,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.white,
                                size: 16,
                              ),
                            ],
                          ),
                          16.verticalSpace,
                          Text(
                            item['goal_title'] ?? 'My Goal',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          8.verticalSpace,
                          Row(
                            children: [
                              Icon(
                                Icons.swipe_right_alt_rounded,
                                color: AppColors.white.withValues(alpha: 0.6),
                                size: 14.sp,
                              ),
                              6.horizontalSpace,
                              Text(
                                'Swipe right to delete  •  Tap to restore',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.white.withValues(alpha: 0.7),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
