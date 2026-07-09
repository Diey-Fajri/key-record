import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();

  static bool _authenticated = false;
  static String _activeUser = '';
  static int failedAttempts = 0;
  static SharedPreferences? _prefs;
  static String? lastErrorMessage;

  static bool get isAuthenticated => _authenticated;
  static String get activeUser => _activeUser;
  static String get activeEmail {
    final firebaseEmail = _auth.currentUser?.email?.trim() ?? '';
    if (firebaseEmail.isNotEmpty) {
      return firebaseEmail;
    }
    return _prefs?.getString('storedEmail')?.trim() ?? '';
  }

  static bool get _firebaseAvailable => Firebase.apps.isNotEmpty;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    if (_firebaseAvailable) {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _authenticated = true;
        _activeUser = await _resolveFirebaseUsername(currentUser);
        await _prefs?.setBool('authenticated', true);
        await _prefs?.setString('activeUser', _activeUser);
        if (_activeUser.trim().isNotEmpty) {
          await _prefs?.setString('storedUsername', _activeUser);
        }
        return;
      }

      // Firebase is available but no signed-in user: treat as logged out.
      _authenticated = false;
      _activeUser = '';
      await _prefs?.remove('authenticated');
      await _prefs?.remove('activeUser');
      return;
    }

    // If Firebase is not available, never auto-unlock into dashboard.
    _authenticated = false;
    _activeUser = '';
  }

  static Future<String> _resolveFirebaseUsername(User currentUser) async {
    final saved = _prefs?.getString('storedUsername')?.trim() ?? '';
    if (saved.isNotEmpty) {
      return saved;
    }

    try {
      final byUid = await _firestore.collection('users').doc(currentUser.uid).get();
      final usernameByUid = (byUid.data()?['username'] as String?)?.trim() ?? '';
      if (usernameByUid.isNotEmpty) {
        return usernameByUid;
      }

      final normalizedEmail = _normalizeEmail(currentUser.email ?? '');
      if (normalizedEmail.isNotEmpty) {
        final byEmail = await _firestore
            .collection('users')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        final usernameByEmail = byEmail.docs.isEmpty
            ? ''
            : ((byEmail.docs.first.data()['username'] as String?)?.trim() ?? '');
        if (usernameByEmail.isNotEmpty) {
          return usernameByEmail;
        }
      }
    } catch (error) {
      debugPrint('AuthService: failed to resolve Firebase username: $error');
    }

    return _usernameFromEmail(currentUser.email);
  }

  static Future<bool> hasPermanentAccount() async {
    if (_firebaseAvailable) {
      final snapshot = await _firestore.collection('users').limit(1).get();
      return snapshot.docs.isNotEmpty;
    }
    final storedUser = _prefs?.getString('storedUsername');
    return storedUser != null;
  }

  static Future<bool> hasStoredCredentials() async {
    final storedUser = _prefs?.getString('storedUsername');
    final storedPass = _prefs?.getString('storedPassword');
    return storedUser != null && storedPass != null;
  }

  static Future<bool> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    lastErrorMessage = null;

    final normalizedEmail = _normalizeEmail(email);
    debugPrint('AuthService: login attempt for [$normalizedEmail]');
    if (normalizedEmail.isEmpty) {
      lastErrorMessage = 'Please enter a member email.';
      failedAttempts += 1;
      return false;
    }

    final storedPassword = _prefs?.getString('storedPassword');
    final storedEmail = _prefs?.getString('storedEmail');
    final storedUsername = _prefs?.getString('storedUsername');

    if (_firebaseAvailable) {
      if (storedPassword != null && storedPassword.isNotEmpty && storedEmail == normalizedEmail) {
        try {
          await _auth.signInWithEmailAndPassword(email: normalizedEmail, password: storedPassword);
          final user = _auth.currentUser;
          _authenticated = user != null;
          _activeUser = user == null
              ? ''
              : (storedUsername != null && storedUsername.isNotEmpty
                    ? storedUsername
                    : await _resolveFirebaseUsername(user));
          failedAttempts = 0;
          await _prefs?.setBool('authenticated', _authenticated);
          await _prefs?.setString('activeUser', _activeUser);
          await _prefs?.setString('storedEmail', normalizedEmail);
          if (_activeUser.isNotEmpty) {
            await _prefs?.setString('storedUsername', _activeUser);
          }
          return true;
        } on FirebaseAuthException catch (error) {
          if (shouldPromptForSetupAfterAuthError(error.code)) {
            await clearStoredCredentials();
            lastErrorMessage = 'Your saved sign-in details are no longer valid. Please set up your account again.';
            failedAttempts += 1;
            return true;
          }

          lastErrorMessage = _messageFromAuthError(error.code);
          failedAttempts += 1;
          return false;
        }
      }

      // No stored password yet: allow continuing to setup flow, but do not authenticate.
      _authenticated = false;
      _activeUser = '';
      await _prefs?.remove('authenticated');
      await _prefs?.remove('activeUser');
      await _prefs?.setString('storedEmail', normalizedEmail);
      return true;
    }

    if (storedPassword != null && storedPassword.isNotEmpty && storedEmail == normalizedEmail) {
      _authenticated = true;
      _activeUser = storedUsername ?? normalizedEmail;
      failedAttempts = 0;
      await _prefs?.setBool('authenticated', true);
      await _prefs?.setString('activeUser', _activeUser);
      return true;
    }

    failedAttempts += 1;
    return false;
  }

  static Future<void> createUser({required String username, required String password, required String email}) async {
    _authenticated = true;
    _activeUser = username;
    failedAttempts = 0;
    lastErrorMessage = null;

    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      lastErrorMessage = 'Please provide a member email.';
      return;
    }

    if (username.trim().isEmpty) {
      lastErrorMessage = 'Please choose a username.';
      return;
    }

    if (password.trim().isEmpty) {
      lastErrorMessage = 'Please choose a password.';
      return;
    }

    if (!isPasswordStrong(password)) {
      lastErrorMessage = 'Please use a 6-digit password.';
      return;
    }

    if (_firebaseAvailable) {
      try {
        await _auth.signInWithEmailAndPassword(email: normalizedEmail, password: password);
        final uid = _auth.currentUser?.uid ?? normalizedEmail;
        final profileDoc = await _firestore.collection('users').doc(uid).get();
        final existingUsername = profileDoc.data()?['username'] as String?;
        final finalUsername = (existingUsername != null && existingUsername.trim().isNotEmpty)
            ? existingUsername.trim()
            : username.trim();
        await _firestore.collection('users').doc(uid).set({
          'username': finalUsername,
          'email': normalizedEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _activeUser = finalUsername;
      } on FirebaseAuthException catch (error) {
        if (shouldCreateAccountAfterSignInError(error.code)) {
          try {
            await _auth.createUserWithEmailAndPassword(email: normalizedEmail, password: password);
            await _firestore.collection('users').doc(_auth.currentUser?.uid ?? normalizedEmail).set({
              'username': username.trim(),
              'email': normalizedEmail,
              'createdAt': FieldValue.serverTimestamp(),
              'passwordUpdatedAt': FieldValue.serverTimestamp(),
            });
          } on FirebaseAuthException catch (createError) {
            lastErrorMessage = _messageFromAuthError(createError.code);
            return;
          }
        } else {
          lastErrorMessage = _messageFromAuthError(error.code);
          return;
        }
      } catch (error) {
        debugPrint('AuthService: failed to save profile: $error');
        lastErrorMessage = 'Unable to create your account right now.';
        return;
      }
    }

    await _prefs?.setString('storedUsername', _activeUser.trim());
    await _prefs?.setString('storedEmail', normalizedEmail);
    await _prefs?.setString('storedPassword', password);
    await _prefs?.setBool('authenticated', true);
    await _prefs?.setString('activeUser', _activeUser.trim());
  }

  static Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || !_firebaseAvailable) {
      return null;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return snapshot.docs.first.data();
    } catch (error) {
      debugPrint('AuthService: failed to load user profile: $error');
      return null;
    }
  }

  static Future<bool> resetPassword({required String email}) async {
    lastErrorMessage = null;
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      lastErrorMessage = 'Please enter your email address.';
      return false;
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return true;
    } on FirebaseAuthException catch (error) {
      lastErrorMessage = _messageFromAuthError(error.code);
      return false;
    }
  }

  static bool isPasswordStrong(String password) {
    final trimmed = password.trim();
    return RegExp(r'^\d{6}$').hasMatch(trimmed);
  }

  static Future<void> logout() async {
    _authenticated = false;
    _activeUser = '';
    if (_firebaseAvailable) {
      await _auth.signOut();
    }
    await clearStoredCredentials();
    await _prefs?.remove('authenticated');
    await _prefs?.remove('activeUser');
  }

  static Future<void> clearStoredCredentials() async {
    await _prefs?.remove('storedUsername');
    await _prefs?.remove('storedEmail');
    await _prefs?.remove('storedPassword');
  }

  static Future<void> updateUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      return;
    }

    _activeUser = normalized;
    await _prefs?.setString('activeUser', normalized);
    await _prefs?.setString('storedUsername', normalized);

    if (_firebaseAvailable) {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': normalized,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final storedEmail = _prefs?.getString('storedEmail')?.trim();
        if (storedEmail != null && storedEmail.isNotEmpty) {
          final normalizedEmail = _normalizeEmail(storedEmail);
          final matches = await _firestore
              .collection('users')
              .where('email', isEqualTo: normalizedEmail)
              .limit(1)
              .get();

          if (matches.docs.isNotEmpty) {
            await matches.docs.first.reference.set({
              'username': normalized,
              'email': normalizedEmail,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } else {
            await _firestore.collection('users').doc(normalizedEmail).set({
              'username': normalized,
              'email': normalizedEmail,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }
    }
  }

  static bool shouldPromptForSetupAfterAuthError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
      case 'invalid-email':
      case 'network-request-failed':
        return true;
      default:
        return false;
    }
  }

  static bool shouldCreateAccountAfterSignInError(String code) {
    switch (code) {
      case 'user-not-found':
        return true;
      default:
        return false;
    }
  }

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String _messageFromAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This member account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'This member email is already registered.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'requires-recent-login':
        return 'Please sign in again and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static String _usernameFromEmail(String? email) {
    if (email == null) {
      return '';
    }
    return email.split('@').first;
  }
}
