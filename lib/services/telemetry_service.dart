import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/telemetry_data.dart';
import 'api_exceptions.dart';

/// Fetches system resource usage (CPU/RAM/disk) from the Homelab backend.
class TelemetryService {
  TelemetryService._();

  static Future<TelemetryData> fetchTelemetry(String baseUrl, String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/telemetry'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode != 200) {
      throw Exception('Le serveur a répondu avec le code ${response.statusCode}.');
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Télémétrie indisponible pour le moment.');
    }

    return TelemetryData.fromJson(body);
  }
}
