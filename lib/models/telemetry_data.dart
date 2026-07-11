/// Mirrors the backend's `RamData` (com.homelab.core.model.telemetry.RamData). Values in GB.
class RamInfo {
  final double totalGb;
  final double usedGb;
  final double coreUsedGb;
  final double modulesUsedGb;

  const RamInfo({
    required this.totalGb,
    required this.usedGb,
    required this.coreUsedGb,
    required this.modulesUsedGb,
  });

  double get usedFraction => totalGb <= 0 ? 0 : (usedGb / totalGb).clamp(0, 1).toDouble();

  factory RamInfo.fromJson(Map<String, dynamic> json) => RamInfo(
        totalGb: (json['total'] as num).toDouble(),
        usedGb: (json['used'] as num).toDouble(),
        coreUsedGb: (json['coreUsed'] as num).toDouble(),
        modulesUsedGb: (json['modulesUsed'] as num).toDouble(),
      );
}

/// Mirrors the backend's `DiskData` (com.homelab.core.model.telemetry.DiskData). Values in GB.
class DiskInfo {
  final double totalGb;
  final double usedGb;
  final double coreStorageUsedGb;
  final double modulesStorageUsedGb;

  const DiskInfo({
    required this.totalGb,
    required this.usedGb,
    required this.coreStorageUsedGb,
    required this.modulesStorageUsedGb,
  });

  double get usedFraction => totalGb <= 0 ? 0 : (usedGb / totalGb).clamp(0, 1).toDouble();

  factory DiskInfo.fromJson(Map<String, dynamic> json) => DiskInfo(
        totalGb: (json['total'] as num).toDouble(),
        usedGb: (json['used'] as num).toDouble(),
        coreStorageUsedGb: (json['coreStorageUsed'] as num).toDouble(),
        modulesStorageUsedGb: (json['modulesStorageUsed'] as num).toDouble(),
      );
}

/// Mirrors the backend's `TelemetryData` (com.homelab.core.model.telemetry.TelemetryData),
/// as returned by `GET /api/telemetry`.
class TelemetryData {
  final double cpuPercent;
  final RamInfo ram;
  final DiskInfo disk;
  final int activeModulesCount;
  final int uptimeSeconds;

  const TelemetryData({
    required this.cpuPercent,
    required this.ram,
    required this.disk,
    required this.activeModulesCount,
    required this.uptimeSeconds,
  });

  String get formattedUptime {
    final days = uptimeSeconds ~/ 86400;
    final hours = (uptimeSeconds % 86400) ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    if (days > 0) return '${days}j ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  factory TelemetryData.fromJson(Map<String, dynamic> json) => TelemetryData(
        cpuPercent: (json['cpu'] as num).toDouble(),
        ram: RamInfo.fromJson(json['ram'] as Map<String, dynamic>),
        disk: DiskInfo.fromJson(json['disk'] as Map<String, dynamic>),
        activeModulesCount: json['activeModulesCount'] as int? ?? 0,
        uptimeSeconds: (json['uptime'] as num?)?.toInt() ?? 0,
      );
}
