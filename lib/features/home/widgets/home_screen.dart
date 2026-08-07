import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/network_smoke_check_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';

/// Pantalla de inicio placeholder — el selector de modo (cliente/profesional, ver
/// `.claude/rules/flutter-architecture.md#multi-rol-en-una-sola-app`) y el contenido real llegan
/// en fases posteriores. Sirve hoy para tener un destino inicial real que `flutter run` pueda
/// mostrar, validar que el esqueleto (tema, routing, l10n) arranca sin errores, y mostrar el
/// resultado del smoke test de red de la Fase 0001 (`networkSmokeCheckProvider`).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final countries = ref.watch(networkSmokeCheckProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.comingSoon,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AsyncStateView<List<String>>(
              isLoading: countries.isLoading,
              hasError: countries.hasError,
              data: countries.valueOrNull,
              errorMessage: l10n.networkSmokeCheckError,
              builder: (context, data) =>
                  Text(l10n.networkSmokeCheckLoaded(data.length)),
            ),
          ],
        ),
      ),
    );
  }
}
