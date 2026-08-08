import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/app_mode_provider.dart';
import '../../professional_profile/providers/my_professional_profile_provider.dart';
import '../../services/providers/my_client_services_provider.dart';
import '../models/payment.dart';
import 'payments_repository_provider.dart';

/// Historial de pagos propios — filtra por `professionalId` (modo profesional, ya expuesto como
/// Int por `myProfessionalProfileProvider`) o por `userId` (modo cliente). `GET /auth/scope`
/// deliberadamente nunca expone el `id` interno del usuario (ver `.claude/rules/auth.md`), así que
/// en modo cliente se deriva de cualquier `Service` propio (`myClientServicesProvider`), que ya
/// trae `userId` — si esa lista está vacía, por definición no hay pagos que buscar, se salta la
/// llamada (ver `openspec/decisions.md`).
final paymentHistoryProvider = FutureProvider.autoDispose<List<Payment>>((
  ref,
) async {
  final mode = ref.watch(appModeProvider);
  final repository = ref.watch(paymentsRepositoryProvider);

  if (mode == AppMode.professional) {
    final profile = await ref.watch(myProfessionalProfileProvider.future);
    if (profile == null) return const [];
    return repository.fetchPayments(professionalId: profile.id);
  }

  final services = await ref.watch(myClientServicesProvider.future);
  if (services.isEmpty) return const [];
  return repository.fetchPayments(userId: services.first.userId);
});
