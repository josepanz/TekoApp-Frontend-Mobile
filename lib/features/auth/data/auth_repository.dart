import '../../../core/api_client/api_client.dart';

/// Llamadas a `/auth/*` — equivalente a `features/auth` en TekoApp-Web, pero sin BFF: acá el
/// secret de Basic Auth de cliente vive en la config de la app, no server-side (ver
/// `.claude/rules/auth.md`, sección "Qué NO replicar del BFF de TekoApp-Web").
///
/// Sin implementar todavía — la Fase 0002 arma acá `requestNonce()`, `login(email, password)`
/// (cifrado RSA-OAEP del password con la clave pública del backend) y `refreshToken()`, usando
/// `apiClient` para las llamadas HTTP.
class AuthRepository {
  const AuthRepository(this.apiClient);

  final ApiClient apiClient;
}
