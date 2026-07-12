/// Mirrors the backend's `AlertEvent` entity (com.homelab.core.model.alert.AlertEvent),
/// as returned by the alert history endpoint. Fields are denormalized at
/// trigger time on the backend, so they stay meaningful even if the
/// underlying rule is later edited or deleted.
class AlertEvent {
  final int id;
  final String ruleName;
  final String metric;
  final String operator;
  final double threshold;
  final String severity;
  final double triggerValue;
  final String triggeredAt;
  final bool resolved;

  const AlertEvent({
    required this.id,
    required this.ruleName,
    required this.metric,
    required this.operator,
    required this.threshold,
    required this.severity,
    required this.triggerValue,
    required this.triggeredAt,
    required this.resolved,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) => AlertEvent(
        id: json['id'] as int,
        ruleName: json['ruleName'] as String? ?? '',
        metric: json['metric'] as String? ?? '',
        operator: json['operator'] as String? ?? '',
        threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
        severity: json['severity'] as String? ?? 'INFO',
        triggerValue: (json['triggerValue'] as num?)?.toDouble() ?? 0,
        triggeredAt: json['triggeredAt'] as String? ?? '',
        resolved: json['resolved'] as bool? ?? false,
      );

  String get operatorSymbol => operator == 'BELOW' ? '<' : '>';
}
