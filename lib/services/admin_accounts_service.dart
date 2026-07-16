import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/signup_request.dart';
import 'api_exceptions.dart';

/// Admin-only account-validation moderation
/// (`/api/admin/signup-requests/**`): lists pending signup requests and
/// approves/rejects them.
class AdminAccountsService {
  AdminAccountsService._();

  static Map<String, String> _headers(String token) => {'Authorization': 'Bearer $token'};

  static Future<List<SignupRequest>> fetchSignupRequests(String baseUrl, String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/signup-requests'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => SignupRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// At least one role must be assigned as part of approval, or the backend
  /// rejects the request with 400 - the resulting account can't be left
  /// roleless (see AdminController.approveSignupRequest).
  static Future<void> approve(String baseUrl, String token, int id, List<int> roleIds) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/admin/signup-requests/$id/approve'),
          headers: {..._headers(token), 'Content-Type': 'application/json'},
          body: jsonEncode({'roleIds': roleIds}),
        )
        .timeout(const Duration(seconds: 10));
    _checkProcessResponse(response);
  }

  static Future<void> reject(String baseUrl, String token, int id) async {
    final response = await http
        .put(Uri.parse('$baseUrl/api/admin/signup-requests/$id/reject'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));
    _checkProcessResponse(response);
  }

  static void _checkProcessResponse(http.Response response) {
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

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is Map && body['success'] != true) {
      throw Exception('The server rejected this action.');
    }
  }
}
