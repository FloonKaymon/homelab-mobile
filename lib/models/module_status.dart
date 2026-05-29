class ModuleStatus {
  final String name;
  final int defaultCpuUsage;
  final bool active;
  final int uptimeSeconds;

  const ModuleStatus({
    required this.name,
    required this.defaultCpuUsage,
    required this.active,
    this.uptimeSeconds = 0,
  });

  int get cpuUsage => active ? defaultCpuUsage : 0;

  String get formattedUptime {
    if (!active) return '';

    const int secondsPerMinute = 60;
    const int secondsPerHour = 3600;
    const int secondsPerDay = 86400;
    const int secondsPerWeek = 604800;
    const int secondsPerMonth = 2592000;
    const int secondsPerYear = 31536000;

    if (uptimeSeconds >= secondsPerYear) {
      final years = uptimeSeconds ~/ secondsPerYear;
      final remaining = uptimeSeconds % secondsPerYear;
      final months = remaining ~/ secondsPerMonth;
      return years == 1
        ? '${years}a ${months}m'
        : '${years}a ${months}m';
    } else if (uptimeSeconds >= secondsPerMonth) {
      final months = uptimeSeconds ~/ secondsPerMonth;
      final remaining = uptimeSeconds % secondsPerMonth;
      final weeks = remaining ~/ secondsPerWeek;
      return months == 1
        ? '${months}m ${weeks}s'
        : '${months}m ${weeks}s';
    } else if (uptimeSeconds >= secondsPerWeek) {
      final weeks = uptimeSeconds ~/ secondsPerWeek;
      final remaining = uptimeSeconds % secondsPerWeek;
      final days = remaining ~/ secondsPerDay;
      return weeks == 1
        ? '${weeks}s ${days}j'
        : '${weeks}s ${days}j';
    } else if (uptimeSeconds >= secondsPerDay) {
      final days = uptimeSeconds ~/ secondsPerDay;
      final remaining = uptimeSeconds % secondsPerDay;
      final hours = remaining ~/ secondsPerHour;
      return days == 1
        ? '${days}j ${hours}h'
        : '${days}j ${hours}h';
    } else if (uptimeSeconds >= secondsPerHour) {
      final hours = uptimeSeconds ~/ secondsPerHour;
      final remaining = uptimeSeconds % secondsPerHour;
      final minutes = remaining ~/ secondsPerMinute;
      return '${hours}h ${minutes}m';
    } else if (uptimeSeconds >= secondsPerMinute) {
      final minutes = uptimeSeconds ~/ secondsPerMinute;
      final seconds = uptimeSeconds % secondsPerMinute;
      return '${minutes}m ${seconds}s';
    } else {
      return '${uptimeSeconds}s';
    }
  }

  ModuleStatus copyWith({
    String? name,
    int? defaultCpuUsage,
    bool? active,
    int? uptimeSeconds,
  }) {
    return ModuleStatus(
      name: name ?? this.name,
      defaultCpuUsage: defaultCpuUsage ?? this.defaultCpuUsage,
      active: active ?? this.active,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
    );
  }
}
