import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client/network_smoke_check_provider.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/app_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';

/// Pantalla de inicio (modo cliente) — el botón "modo profesional" lleva a `/profesional`, cuyo
/// gate (`app.dart`) decide si mostrar el perfil activo o pedir activarlo primero (ver
/// `openspec/changes/0003-services-marketplace-core.md`). El contenido de cliente en sí sigue
/// siendo mínimo — el smoke test de red de la Fase 0001 (`networkSmokeCheckProvider`) queda como
/// verificación de que el esqueleto (tema, routing, l10n) arranca sin errores.
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
            const SizedBox(height: 24),
            TekoButton(
              key: const Key('home_request_service_button'),
              label: l10n.requestServiceTitle,
              onPressed: () => context.push('/solicitar'),
            ),
            const SizedBox(height: 12),
            TekoButton(
              key: const Key('home_my_services_button'),
              label: l10n.myServicesTitle,
              variant: TekoButtonVariant.outline,
              onPressed: () => context.push('/mis-servicios'),
            ),
            const SizedBox(height: 12),
            TekoButton(
              key: const Key('home_professional_mode_button'),
              label: l10n.professionalHomeTitle,
              variant: TekoButtonVariant.ghost,
              onPressed: () {
                ref.read(appModeProvider.notifier).state = AppMode.professional;
                context.push('/profesional');
              },
            ),
          ],
        ),
      ),
    );
  }
}
