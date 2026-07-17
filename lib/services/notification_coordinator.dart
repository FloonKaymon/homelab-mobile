import 'alert_stream_service.dart';

/// Front door for alert delivery. Alerts reach the device by polling the
/// Modulabs backend every 30 seconds from [AlertStreamService]'s foreground
/// service (works off the home network, survives the app being backgrounded).
/// This indirection keeps `main.dart` and the settings screen decoupled from
/// the transport.
class NotificationCoordinator {
  NotificationCoordinator._();

  /// Starts alert delivery for [baseUrl], unless the user turned it off.
  static Future<void> start({required String baseUrl, required String token}) async {
    if (!await AlertStreamService.isEnabled()) return;
    await AlertStreamService.start(baseUrl: baseUrl, token: token);
  }

  /// Tears delivery down (logout / server change). No-op if never started.
  static Future<void> stop() async {
    await AlertStreamService.stop();
  }

  /// Applies the user toggling alerts on/off in Settings: persists the
  /// preference, then starts or stops the stream accordingly.
  static Future<void> setEnabled(
    bool enabled, {
    required String baseUrl,
    required String token,
  }) async {
    await AlertStreamService.setEnabled(enabled);
    if (enabled) {
      await AlertStreamService.start(baseUrl: baseUrl, token: token);
    } else {
      await AlertStreamService.stop();
    }
  }
}
