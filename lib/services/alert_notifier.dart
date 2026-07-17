import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Renders an alert as an Android notification.
///
/// Used by the polling delivery path (`alert_stream_service.dart`) for every
/// event fetched from the backend, so every alert produces an identical
/// notification.
///
/// Safe to call from a background isolate (the foreground task that runs the
/// poll loop lives outside the UI isolate).
class AlertNotifier {
  AlertNotifier._();

  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _channelReady = false;

  /// Fixed notification id for server-error alerts. Reusing one id means a new
  /// error notification *replaces* the previous one instead of stacking, so the
  /// user only ever sees a single "an error occurred" entry (the backend already
  /// coalesces bursts; this collapses the display too). Picked high enough that a
  /// database-generated event id can't realistically collide with it.
  static const int _errorNotificationId = 2000000001;

  /// Shows a notification for one alert. [severity] is the backend enum name
  /// (`CRITICAL`/`HIGH`/`MEDIUM`/`LOW`/…), which drives the importance; [source]
  /// (`RULE`/`ACCOUNT`/`ERROR`) refines the title and, for `ERROR`, forces a
  /// fixed notification id so repeats collapse into one.
  static Future<void> show({
    required int id,
    required String source,
    required String severity,
    required String message,
  }) async {
    await _ensureChannel();

    final title = switch (source) {
      'ERROR' => 'Server error',
      'ACCOUNT' => 'Account to validate',
      _ => switch (severity) {
          'CRITICAL' => 'Critical alert',
          'HIGH' => 'Important alert',
          'MEDIUM' => 'Warning',
          'LOW' => 'Minor alert',
          _ => 'Modulabs alert',
        },
    };
    // A new-account request is only MEDIUM severity, but the admin needs to act
    // on it, so surface it as a heads-up (banner + sound) like a high alert
    // regardless of severity. Everything else follows its severity.
    final importance = source == 'ACCOUNT'
        ? Importance.high
        : switch (severity) {
            'CRITICAL' || 'HIGH' => Importance.high,
            'MEDIUM' => Importance.defaultImportance,
            _ => Importance.low,
          };

    await _notifications.show(
      id: source == 'ERROR' ? _errorNotificationId : id,
      title: title,
      body: message,
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

  static Future<void> _ensureChannel() async {
    if (_channelReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(settings: const InitializationSettings(android: androidInit));

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // NB: do NOT request the notification permission here. This runs in the
    // foreground-service background isolate, whose FlutterEngine has no Activity
    // attached, so `requestNotificationsPermission()` dereferences a null
    // Activity and throws - which would abort channel creation below and leave
    // `show()` silently posting nothing. The permission is requested from the UI
    // isolate instead (see AlertStreamService.start).
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
