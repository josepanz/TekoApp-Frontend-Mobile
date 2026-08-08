/// Resultado de `AuthRepository.login()` — espejo de `LoginUserResponseDTO` del backend, sin
/// `refreshToken` (nunca viaja en el body, solo como cookie httpOnly, ver
/// `openspec/decisions.md`).
class LoginResult {
  const LoginResult({
    required this.success,
    required this.requiresNewPassword,
    this.accessToken,
  });

  final bool success;
  final bool requiresNewPassword;
  final String? accessToken;
}
