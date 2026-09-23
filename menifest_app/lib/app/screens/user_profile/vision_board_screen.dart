import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../models/vision_board_item.dart';
import '../../services/manifest_provider.dart';
import '../../services/user_provider.dart';

/// VisionBoardScreen displays historical manifestations and active visions.
///
/// Features:
/// - Decoupled typed data model ([VisionBoardItem])
/// - Swipe-to-dismiss gesture with confirmation guard
/// - RepaintBoundary-isolated 60 FPS loading animation
/// - Comprehensive Semantics accessibility tags
/// - Pull-to-refresh & responsive ScreenUtil sizing
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

  void _restoreAndNavigate(
    BuildContext context,
    ManifestProvider provider,
    VisionBoardItem item,
  ) {
    HapticFeedback.lightImpact();
    provider.restoreHistoricalPlan(item.rawData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Restored plan for: "${item.goalTitle}" ✨',
          style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        duration: const Duration(milliseconds: 2000),
      ),
    );
    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.home || route.isFirst,
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    ManifestProvider provider,
    VisionBoardItem item,
  ) async {
    HapticFeedback.lightImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ReleaseConfirmationDialog(title: item.goalTitle),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteHistoryItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✨ Manifestation released.'
                  : '❌ Could not delete. Please try again.',
            ),
            backgroundColor: success ? AppColors.purple : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        );
      }
      return success;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManifestProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingHistory && provider.history.isEmpty) {
          return const _VisionBoardLoadingScreen();
        }

        final items = provider.history
            .map((raw) => VisionBoardItem.fromRaw(raw))
            .toList();

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: _buildAppBar(context, items.length),
          body: items.isEmpty
              ? const _EmptyVisionBoardView()
              : RefreshIndicator(
                  color: AppColors.purple,
                  onRefresh: () async {
                    final user = context.read<UserProvider>();
                    if (user.userId != null) {
                      await context.read<ManifestProvider>().loadHistory(
                        user.userId!,
                      );
                    }
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 36.h),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => 14.verticalSpace,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: ValueKey('vision_item_${item.id}_$index'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) =>
                            _confirmDelete(context, provider, item),
                        background: const _DismissibleDeleteBackground(),
                        child: _VisionBoardCard(
                          item: item,
                          onTap: () =>
                              _restoreAndNavigate(context, provider, item),
                          onDelete: () =>
                              _confirmDelete(context, provider, item),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, int count) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      surfaceTintColor: AppColors.white,
      centerTitle: false,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: Center(
          child: Semantics(
            label: 'Go back to profile',
            button: true,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15.sp,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Vision Board',
        style: AppTextStyles.headingMedium.copyWith(
          color: AppColors.textDark,
          fontSize: 20.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        if (count > 0)
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  '$count ${count == 1 ? 'Vision' : 'Visions'}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vision Board Card
// ─────────────────────────────────────────────────────────────────────────────

class _VisionBoardCard extends StatelessWidget {
  final VisionBoardItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VisionBoardCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Vision: ${item.goalTitle}. Tap to restore plan. Swipe left to release.',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.borderLight, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.04),
                blurRadius: 16.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Meta Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.formattedDate.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        item.formattedDate,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Semantics(
                    label: 'Release manifestation "${item.goalTitle}"',
                    button: true,
                    child: InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(10.r),
                      child: Padding(
                        padding: EdgeInsets.all(6.r),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16.sp,
                          color: AppColors.textLightGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              10.verticalSpace,

              // Goal Title
              Text(
                item.goalTitle,
                style: TextStyle(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),

              // Vision Statement preview (if available)
              if (item.visionStatement.isNotEmpty) ...[
                8.verticalSpace,
                Text(
                  '“${item.visionStatement}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: AppColors.textGrey,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
              ],

              14.verticalSpace,

              // Bottom Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.actionStepsCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EEFF),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13.sp,
                            color: AppColors.purple,
                          ),
                          6.horizontalSpace,
                          Text(
                            '${item.actionStepsCount} action steps',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.purple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Restore',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      4.horizontalSpace,
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13.sp,
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe-to-Dismiss Background
// ─────────────────────────────────────────────────────────────────────────────

class _DismissibleDeleteBackground extends StatelessWidget {
  const _DismissibleDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 22.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: Colors.red.shade600,
            size: 20.sp,
          ),
          8.horizontalSpace,
          Text(
            'Release',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Release Confirmation Modal Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ReleaseConfirmationDialog extends StatelessWidget {
  final String title;

  const _ReleaseConfirmationDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(26.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.12),
              blurRadius: 32.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade600,
                size: 26.sp,
              ),
            ),
            18.verticalSpace,
            Text(
              'Release to Cosmos?',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textDark,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            10.verticalSpace,
            Text(
              'Are you sure you want to release "$title"?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
                height: 1.5,
                fontSize: 13.5.sp,
              ),
              textAlign: TextAlign.center,
            ),
            26.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textGrey,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          side: BorderSide(
                            color: AppColors.borderLight,
                            width: 1.2.w,
                          ),
                        ),
                      ),
                      child: Text(
                        'Keep',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Release',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State View
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyVisionBoardView extends StatelessWidget {
  const _EmptyVisionBoardView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.purple,
                  size: 28.sp,
                ),
              ),
            ),
            24.verticalSpace,
            Text(
              'No Manifestations Yet',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textDark,
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            10.verticalSpace,
            Text(
              'Goals you manifest on the home screen will be preserved here on your board.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13.5.sp,
                height: 1.5,
              ),
            ),
            28.verticalSpace,
            Semantics(
              label: 'Manifest a Goal button',
              button: true,
              child: SizedBox(
                height: 48.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).popUntil(
                      (route) =>
                          route.settings.name == AppRoutes.home ||
                          route.isFirst,
                    );
                  },
                  icon: Icon(
                    Icons.add_rounded,
                    size: 18.sp,
                    color: AppColors.white,
                  ),
                  label: Text(
                    'Manifest a Goal',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
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

// ─────────────────────────────────────────────────────────────────────────────
// RepaintBoundary-Optimized Loading Screen
// ─────────────────────────────────────────────────────────────────────────────

class _VisionBoardLoadingScreen extends StatelessWidget {
  const _VisionBoardLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Center(
            child: Semantics(
              label: 'Go back to profile',
              button: true,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15.sp,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // RepaintBoundary isolates the 60 FPS animation ticker from the text
            const RepaintBoundary(child: _FloatingCosmicBall()),
            22.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'Gathering Your Sacred Visions... ✨',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                ),
              ),
            ),
            10.verticalSpace,
            Text(
              'The universe is assembling your dreams\nand manifestations',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
                height: 1.5,
                fontSize: 13.sp,
              ),
            ),
            40.verticalSpace,
          ],
        ),
      ),
    );
  }
}

class _FloatingCosmicBall extends StatefulWidget {
  const _FloatingCosmicBall();

  @override
  State<_FloatingCosmicBall> createState() => _FloatingCosmicBallState();
}

class _FloatingCosmicBallState extends State<_FloatingCosmicBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _sparkle(double dx, double dy, double phase) {
    final t = (phase % 1.0);
    final wave = 1.0 - (t - 0.5).abs() * 2;
    final opacity = (0.35 + 0.65 * wave).clamp(0.2, 1.0);
    final scale = 0.85 + 0.35 * wave;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Text(
            '✦',
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFFAB6FF5)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final floatOffset = -10.0 * (1.0 - (t - 0.5).abs() * 2);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _sparkle(-46, -18, (t + 0.1) % 1.0),
            _sparkle(44, -26, (t + 0.4) % 1.0),
            _sparkle(-34, 30, (t + 0.7) % 1.0),
            _sparkle(40, 26, (t + 0.25) % 1.0),
            Transform.translate(offset: Offset(0, floatOffset), child: child),
          ],
        );
      },
      child: Text('🔮', style: TextStyle(fontSize: 64.sp)),
    );
  }
}
