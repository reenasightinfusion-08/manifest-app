import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/common/core.dart';
import 'ad_service.dart';

/// "Watch an ad to unlock for 24h" gate. Never blocks the user when ads are
/// unsupported or none is ready.
class AdGate {
  static const _validFor = Duration(hours: 24);

  static Future<bool> _isUnlocked(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final at = prefs.getInt('ad_gate_$key');
      if (at == null) return false;
      return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) <
          _validFor;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _unlock(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ad_gate_$key', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<void> run(
    BuildContext context, {
    required String key,
    required String title,
    required String message,
    required VoidCallback onUnlocked,
    bool interstitialStyle = false,
    bool blocking = true,
  }) async {
    final ready = interstitialStyle
        ? AdService.rewardedInterstitialReady
        : AdService.rewardedReady;
    if (!AdService.supported || !ready || await _isUnlocked(key)) {
      onUnlocked();
      return;
    }
    if (!context.mounted) return;

    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Watch ad',
              style: const TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (watch != true) {
      if (!blocking) onUnlocked();
      return;
    }

    var earned = false;
    void onReward(_) => earned = true;
    void onClosed() {
      if (!earned) {
        if (!blocking) onUnlocked();
        return;
      }
      _unlock(key);
      onUnlocked();
    }

    final shown = interstitialStyle
        ? AdService.showRewardedInterstitial(onReward: onReward, onClosed: onClosed)
        : AdService.showRewarded(onReward: onReward, onClosed: onClosed);
    if (!shown) onUnlocked();
  }
}
