import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/user.dart';
import 'package:ai_study_companion/services/firestore_service.dart';

/// Service class interfacing with Firebase Authentication.
/// Supports a Developer Fallback Mode when Firebase credentials are placeholders.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  static const _keyIsLoggedIn = 'local_isLoggedIn';
  static const _keyName = 'local_userName';
  static const _keyEmail = 'local_userEmail';
  static const _keyUid = 'local_userUid';

  /// Determines if the app is running in offline Developer Fallback Mode.
  bool get isFallbackMode {
    try {
      return _auth.app.options.apiKey == "placeholder-api-key-ai-study-companion";
    } catch (_) {
      return true; // Fallback if Firebase is not initialized
    }
  }

  /// Gets the currently authenticated user's details mapped to [AppUser].
  Future<AppUser?> getCurrentUser() async {
    if (isFallbackMode) {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return null;

      return AppUser(
        id: prefs.getString(_keyUid) ?? 'offline_uid',
        name: prefs.getString(_keyName) ?? 'Student',
        email: prefs.getString(_keyEmail) ?? 'offline@example.com',
        university: prefs.getString('local_university') ?? 'COMSATS University Islamabad (Offline)',
        department: prefs.getString('local_department') ?? 'BSCS',
        timeline: prefs.getString('local_timeline') ?? '2023–2027',
      );
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final profile = await _firestoreService.getUserProfile(firebaseUser.uid);
      if (profile != null) {
        return AppUser(
          id: firebaseUser.uid,
          name: profile['name'] as String? ?? firebaseUser.displayName ?? 'Student',
          email: firebaseUser.email ?? '',
          university: profile['university'] as String? ?? 'COMSATS University Islamabad',
          department: profile['department'] as String? ?? 'BSCS',
          timeline: profile['timeline'] as String? ?? '2023–2027',
        );
      }
    } catch (_) {}

    return AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Student',
      email: firebaseUser.email ?? '',
      university: 'COMSATS University Islamabad',
      department: 'BSCS',
      timeline: '2023–2027',
    );
  }

  /// Logs the user in, using fallback local storage if in placeholder mode.
  Future<AppUser> login(String email, String password) async {
    if (isFallbackMode) {
      // Simulate validation
      if (!email.contains('@') || password.length < 6) {
        throw Exception('Invalid email format or password too short.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      // Derive name from email
      final name = email.split('@').first;
      final capitalizedName = name[0].toUpperCase() + name.substring(1);

      await prefs.setString(_keyName, capitalizedName);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyUid, 'offline_user_${name.hashCode}');

      return AppUser(
        id: 'offline_user_${name.hashCode}',
        name: capitalizedName,
        email: email,
        university: 'COMSATS University Islamabad (Offline)',
        department: 'BSCS',
        timeline: '2023–2027',
      );
    }

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('User was null after login.');
      }

      final appUser = await getCurrentUser();
      return appUser ?? AppUser(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Student',
        email: firebaseUser.email ?? '',
        university: 'COMSATS University Islamabad',
        department: 'BSCS',
        timeline: '2023–2027',
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled.';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred during login.');
    }
  }

  /// Registers a new user account, using fallback local storage if in placeholder mode.
  Future<AppUser> signup({
    required String name,
    required String email,
    required String university,
    required String department,
    required String timeline,
    required String password,
  }) async {
    if (isFallbackMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyName, name);
      await prefs.setString(_keyEmail, email);
      await prefs.setString('local_university', university);
      await prefs.setString('local_department', department);
      await prefs.setString('local_timeline', timeline);
      await prefs.setString(_keyUid, 'offline_user_${name.hashCode}');

      return AppUser(
        id: 'offline_user_${name.hashCode}',
        name: name,
        email: email,
        university: university,
        department: department,
        timeline: timeline,
      );
    }

    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('User creation failed.');
      }

      await firebaseUser.updateDisplayName(name);

      await _firestoreService.createUserProfile(
        uid: firebaseUser.uid,
        name: name,
        university: university,
        department: department,
        timeline: timeline,
      );

      return AppUser(
        id: firebaseUser.uid,
        name: name,
        email: email,
        university: university,
        department: department,
        timeline: timeline,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed.';
      if (e.code == 'email-already-in-use') {
        message = 'The email address is already in use by another account.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  /// Creates or updates a user profile collection document in Firestore.
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String university,
    required String department,
    required String timeline,
  }) async {
    if (isFallbackMode) return;
    await _firestoreService.createUserProfile(
      uid: uid,
      name: name,
      university: university,
      department: department,
      timeline: timeline,
    );
  }

  /// Signs the current user out.
  Future<void> logout() async {
    if (isFallbackMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return;
    }
    await _auth.signOut();
  }
}
