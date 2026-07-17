/// Mirrors the backend's `AlertEventDto` (com.homelab.core.api.dto.alert.AlertEventDto),
/// as returned by `GET /api/alerts/events`. Fields are denormalized at
/// trigger time on the backend, so they stay meaningful even if the
/// underlying rule is later edited or deleted.
class AlertEvent {
  final int id;

  /// What produced the event, from the backend `AlertSource` enum:
  /// `RULE` (a threshold rule fired), `ACCOUNT` (a sign-up awaits validation),
  /// or `ERROR` (the server logged an error). Drives the notification's title
  /// and, for `ERROR`, collapses repeats into a single notification.
  final String source;
  final int ruleId;
  final String ruleName;
  final String metric;
  final String severity;
  final double threshold;
  final double value;
  final String message;
  final String triggeredAt;

  const AlertEvent({
    required this.id,
    required this.source,
    required this.ruleId,
    required this.ruleName,
    required this.metric,
    required this.severity,
    required this.threshold,
    required this.value,
    required this.message,
    required this.triggeredAt,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) => AlertEvent(
        id: json['id'] as int,
        source: json['source'] as String? ?? 'RULE',
        ruleId: json['ruleId'] as int? ?? 0,
        ruleName: json['ruleName'] as String? ?? '',
        metric: json['metric'] as String? ?? '',
        severity: json['severity'] as String? ?? 'INFO',
        threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        message: json['message'] as String? ?? '',
        triggeredAt: json['triggeredAt'] as String? ?? '',
      );
}
