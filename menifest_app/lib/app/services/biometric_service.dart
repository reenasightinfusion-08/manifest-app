import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';

/// Result of an authenticate() attempt. Unlike a bare bool, this tells the
/// caller *why* it failed — critical for biometrics, where "it didn't work"
/// can mean five completely different things (no match, cancelled, no
/// fingerprint enrolled, or Android's OS-level lockout after too many
/// failed attempts — which a bare bool can't distinguish from "the fingerprint
/// just didn't match this once").
class BiometricAuthResult {
  final bool success;
  final String? message;
  const BiometricAuthResult(this.success, [this.message]);
}

/// Thin wrapper around local_auth so the rest of the app never touches the
/// plugin directly.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True only if this device can actually prompt for biometrics right now
  /// (hardware present AND at least one fingerprint/face already enrolled
  /// in the OS). Check this before letting someone turn the toggle on.
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (e) {
      debugPrint('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Shows the OS biometric prompt (Face ID / fingerprint / device
  /// credential UI).
  ///
  /// Wrapped in a hard timeout: on some devices, requesting this right as
  /// the hosting Activity is mid-transition (e.g. right as the app resumes
  /// and the lock screen replaces the whole nav stack in the same instant)
  /// the native call can silently never respond — no error, no dialog,
  /// nothing — leaving the caller awaiting forever. A timeout guarantees
  /// this always resolves one way or another instead of hanging the UI.
  static Future<BiometricAuthResult> authenticate({
    String reason = 'Confirm your identity to continue',
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final ok = await _auth
          .authenticate(
            localizedReason: reason,
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          )
          .timeout(timeout);
      return BiometricAuthResult(
        ok,
        ok ? null : 'Fingerprint/Face ID didn\'t match. Try again.',
      );
    } on TimeoutException {
      debugPrint('Biometric authentication timed out after $timeout');
      return const BiometricAuthResult(
        false,
        'Biometric prompt didn\'t respond. Use your password instead.',
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.code} — ${e.message}');
      switch (e.code) {
        case 'LockedOut':
          return const BiometricAuthResult(
            false,
            'Too many failed attempts. Wait about 30 seconds, then try again.',
          );
        case 'PermanentlyLockedOut':
          return const BiometricAuthResult(
            false,
            'Too many failed attempts — biometrics are locked. '
            'Unlock your phone once with your PIN/pattern/password to reset it, then try again.',
          );
        case 'NotEnrolled':
          return const BiometricAuthResult(
            false,
            'No fingerprint or Face ID is set up on this device.',
          );
        case 'NotAvailable':
          return const BiometricAuthResult(
            false,
            'Biometric hardware isn\'t available on this device.',
          );
        case 'PasscodeNotSet':
          return const BiometricAuthResult(
            false,
            'Set a device PIN, pattern, or password first — biometrics require one.',
          );
        default:
          return BiometricAuthResult(
            false,
            'Biometric check failed: ${e.message ?? e.code}',
          );
      }
    } catch (e) {
      debugPrint('Biometric authentication failed: $e');
      return const BiometricAuthResult(false, 'Biometric check failed.');
    }
  }
}
