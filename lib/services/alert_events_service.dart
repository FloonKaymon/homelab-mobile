import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alert_event.dart';
import 'api_exceptions.dart';

/// Result of a single `GET /api/alerts/events` call: the server's own clock
/// (to store and replay as `since` on the next poll, avoiding phone/server
/// clock drift) plus the events triggered since the last poll.
class AlertEventsPage {
  final String serverTime;
  final List<AlertEvent> events;

  const AlertEventsPage({required this.serverTime, required this.events});
}

/// Fetches alert events from the Modulabs backend (`GET /api/alerts/events`).
/// Available to any authenticated user (not admin-gated), so the mobile app
/// can poll it for notifications.
class AlertEventsService {
  AlertEventsService._();

  static Future<AlertEventsPage> fetchEvents(
    String baseUrl,
    String token, {
    String? since,
  }) async {
    final uri = Uri.parse('$baseUrl/api/alerts/events').replace(
      queryParameters: since != null ? {'since': since} : null,
    );
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 401) throw UnauthorizedException();
    if (response.statusCode != 200) {
      throw Exception('The server responded with code ${response.statusCode}.');
    }

    // The backend sends `application/json` without a charset, so decode the
    // raw bytes as UTF-8 explicitly - otherwise Dart's http package falls
    // back to latin1 and accented text (e.g. "Mémoire") arrives mangled.
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) {
      throw Exception('Alert history is currently unavailable.');
    }

    final events = (body['events'] as List? ?? const [])
        .map((e) => AlertEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    return AlertEventsPage(
      serverTime: body['serverTime'] as String? ?? '',
      events: events,
    );
  }
}
