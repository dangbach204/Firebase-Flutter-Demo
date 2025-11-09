import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'appwrite_client.dart';

class AuthService {
  final Account _account = AppwriteService.account;

  models.User? _currentUser;

  models.User? get currentUser => _currentUser;

  /// Helper method to get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Kiểm tra lỗi kết nối internet
    if (errorString.contains('socketsexception') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated') ||
        errorString.contains('timeout')) {
      return 'Không có kết nối internet. Vui lòng kiểm tra mạng và thử lại.';
    }

    if (error is AppwriteException) {
      final message = error.message?.toLowerCase() ?? '';

      if (message.contains('network') ||
          message.contains('connection') ||
          message.contains('timeout')) {
        return 'Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.';
      }

      return error.message ?? 'Đã xảy ra lỗi';
    }

    return error.toString();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      _currentUser = await _account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current user
  Future<models.User?> getCurrentUser() async {
    try {
      _currentUser = await _account.get();
      return _currentUser;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Register new user with email and password
  Future<models.User?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create account
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      debugPrint('Account created successfully');

      // Automatically log in after registration
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      debugPrint('Session created after registration');

      // Get user details
      _currentUser = await _account.get();
      debugPrint('User registered and logged in: ${_currentUser!.$id}');

      return _currentUser;
    } on AppwriteException catch (e) {
      debugPrint('Error during registration: ${e.message}');
      throw _getErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      throw _getErrorMessage(e);
    }
  }

  /// Login with email and password
  Future<models.User?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Create email session
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      debugPrint('Session created successfully');

      // Get user details
      _currentUser = await _account.get();
      debugPrint('User logged in: ${_currentUser!.$id}');

      return _currentUser;
    } on AppwriteException catch (e) {
      debugPrint('Error during login: ${e.message}');
      throw _getErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during login: $e');
      throw _getErrorMessage(e);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Delete current session
      await _account.deleteSession(sessionId: 'current');
      _currentUser = null;
      debugPrint('User logged out successfully');
    } on AppwriteException catch (e) {
      debugPrint('Error during logout: ${e.message}');
      throw _getErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during logout: $e');
      throw _getErrorMessage(e);
    }
  }

  /// Sign in anonymously (for testing)
  Future<models.User?> signInAnonymously() async {
    try {
      try {
        _currentUser = await _account.get();
        debugPrint('Already logged in as: ${_currentUser!.$id}');
        return _currentUser;
      } catch (e) {
        debugPrint('No active session, creating anonymous session...');
      }

      final session = await _account.createAnonymousSession();
      debugPrint('Anonymous session created: ${session.$id}');

      _currentUser = await _account.get();
      debugPrint('User ID: ${_currentUser!.$id}');

      return _currentUser;
    } on AppwriteException catch (e) {
      debugPrint('Error during anonymous sign-in: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error during sign-in: $e');
      return null;
    }
  }

  /// Login as guest with fixed credentials
  Future<models.User?> loginAsGuest() async {
    const guestEmail = 'guest@example.com';
    const guestPassword = 'Password';

    try {
      await _account.createEmailPasswordSession(
        email: guestEmail,
        password: guestPassword,
      );
      debugPrint('Guest session created successfully');

      _currentUser = await _account.get();
      debugPrint('Guest logged in: ${_currentUser!.$id}');

      return _currentUser;
    } on AppwriteException catch (e) {
      debugPrint('Error during guest login: ${e.message}');
      throw _getErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected error during guest login: $e');
      throw _getErrorMessage(e);
    }
  }
}
