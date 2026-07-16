import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/user_dto.dart';

enum LoginResult { success, invalidCredentials, unreachable, error }

/// Handles login against the Modulabs backend and persists the resulting
/// JWT session (token + user email) in the platform secure storage.
class AuthService {
  AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'modulabs_jwt_token';
  static const _emailKey = 'modulabs_user_email';

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<String?> getUserEmail() => _storage.read(key: _emailKey);

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }

  static Future<LoginResult> login(String baseUrl, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401) return LoginResult.invalidCredentials;
      if (response.statusCode != 200) return LoginResult.error;

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final token = body is Map ? body['token'] as String? : null;
      if (body is Map && body['success'] == true && token != null) {
        final userEmail = (body['userEmail'] as String?) ?? email;
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _emailKey, value: userEmail);
        return LoginResult.success;
      }
      return LoginResult.invalidCredentials;
    } on TimeoutException {
      return LoginResult.unreachable;
    } catch (_) {
      return LoginResult.unreachable;
    }
  }

  /// Fetches the currently authenticated user (`GET /api/auth/me`), used to
  /// decide whether to show the admin section (accounts / roles) in the UI.
  /// Returns null on any failure - callers should treat that as "not admin"
  /// rather than blocking the rest of the app.
  static Future<UserDto?> fetchCurrentUser(String baseUrl, String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      return UserDto.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Submits a "small reset" request (`POST /api/auth/password-reset-requests`):
  /// an admin must approve it before a temporary password is issued. Always
  /// returns a generic success message - the backend replies the same way
  /// whether or not the email exists, to avoid leaking registered accounts.
  static Future<bool> requestPasswordReset(String baseUrl, String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/password-reset-requests'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Self-service password change (`PUT /api/auth/password`). [currentPassword]
  /// is required unless the session came from a one-time temporary password
  /// (`mustResetPassword`), where the login itself already proved identity.
  static Future<UpdatePasswordResult> updatePassword(
    String baseUrl,
    String token, {
    String? currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/auth/password'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'currentPassword': ?currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 401) return UpdatePasswordResult.unauthorized;
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 && body is Map && body['success'] == true) {
        return UpdatePasswordResult.success;
      }
      if (response.statusCode == 403) return UpdatePasswordResult.wrongCurrentPassword;
      return UpdatePasswordResult.error;
    } catch (_) {
      return UpdatePasswordResult.unreachable;
    }
  }
}

enum UpdatePasswordResult { success, wrongCurrentPassword, unauthorized, unreachable, error }
