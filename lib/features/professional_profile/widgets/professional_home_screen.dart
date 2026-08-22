import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/app_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../locations/providers/online_status_controller_provider.dart';
import '../../services/widgets/available_services_screen.dart';
import '../providers/my_professional_profile_provider.dart';

class _ProfessionalActiveBody extends ConsumerWidget {
  const _ProfessionalActiveBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final onlineAsync = ref.watch(onlineStatusControllerProvider);
    return Column(
      children: [
        SwitchListTile(
          key: const Key('professional_home_online_switch'),
          title: Text(l10n.professionalOnlineToggleTitle),
          subtitle: onlineAsync.hasError
              ? Text(l10n.professionalOnlineToggleError)
              : Text(l10n.professionalOnlineToggleSubtitle),
          value: onlineAsync.value ?? false,
          onChanged: onlineAsync.isLoading
              ? null
              : (next) => ref
                  .read(onlineStatusControllerProvider.notifier)
                  .setOnline(next),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TekoButton(
            key: const Key('professional_home_my_services_button'),
            label: l10n.professionalServicesTitle,
            variant: TekoButtonVariant.outline,
            onPressed: () => context.push('/profesional/mis-servicios'),
          ),
        ),
        const Expanded(child: AvailableServicesScreen()),
      ],
    );
  }
}

/// Destino de "modo profesional" — el gate de `go_router` (`app.dart`) ya redirige acá solo si
/// hay perfil profesional (o el servicio de perfiles no está disponible); el caso "sin perfil" se
/// mantiene como respaldo defensivo por si esta pantalla se alcanza antes de que el redirect
/// async resuelva. Con perfil activo, muestra `AvailableServicesScreen` (servicios disponibles en
/// mi categoría + proponerme, ver `openspec/changes/0003-services-marketplace-core.md`).
class ProfessionalHomeScreen extends ConsumerWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myProfessionalProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.professionalHomeTitle)),
      body: Column(
        children: [
          Expanded(
            child: switch (profileAsync) {
              AsyncData(value: null) => Center(
                  child: Text(l10n.professionalHomeNoProfile),
                ),
              AsyncData() => const _ProfessionalActiveBody(),
              AsyncError() => Center(
                  child: Text(l10n.professionalHomeServiceUnavailable),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TekoButton(
              key: const Key('professional_home_back_to_client_button'),
              label: l10n.professionalHomeBackToClient,
              variant: TekoButtonVariant.outline,
              onPressed: () {
                ref.read(appModeProvider.notifier).state = AppMode.client;
                context.go('/');
              },
            ),
          ),
        ],
      ),
    );
  }
}
