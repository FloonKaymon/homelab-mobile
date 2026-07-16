import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert_event.dart';
import 'alert_events_service.dart';
import 'auth_service.dart';

const _serviceId = 300;
const _baseUrlKey = 'modulabs_poll_base_url';
const _sinceKey = 'modulabs_alert_events_since';
const _seenIdsKey = 'modulabs_seen_alert_event_ids';

/// Runs the alert-polling loop as an Android foreground service so it keeps
/// checking `/api/alerts/events` every minute for newly triggered alerts and
/// shows a local notification for each one - even while the app is
/// backgrounded or has been killed by the OS. Started on login, stopped on
/// logout/server change (see `main.dart`).
class AlertPollingService {
  AlertPollingService._();

  /// Call once at app startup, before `runApp`.
  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'modulabs_alert_polling',
        channelName: 'Modulabs Alert Monitoring',
        channelDescription: 'Checks for new alerts every minute.',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
      ),
    );
  }

  /// Starts (or restarts, picking up a fresh base URL) the polling service.
  /// Best-effort: a denied permission just means fewer/no notifications,
  /// never a crash.
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
      notificationText: 'Monitoring alerts...',
      callback: startCallback,
    );
  }

  /// Stops the polling service and forgets the polling cursor, so re-login
  /// (possibly to a different Modulabs instance) starts from a clean slate.
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
  FlutterForegroundTask.setTaskHandler(_AlertPollingTaskHandler());
}

class _AlertPollingTaskHandler extends TaskHandler {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _channelReady = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _poll();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_poll());
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
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_baseUrlKey);
    final token = await AuthService.getToken();
    if (baseUrl == null || token == null) return;

    final since = prefs.getString(_sinceKey);

    AlertEventsPage page;
    try {
      page = await AlertEventsService.fetchEvents(baseUrl, token, since: since);
    } catch (_) {
      // Offline, Modulabs unreachable, expired token, etc. - just try again
      // next minute.
      return;
    }

    // Anchor on the server's own clock, not the phone's, so a clock
    // difference between the two can't cause missed or duplicated events.
    if (page.serverTime.isNotEmpty) {
      await prefs.setString(_sinceKey, page.serverTime);
    }

    // Events are emitted edge-trigger (once per threshold crossing), but
    // dedupe by id as a safety net in case of a retry/overlap.
    final seenIds = prefs.getStringList(_seenIdsKey) ?? const <String>[];
    final seenSet = seenIds.toSet();
    final newEvents = page.events.where((e) => !seenSet.contains(e.id.toString())).toList();

    final updatedIds = [...seenIds, ...newEvents.map((e) => e.id.toString())];
    final capped = updatedIds.length > 300 ? updatedIds.sublist(updatedIds.length - 300) : updatedIds;
    await prefs.setStringList(_seenIdsKey, capped);

    // First poll after (re)starting: `since` was null, so this just seeds
    // the server-time cursor instead of notifying for the entire history.
    if (since == null) return;

    for (final event in newEvents) {
      await _notify(event);
    }
  }

  Future<void> _notify(AlertEvent event) async {
    await _ensureChannel();

    final title = switch (event.severity) {
      'CRITICAL' => 'Critical alert',
      'HIGH' => 'Important alert',
      'MEDIUM' => 'Warning',
      'LOW' => 'Minor alert',
      _ => 'Modulabs alert',
    };
    final body = event.message.isNotEmpty
        ? event.message
        : '${event.ruleName}: ${event.metric} = ${event.value.toStringAsFixed(1)} (threshold ${event.threshold})';
    final importance = switch (event.severity) {
      'CRITICAL' || 'HIGH' => Importance.high,
      'MEDIUM' => Importance.defaultImportance,
      _ => Importance.low,
    };

    await _notifications.show(
      id: event.id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'modulabs_alerts',
          'Modulabs Alerts',
          channelDescription: 'Modulabs threshold-breach notifications',
          importance: importance,
          priority: importance == Importance.high ? Priority.high : Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> _ensureChannel() async {
    if (_channelReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(settings: const InitializationSettings(android: androidInit));

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'modulabs_alerts',
        'Modulabs Alerts',
        description: 'Modulabs threshold-breach notifications',
        importance: Importance.high,
      ),
    );

    _channelReady = true;
  }
}
