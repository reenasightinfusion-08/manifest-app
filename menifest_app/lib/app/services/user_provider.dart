import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  // ── Basic Profile ────────────────────────────────────────────────────────
  String _name = 'Alex Manifestor';
  String get name => _name;

  String _profileImage =
      'https://api.dicebear.com/7.x/avataaars/png?seed=manifest&backgroundColor=b6e3f4,c0aede,d1d4f9';
  String get profileImage => _profileImage;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // ── Security & Privacy ────────────────────────────────────────────────
  String? _passcode;
  String? get passcode => _passcode;

  void setPasscode(String? code) {
    _passcode = code;
    notifyListeners();
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
    notifyListeners();
  }

  bool _personalizationEnabled = true;
  bool get personalizationEnabled => _personalizationEnabled;
  void setPersonalization(bool value) {
    _personalizationEnabled = value;
    notifyListeners();
  }

  bool _crashReportsEnabled = true;
  bool get crashReportsEnabled => _crashReportsEnabled;
  void setCrashReports(bool value) {
    _crashReportsEnabled = value;
    notifyListeners();
  }

  bool _biometricLock = false;
  bool get biometricLock => _biometricLock;
  void setBiometricLock(bool value) {
    _biometricLock = value;
    notifyListeners();
  }

  bool _autoLock = true;
  bool get autoLock => _autoLock;
  void setAutoLock(bool value) {
    _autoLock = value;
    notifyListeners();
  }

  // ── Onboarding Survey Answers ──────────────────────────────────────────────
  final List<String> personalAnswers = List.filled(5, '');
  final List<String> familyAnswers = List.filled(5, '');
  final List<String> professionalAnswers = List.filled(5, '');

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

  String? _userId;
  String? get userId => _userId;

  // ── Spiritual Archetype ───────────────────────────────────────────────
  bool _isFetchingArchetype = false;
  bool get isFetchingArchetype => _isFetchingArchetype;

  Map<String, dynamic>? _archetypeData;
  Map<String, dynamic>? get archetypeData => _archetypeData;

  Future<void> fetchArchetype() async {
    if (_userId == null) return;

    _isFetchingArchetype = true;
    notifyListeners();

    try {
      _archetypeData = await _apiService.generateArchetype(_userId!);
    } catch (e) {
      debugPrint('Failed to fetch archetype: $e');
      _archetypeData = null;
    } finally {
      _isFetchingArchetype = false;
      notifyListeners();
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Fetch FCM token
    _fcmToken = await NotificationService.getToken();

    debugPrint('INIT: userId: $_userId, loggedIn: $_isLoggedIn');

    // Safety check: If we are "logged in" but have no ID from the new system, reset.
    if (_isLoggedIn && (_userId == null || _userId!.isEmpty)) {
      _isLoggedIn = false;
      await prefs.clear();
    }

    _name = prefs.getString('userName') ?? 'Alex Manifestor';
    _profileImage = prefs.getString('userImage') ?? _profileImage;
    _passcode = prefs.getString('userPasscode');
    notifyListeners();
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
      if (isStepComplete(_onboardingStep)) {
        _showOnboardingErrors = false;
      }
    }
    notifyListeners();
  }

  List<String> getAnswersFor(int step) {
    if (step == 0) return personalAnswers;
    if (step == 1) return familyAnswers;
    return professionalAnswers;
  }

  bool isStepComplete(int step) {
    if (step == 3) {
      return _passcode != null && _passcode!.length == 4;
    }
    final answers = getAnswersFor(step);
    return answers.every((a) => a.trim().isNotEmpty);
  }

  Future<void> syncToApi() async {
    _isLoading = true;
    notifyListeners();

    debugPrint('SYNCING: userId=$_userId, name=$_name');

    try {
      debugPrint('SYNCING DATA: passcode=$_passcode');
      final data = await _apiService.saveUserProfile(
        id: _userId,
        name: _name,
        avatarUrl: _profileImage,
        personalAnswers: personalAnswers,
        familyAnswers: familyAnswers,
        professionalAnswers: professionalAnswers,
        passcode: _passcode,
        fcmToken: _fcmToken,
      );

      // Save locally after successful sync
      if (data != null) {
        final prefs = await SharedPreferences.getInstance();
        _userId = data['id']; // Get ID from response
        debugPrint('SYNC SUCCESS: new userId=$_userId');

        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', _name);
        await prefs.setString('userImage', _profileImage);
        await prefs.setString('userId', _userId!);
        if (_passcode != null) {
          await prefs.setString('userPasscode', _passcode!);
        }
        _isLoggedIn = true;
      } else {
        debugPrint('SYNC SUCCESS but returned no data object.');
      }
    } catch (e) {
      debugPrint('SYNC ERROR: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginByEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      const allowedId = 'anandyadav21219@gmail.com';
      if (email == allowedId && password == allowedId) {
        // Find or create a profile for this admin
        var profile = await _apiService.searchProfileByName('Anand Yadav');

        if (profile == null) {
          // If profile doesn't exist, we might need to create it,
          // but for now let's just use a dummy if search fails
          _userId = 'admin_anand';
          _name = 'Anand Yadav';
        } else {
          _userId = profile['id'];
          _name = profile['full_name'] ?? 'Anand Yadav';
          _profileImage = profile['avatar_url'] ?? _profileImage;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', _name);
        await prefs.setString('userId', _userId!);

        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinExistingProfile(String name, String passcode) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _apiService.searchProfileByName(name);
      if (profile != null) {
        // Verify Passcode for privacy
        // We must check if the entered passcode matches the saved one.
        // If the saved passcode is null or empty, we treat it as no passcode set,
        // but since our app requires 4 digits, any mismatch is an error.
        if (profile['passcode'] != passcode) {
          throw Exception('Incorrect passcode for this cosmic identity.');
        }

        _userId = profile['id'];
        _name = profile['full_name'] ?? _name;
        _profileImage = profile['avatar_url'] ?? _profileImage;

        // Restore answers
        if (profile['personal_answers'] != null) {
          final List<dynamic> pa = profile['personal_answers'];
          for (int i = 0; i < pa.length && i < 5; i++) {
            personalAnswers[i] = pa[i].toString();
          }
        }
        if (profile['family_answers'] != null) {
          final List<dynamic> fa = profile['family_answers'];
          for (int i = 0; i < fa.length && i < 5; i++) {
            familyAnswers[i] = fa[i].toString();
          }
        }
        if (profile['professional_answers'] != null) {
          final List<dynamic> pra = profile['professional_answers'];
          for (int i = 0; i < pra.length && i < 5; i++) {
            professionalAnswers[i] = pra[i].toString();
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', _name);
        await prefs.setString('userImage', _profileImage);
        await prefs.setString('userId', _userId!);
        // Save passcode locally and update state
        _passcode = passcode;
        await prefs.setString('userPasscode', passcode);

        _isLoggedIn = true;

        debugPrint('JOIN SUCCESS: userId=$_userId');
        notifyListeners();
        return true;
      }
      return false;
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
    _passcode = null;
    _profileImage =
        'https://api.dicebear.com/7.x/avataaars/png?seed=manifest&backgroundColor=b6e3f4,c0aede,d1d4f9';
    _archetypeData = null;
    _onboardingStep = 0;

    // Clear answers
    for (int i = 0; i < 5; i++) {
      personalAnswers[i] = '';
      familyAnswers[i] = '';
      professionalAnswers[i] = '';
    }

    notifyListeners();
  }
}
