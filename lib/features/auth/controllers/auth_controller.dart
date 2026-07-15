import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/user.dart';
import 'package:ai_study_companion/services/local_auth_service.dart';

/// Controls authentication state for login, signup, and logout flows.
///
/// Wraps [LocalAuthService] and exposes reactive properties via
/// [ChangeNotifier] so the UI can rebuild on state changes.
class AuthController extends ChangeNotifier {
  final LocalAuthService _authService;

  AuthController(this._authService);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

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

  /// Logs in the user with the provided [name] and [rollNumber].
  ///
  /// Sets [isLoading] while the request is in-flight.
  /// On success, [currentUser] is populated and [isLoggedIn] becomes `true`.
  /// On failure, [errorMessage] is set with a human-readable description.
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Use email as name, password as rollNumber for local auth
      _currentUser = await _authService.login(email, password);
    } catch (e) {
      _errorMessage = 'Login failed. Please check your credentials.';
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new account with the given [name], [email], and [password].
  ///
  /// For local auth, we use name and email (as rollNumber).
  Future<void> signup(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.login(name, email);
    } catch (e) {
      _errorMessage = 'Signup failed. Please try again later.';
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
