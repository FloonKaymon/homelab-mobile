/// Mirrors the backend's `PasswordResetRequestDto`, as returned by
/// `GET /api/admin/password-reset-requests`.
class PasswordResetRequest {
  final int id;
  final String email;
  final String status;
  final String createdAt;
  final String? processedAt;

  const PasswordResetRequest({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) => PasswordResetRequest(
        id: json['id'] as int,
        email: json['email'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        createdAt: json['createdAt'] as String? ?? '',
        processedAt: json['processedAt'] as String?,
      );
}
