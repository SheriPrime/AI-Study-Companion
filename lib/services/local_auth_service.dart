import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/user.dart';

/// Local authentication service using SharedPreferences.
///
/// Persists login state and user profile data locally.
/// Replaces MockAuthService for real device usage.
class LocalAuthService {
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyName = 'userName';
  static const _keyEmail = 'userEmail';
  static const _keyRollNumber = 'userRollNumber';
  static const _keyUniversity = 'userUniversity';
  static const _keyDepartment = 'userDepartment';
  static const _keyTimeline = 'userTimeline';

  /// Logs in the user by saving their details to shared preferences.
  Future<AppUser> login(String name, String rollNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, '$rollNumber@comsats.edu.pk');
    await prefs.setString(_keyRollNumber, rollNumber);
    await prefs.setString(_keyUniversity, 'COMSATS University Islamabad');
    await prefs.setString(_keyDepartment, 'BSCS');
    await prefs.setString(_keyTimeline, '2023–2027');

    return AppUser(
      id: rollNumber,
      name: name,
      email: '$rollNumber@comsats.edu.pk',
      university: 'COMSATS University Islamabad',
      department: 'BSCS',
      timeline: '2023–2027',
    );
  }

  /// Checks if a user is currently logged in.
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Retrieves the currently saved user profile, or null if not logged in.
  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (!isLoggedIn) return null;

    return AppUser(
      id: prefs.getString(_keyRollNumber) ?? '',
      name: prefs.getString(_keyName) ?? '',
      email: prefs.getString(_keyEmail) ?? '',
      university: prefs.getString(_keyUniversity) ?? 'COMSATS University Islamabad',
      department: prefs.getString(_keyDepartment) ?? 'BSCS',
      timeline: prefs.getString(_keyTimeline) ?? '2023–2027',
    );
  }

  /// Logs out by clearing all saved preferences.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
