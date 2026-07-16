import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/password_reset_request.dart';
import 'api_exceptions.dart';

/// Admin-only moderation of self-service "small reset" requests
/// (`/api/admin/password-reset-requests/**`): lists pending requests and
/// approves (issuing a one-time temporary password) or rejects them.
class AdminPasswordResetService {
  AdminPasswordResetService._();

  static Map<String, String> _headers(String token) => {'Authorization': 'Bearer $token'};

  static Future<List<PasswordResetRequest>> fetchRequests(String baseUrl, String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/password-reset-requests'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => PasswordResetRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Approves the request and returns the one-time temporary password the
  /// backend just issued - shown once to the admin, who is responsible for
  /// communicating it to the user out of band.
  static Future<String> approve(String baseUrl, String token, int id) async {
    final response = await http
        .put(Uri.parse('$baseUrl/api/admin/password-reset-requests/$id/approve'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    _checkStatus(response);
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final temporaryPassword = body is Map ? body['temporaryPassword'] as String? : null;
    if (temporaryPassword == null) {
      throw Exception('The server did not return a temporary password.');
    }
    return temporaryPassword;
  }

  static Future<void> reject(String baseUrl, String token, int id) async {
    final response = await http
        .put(Uri.parse('$baseUrl/api/admin/password-reset-requests/$id/reject'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));
    _checkStatus(response);
  }

  static void _checkStatus(http.Response response) {
    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode == 404) {
      throw Exception('This request could not be found.');
    }
    if (response.statusCode == 400) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body is Map ? body['message'] as String? : null;
      throw Exception(message ?? 'This request has already been processed.');
    }
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }
  }
}
