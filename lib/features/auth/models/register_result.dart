/// Resultado de `AuthRepository.register()` — espejo de `OnboardingUserResponseDTO` del backend.
class RegisterResult {
  const RegisterResult({
    required this.referenceId,
    required this.email,
    required this.status,
  });

  final String referenceId;
  final String email;
  final String status;
}
