/// Mirrors the backend's `CpuData` (com.homelab.core.model.telemetry.CpuData). Values in percent.
class CpuInfo {
  final double totalPercent;
  final double coreUsedPercent;

  const CpuInfo({required this.totalPercent, required this.coreUsedPercent});

  factory CpuInfo.fromJson(Map<String, dynamic> json) => CpuInfo(
        totalPercent: (json['total'] as num).toDouble(),
        coreUsedPercent: (json['coreUsed'] as num?)?.toDouble() ?? 0,
      );
}

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

/// Mirrors the backend's `ModuleStorageData`
/// (com.homelab.core.model.telemetry.ModuleStorageData).
class ModuleStorageData {
  final String id;
  final String name;
  final double storageGb;

  const ModuleStorageData({required this.id, required this.name, required this.storageGb});

  factory ModuleStorageData.fromJson(Map<String, dynamic> json) => ModuleStorageData(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        storageGb: (json['storageGb'] as num?)?.toDouble() ?? 0,
      );
}

/// Mirrors the backend's `TelemetryData` (com.homelab.core.model.telemetry.TelemetryData),
/// as returned by `GET /api/telemetry`.
class TelemetryData {
  final CpuInfo cpu;
  final RamInfo ram;
  final DiskInfo disk;
  final int activeModulesCount;
  final int uptimeSeconds;
  final List<ModuleStorageData> perModuleStorage;

  const TelemetryData({
    required this.cpu,
    required this.ram,
    required this.disk,
    required this.activeModulesCount,
    required this.uptimeSeconds,
    required this.perModuleStorage,
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
        cpu: CpuInfo.fromJson(json['cpu'] as Map<String, dynamic>),
        ram: RamInfo.fromJson(json['ram'] as Map<String, dynamic>),
        disk: DiskInfo.fromJson(json['disk'] as Map<String, dynamic>),
        activeModulesCount: json['activeModulesCount'] as int? ?? 0,
        uptimeSeconds: (json['uptime'] as num?)?.toInt() ?? 0,
        perModuleStorage: (json['perModuleStorage'] as List? ?? const [])
            .map((e) => ModuleStorageData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
