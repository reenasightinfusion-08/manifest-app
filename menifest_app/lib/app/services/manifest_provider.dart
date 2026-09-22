import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'analytics_service.dart';

class ManifestProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _currentPlan;
  Map<String, dynamic>? get currentPlan => _currentPlan;

  Map<String, dynamic>? _fullAi;
  Map<String, dynamic>? get fullAi => _fullAi;

  List<dynamic> _actionCards = [];
  List<dynamic> get actionCards => _actionCards;

  String _activeGoal = '';
  String get activeGoal => _activeGoal;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Loading the user's past manifestations (used by the vision board and
  // to seed history on app start) is a separate flag from _isLoading
  // above. They used to share one flag, which meant the "generate my
  // plan" button + spinner on the home screen would flash on every cold
  // start — loadHistory() flips _isLoading true/false before the user has
  // typed anything, and the home screen's empty-textfield check
  // (`!provider.isLoading`) was reading that same flag.
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  String? _invalidReason;
  String? get invalidReason => _invalidReason;

  String? _invalidTip;
  String? get invalidTip => _invalidTip;

  bool _duplicateDetected = false;
  bool get duplicateDetected => _duplicateDetected;

  void clearDuplicateError() {
    _duplicateDetected = false;
    notifyListeners();
  }

  bool _isFocused = false;
  bool get isFocused => _isFocused;

  void setFocused(bool value) {
    _isFocused = value;
    notifyListeners();
  }

  Future<void> generateManifestationPlan(
    String userId,
    String goal, {
    bool personalize = true,
  }) async {
    if (goal.trim().isEmpty) return;

    _isLoading = true;
    _currentPlan = null;
    _actionCards = [];
    _fullAi = null;
    _invalidReason = null;
    _invalidTip = null;
    _duplicateDetected = false;
    _activeGoal = goal.trim();
    notifyListeners();

    // Check for duplicates in history
    final isDuplicate = _history.any((item) =>
        item['goal_title'].toString().toLowerCase() == goal.trim().toLowerCase());

    if (isDuplicate) {
      _duplicateDetected = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final data = await _apiService.generatePlan(
        userId,
        goal.trim(),
        personalize: personalize,
      );

      // Check if backend rejected the input as invalid
      if (data['valid'] == false) {
        _invalidReason =
            data['reason'] ?? 'This doesn\'t look like a valid goal.';
        _invalidTip = data['tip'];
        _activeGoal = ''; // reset so the button doesn't stay hidden
        return;
      }

      _currentPlan = data['plan'];
      _actionCards = data['cards'] ?? [];
      _fullAi = data['full_ai'];
      if (data['streak'] != null) {
        _streakCount = (data['streak'] as num).toInt();
      }
      AnalyticsService.logEvent('manifestation_generated', {'personalize': personalize});
    } catch (e) {
      debugPrint('Plan Generation Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> _history = [];
  List<dynamic> get history => _history;

  /// Distinct goals the user has manifested for, not just total
  /// manifestation runs — trimmed + case-folded the same way
  /// [generateManifestationPlan]'s duplicate check compares `goal_title`,
  /// so re-running the exact same goal only counts once here too.
  int get distinctGoalsCount {
    final titles = <String>{};
    for (final item in _history) {
      final title = item['goal_title']?.toString().trim().toLowerCase();
      if (title != null && title.isNotEmpty) titles.add(title);
    }
    return titles.length;
  }

  // The streak is NOT computed from _history — it's stored on the
  // server's `users` row (current_streak / last_manifested_date) and
  // fetched alongside history / updated after each successful plan
  // generation. This is deliberate: computing it from _history meant
  // deleting your manifestations also deleted your streak, since there
  // was nothing left to count from. Storing it separately means it
  // survives "Delete All Manifestations" — the achievement is "days you
  // showed up", not "days you still have saved".
  int _streakCount = 0;
  int get streakCount => _streakCount;

  Future<void> loadHistory(String userId) async {
    // 1. Instant cache load: if in-memory history is empty, populate from local storage immediately
    if (_history.isEmpty && _streakCount == 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedHistoryStr = prefs.getString('cached_history_$userId');
        final cachedStreak = prefs.getInt('cached_streak_$userId');
        if (cachedHistoryStr != null && cachedHistoryStr.isNotEmpty) {
          _history = jsonDecode(cachedHistoryStr) as List<dynamic>;
        }
        if (cachedStreak != null) {
          _streakCount = cachedStreak;
        }
        if (_history.isNotEmpty || _streakCount > 0) {
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Cache read error: $e');
      }
    }

    _isLoadingHistory = true;
    notifyListeners();
    try {
      final result = await _apiService.getManifestationHistoryWithStreak(userId);
      _history = result.history;
      _streakCount = result.streak;

      // Persist to local cache for instant future loads
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_history_$userId', jsonEncode(result.history));
        await prefs.setInt('cached_streak_$userId', result.streak);
      } catch (e) {
        debugPrint('Cache write error: $e');
      }
    } catch (e) {
      debugPrint('History Load Error: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void restoreHistoricalPlan(Map<String, dynamic> historyItem) {
    if (historyItem['manifestation_plans'] != null &&
        historyItem['manifestation_plans'].isNotEmpty) {
      final plan = historyItem['manifestation_plans'][0];
      _currentPlan = plan;
      List<dynamic> restoredCards = plan['daily_tasks'] ?? [];
      _activeGoal = historyItem['goal_title'] ?? '';

      // Attempt to restore `fullAi` mock format from `full_content` if available
      try {
        if (plan['full_content'] != null) {
          _fullAi = jsonDecode(plan['full_content']);

          // SELF-HEALING: If DB rejected the tasks because of schema errors, rebuild them instantly!
          if (restoredCards.isEmpty &&
              _fullAi != null &&
              _fullAi!['pillars'] != null) {
            restoredCards = (_fullAi!['pillars'] as List).asMap().entries.map((
              entry,
            ) {
              return {
                'day_number': entry.key + 1,
                'task_title': entry.value['title'],
                'task_description': entry.value['huge_text'],
                'task_summary': entry.value['summary'],
              };
            }).toList();
          }
        }
      } catch (_) {}

      _actionCards = restoredCards;
      notifyListeners();
    }
  }

  Future<bool> deleteHistoryItem(String manifestationId) async {
    try {
      final success = await _apiService.deleteManifest(manifestationId);
      if (success) {
        _history.removeWhere(
          (item) => item['id'].toString() == manifestationId,
        );
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  Future<bool> deleteAllHistory(String userId) async {
    try {
      final success = await _apiService.deleteAllManifestations(userId);
      if (success) {
        _history = [];
        _currentPlan = null;
        _actionCards = [];
        _fullAi = null;
        _activeGoal = '';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('cached_history_$userId');
        } catch (_) {}
        AnalyticsService.logEvent('history_deleted');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Delete all history error: $e');
      rethrow;
    }
  }

  void clearPlan() {
    _currentPlan = null;
    _actionCards = [];
    _fullAi = null;
    notifyListeners();
  }

  /// Wipes every piece of per-user state. Must be called on logout/account
  /// switch — this provider is a single app-lifetime singleton (see
  /// my_app.dart), so without this the next account to log in sees the
  /// previous account's in-memory goal/plan until they generate a new one.
  void resetForLogout() {
    _currentPlan = null;
    _fullAi = null;
    _actionCards = [];
    _activeGoal = '';
    _isLoading = false;
    _isLoadingHistory = false;
    _invalidReason = null;
    _invalidTip = null;
    _duplicateDetected = false;
    _isFocused = false;
    _history = [];
    _streakCount = 0;
    _isPlaying = false;
    notifyListeners();
  }

  // ── Audio Playback ────────────────────────────────────────────────────────
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  void setPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }

  double _speechRate = 0.45;
  double get speechRate => _speechRate;

  void setSpeechRate(double rate) {
    _speechRate = rate;
    notifyListeners();
  }
}
