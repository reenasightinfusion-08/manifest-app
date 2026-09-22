import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

enum AppUpdateStatus {
  upToDate,
  flexible,
  forceUpdate,
}

class AppUpdateInfo {
  final AppUpdateStatus status;
  final String currentVersion;
  final String minVersion;
  final String latestVersion;
  final String updateUrl;
  final String title;
  final String message;
  final String releaseNotes;

  const AppUpdateInfo({
    required this.status,
    required this.currentVersion,
    required this.minVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.title,
    required this.message,
    required this.releaseNotes,
  });

  bool get isForceUpdate => status == AppUpdateStatus.forceUpdate;
  bool get isFlexibleUpdate => status == AppUpdateStatus.flexible;
  bool get isUpdateAvailable => status != AppUpdateStatus.upToDate;
}

class VersionCheckService {
  /// Compares two semantic version strings (e.g. "1.0.0" and "1.0.1").
  /// Returns:
  ///   -1 if v1 < v2
  ///    0 if v1 == v2
  ///    1 if v1 > v2
  static int compareSemVer(String v1, String v2) {
    try {
      // Strip any build numbers (e.g. 1.0.0+1 -> 1.0.0)
      final cleanV1 = v1.split('+').first.trim();
      final cleanV2 = v2.split('+').first.trim();

      final parts1 = cleanV1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

      for (int i = 0; i < maxLength; i++) {
        final part1 = i < parts1.length ? parts1[i] : 0;
        final part2 = i < parts2.length ? parts2[i] : 0;

        if (part1 < part2) return -1;
        if (part1 > part2) return 1;
      }
      return 0;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return 0;
    }
  }

  /// Checks the backend for version requirements and compares with local app version.
  /// Fails open (upToDate) if offline or network times out.
  static Future<AppUpdateInfo> checkAppVersion() async {
    String currentVersion = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (e) {
      debugPrint('Could not read local package info: $e');
    }

    final remoteData = await ApiService.getAppVersionInfo();

    // If backend is unreachable or offline, fail open so the user can continue
    if (remoteData == null) {
      return AppUpdateInfo(
        status: AppUpdateStatus.upToDate,
        currentVersion: currentVersion,
        minVersion: currentVersion,
        latestVersion: currentVersion,
        updateUrl: '',
        title: '',
        message: '',
        releaseNotes: '',
      );
    }

    final minVersion = (remoteData['min_version'] ?? '1.0.0').toString();
    final latestVersion = (remoteData['latest_version'] ?? '1.0.0').toString();
    final globalForceUpdate = remoteData['force_update'] == true;
    final updateUrl = (remoteData['update_url'] ?? '').toString();
    final title = (remoteData['title'] ?? 'Update Required').toString();
    final message = (remoteData['message'] ?? 'A new version of Manifest is available. Please update to continue.').toString();
    final releaseNotes = (remoteData['release_notes'] ?? '').toString();

    // Comparison logic:
    // If current < minVersion -> MUST force update
    // If globalForceUpdate is true AND current < latestVersion -> MUST force update
    // If current < latestVersion -> flexible update (optional)
    // Otherwise -> up to date
    AppUpdateStatus status = AppUpdateStatus.upToDate;

    final cmpMin = compareSemVer(currentVersion, minVersion);
    final cmpLatest = compareSemVer(currentVersion, latestVersion);

    if (cmpMin < 0 || (globalForceUpdate && cmpLatest < 0)) {
      status = AppUpdateStatus.forceUpdate;
    } else if (cmpLatest < 0) {
      status = AppUpdateStatus.flexible;
    }

    return AppUpdateInfo(
      status: status,
      currentVersion: currentVersion,
      minVersion: minVersion,
      latestVersion: latestVersion,
      updateUrl: updateUrl,
      title: title,
      message: message,
      releaseNotes: releaseNotes,
    );
  }
}
