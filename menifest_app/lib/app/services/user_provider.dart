import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'analytics_service.dart';
import 'crash_reporting_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  // ── Basic Profile ────────────────────────────────────────────────────────
  String _name = 'Alex Manifestor';
  String get name => _name;

  static const List<String> _memojiList = [
    'memo_1',
    'memo_2',
    'memo_3',
    'memo_4',
    'memo_5',
    'memo_6',
    'memo_7',
    'memo_8',
    'memo_9',
    'memo_10',
    'memo_11',
    'memo_12',
    'memo_13',
    'memo_14',
    'memo_15',
    'memo_16',
    'memo_17',
    'memo_18',
    'memo_19',
    'memo_20',
    'memo_21',
    'memo_22',
    'memo_23',
    'memo_24',
    'memo_25',
    'memo_26',
    'memo_27',
    'memo_28',
    'memo_29',
    'memo_30',
  ];

  static List<String> get memojiList => _memojiList;

  static String generateRandomAvatarUrl([String? seed]) {
    final list = List<String>.from(_memojiList)..shuffle();
    final chosen = list.first;
    return 'https://cdn.jsdelivr.net/gh/alohe/memojis@main/png/$chosen.png';
  }

  String _profileImage =
      'https://cdn.jsdelivr.net/gh/alohe/memojis@main/png/memo_1.png';
  String get profileImage => _profileImage;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ── Security & Privacy ────────────────────────────────────────────────
  // Email + password are the login credentials (also used to gate the
  // in-app lock screen — see MyApp/_canAutoLock and AppLockScreen). The
  // backend only ever stores/compares a bcrypt hash of the password; this
  // plaintext copy is kept locally (SharedPreferences) purely so the lock
  // screen can verify it offline, same tradeoff the old 4-digit passcode
  // made.
  String? _email;
  String? get email => _email;

  String? _password;
  String? get password => _password;

  void setEmail(String? value) {
    _email = value;
    // Stale "already exists" / "domain doesn't exist" error shouldn't
    // survive an edit to the field it was about.
    _emailCheckError = null;
    notifyListeners();
  }

  String? _emailCheckError;
  String? get emailCheckError => _emailCheckError;

  bool _checkingEmail = false;
  bool get checkingEmail => _checkingEmail;

  /// Hits the backend right after the email/password onboarding step, so
  /// "already registered" or "that domain doesn't exist" surfaces before
  /// the user spends time on the rest of the questions. Returns true when
  /// clear to move to the next step.
  Future<bool> checkEmailAvailability() async {
    final value = (_email ?? '').trim();
    _checkingEmail = true;
    notifyListeners();
    try {
      _emailCheckError = await _apiService.checkEmailAvailable(value);
      return _emailCheckError == null;
    } finally {
      _checkingEmail = false;
      notifyListeners();
    }
  }

  void setPassword(String? value) {
    _password = value;
    notifyListeners();
  }

  // Whether the account's email has been confirmed via the link sent at
  // signup. A logged-in account with this false is routed to
  // VerifyEmailScreen instead of the app (see SplashScreen and MyApp's
  // route table).
  bool _emailVerified = false;
  bool get emailVerified => _emailVerified;

  /// Re-checks the server for whether the verification link has been
  /// tapped yet, and persists the result. Returns the up-to-date value.
  Future<bool> refreshEmailVerified() async {
    if (_userId == null || _userId!.isEmpty) return _emailVerified;
    final status = await _apiService.checkVerificationStatus(_userId!);
    _emailVerified = status.verified;
    final prefs = await SharedPreferences.getInstance();
    // Right after signup, _userId is a pending-signup id — verifying is
    // what promotes that into a real account, under a DIFFERENT id. Pick
    // that up here, or every call after this one (profile sync, login,
    // future polls) keeps addressing an id that stopped resolving to
    // anything new the moment it was promoted.
    if (status.id != _userId) {
      _userId = status.id;
      await prefs.setString('userId', status.id);
    }
    notifyListeners();
    await prefs.setBool('emailVerified', status.verified);
    return status.verified;
  }

  Future<String> resendVerificationEmail(String email) {
    return _apiService.resendVerification(email);
  }

  bool _securityError = false;
  bool get securityError => _securityError;

  void setSecurityError(bool value) {
    _securityError = value;
    notifyListeners();
  }

  bool _analyticsEnabled = true;
  bool get analyticsEnabled => _analyticsEnabled;
  void setAnalytics(bool value) {
    _analyticsEnabled = value;
    AnalyticsService.enabled = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('analyticsEnabled', value),
    );
  }

  bool _personalizationEnabled = true;
  bool get personalizationEnabled => _personalizationEnabled;
  void setPersonalization(bool value) {
    _personalizationEnabled = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('personalizationEnabled', value),
    );
  }

  bool _crashReportsEnabled = true;
  bool get crashReportsEnabled => _crashReportsEnabled;
  void setCrashReports(bool value) {
    _crashReportsEnabled = value;
    CrashReportingService.enabled = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('crashReportsEnabled', value),
    );
  }

  bool _biometricLock = false;
  bool get biometricLock => _biometricLock;
  void setBiometricLock(bool value) {
    _biometricLock = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('biometricLockEnabled', value),
    );
  }

  bool _autoLock = false;
  bool get autoLock => _autoLock;
  void setAutoLock(bool value) {
    _autoLock = value;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('autoLockEnabled', value),
    );
  }

  // ── Notifications ───────────────────────────────────────────────────
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    NotificationService.notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    // Tell the server too — otherwise the daily reminder cron and the
    // welcome/plan-ready pushes have no idea this user opted out, and
    // keep notifying them even while the app is backgrounded or closed.
    if (_userId != null && _userId!.isNotEmpty) {
      unawaited(
        _apiService.updateNotificationPrefs(
          _userId!,
          notificationsEnabled: value,
        ),
      );
    }
  }

  bool _manifestationTips = true;
  bool get manifestationTips => _manifestationTips;

  Future<void> setManifestationTips(bool value) async {
    _manifestationTips = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('manifestationTips', value);
    if (_userId != null && _userId!.isNotEmpty) {
      unawaited(
        _apiService.updateNotificationPrefs(
          _userId!,
          manifestationTipsEnabled: value,
        ),
      );
    }
  }

  // ── Default Autofill Answers ───────────────────────────────────────────────
  static const List<String> defaultPersonalAnswers = ['', '', '', '', ''];

  static const List<String> defaultFamilyAnswers = ['', '', '', '', ''];

  static const List<String> defaultProfessionalAnswers = ['', '', '', '', ''];

  // ── Onboarding Survey Answers ──────────────────────────────────────────────
  final List<String> personalAnswers = List.from(defaultPersonalAnswers);
  final List<String> familyAnswers = List.from(defaultFamilyAnswers);
  final List<String> professionalAnswers = List.from(
    defaultProfessionalAnswers,
  );

  // ── Focus & Navigation ────────────────────────────────────────────────
  int? _focusedQuestionIndex;
  int? get focusedQuestionIndex => _focusedQuestionIndex;

  void setFocusedQuestion(int? index) {
    _focusedQuestionIndex = index;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // Cached, persisted mirror of isProfileComplete — the last time it was
  // actually confirmed against the server. SplashScreen falls back to this
  // when a fresh check can't reach the network, rather than assuming
  // "incomplete" just because nothing loaded this cold start (which would
  // wrongly bounce an already-finished, offline user back into
  // ProfileSetupScreen).
  bool _cachedProfileComplete = false;
  bool get cachedProfileComplete => _cachedProfileComplete;

  Future<void> _setCachedProfileComplete(bool value) async {
    if (_cachedProfileComplete == value) return;
    _cachedProfileComplete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profileComplete', value);
  }

  String? _userId;
  String? get userId => _userId;

  // ── Spiritual Archetype ───────────────────────────────────────────────
  bool _isFetchingArchetype = false;
  bool get isFetchingArchetype => _isFetchingArchetype;

  String? _archetypeError;
  String? get archetypeError => _archetypeError;

  Map<String, dynamic>? _archetypeData;
  Map<String, dynamic>? get archetypeData => _archetypeData;

  String _getAnswersHash() {
    return '${personalAnswers.map((s) => s.trim()).join('|')}###'
        '${familyAnswers.map((s) => s.trim()).join('|')}###'
        '${professionalAnswers.map((s) => s.trim()).join('|')}';
  }

  Future<void> fetchArchetype({bool force = false}) async {
    if (_userId == null || _userId!.isEmpty) return;
    if (_isFetchingArchetype) return;

    // Avoid querying archetype endpoint if survey answers haven't been loaded or answered
    final hasAnswers =
        personalAnswers.any((a) => a.trim().isNotEmpty) ||
        familyAnswers.any((a) => a.trim().isNotEmpty) ||
        professionalAnswers.any((a) => a.trim().isNotEmpty);
    if (!hasAnswers) return;

    final currentHash = _getAnswersHash();

    // 1. Cache check: only reuse cached archetype if answers haven't changed and not forced
    if (!force) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedHash = prefs.getString('cached_archetype_hash_$_userId');

        final isCacheValid = savedHash != null && savedHash == currentHash;

        if (isCacheValid) {
          if (_archetypeData != null) {
            return;
          }
          final cached = prefs.getString('cached_archetype_$_userId');
          if (cached != null && cached.isNotEmpty) {
            _archetypeData = jsonDecode(cached) as Map<String, dynamic>;
            _archetypeError = null;
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        debugPrint('Failed to read archetype cache: $e');
      }
    }

    _isFetchingArchetype = true;
    _archetypeError = null;
    notifyListeners();

    try {
      final data = await _apiService.generateArchetype(_userId!);
      _archetypeData = data;
      _archetypeError = null;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_archetype_$_userId', jsonEncode(data));
        await prefs.setString('cached_archetype_hash_$_userId', currentHash);
      } catch (e) {
        debugPrint('Failed to persist archetype cache: $e');
      }
    } catch (e) {
      debugPrint('Failed to fetch archetype: $e');
      _archetypeError = e.toString();

      // Graceful offline fallback: if no archetype is in memory, attempt reading last known cache
      if (_archetypeData == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final cached = prefs.getString('cached_archetype_$_userId');
          if (cached != null && cached.isNotEmpty) {
            _archetypeData = jsonDecode(cached) as Map<String, dynamic>;
          }
        } catch (_) {}
      }
    } finally {
      _isFetchingArchetype = false;
      notifyListeners();
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    debugPrint('INIT: userId: $_userId, loggedIn: $_isLoggedIn');

    // Safety check: If we are "logged in" but have no ID from the new system, reset.
    if (_isLoggedIn && (_userId == null || _userId!.isEmpty)) {
      _isLoggedIn = false;
      await prefs.clear();
    }

    _name = prefs.getString('userName') ?? 'Alex Manifestor';
    _profileImage = prefs.getString('userImage') ?? _profileImage;
    _email = prefs.getString('userEmail');
    _password = prefs.getString('userPassword');
    // Read together with isLoggedIn, before the FCM await below — the
    // splash screen decides isLoggedIn vs. emailVerified routing off
    // whatever this provider holds the instant its navigation timer
    // fires, with no guarantee init() has finished. Setting these two
    // fields on either side of an await left a window where isLoggedIn
    // was already true but emailVerified was still its false default,
    // which sent verified, logged-in users to the verify-email screen
    // after a cold start.
    _emailVerified = prefs.getBool('emailVerified') ?? false;
    // Same "must be in place before the splash timer's navigation check"
    // reasoning as emailVerified above — this is the offline fallback for
    // that same check.
    _cachedProfileComplete = prefs.getBool('profileComplete') ?? false;
    if (_userId != null && _userId!.isNotEmpty) {
      final cachedArch = prefs.getString('cached_archetype_$_userId');
      if (cachedArch != null && cachedArch.isNotEmpty) {
        try {
          _archetypeData = jsonDecode(cachedArch) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
    _biometricLock = prefs.getBool('biometricLockEnabled') ?? false;
    _analyticsEnabled = prefs.getBool('analyticsEnabled') ?? true;
    AnalyticsService.enabled = _analyticsEnabled;
    _personalizationEnabled = prefs.getBool('personalizationEnabled') ?? true;
    _crashReportsEnabled = prefs.getBool('crashReportsEnabled') ?? true;
    CrashReportingService.enabled = _crashReportsEnabled;
    _autoLock = prefs.getBool('autoLockEnabled') ?? false;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    NotificationService.notificationsEnabled = _notificationsEnabled;
    _manifestationTips = prefs.getBool('manifestationTips') ?? true;

    // Fetch FCM token last — this can retry for several seconds, and
    // every field the splash screen reads must already be in place
    // before we await anything here.
    _fcmToken = await NotificationService.getToken();
    notifyListeners();

    // Push whatever this device has stored up to the server once per cold
    // start — covers a fresh install (SharedPreferences reset to the
    // defaults) landing on an existing account whose server-side prefs
    // were last set differently.
    if (_userId != null && _userId!.isNotEmpty) {
      unawaited(
        _apiService.updateNotificationPrefs(
          _userId!,
          notificationsEnabled: _notificationsEnabled,
          manifestationTipsEnabled: _manifestationTips,
        ),
      );
    }

    // A cold start with an already-logged-in session never goes through
    // loginWithEmail, so personalAnswers/familyAnswers/professionalAnswers
    // would otherwise sit at their empty defaults for the whole session —
    // fetch them in the background rather than blocking startup on it.
    unawaited(refreshProfileAnswers());

    // Keep Supabase's fcm_token correct for the rest of this account's
    // lifetime — covers token rotations Firebase triggers on its own,
    // with no reinstall involved.
    NotificationService.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed, syncing: $newToken');
      _fcmToken = newToken;
      if (_userId != null && _userId!.isNotEmpty) {
        _apiService.updateFcmToken(_userId!, newToken);
      }
    });
  }

  bool _showOnboardingErrors = false;
  bool get showOnboardingErrors => _showOnboardingErrors;

  void setShowOnboardingErrors(bool show) {
    _showOnboardingErrors = show;
    notifyListeners();
  }

  int _onboardingStep = 0;
  int get onboardingStep => _onboardingStep;

  void setOnboardingStep(int step) {
    _onboardingStep = step;
    _showOnboardingErrors = false;
    notifyListeners();
  }

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void updateAvatar(String url) {
    _profileImage = url;
    notifyListeners();
  }

  void updateAnswer(int step, int qIndex, String value) {
    if (step == 0) {
      personalAnswers[qIndex] = value;
      // If this is the "What is your first name?" question, update the main name
      if (qIndex == 0) {
        _name = value.isEmpty ? 'Alex Manifestor' : value;
      }
    } else if (step == 1) {
      familyAnswers[qIndex] = value;
    } else {
      professionalAnswers[qIndex] = value;
    }
    if (_showOnboardingErrors && value.trim().isNotEmpty) {
      // Check if all fields for current step are now filled to clear errors
      if (getAnswersFor(step).every((a) => a.trim().isNotEmpty)) {
        _showOnboardingErrors = false;
      }
    }
    _archetypeData = null;
    notifyListeners();
  }

  List<String> getAnswersFor(int step) {
    if (step == 0) return personalAnswers;
    if (step == 1) return familyAnswers;
    return professionalAnswers;
  }

  bool isStepComplete(int step) {
    // Page 0 is now the email/password step (see UserInfoScreen's
    // PageView) — pages 1-3 are the personal/family/professional
    // question pages, i.e. getAnswersFor(step - 1).
    if (step == 0) {
      final emailOk =
          (_email ?? '').trim().contains('@') &&
          (_email ?? '').trim().contains('.');
      final passwordOk = (_password ?? '').length >= 6;
      return emailOk && passwordOk;
    }
    final answers = getAnswersFor(step - 1);
    return answers.every((a) => a.trim().isNotEmpty);
  }

  /// True once all three ProfileSetupScreen pages are filled in. There's
  /// no durable "profile complete" flag on the backend — `complete_profile`
  /// on POST /api/users is a one-shot request flag that only decides
  /// whether to fire the welcome push, it isn't stored as a column — so
  /// this is inferred the same way the form itself validates each step.
  /// Used by SplashScreen to decide whether a logged-in, verified user
  /// goes to Home or back to ProfileSetupScreen to finish what they
  /// started (see the comment there for why isLoggedIn alone isn't a
  /// reliable signal for this).
  bool get isProfileComplete =>
      isStepComplete(1) && isStepComplete(2) && isStepComplete(3);

  /// [completeProfile] should be true only on the call that finishes
  /// ProfileSetupScreen (personal/family/professional questions all
  /// answered) — it's what tells the backend the account is genuinely
  /// ready, which is when the welcome push actually fires. Signup
  /// (account creation) and any other profile edit must leave it false.
  Future<void> syncToApi({bool completeProfile = false}) async {
    _isLoading = true;
    notifyListeners();

    debugPrint('SYNCING: userId=$_userId, name=$_name');

    try {
      // If we don't already have an FCM token, do a non-blocking fast check
      if (_fcmToken == null) {
        try {
          final freshToken = await NotificationService.getToken().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => null,
          );
          if (freshToken != null) {
            _fcmToken = freshToken;
          }
        } catch (_) {}
      }
      debugPrint('SYNCING DATA: email=$_email, fcmToken=$_fcmToken');
      final data = await _apiService.saveUserProfile(
        id: _userId,
        name: _name,
        avatarUrl: _profileImage,
        personalAnswers: personalAnswers,
        familyAnswers: familyAnswers,
        professionalAnswers: professionalAnswers,
        email: _email,
        password: _password,
        fcmToken: _fcmToken,
        completeProfile: completeProfile,
      );

      // Save locally after successful sync
      final prefs = await SharedPreferences.getInstance();
      _userId = data['id']; // Get ID from response
      debugPrint('SYNC SUCCESS: new userId=$_userId');
      AnalyticsService.logEvent('signup_complete', {'userId': _userId});

      // The call that actually finishes ProfileSetupScreen — cache it now
      // rather than waiting for some later refreshProfileAnswers() to
      // confirm it, so a quit-and-reopen right after finishing still goes
      // to Home even if that next cold start happens offline.
      if (completeProfile) {
        await _setCachedProfileComplete(true);
      }

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', _name);
      await prefs.setString('userImage', _profileImage);
      await prefs.setString('userId', _userId!);
      // If answers were updated, invalidate cached archetype so it regenerates
      final currentHash = _getAnswersHash();
      final savedHash = prefs.getString('cached_archetype_hash_$_userId');
      if (savedHash != currentHash) {
        _archetypeData = null;
        await prefs.remove('cached_archetype_$_userId');
        await prefs.remove('cached_archetype_hash_$_userId');
      }
      if (_email != null) {
        await prefs.setString('userEmail', _email!);
      }
      if (_password != null) {
        await prefs.setString('userPassword', _password!);
      }
      // A brand-new signup always comes back unverified; an existing
      // account being re-synced (e.g. profile edit) carries whatever its
      // current server-side value is.
      _emailVerified = data['email_verified'] == true;
      await prefs.setBool('emailVerified', _emailVerified);
      _isLoggedIn = true;
    } catch (e) {
      debugPrint('SYNC ERROR: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Copies the personal/family/professional answer arrays out of a raw
  /// profile map (whatever shape login and GET /api/users/:id both return)
  /// into the in-memory lists the onboarding/edit form reads from.
  void _restoreAnswersFrom(Map<String, dynamic> profile) {
    if (profile['personal_answers'] != null) {
      final List<dynamic> pa = profile['personal_answers'];
      for (int i = 0; i < pa.length && i < personalAnswers.length; i++) {
        personalAnswers[i] = pa[i].toString();
      }
    }
    if (profile['family_answers'] != null) {
      final List<dynamic> fa = profile['family_answers'];
      for (int i = 0; i < fa.length && i < familyAnswers.length; i++) {
        familyAnswers[i] = fa[i].toString();
      }
    }
    if (profile['professional_answers'] != null) {
      final List<dynamic> pra = profile['professional_answers'];
      for (int i = 0; i < pra.length && i < professionalAnswers.length; i++) {
        professionalAnswers[i] = pra[i].toString();
      }
    }
  }

  /// Re-fetches this account's saved answers from the backend and merges
  /// them into personalAnswers/familyAnswers/professionalAnswers.
  ///
  /// Those three lists are only ever populated two ways: this call, or
  /// [loginWithEmail]'s response. A session that reached the logged-in
  /// state via [init] (cold start with a SharedPreferences userId, the
  /// common case) never goes through login, so without this the lists sit
  /// at their empty defaults for the rest of the session even though the
  /// backend has real data — which is what made the "Edit Your Answers"
  /// form open blank. Called from init() in the background, again right
  /// before ProfileSetupScreen opens in edit mode so that screen never
  /// shows stale/blank data, and by SplashScreen to decide Home vs.
  /// resuming ProfileSetupScreen.
  ///
  /// Returns whether it actually reached the server — false (offline,
  /// deleted account, …) means the answer lists and [cachedProfileComplete]
  /// were left untouched, so a caller that needs to fall back to cached
  /// state can tell the difference from "reached the server and the
  /// answers are genuinely empty."
  Future<bool> refreshProfileAnswers() async {
    if (_userId == null || _userId!.isEmpty) return false;
    final profile = await _apiService.getUserProfile(_userId!);
    if (profile == null) return false;
    _restoreAnswersFrom(profile);
    await _setCachedProfileComplete(
      isStepComplete(1) && isStepComplete(2) && isStepComplete(3),
    );
    notifyListeners();
    return true;
  }

  /// Logs in with email + password. The backend verifies the password
  /// against the bcrypt hash and only returns a profile on a match, so
  /// there's nothing left to check client-side here.
  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _apiService.login(email, password);
      if (profile != null) {
        _userId = profile['id'];
        _name = profile['full_name'] ?? _name;
        _profileImage = profile['avatar_url'] ?? _profileImage;

        _restoreAnswersFrom(profile);
        await _setCachedProfileComplete(
          isStepComplete(1) && isStepComplete(2) && isStepComplete(3),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', _name);
        await prefs.setString('userImage', _profileImage);
        await prefs.setString('userId', _userId!);
        // Save email/password locally — used to gate the app-lock screen
        // offline, same as the old passcode did.
        _email = email;
        _password = password;
        await prefs.setString('userEmail', email);
        await prefs.setString('userPassword', password);
        // The backend only returns success here when email_verified is
        // already true (see POST /api/login) — nothing left to check.
        _emailVerified = true;
        await prefs.setBool('emailVerified', true);

        _isLoggedIn = true;

        debugPrint('JOIN SUCCESS: userId=$_userId');
        AnalyticsService.logEvent('login_success', {'userId': _userId});
        notifyListeners();

        // This device's fcm_token may not be the one already stored for
        // this account (fresh install after uninstall = brand-new token).
        // Sync it now instead of waiting for a token rotation event that
        // may never come.
        NotificationService.getToken().then((token) {
          if (token != null && _userId != null) {
            _fcmToken = token;
            _apiService.updateFcmToken(_userId!, token);
          }
        });

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [UserProvider] loginWithEmail error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    if (_userId == null || _userId!.isEmpty) return false;
    try {
      final success = await _apiService.deleteAccount(_userId!);
      if (success) {
        AnalyticsService.logEvent('account_deleted');
        await logout();
      }
      return success;
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Reset all state
    _isLoggedIn = false;
    _userId = null;
    _name = 'Alex Manifestor';
    _email = null;
    _password = null;
    _emailVerified = false;
    _profileImage =
        'https://cdn.jsdelivr.net/gh/alohe/memojis@main/png/memo_1.png';
    _archetypeData = null;
    _archetypeError = null;
    _onboardingStep = 0;
    _cachedProfileComplete = false;

    // Reset answers
    for (int i = 0; i < 5; i++) {
      personalAnswers[i] = defaultPersonalAnswers[i];
      familyAnswers[i] = defaultFamilyAnswers[i];
      professionalAnswers[i] = defaultProfessionalAnswers[i];
    }

    notifyListeners();
  }
}
