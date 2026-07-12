import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alert_event.dart';
import 'api_exceptions.dart';

/// Fetches recently triggered alert events from the Modulabs backend.
///
/// Hits `GET /api/alerts/events` - a **non-admin** counterpart to the
/// existing admin-only `/api/admin/alerts/events` (same response shape,
/// same `?limit=` param). This endpoint does not exist on the backend yet;
/// it needs to be added there (see alerts-and-push-notifications.md) before
/// polling can work end-to-end. Any authenticated user can call it, matching
/// how `/api/devices` was deliberately made non-admin-gated.
class AlertEventsService {
  AlertEventsService._();

  static Future<List<AlertEvent>> fetchRecentEvents(
    String baseUrl,
    String token, {
    int limit = 20,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/alerts/events?limit=$limit'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode != 200) {
      throw Exception('Le serveur a répondu avec le code ${response.statusCode}.');
    }

    final body = jsonDecode(response.body);
    if (body is! List) {
      throw Exception('Historique des alertes indisponible pour le moment.');
    }

    return body.map((e) => AlertEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
