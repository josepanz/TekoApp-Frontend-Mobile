import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';

/// Smoke test de red de la Fase 0001 (ver `openspec/changes/0001-project-bootstrap.md`) — confirma
/// que `dio` + la config de red del emulador/simulador hacia el backend local funcionan, pegándole
/// a un endpoint público real (`GET /countries`, sin guard, ver
/// `TekoApp-Backend/src/api/countries/controllers/countries.controller.ts`).
///
/// No es una feature de dominio: cuando una fase futura necesite países de verdad (ej.
/// onboarding), reemplazar esto por `features/countries/` siguiendo
/// `.claude/rules/flutter-architecture.md` en vez de extender este archivo.
final networkSmokeCheckProvider = FutureProvider<List<String>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.raw.get<Map<String, dynamic>>('/countries');
  final data = response.data?['data'] as List<dynamic>? ?? [];

  return data.map(_toCommonName).toList();
});

String _toCommonName(dynamic country) =>
    (country as Map<String, dynamic>)['commonName'] as String;
