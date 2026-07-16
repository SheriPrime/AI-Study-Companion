import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/user.dart';
import 'package:ai_study_companion/services/firebase_auth_service.dart';

/// Controls authentication state for login, signup, and logout flows.
///
/// Wraps [FirebaseAuthService] and exposes reactive properties via
/// [ChangeNotifier] so the UI can rebuild on state changes.
class AuthController extends ChangeNotifier {
  final FirebaseAuthService _authService;

  AuthController(this._authService);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  /// Exposes if the auth service is operating in local fallback mode.
  bool get isFallbackMode => _authService.isFallbackMode;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Checks if a user is already logged in (called on app startup).
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      debugPrint('AuthController.checkLoginStatus error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs in the user with the provided [email] and [password] via Firebase.
  /// On success, [currentUser] is populated. On failure, returns error.
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.login(email, password);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new account with the given [name], [email], and [password] via Firebase.
  Future<void> signup(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.signup(name, email, password);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  /// Signs the current user out and resets controller state.
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears the current error message so the UI can dismiss error indicators.
  void clearError() {
    _clearError();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
