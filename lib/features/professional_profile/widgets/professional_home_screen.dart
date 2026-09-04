import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/app_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_gradient_background.dart';
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: TekoGradientBackground(
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.work_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.professionalHomeTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
          child: Column(
            children: [
              TekoButton(
                key: const Key('professional_home_my_services_button'),
                label: l10n.professionalServicesTitle,
                variant: TekoButtonVariant.outline,
                onPressed: () => context.push('/profesional/mis-servicios'),
              ),
              const SizedBox(height: 8),
              TekoButton(
                key: const Key('professional_home_my_documents_button'),
                label: l10n.myDocumentsScreenTitle,
                variant: TekoButtonVariant.outline,
                onPressed: () => context.push('/profesional/mis-documentos'),
              ),
              const SizedBox(height: 8),
              TekoButton(
                key: const Key('professional_home_my_portfolio_button'),
                label: l10n.myPortfolioScreenTitle,
                variant: TekoButtonVariant.outline,
                onPressed: () => context.push('/profesional/mi-portafolio'),
              ),
              const SizedBox(height: 8),
              TekoButton(
                key: const Key('professional_home_my_contracts_button'),
                label: l10n.myContractsTitle,
                variant: TekoButtonVariant.outline,
                onPressed: () => context.push('/contratos'),
              ),
              const SizedBox(height: 8),
              TekoButton(
                key: const Key('professional_home_my_rating_stats_button'),
                label: l10n.professionalRatingStatsTitle,
                variant: TekoButtonVariant.outline,
                onPressed: () =>
                    context.push('/profesional/mis-calificaciones'),
              ),
            ],
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
      appBar: AppBar(
        title: Text(l10n.professionalHomeTitle),
        actions: [
          IconButton(
            key: const Key('professional_home_back_to_client_button'),
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.professionalHomeBackToClient,
            onPressed: () {
              ref.read(appModeProvider.notifier).state = AppMode.client;
              context.go('/');
            },
          ),
        ],
      ),
      body: switch (profileAsync) {
        AsyncData(value: null) => Center(
            child: Text(l10n.professionalHomeNoProfile),
          ),
        AsyncData() => const _ProfessionalActiveBody(),
        AsyncError() => Center(
            child: Text(l10n.professionalHomeServiceUnavailable),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
