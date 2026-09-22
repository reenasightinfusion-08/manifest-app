import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/common/app_colors.dart';
import '../services/version_check_service.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  /// Displays the update dialog with appropriate dismissal constraints.
  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.isForceUpdate,
      builder: (_) => UpdateDialog(updateInfo: info),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final urlStr = updateInfo.updateUrl;
    if (urlStr.isEmpty) return;

    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch update URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForce = updateInfo.isForceUpdate;

    // Determine the target version for the badge
    final targetVersion =
        (VersionCheckService.compareSemVer(updateInfo.latestVersion, updateInfo.currentVersion) > 0)
            ? updateInfo.latestVersion
            : (VersionCheckService.compareSemVer(updateInfo.minVersion, updateInfo.currentVersion) > 0)
                ? updateInfo.minVersion
                : (updateInfo.latestVersion.isNotEmpty ? updateInfo.latestVersion : updateInfo.minVersion);

    final showTransition = targetVersion.isNotEmpty && targetVersion != updateInfo.currentVersion;

    return PopScope(
      canPop: !isForce,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        elevation: 20,
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowPurple.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cosmic Double-Ring Icon with Glow
              Container(
                width: 82.w,
                height: 82.w,
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.15),
                      AppColors.pink.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.glowPink,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isForce ? Icons.system_update_rounded : Icons.auto_awesome_rounded,
                    color: AppColors.white,
                    size: 38.sp,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                updateInfo.title.isNotEmpty
                    ? updateInfo.title
                    : (isForce ? 'Update Required' : 'New Update Available'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 10.h),

              // Version Badge (clean pill)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.purpleLight.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14.sp,
                      color: AppColors.purple,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      showTransition
                          ? 'v${updateInfo.currentVersion}  ➔  v$targetVersion'
                          : 'Version $targetVersion',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.purple,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // Description message
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  updateInfo.message.isNotEmpty
                      ? updateInfo.message
                      : 'A newer version of Manifest is ready with important improvements. Please update to continue your journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.45,
                    color: AppColors.textGrey,
                  ),
                ),
              ),

              // Release notes (if present)
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVeryLight,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.borderVeryLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14.sp,
                            color: AppColors.purple,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            "What's New",
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        updateInfo.releaseNotes,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textFaded,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Action Buttons
              Column(
                children: [
                  // Full-width Primary Gradient Button (No text clipping)
                  Container(
                    width: double.infinity,
                    height: 54.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowPink.withValues(alpha: 0.4),
                          blurRadius: 16.r,
                          spreadRadius: -2.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openStore(context),
                        borderRadius: BorderRadius.circular(20.r),
                        splashColor: AppColors.white.withValues(alpha: 0.2),
                        highlightColor: AppColors.white.withValues(alpha: 0.1),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_download_rounded,
                                color: AppColors.white,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Update Now',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // If flexible update, show "Maybe Later" button
                  if (!isForce) ...[
                    SizedBox(height: 10.h),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
