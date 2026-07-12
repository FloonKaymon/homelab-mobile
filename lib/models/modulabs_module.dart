/// Mirrors the backend's `ModuleStatus` enum (com.homelab.core.model.module.ModuleStatus).
enum ModuleRunStatus { active, inactive, installing, error, unknown }

ModuleRunStatus _statusFromApi(String? raw) {
  switch (raw) {
    case 'ACTIVE':
      return ModuleRunStatus.active;
    case 'INACTIVE':
      return ModuleRunStatus.inactive;
    case 'INSTALLING':
      return ModuleRunStatus.installing;
    case 'ERROR':
      return ModuleRunStatus.error;
    default:
      return ModuleRunStatus.unknown;
  }
}

/// Mirrors the backend's `ModuleDto` (com.homelab.core.api.dto.ModuleDto),
/// as returned by `GET /api/modules`.
class ModulabsModule {
  final String id;
  final String name;
  final String version;
  final String? description;
  final String? iconUrl;
  final ModuleRunStatus status;
  final bool hasParams;

  const ModulabsModule({
    required this.id,
    required this.name,
    required this.version,
    required this.status,
    this.description,
    this.iconUrl,
    this.hasParams = false,
  });

  bool get isActive => status == ModuleRunStatus.active;
  bool get isBusy => status == ModuleRunStatus.installing;

  factory ModulabsModule.fromJson(Map<String, dynamic> json) {
    return ModulabsModule(
      id: json['id'] as String,
      name: json['name'] as String,
      version: (json['version'] as String?) ?? '',
      description: json['description'] as String?,
      iconUrl: json['icon'] as String?,
      status: _statusFromApi(json['status'] as String?),
      hasParams: json['hasParams'] as bool? ?? false,
    );
  }
}
