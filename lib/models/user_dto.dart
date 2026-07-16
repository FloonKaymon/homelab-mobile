/// Mirrors the backend's `UserDto` (com.homelab.core.api.dto.auth.UserDto),
/// as returned by `GET /api/auth/me` and `GET /api/admin/users`.
class UserDto {
  final int id;
  final String email;
  final String name;
  final bool isAdmin;
  final List<int> roleIds;
  final bool mustResetPassword;

  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.isAdmin,
    required this.roleIds,
    required this.mustResetPassword,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as int,
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        isAdmin: json['isAdmin'] as bool? ?? false,
        roleIds: (json['roleIds'] as List? ?? const []).map((e) => e as int).toList(),
        mustResetPassword: json['mustResetPassword'] as bool? ?? false,
      );
}
