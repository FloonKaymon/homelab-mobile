import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_modulab.dart';

/// Result of attempting to reach a Modulabs server.
enum ConnectionResult { success, unreachable, notModulabs, invalidUrl }

/// Stores and validates the URL of the Modulabs instance the app talks to.
///
/// The URL is the first thing a user must configure: everything else
/// (module status, telemetry, notifications) is fetched relative to it.
class ModulabsConnection {
  ModulabsConnection._();

  static const _prefsKey = 'modulabs_base_url';
  static const _savedListKey = 'modulabs_saved_connections';
  static const _activeIdKey = 'modulabs_active_connection_id';

  /// Returns the previously saved Modulabs base URL, or null if none is set.
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
    await prefs.remove(_activeIdKey);
  }

  /// All Modulabs instances the user has named and saved, in the order they
  /// were added.
  static Future<List<SavedModulab>> getSavedConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedListKey) ?? const [];
    return raw
        .map((s) => SavedModulab.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _writeConnections(List<SavedModulab> connections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _savedListKey,
      connections.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  /// Saves a new named connection and returns it.
  static Future<SavedModulab> addConnection({
    required String name,
    required String baseUrl,
  }) async {
    final connections = await getSavedConnections();
    final connection = SavedModulab(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      baseUrl: baseUrl,
    );
    await _writeConnections([...connections, connection]);
    return connection;
  }

  static Future<void> renameConnection(String id, String name) async {
    final connections = await getSavedConnections();
    await _writeConnections([
      for (final c in connections) c.id == id ? c.copyWith(name: name) : c,
    ]);
  }

  static Future<void> removeConnection(String id) async {
    final connections = await getSavedConnections();
    await _writeConnections(connections.where((c) => c.id != id).toList());
    final activeId = await getActiveConnectionId();
    if (activeId == id) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeIdKey);
    }
  }

  /// The id of the [SavedModulab] currently in use, if the active connection
  /// was picked from (or saved to) the named list.
  static Future<String?> getActiveConnectionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeIdKey);
  }

  static Future<void> setActiveConnectionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeIdKey, id);
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

  /// Verifies that [baseUrl] actually points to a reachable Modulabs backend
  /// by calling the public, unauthenticated `/api/auth/challenge` endpoint.
  static Future<ConnectionResult> testConnection(String baseUrl) async {
    final normalized = normalize(baseUrl);
    if (normalized == null) return ConnectionResult.invalidUrl;

    try {
      final response = await http
          .get(Uri.parse('$normalized/api/auth/challenge'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return ConnectionResult.notModulabs;

      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('challenge')) {
        return ConnectionResult.success;
      }
      return ConnectionResult.notModulabs;
    } on TimeoutException {
      return ConnectionResult.unreachable;
    } catch (_) {
      return ConnectionResult.unreachable;
    }
  }
}
