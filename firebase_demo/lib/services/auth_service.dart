import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'firebase_client.dart';

class AppUser {
  String $id;
  String? name;
  String? email;

  AppUser({required this.$id, this.name, this.email});
}

class AuthService {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Future<bool> isLoggedIn() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) return false;
      _currentUser = AppUser(
        $id: user.uid,
        name: user.displayName,
        email: user.email,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<AppUser?> getCurrentUser() async {
    try {
      final user = FirebaseService.auth.currentUser;
      if (user == null) return null;
      _currentUser = AppUser(
        $id: user.uid,
        name: user.displayName ?? user.email?.split('@').first,
        email: user.email,
      );
      return _currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<AppUser?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await FirebaseService.auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(name);

      final user = credential.user;
      if (user == null) throw 'Registration failed: no user returned';

      _currentUser = AppUser(
        $id: user.uid,
        name: user.displayName ?? name,
        email: user.email,
      );
      debugPrint('User registered and logged in: ${_currentUser!.$id}');
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Error during registration: ${e.message}');
      throw e.message ?? 'Registration failed';
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      throw 'Registration failed: $e';
    }
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw 'Login failed: no user returned';
      _currentUser = AppUser(
        $id: user.uid,
        name: user.displayName ?? user.email?.split('@').first,
        email: user.email,
      );
      debugPrint('User logged in: ${_currentUser!.$id}');
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Error during login: ${e.message}');
      throw e.message ?? 'Login failed';
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      throw 'Login failed: $e';
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseService.auth.signOut();
      _currentUser = null;
      debugPrint('User logged out successfully');
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Error during logout: ${e.message}');
      throw e.message ?? 'Logout failed';
    } catch (e) {
      debugPrint('Unexpected error during logout: $e');
      throw 'Logout failed: $e';
    }
  }

  Future<AppUser?> signInAnonymously() async {
    try {
      final existing = FirebaseService.auth.currentUser;
      if (existing != null) {
        _currentUser = AppUser(
          $id: existing.uid,
          name: existing.displayName,
          email: existing.email,
        );
        debugPrint('Already logged in as: ${_currentUser!.$id}');
        return _currentUser;
      }

      final result = await FirebaseService.auth.signInAnonymously();
      final user = result.user;
      if (user == null) return null;
      _currentUser = AppUser(
        $id: user.uid,
        name: user.displayName,
        email: user.email,
      );
      debugPrint('Anonymous user id: ${_currentUser!.$id}');
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('Error during anonymous sign-in: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error during sign-in: $e');
      return null;
    }
  }
}
