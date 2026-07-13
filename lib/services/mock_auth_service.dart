import 'package:ai_study_companion/models/user.dart';

/// Mock authentication service that simulates real-world latency.
/// Replace with a real implementation backed by SQLite in Phase 2.
class MockAuthService {
  static final AppUser _mockUser = AppUser(
    id: 'user_001',
    name: 'Muhammad Shaheer Sajid',
    email: 'shaheer@example.com',
    university: 'COMSATS University Islamabad',
    department: 'BSCS',
    timeline: '2023–2027',
  );

  AppUser? _currentUser;

  /// Simulates login with a 2-second delay.
  Future<AppUser> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = _mockUser;
    return _mockUser;
  }

  /// Simulates signup with a 2-second delay.
  Future<AppUser> signup(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    _currentUser = AppUser(
      id: 'user_002',
      name: name,
      email: email,
      university: 'COMSATS University Islamabad',
      department: 'BSCS',
      timeline: '2023–2027',
    );
    return _currentUser!;
  }

  /// Returns the currently logged-in user.
  AppUser? getCurrentUser() => _currentUser;

  /// Clears the auth state (logout).
  void logout() {
    _currentUser = null;
  }

  /// Whether a user is currently logged in.
  bool get isLoggedIn => _currentUser != null;
}
