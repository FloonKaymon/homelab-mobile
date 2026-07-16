import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exceptions.dart';

/// Admin-only system controls (`/api/admin/config`, `/api/admin/restart`):
/// restarts the backend container from inside the app.
class AdminSystemService {
  AdminSystemService._();

  static Map<String, String> _headers(String token) => {'Authorization': 'Bearer $token'};

  /// Whether the restart button should be enabled - false when the Docker
  /// socket isn't mounted on this deployment (see SystemRestartService).
  static Future<bool> fetchRestartAvailable(String baseUrl, String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/config'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return body is Map && body['restartAvailable'] == true;
  }

  /// Triggers a container restart. The connection can be cut by the restart
  /// itself before the HTTP response arrives - callers should treat a
  /// network failure here as a likely success, not an error.
  static Future<void> restart(String baseUrl, String token) async {
    final response = await http
        .post(Uri.parse('$baseUrl/api/admin/restart'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final message = body is Map ? body['message'] as String? : null;
      throw Exception(message ?? 'The restart failed.');
    }
  }
}
