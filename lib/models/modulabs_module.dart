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

  factory ModulabsModule.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    return ModulabsModule(
      id: json['id'] as String,
      name: json['name'] as String,
      version: (json['version'] as String?) ?? '',
      description: json['description'] as String?,
      iconUrl: _resolveIconUrl(json['icon'] as String?, baseUrl),
      status: _statusFromApi(json['status'] as String?),
      hasParams: json['hasParams'] as bool? ?? false,
    );
  }

  /// The backend exposes the icon as a *relative* path (e.g.
  /// `/api/modules/{id}/UI/icon`), which `Image.network` can't fetch on its own.
  /// Prefix it with the server's base URL so it resolves to an absolute URL. An
  /// already-absolute URL is passed through unchanged.
  static String? _resolveIconUrl(String? icon, String? baseUrl) {
    if (icon == null || icon.isEmpty) return null;
    if (icon.startsWith('http://') || icon.startsWith('https://')) return icon;
    if (baseUrl == null || baseUrl.isEmpty) return icon;
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final path = icon.startsWith('/') ? icon : '/$icon';
    return '$base$path';
  }
}
