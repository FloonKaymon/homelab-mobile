import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert_event.dart';
import 'alert_events_service.dart';
import 'alert_notifier.dart';
import 'auth_service.dart';

const _serviceId = 300;
const _baseUrlKey = 'modulabs_stream_base_url';
const _sinceKey = 'modulabs_alert_events_since';
const _seenIdsKey = 'modulabs_seen_alert_event_ids';
const _enabledKey = 'modulabs_alerts_enabled';

/// Delivers Modulabs alerts to the device by polling `GET /api/alerts/events`
/// every 30 seconds from inside an Android foreground service, so alerts keep
/// arriving even while the app is backgrounded or killed by the OS.
///
/// Each poll fetches everything triggered since the last server-time cursor and
/// raises one notification per new event (rule breach, account to validate, or
/// server error - see [AlertSource]). An id dedupe set makes re-fetching the
/// same event harmless. No third-party push server is involved: the phone talks
/// straight to the same backend it already uses for everything else.
///
/// Started on login, stopped on logout/server change (see `main.dart` /
/// [NotificationCoordinator]).
class AlertStreamService {
  AlertStreamService._();

  /// Call once at app startup, before `runApp`.
  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'modulabs_alert_stream',
        channelName: 'Modulabs Alert Monitoring',
        channelDescription: 'Checks for new alerts in the background.',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Poll for new alerts on this fixed cadence.
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
      ),
    );
  }

  /// Whether the user opted into background alerts (defaults to on).
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Persists the preference. Does not start/stop anything itself - the caller
  /// applies it via [NotificationCoordinator].
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Starts (or restarts, picking up a fresh base URL) the polling service.
  /// Best-effort: a denied permission just means fewer/no notifications, never a
  /// crash.
  static Future<void> start({required String baseUrl, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return;
    }

    if (await FlutterForegroundTask.checkNotificationPermission() != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    try {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (_) {
      // Best-effort - not fatal if the OEM/Android version doesn't support this.
    }

    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Modulabs',
      notificationText: 'Checking for new alerts',
      callback: startCallback,
    );
  }

  /// Stops the service and forgets the poll cursor, so re-login (possibly to a
  /// different Modulabs instance) starts from a clean slate.
  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    await prefs.remove(_sinceKey);
    await prefs.remove(_seenIdsKey);
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_AlertPollTaskHandler());
}

class _AlertPollTaskHandler extends TaskHandler {
  bool _polling = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _poll();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Fires every 30s (see initialize). Skip if the previous poll is still in
    // flight so a slow network can't stack overlapping requests.
    if (!_polling) unawaited(_poll());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString(_baseUrlKey);
      final token = await AuthService.getToken();
      if (baseUrl == null || token == null) return;
      await _catchUp(prefs, baseUrl, token);
    } catch (_) {
      // Swallow: a failed tick (offline, transient error) is retried on the next
      // 30s cycle. Never let it crash the foreground service.
    } finally {
      _polling = false;
    }
  }

  Future<void> _catchUp(SharedPreferences prefs, String baseUrl, String token) async {
    final since = prefs.getString(_sinceKey);
    AlertEventsPage page;
    try {
      page = await AlertEventsService.fetchEvents(baseUrl, token, since: since);
    } catch (_) {
      return; // Offline / unreachable - the next tick retries.
    }

    // Anchor on the server's clock, not the phone's, so clock drift can't cause
    // missed or duplicated events.
    if (page.serverTime.isNotEmpty) {
      await prefs.setString(_sinceKey, page.serverTime);
    }

    final seen = (prefs.getStringList(_seenIdsKey) ?? const <String>[]).toList();
    final seenSet = seen.toSet();
    final fresh = page.events.where((e) => !seenSet.contains(e.id.toString())).toList();

    final updated = [...seen, ...fresh.map((e) => e.id.toString())];
    final capped = updated.length > 300 ? updated.sublist(updated.length - 300) : updated;
    await prefs.setStringList(_seenIdsKey, capped);

    // First poll after a fresh (re)start: `since` was null, so this only seeds
    // the cursor + dedupe set instead of replaying all history as a burst of
    // notifications. New events fired after this get notified on the next tick.
    if (since == null) return;

    for (final event in fresh) {
      await _notify(event);
    }
  }

  Future<void> _notify(AlertEvent event) async {
    final body = event.message.isNotEmpty
        ? event.message
        : '${event.ruleName}: ${event.metric} = ${event.value.toStringAsFixed(1)} (threshold ${event.threshold})';
    await AlertNotifier.show(
      id: event.id,
      source: event.source,
      severity: event.severity,
      message: body,
    );
  }
}
