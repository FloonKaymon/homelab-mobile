import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

enum LoginResult { success, invalidCredentials, unreachable, error }

/// Handles login against the Homelab backend and persists the resulting
/// JWT session (token + user email) in the platform secure storage.
class AuthService {
  AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'homelab_jwt_token';
  static const _emailKey = 'homelab_user_email';

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

      final body = jsonDecode(response.body);
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

  /// Confirms a previously stored token is still accepted by the server,
  /// using the lightweight authenticated `/api/telemetry` endpoint as a probe.
  static Future<bool> verifyToken(String baseUrl, String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/telemetry'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
