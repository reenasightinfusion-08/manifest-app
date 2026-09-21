import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown by [ApiService.login] when the password was correct but the
/// account's email hasn't been verified yet (backend responds 403). Carries
/// just enough to drive the "check your email" screen — no password.
class EmailNotVerifiedException implements Exception {
  final String userId;
  final String email;
  EmailNotVerifiedException({required this.userId, required this.email});
}

/// Result of GET /api/users/:id/verification-status. [id] is the id the
/// caller should keep using going forward — it changes from a
/// pending_signups id to a real users.id the moment [verified] flips true.
class VerificationStatus {
  final bool verified;
  final String id;
  VerificationStatus({required this.verified, required this.id});
}

class ApiService {
  // Build-time default or fallback:
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-mu-tawny-16.vercel.app',
  );

  static const String _prefsKey = 'server_base_url';

  // Shared across all ApiService instances so a runtime change (or the
  // value loaded from disk at startup) is picked up everywhere at once.
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Call once at app startup (before runApp) to restore any server address
  /// the user saved on this device previously.
  static Future<void> loadSavedBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.trim().isNotEmpty) {
        final trimmed = saved.trim();
        // If an old local IP was cached from earlier development, purge it
        if (trimmed.contains('192.168.') ||
            trimmed.contains('10.0.2.2') ||
            trimmed.contains('localhost')) {
          await prefs.remove(_prefsKey);
          _dio.options.baseUrl = _defaultBaseUrl;
        } else {
          _dio.options.baseUrl = trimmed;
        }
      }
    } catch (e) {
      debugPrint('Could not load saved server address: $e');
    }
  }

  static String get currentBaseUrl => _dio.options.baseUrl;

  /// Persist + apply a new server address immediately (e.g. from a
  /// Settings screen), no app restart required.
  static Future<void> setBaseUrl(String url) async {
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    _dio.options.baseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, cleaned);
  }

  static Future<void> resetBaseUrl() async {
    _dio.options.baseUrl = _defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Quick reachability check for a Settings "Test Connection" button.
  static Future<bool> testConnection({String? url}) async {
    try {
      final target = url ?? _dio.options.baseUrl;
      final probe = Dio(
        BaseOptions(
          baseUrl: target,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final res = await probe.get('/');
      return res.statusCode != null && res.statusCode! < 500;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> saveUserProfile({
    String? id,
    required String name,
    required String avatarUrl,
    required List<String> personalAnswers,
    required List<String> familyAnswers,
    required List<String> professionalAnswers,
    String? email,
    String? password,
    String? fcmToken,
    // True only on ProfileSetupScreen's final "Complete My Profile" call —
    // that's what the backend uses to know the account is genuinely ready
    // and fire the welcome push (see complete_profile in POST /api/users).
    bool completeProfile = false,
  }) async {
    try {
      final response = await _dio.post(
        '/api/users',
        data: {
          'id': id,
          'full_name': name,
          'avatar_url': avatarUrl,
          'personal_answers': personalAnswers,
          'family_answers': familyAnswers,
          'professional_answers': professionalAnswers,
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
          if (completeProfile) 'complete_profile': true,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server returned error: ${response.data['message']}');
      }
      return response.data['data'];
    } catch (e) {
      if (e is DioException) {
        String? serverMessage;
        if (e.response?.data != null && e.response?.data is Map) {
          serverMessage =
              e.response?.data['message'] ?? e.response?.data['error'];
        }
        // The server actually responded (e.g. 400 validation failure) —
        // that's not a network problem, so don't label it as one.
        if (serverMessage != null) {
          throw Exception(serverMessage);
        }
        throw Exception('Network Error: ${e.message}');
      }
      throw Exception('Cosmic Sync Error: $e');
    }
  }

  /// Syncs just the fcm_token for an existing user — used when logging into
  /// an existing account on a fresh install (old token is dead) and whenever
  /// Firebase rotates the device's token on its own. Deliberately silent on
  /// failure: a missed token sync shouldn't interrupt whatever the user is
  /// doing (login, app resume, etc.).
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    try {
      await _dio.post(
        '/api/users/$userId/fcm-token',
        data: {'fcm_token': fcmToken},
      );
      debugPrint('FCM token synced for user $userId');
    } catch (e) {
      debugPrint('Failed to sync FCM token: $e');
    }
  }

  /// Pushes the "Push Notifications" / "Manifestation Tips" toggle state to
  /// the backend so server-triggered notifications (the daily reminder
  /// cron, the welcome push, the "plan ready" push) actually respect what
  /// the user chose in-app instead of firing regardless. Deliberately
  /// silent on failure, same reasoning as [updateFcmToken] — a missed sync
  /// shouldn't interrupt the user flipping a switch.
  Future<void> updateNotificationPrefs(
    String userId, {
    bool? notificationsEnabled,
    bool? manifestationTipsEnabled,
  }) async {
    try {
      await _dio.post(
        '/api/users/$userId/notification-prefs',
        data: {
          'notifications_enabled': ?notificationsEnabled,
          'manifestation_tips_enabled': ?manifestationTipsEnabled,
        },
      );
      debugPrint('Notification prefs synced for user $userId');
    } catch (e) {
      debugPrint('Failed to sync notification prefs: $e');
    }
  }

  /// Logs in with email + password. The password is verified server-side
  /// against the bcrypt hash — returns the profile on success, null on a
  /// wrong email/password (401) or unknown account (404), and throws
  /// [EmailNotVerifiedException] when the password was right but the email
  /// link was never tapped (403).
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      debugPrint(
        '🔐 [ApiService] POST ${_dio.options.baseUrl}/api/login (email: $email)',
      );
      final response = await _dio.post(
        '/api/login',
        data: {'email': email, 'password': password},
      );

      debugPrint(
        '✅ [ApiService] Login response (${response.statusCode}): ${response.data}',
      );
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ApiService] Login failed: $e');
      if (e is DioException) {
        debugPrint(
          '🔍 [ApiService] DioException Details: status=${e.response?.statusCode}, type=${e.type}, url=${e.requestOptions.uri}, data=${e.response?.data}',
        );
        if (e.response?.statusCode == 403 &&
            e.response?.data is Map &&
            e.response?.data['email_verified'] == false) {
          final data = e.response?.data['data'];
          throw EmailNotVerifiedException(
            userId: data?['id']?.toString() ?? '',
            email: data?['email']?.toString() ?? email,
          );
        }
        if (e.response?.statusCode == 401) {
          return null; // Invalid credentials
        }
        if (e.response?.statusCode == 404) {
          throw Exception(
            'Endpoint /api/login returned 404 Not Found on ${_dio.options.baseUrl}',
          );
        }
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          throw Exception(
            'Cannot connect to ${_dio.options.baseUrl}. Check internet connection.',
          );
        }
        throw Exception(
          'Server error (${e.response?.statusCode ?? e.type}): ${e.response?.data ?? e.message}',
        );
      }
      rethrow;
    }
  }

  /// Pre-check hit right after the email field on signup — catches an
  /// already-registered email or a domain that can't receive mail before
  /// the user fills out the rest of onboarding. Returns null when the
  /// email looks fine, or a message to show inline otherwise.
  Future<String?> checkEmailAvailable(String email) async {
    try {
      final response = await _dio.get(
        '/api/check-email',
        queryParameters: {'email': email},
      );
      final data = response.data;
      if (data is Map && data['available'] == true) return null;
      return (data is Map ? data['message'] as String? : null) ??
          "That email doesn't look right.";
    } catch (e) {
      // A network hiccup here shouldn't block the user — the final submit
      // still re-validates on the server, this is just an early heads-up.
      debugPrint('checkEmailAvailable failed, skipping: $e');
      return null;
    }
  }

  /// Polls whether the emailed verification link has been tapped yet.
  /// Right after signup, the id the app has is a pending_signups id, not
  /// a real users.id yet — the backend only creates the real user row
  /// once the emailed link is tapped. So this returns the id right along
  /// with the verified flag: once verified, it may be a DIFFERENT id than
  /// what was passed in, and callers must start using it (see
  /// UserProvider.refreshEmailVerified), or every call after this one
  /// keeps polling a pending id that no longer resolves to anything new.
  Future<VerificationStatus> checkVerificationStatus(String userId) async {
    try {
      debugPrint('[ApiService] 🔍 Checking verification status for userId: $userId');
      final response = await _dio.get('/api/users/$userId/verification-status');
      debugPrint('[ApiService] 📥 Verification status response: ${response.statusCode} -> ${response.data}');
      final data = response.data['data'];
      if (data == null) return VerificationStatus(verified: false, id: userId);
      return VerificationStatus(
        verified: data['email_verified'] == true,
        id: data['id']?.toString() ?? userId,
      );
    } catch (e) {
      debugPrint('❌ [ApiService] Failed to check verification status: $e');
      return VerificationStatus(verified: false, id: userId);
    }
  }

  /// Asks the backend to send a fresh verification email. Returns the
  /// server's message so the UI can show it directly.
  Future<String> resendVerification(String email) async {
    try {
      debugPrint('[ApiService] 📨 Requesting resend verification for email: "$email" to ${_dio.options.baseUrl}/api/resend-verification');
      final response = await _dio.post(
        '/api/resend-verification',
        data: {'email': email},
      );
      debugPrint('[ApiService] 📥 Resend verification response: ${response.statusCode} -> ${response.data}');
      return response.data['message'] ?? 'Verification email sent.';
    } catch (e) {
      debugPrint('❌ [ApiService] Resend verification failed: $e');
      if (e is DioException && e.response?.data is Map) {
        debugPrint('❌ [ApiService] Server error data: ${e.response?.data}');
        return e.response?.data['message'] ?? 'Could not resend the email.';
      }
      return 'Could not resend the email. Check your connection.';
    }
  }

  Future<Map<String, dynamic>> generatePlan(
    String userId,
    String goal, {
    bool personalize = true,
  }) async {
    try {
      final response = await _dio.post(
        '/api/generate-plan',
        data: {
          'user_id': userId,
          'goal_title': goal,
          'personalize': personalize,
        },
      );
      final body = Map<String, dynamic>.from(response.data);
      // Pass through invalid-input responses so provider can show the reason
      if (body['valid'] == false) return body;
      return body['data'] ?? {};
    } catch (e) {
      if (e is DioException) {
        String? serverMessage;
        if (e.response?.data != null && e.response?.data is Map) {
          serverMessage =
              e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception(
          'Failed to manifest your plan: ${serverMessage ?? e.message}',
        );
      }
      throw Exception('Failed to manifest your plan: $e');
    }
  }

  Future<List<dynamic>> getManifestationHistory(String userId) async {
    try {
      final response = await _dio.get('/api/history/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to load history: $e');
      return [];
    }
  }

  /// Same call as [getManifestationHistory], but also returns the user's
  /// current streak — which lives on the `users` row, not the
  /// manifestations themselves, so it survives even after they're deleted.
  Future<({List<dynamic> history, int streak})>
  getManifestationHistoryWithStreak(String userId) async {
    try {
      final response = await _dio.get('/api/history/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (
          history: response.data['data'] as List<dynamic>,
          streak: (response.data['streak'] as num?)?.toInt() ?? 0,
        );
      }
      return (history: <dynamic>[], streak: 0);
    } catch (e) {
      debugPrint('Failed to load history: $e');
      return (history: <dynamic>[], streak: 0);
    }
  }

  Future<bool> deleteManifest(String manifestationId) async {
    try {
      final response = await _dio.delete(
        '/api/manifestations/$manifestationId',
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('Failed to delete manifestation: $e');
      return false;
    }
  }

  Future<bool> deleteAllManifestations(String userId) async {
    try {
      final response = await _dio.delete('/api/history/$userId');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        String? serverMessage;
        if (e.response?.data != null && e.response?.data is Map) {
          serverMessage =
              e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception(
          'Failed to clear manifestations: ${serverMessage ?? e.message}',
        );
      }
      throw Exception('Failed to clear manifestations: $e');
    }
  }

  Future<bool> deleteAccount(String userId) async {
    try {
      final response = await _dio.delete('/api/users/$userId');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        String? serverMessage;
        if (e.response?.data != null && e.response?.data is Map) {
          serverMessage =
              e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception(
          'Failed to delete account: ${serverMessage ?? e.message}',
        );
      }
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<Map<String, dynamic>> generateArchetype(String userId) async {
    try {
      final response = await _dio.post(
        '/api/generate-archetype',
        data: {'user_id': userId},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        String? serverMessage;
        if (e.response?.data != null && e.response?.data is Map) {
          serverMessage =
              e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception(
          'Failed to discover your archetype: ${serverMessage ?? e.message}',
        );
      }
      throw Exception('Failed to discover your archetype: $e');
    }
  }
}
