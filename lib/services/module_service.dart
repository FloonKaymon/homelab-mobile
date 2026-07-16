import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/modulabs_module.dart';
import 'api_exceptions.dart';

export 'api_exceptions.dart' show UnauthorizedException;

/// Lists modules and drives their start/stop lifecycle against the Modulabs
/// backend (`/api/modules/**`).
class ModuleService {
  ModuleService._();

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
      };

  static Future<List<ModulabsModule>> fetchModules(String baseUrl, String token) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/modules'), headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => ModulabsModule.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> startModule(String baseUrl, String token, String id) =>
      _setRunning(baseUrl, token, id, start: true);

  static Future<void> stopModule(String baseUrl, String token, String id) =>
      _setRunning(baseUrl, token, id, start: false);

  static Future<void> _setRunning(String baseUrl, String token, String id, {required bool start}) async {
    final action = start ? 'start' : 'stop';
    final response = await http
        .post(Uri.parse('$baseUrl/api/modules/$id/$action'), headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode != 200) {
      throw Exception(start ? 'Unable to start the module.' : 'Unable to stop the module.');
    }

    final body = jsonDecode(response.body);
    if (body is Map && body['success'] != true) {
      throw Exception('The server rejected this action.');
    }
  }
}
