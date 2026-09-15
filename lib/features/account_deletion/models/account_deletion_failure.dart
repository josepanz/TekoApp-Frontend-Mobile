import 'deletion_blocker.dart';

/// Errores de `POST /auth/me/deletion-request` y su `/cancel` — mismo criterio que
/// `LegalConsentsFailure`: distinguir por `errorCode` primero, caer a status HTTP genérico
/// después (ver `openspec/specs/account-deletion.md`, "Casos de error").
sealed class AccountDeletionFailure implements Exception {
  const AccountDeletionFailure();
}

/// `409 DELETION_BLOCKED` — el usuario tiene al menos un bloqueante (servicio activo, pago
/// pendiente, contrato sin firmar). La UI mapea cada uno a una acción concreta, nunca un mensaje
/// genérico (ver spec, paso 3 del flujo).
class AccountDeletionBlockedFailure extends AccountDeletionFailure {
  const AccountDeletionBlockedFailure(this.blockers);

  final List<DeletionBlocker> blockers;
}

/// `409 DELETION_ALREADY_REQUESTED` — ya hay una solicitud en curso. No debería ocurrir si la UI
/// oculta el botón correctamente, pero se maneja igual (mensaje, no crash — ver spec).
class AccountDeletionAlreadyRequestedFailure extends AccountDeletionFailure {
  const AccountDeletionAlreadyRequestedFailure();
}

/// `400 DELETION_NOT_REQUESTED` — cancelar sin solicitud activa. Mismo criterio que arriba.
class AccountDeletionNotRequestedFailure extends AccountDeletionFailure {
  const AccountDeletionNotRequestedFailure();
}

class AccountDeletionServiceUnavailableFailure extends AccountDeletionFailure {
  const AccountDeletionServiceUnavailableFailure();
}

class AccountDeletionNoConnectionFailure extends AccountDeletionFailure {
  const AccountDeletionNoConnectionFailure();
}
