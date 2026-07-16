import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/role.dart';
import '../models/user_dto.dart';
import 'api_exceptions.dart';

/// Admin-only role management (`/api/admin/roles`, `/api/admin/users`):
/// lists roles/users and assigns roles to a user.
class AdminRolesService {
  AdminRolesService._();

  static Map<String, String> _headers(String token) => {'Authorization': 'Bearer $token'};

  static Future<List<Role>> fetchRoles(String baseUrl, String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/roles'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => Role.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<UserDto>> fetchUsers(String baseUrl, String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admin/users'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => UserDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Replaces the full set of roles assigned to a user - not incremental,
  /// pass every role id the user should keep. An empty list clears them all.
  static Future<void> assignRoles(String baseUrl, String token, int userId, List<int> roleIds) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/admin/users/$userId/roles'),
          headers: {..._headers(token), 'Content-Type': 'application/json'},
          body: jsonEncode(roleIds),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode == 403) throw ForbiddenException();
    if (response.statusCode != 200) {
      throw Exception('Unable to assign roles.');
    }
  }
}
