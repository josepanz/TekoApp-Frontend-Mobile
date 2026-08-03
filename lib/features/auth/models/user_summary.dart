/// Subconjunto de `UserResponseDTO` (backend) necesario en el cliente tras el login/`GET /auth/scope`.
///
/// `referenceId` es el identificador público (UUID) — nunca el `id` interno del backend, ni
/// siquiera si en algún momento el DTO lo expone (ver `.claude/rules/flutter-architecture.md`).
class UserSummary {
  const UserSummary({
    required this.referenceId,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  final String referenceId;
  final String email;
  final String firstName;
  final String lastName;

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      referenceId: json['referenceId'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }
}
