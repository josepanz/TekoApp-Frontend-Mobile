import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/session_provider.dart';
import '../../../core/auth/session_state.dart';
import '../../../core/mode/app_mode.dart';
import '../../../core/mode/app_mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_card.dart';

/// Pantalla de inicio (modo cliente) — el botón "modo profesional" en el `AppBar` lleva a
/// `/profesional`, cuyo gate (`app.dart`) decide si mostrar el perfil activo o pedir activarlo
/// primero (ver `openspec/changes/0003-services-marketplace-core.md`).
///
/// Layout Opción C de `openspec/changes/0013-client-home-redesign.md` (confirmado 2026-08-25):
/// saludo + CTA destacada de "pedir servicio" (único uso de `accent` en la pantalla, balance 80/20
/// de marca) + grid secundario 2x2 para el resto de los accesos ya wireados en `app.dart`. `/` es
/// una ruta protegida (ver `app.dart`), así que esta pantalla solo se monta con sesión iniciada —
/// `SessionAuthenticated` es la única rama con contenido real.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider);
    final firstName =
        session is SessionAuthenticated ? session.user.firstName : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('home_professional_mode_button'),
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.professionalHomeTitle,
            onPressed: () {
              ref.read(appModeProvider.notifier).state = AppMode.professional;
              context.push('/profesional');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeGreeting(firstName),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _RequestServiceCta(
              label: l10n.requestServiceTitle,
              onPressed: () => context.push('/solicitar'),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _QuickAccessTile(
                  quickAccessKey: 'home_nearby_map_button',
                  icon: Icons.map_outlined,
                  label: l10n.nearbyProfessionalsMapTitle,
                  onPressed: () => context.push('/mapa/cercanos'),
                ),
                _QuickAccessTile(
                  quickAccessKey: 'home_my_services_button',
                  icon: Icons.list_alt_outlined,
                  label: l10n.myServicesTitle,
                  onPressed: () => context.push('/mis-servicios'),
                ),
                _QuickAccessTile(
                  quickAccessKey: 'home_payment_methods_button',
                  icon: Icons.credit_card_outlined,
                  label: l10n.paymentMethodsTitle,
                  onPressed: () => context.push('/pagos/metodos'),
                ),
                _QuickAccessTile(
                  quickAccessKey: 'home_payment_history_button',
                  icon: Icons.history_outlined,
                  label: l10n.paymentHistoryTitle,
                  onPressed: () => context.push('/pagos/historial'),
                ),
                _QuickAccessTile(
                  quickAccessKey: 'home_my_contracts_button',
                  icon: Icons.description_outlined,
                  label: l10n.myContractsTitle,
                  onPressed: () => context.push('/contratos'),
                ),
                _QuickAccessTile(
                  quickAccessKey: 'home_my_rating_stats_button',
                  icon: Icons.star_outline,
                  label: l10n.myRatingStatsTitle,
                  onPressed: () => context.push('/mis-calificaciones'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Única tarjeta `accent` de la pantalla — regla 80/20 de balance de marca (ver
/// `.claude/rules/design-system.md`): "pedir servicio" es la acción más importante del home de
/// cliente, así que es el único punto de énfasis teal.
class _RequestServiceCta extends StatelessWidget {
  const _RequestServiceCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colorScheme.tertiary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: const Key('home_request_service_button'),
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: colorScheme.onTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onTertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward, color: colorScheme.onTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Acceso secundario del grid 2x2 — usa `primary` en el ícono sobre `TekoCard` neutro, nunca
/// `accent` (ese queda reservado a `_RequestServiceCta`, único foco teal de la pantalla).
class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.quickAccessKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String quickAccessKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: Key(quickAccessKey),
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: TekoCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
