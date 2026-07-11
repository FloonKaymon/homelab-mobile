import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush/unifiedpush.dart';

/// Registers this app with a UnifiedPush distributor (e.g. the ntfy app,
/// pointed at a self-hosted ntfy server) and relays the resulting endpoint to
/// the Homelab backend so it can push alert notifications. Mirrors the
/// static-class + plain `http` pattern used by `AuthService`/`ModuleService`.
class PushService {
  PushService._();

  static const _instance = 'homelab-mobile';
  static const _endpointPrefsKey = 'homelab_push_endpoint';

  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _channelReady = false;

  static Future<void> initialize({required String baseUrl, required String token}) async {
    await _ensureNotificationChannel();

    // initialize() returns true iff a distributor is already saved from a
    // previous run - in that case we can register directly. Otherwise we
    // need to pick a distributor first (see below).
    final alreadyHasDistributor = await UnifiedPush.initialize(
      onNewEndpoint: (endpoint, instance) => _onNewEndpoint(endpoint, instance, baseUrl, token),
      onRegistrationFailed: (_, _) {},
      onUnregistered: (instance) => _onUnregistered(instance, baseUrl, token),
      onMessage: _onMessage,
    );

    if (!alreadyHasDistributor) {
      final gotDistributor = await UnifiedPush.tryUseCurrentOrDefaultDistributor();
      if (!gotDistributor) {
        // No distributor saved yet - if exactly one UnifiedPush-capable app
        // (e.g. ntfy) is installed, use it automatically. Otherwise there's
        // nothing to register against until the user installs one.
        final distributors = await UnifiedPush.getDistributors();
        if (distributors.isEmpty) return;
        await UnifiedPush.saveDistributor(distributors.first);
      }
    }

    await UnifiedPush.register(instance: _instance);
  }

  /// Unregisters this device from both the distributor and the backend.
  /// Call on logout / server change so a stale session doesn't keep
  /// receiving (and silently dropping) pushes for no one.
  static Future<void> teardown(String baseUrl, String token) async {
    final endpoint = await getStoredEndpoint();
    if (endpoint != null) {
      await unregisterEndpoint(baseUrl, token, endpoint);
    }
    try {
      await UnifiedPush.unregister(_instance);
    } catch (_) {
      // Best-effort - the distributor may already consider us unregistered.
    }
  }

  static Future<String?> getStoredEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_endpointPrefsKey);
  }

  static Future<void> registerEndpoint(String baseUrl, String token, String endpointUrl) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/devices'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
            body: jsonEncode({'endpointUrl': endpointUrl}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Best-effort: a failed registration here just means push won't arrive
      // until the next successful retry (e.g. the next app open).
    }
  }

  static Future<void> unregisterEndpoint(String baseUrl, String token, String endpointUrl) async {
    try {
      await http
          .delete(
            Uri.parse('$baseUrl/api/devices'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
            body: jsonEncode({'endpointUrl': endpointUrl}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static Future<void> _onNewEndpoint(
    PushEndpoint endpoint,
    String instance,
    String baseUrl,
    String token,
  ) async {
    if (instance != _instance) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointPrefsKey, endpoint.url);
    await registerEndpoint(baseUrl, token, endpoint.url);
  }

  static Future<void> _onUnregistered(String instance, String baseUrl, String token) async {
    if (instance != _instance) return;
    final prefs = await SharedPreferences.getInstance();
    final endpoint = prefs.getString(_endpointPrefsKey);
    if (endpoint == null) return;
    await unregisterEndpoint(baseUrl, token, endpoint);
    await prefs.remove(_endpointPrefsKey);
  }

  static void _onMessage(PushMessage message, String instance) {
    if (instance != _instance) return;
    if (!message.decrypted) {
      // Payload uses Web Push encryption this app doesn't implement yet -
      // nothing readable to show. See push_service.dart's docs / project
      // notes: the backend currently sends plaintext content.
      return;
    }

    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(utf8.decode(message.content)) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final title = payload['title'] as String? ?? 'Alerte Homelab';
    final body = payload['body'] as String? ?? '';
    unawaited(_showNotification(title, body));
  }

  static Future<void> _ensureNotificationChannel() async {
    if (_channelReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidInit),
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'homelab_alerts',
        'Alertes Homelab',
        description: 'Notifications de dépassement de seuil du Homelab',
        importance: Importance.high,
      ),
    );

    _channelReady = true;
  }

  static Future<void> _showNotification(String title, String body) async {
    await _ensureNotificationChannel();
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'homelab_alerts',
          'Alertes Homelab',
          channelDescription: 'Notifications de dépassement de seuil du Homelab',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
