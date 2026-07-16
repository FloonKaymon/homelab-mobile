/// Mirrors the backend's `BlockedWindow` (com.homelab.core.model.auth.BlockedWindow):
/// a recurring time window, local to the backend's timezone, during which a
/// role's access is blocked. `end < start` means the window crosses
/// midnight (e.g. 22:00 -> 07:00 = blocked overnight).
class BlockedWindow {
  final String dayOfWeek;
  final String start;
  final String end;

  const BlockedWindow({required this.dayOfWeek, required this.start, required this.end});

  factory BlockedWindow.fromJson(Map<String, dynamic> json) => BlockedWindow(
        dayOfWeek: json['dayOfWeek'] as String? ?? '',
        start: json['start'] as String? ?? '',
        end: json['end'] as String? ?? '',
      );
}

/// Mirrors the backend's `RoleDto` (com.homelab.core.api.dto.auth.RoleDto),
/// as returned by `GET /api/admin/roles`.
class Role {
  final int id;
  final String name;
  final List<String> moduleIds;
  final List<BlockedWindow> blockedWindows;

  const Role({
    required this.id,
    required this.name,
    required this.moduleIds,
    required this.blockedWindows,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        moduleIds: (json['moduleIds'] as List? ?? const []).map((e) => e as String).toList(),
        blockedWindows: (json['blockedWindows'] as List? ?? const [])
            .map((e) => BlockedWindow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
