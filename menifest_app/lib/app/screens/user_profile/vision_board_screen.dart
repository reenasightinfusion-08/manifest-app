import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/common/core.dart';
import '../../models/vision_board_item.dart';
import '../../services/manifest_provider.dart';
import '../../services/user_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import '../../ads/banner_ad_widget.dart';
import '../../ads/native_ad_widget.dart';

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
    final isTablet = context.isTablet;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Restored plan for: "${item.goalTitle}" ✨',
          style: TextStyle(
            fontSize: isTablet ? 14.0 : 13.5.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14.0 : 14.r),
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
        final isTablet = context.isTablet;
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
              borderRadius: BorderRadius.circular(isTablet ? 14.0 : 14.r),
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

        if (context.isTablet) {
          return _buildTabletLayout(context, provider, items);
        }

        return _buildMobileLayout(context, provider, items);
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ManifestProvider provider,
    List<VisionBoardItem> items,
  ) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context, items.length),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
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
                itemCount: items.length >= 4 ? items.length + 1 : items.length,
                separatorBuilder: (context, index) => 14.verticalSpace,
                itemBuilder: (context, index) {
                  final hasAd = items.length >= 4;
                  if (hasAd && index == 2) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: const NativeAdWidget(
                        templateType: TemplateType.small,
                      ),
                    );
                  }
                  final item = items[hasAd && index > 2 ? index - 1 : index];
                  return Dismissible(
                    key: ValueKey('vision_item_${item.id}_$index'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) =>
                        _confirmDelete(context, provider, item),
                    background: const _DismissibleDeleteBackground(),
                    child: _VisionBoardCard(
                      item: item,
                      onTap: () => _restoreAndNavigate(context, provider, item),
                      onDelete: () => _confirmDelete(context, provider, item),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ── Tablet Layout ──────────────────────────────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    ManifestProvider provider,
    List<VisionBoardItem> items,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? 820.0 : 720.0,
                ),
                child: Container(
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
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
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 10.0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Tablet top bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.purple.withValues(alpha: 0.08),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Semantics(
                              label: 'Go back to profile',
                              button: true,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12.0),
                                child: Container(
                                  width: 38.0,
                                  height: 38.0,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16.0,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14.0),
                            Expanded(
                              child: Text(
                                'Vision Board',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: AppColors.textDark,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (items.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 5.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                child: Text(
                                  '${items.length} ${items.length == 1 ? 'Vision' : 'Visions'}',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Content body
                      Expanded(
                        child: items.isEmpty
                            ? const _TabletEmptyVisionBoardView()
                            : RefreshIndicator(
                                color: AppColors.purple,
                                onRefresh: () async {
                                  final user = context.read<UserProvider>();
                                  if (user.userId != null) {
                                    await context
                                        .read<ManifestProvider>()
                                        .loadHistory(user.userId!);
                                  }
                                },
                                child: ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    isLandscape ? 32.0 : 24.0,
                                    16.0,
                                    isLandscape ? 32.0 : 24.0,
                                    36.0,
                                  ),
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  itemCount: items.length >= 4
                                      ? items.length + 1
                                      : items.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 14.0),
                                  itemBuilder: (context, index) {
                                    final hasAd = items.length >= 4;
                                    if (hasAd && index == 2) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10.0,
                                        ),
                                        child: NativeAdWidget(
                                          templateType: TemplateType.small,
                                        ),
                                      );
                                    }
                                    final item =
                                        items[hasAd && index > 2
                                            ? index - 1
                                            : index];
                                    return Dismissible(
                                      key: ValueKey(
                                        'vision_item_tablet_${item.id}_$index',
                                      ),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (_) => _confirmDelete(
                                        context,
                                        provider,
                                        item,
                                      ),
                                      background:
                                          const _TabletDismissibleDeleteBackground(),
                                      child: _TabletVisionBoardCard(
                                        item: item,
                                        onTap: () => _restoreAndNavigate(
                                          context,
                                          provider,
                                          item,
                                        ),
                                        onDelete: () => _confirmDelete(
                                          context,
                                          provider,
                                          item,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SafeArea(top: false, child: BannerAdWidget()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
    final isTablet = context.isTablet;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 28.0 : 28.r),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 420.0 : double.infinity,
        ),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 26.0 : 26.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isTablet ? 28.0 : 28.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.12),
                blurRadius: isTablet ? 32.0 : 32.r,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isTablet ? 52.0 : 52.r,
                height: isTablet ? 52.0 : 52.r,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade600,
                  size: isTablet ? 26.0 : 26.sp,
                ),
              ),
              isTablet ? const SizedBox(height: 18.0) : 18.verticalSpace,
              Text(
                'Release to Cosmos?',
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.textDark,
                  fontSize: isTablet ? 20.0 : 20.sp,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              isTablet ? const SizedBox(height: 10.0) : 10.verticalSpace,
              Text(
                'Are you sure you want to release "$title"?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGrey,
                  height: 1.5,
                  fontSize: isTablet ? 14.0 : 13.5.sp,
                ),
                textAlign: TextAlign.center,
              ),
              isTablet ? const SizedBox(height: 26.0) : 26.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: isTablet ? 48.0 : 48.h,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textGrey,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isTablet ? 14.0 : 14.r,
                            ),
                            side: BorderSide(
                              color: AppColors.borderLight,
                              width: isTablet ? 1.2 : 1.2.w,
                            ),
                          ),
                        ),
                        child: Text(
                          'Keep',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  isTablet ? const SizedBox(width: 12.0) : 12.horizontalSpace,
                  Expanded(
                    child: SizedBox(
                      height: isTablet ? 48.0 : 48.h,
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
                            borderRadius: BorderRadius.circular(
                              isTablet ? 14.0 : 14.r,
                            ),
                          ),
                        ),
                        child: Text(
                          'Release',
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 14.sp,
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
// Tablet Dedicated Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TabletVisionBoardCard extends StatelessWidget {
  final VisionBoardItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TabletVisionBoardCard({
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
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.04),
                blurRadius: 16.0,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        item.formattedDate,
                        style: const TextStyle(
                          fontSize: 11.5,
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
                      borderRadius: BorderRadius.circular(10.0),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.0,
                          color: AppColors.textLightGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Goal Title
              Text(
                item.goalTitle,
                style: const TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),

              // Vision Statement preview (if available)
              if (item.visionStatement.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Text(
                  '“${item.visionStatement}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textGrey,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 16.0),

              // Bottom Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.actionStepsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EEFF),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 14.0,
                            color: AppColors.purple,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            '${item.actionStepsCount} action steps',
                            style: const TextStyle(
                              fontSize: 12.0,
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
                    children: const [
                      Text(
                        'Restore',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4.0),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14.0,
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

class _TabletDismissibleDeleteBackground extends StatelessWidget {
  const _TabletDismissibleDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: Colors.red.shade600,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            'Release',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletEmptyVisionBoardView extends StatelessWidget {
  const _TabletEmptyVisionBoardView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76.0,
              height: 76.0,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.purple,
                  size: 32.0,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              'No Manifestations Yet',
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textDark,
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Goals you manifest on the home screen will be preserved here on your board.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14.0,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28.0),
            Semantics(
              label: 'Manifest a Goal button',
              button: true,
              child: SizedBox(
                height: 48.0,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).popUntil(
                      (route) =>
                          route.settings.name == AppRoutes.home ||
                          route.isFirst,
                    );
                  },
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 18.0,
                    color: AppColors.white,
                  ),
                  label: const Text(
                    'Manifest a Goal',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
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
    final isTablet = context.isTablet;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: EdgeInsets.only(left: isTablet ? 24.0 : 16.w),
          child: Center(
            child: Semantics(
              label: 'Go back to profile',
              button: true,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(isTablet ? 14.0 : 14.r),
                child: Container(
                  width: isTablet ? 42.0 : 38.r,
                  height: isTablet ? 42.0 : 38.r,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(isTablet ? 14.0 : 14.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: isTablet ? 16.0 : 15.sp,
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
            isTablet ? const SizedBox(height: 24.0) : 22.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 20.w),
              child: Text(
                'Gathering Your Sacred Visions... ✨',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w800,
                  fontSize: isTablet ? 22.0 : 18.sp,
                ),
              ),
            ),
            isTablet ? const SizedBox(height: 12.0) : 10.verticalSpace,
            Text(
              'The universe is assembling your dreams\nand manifestations',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGrey,
                height: 1.5,
                fontSize: isTablet ? 14.5 : 13.sp,
              ),
            ),
            isTablet ? const SizedBox(height: 40.0) : 40.verticalSpace,
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

  Widget _sparkle(double dx, double dy, double phase, {bool isTablet = false}) {
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
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.sp,
              color: const Color(0xFFAB6FF5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final floatOffset = -10.0 * (1.0 - (t - 0.5).abs() * 2);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _sparkle(-46, -18, (t + 0.1) % 1.0, isTablet: isTablet),
            _sparkle(44, -26, (t + 0.4) % 1.0, isTablet: isTablet),
            _sparkle(-34, 30, (t + 0.7) % 1.0, isTablet: isTablet),
            _sparkle(40, 26, (t + 0.25) % 1.0, isTablet: isTablet),
            Transform.translate(offset: Offset(0, floatOffset), child: child),
          ],
        );
      },
      child: Text('🔮', style: TextStyle(fontSize: isTablet ? 72.0 : 64.sp)),
    );
  }
}
