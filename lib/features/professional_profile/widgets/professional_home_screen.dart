import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mode/app_mode.dart';
import '../../../core/mode/app_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../providers/my_professional_profile_provider.dart';

/// Destino de "modo profesional" — el gate de `go_router` (`app.dart`) ya redirige acá solo si
/// hay perfil profesional (o el servicio de perfiles no está disponible); el caso "sin perfil" se
/// mantiene como respaldo defensivo por si esta pantalla se alcanza antes de que el redirect
/// async resuelva.
///
/// El cuerpo "perfil activo" es un placeholder — el Paso 7
/// (`openspec/changes/0003-services-marketplace-core.md`) lo reemplaza por el listado real de
/// servicios disponibles en la categoría del profesional.
class ProfessionalHomeScreen extends ConsumerWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myProfessionalProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.professionalHomeTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            switch (profileAsync) {
              AsyncData(value: null) => Text(l10n.professionalHomeNoProfile),
              AsyncData() => Text(l10n.professionalHomeActive),
              AsyncError() => Text(l10n.professionalHomeServiceUnavailable),
              _ => const CircularProgressIndicator(),
            },
            const SizedBox(height: 24),
            TekoButton(
              key: const Key('professional_home_back_to_client_button'),
              label: l10n.professionalHomeBackToClient,
              variant: TekoButtonVariant.outline,
              onPressed: () {
                ref.read(appModeProvider.notifier).state = AppMode.client;
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}
