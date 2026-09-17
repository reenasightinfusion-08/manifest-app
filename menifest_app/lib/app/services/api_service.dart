import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Build-time default (still works if you want it):
  //   flutter build apk --dart-define=API_BASE_URL=http://<your-pc-ip>:3000
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.29.88:3000',
  );

  static const String _prefsKey = 'server_base_url';

  // Shared across all ApiService instances so a runtime change (or the
  // value loaded from disk at startup) is picked up everywhere at once.
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Call once at app startup (before runApp) to restore any server address
  /// the user saved on this device previously — so a release build keeps
  /// working after the PC's LAN IP changes, with no rebuild needed.
  static Future<void> loadSavedBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _dio.options.baseUrl = saved.trim();
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
    String? passcode,
    String? fcmToken,
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
          'passcode': passcode,
          'fcm_token': fcmToken,
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
        throw Exception('Network Error: ${serverMessage ?? e.message}');
      }
      throw Exception('Cosmic Sync Error: $e');
    }
  }

  Future<Map<String, dynamic>?> searchProfileByName(String name) async {
    try {
      final response = await _dio.get(
        '/api/users/search',
        queryParameters: {'name': name},
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generatePlan(String userId, String goal) async {
    try {
      final response = await _dio.post(
        '/api/generate-plan',
        data: {'user_id': userId, 'goal_title': goal},
      );
      final body = Map<String, dynamic>.from(response.data);
      // Pass through invalid-input responses so provider can show the reason
      if (body['valid'] == false) return body;
      return body['data'] ?? {};
    } catch (e) {
      if (e is DioException) {
        String? serverMessage;
        if (e.response?.data != null && e.response?.data is Map) {
          serverMessage = e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception('Failed to manifest your plan: ${serverMessage ?? e.message}');
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
          serverMessage = e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception('Failed to clear manifestations: ${serverMessage ?? e.message}');
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
          serverMessage = e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception('Failed to delete account: ${serverMessage ?? e.message}');
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
          serverMessage = e.response?.data['message'] ?? e.response?.data['error'];
        }
        throw Exception('Failed to discover your archetype: ${serverMessage ?? e.message}');
      }
      throw Exception('Failed to discover your archetype: $e');
    }
  }
}
