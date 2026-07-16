/// Mirrors the backend's `SignupRequestDto`, as returned by
/// `GET /api/admin/signup-requests`.
class SignupRequest {
  final int id;
  final String name;
  final String email;
  final String status;
  final String createdAt;
  final String? processedAt;

  const SignupRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory SignupRequest.fromJson(Map<String, dynamic> json) => SignupRequest(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        createdAt: json['createdAt'] as String? ?? '',
        processedAt: json['processedAt'] as String?,
      );
}
