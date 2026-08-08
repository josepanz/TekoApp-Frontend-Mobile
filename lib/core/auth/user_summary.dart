/// Subconjunto de `UserScopeResponseDTO.user` (backend, `GET /auth/scope`) necesario en el
/// cliente tras el login.
///
/// `referenceId` es el identificador público (UUID) — nunca el `id` interno del backend. OJO: en
/// la respuesta real de `GET /auth/scope` ese UUID viaja en un campo llamado literalmente `id`
/// (`AuthApiService.scope()` mapea `fullUser.referenceId` ahí) — no confundir con el `id` interno
/// numérico, que esa respuesta nunca expone (ver `.claude/rules/flutter-architecture.md`).
class UserSummary {
  const UserSummary({
    required this.referenceId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String referenceId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  /// URL presignada, resuelta fresca en cada `GET /auth/scope` (expira en 900s) — nunca persistir
  /// esto más allá de la sesión/pantalla actual, ver `.claude/rules/auth.md`.
  final String? avatarUrl;

  /// Recibe el objeto `user` de `UserScopeResponseDTO`, no la respuesta completa (que también
  /// trae `roles`/`permissions` como hermanos de `user`).
  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      referenceId: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
