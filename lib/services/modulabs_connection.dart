import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Result of attempting to reach a Homelab server.
enum ConnectionResult { success, unreachable, notHomelab, invalidUrl }

/// Stores and validates the URL of the Homelab instance the app talks to.
///
/// The URL is the first thing a user must configure: everything else
/// (module status, telemetry, notifications) is fetched relative to it.
class HomelabConnection {
  HomelabConnection._();

  static const _prefsKey = 'homelab_base_url';

  /// Returns the previously saved Homelab base URL, or null if none is set.
  static Future<String?> getSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  static Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Normalizes user input into a base URL with no trailing slash,
  /// defaulting to http:// when no scheme is given (most homelabs are
  /// reached over plain HTTP on the local network).
  static String? normalize(String input) {
    var value = input.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) {
      value = 'http://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    var normalized = uri.toString();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Verifies that [baseUrl] actually points to a reachable Homelab backend
  /// by calling the public, unauthenticated `/api/auth/challenge` endpoint.
  static Future<ConnectionResult> testConnection(String baseUrl) async {
    final normalized = normalize(baseUrl);
    if (normalized == null) return ConnectionResult.invalidUrl;

    try {
      final response = await http
          .get(Uri.parse('$normalized/api/auth/challenge'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return ConnectionResult.notHomelab;

      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('challenge')) {
        return ConnectionResult.success;
      }
      return ConnectionResult.notHomelab;
    } on TimeoutException {
      return ConnectionResult.unreachable;
    } catch (_) {
      return ConnectionResult.unreachable;
    }
  }
}
