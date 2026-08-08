import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/session_provider.dart';
import 'core/auth/session_state.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/widgets/login_screen.dart';
import 'features/home/widgets/home_screen.dart';
import 'features/profile/widgets/profile_screen.dart';
import 'features/services/widgets/my_services_screen.dart';
import 'features/services/widgets/request_service_screen.dart';
import 'features/services/widgets/service_detail_screen.dart';
import 'l10n/app_localizations.dart';

/// Rutas que requieren sesión (ver `core/auth/session_provider.dart`) — se comparan contra
/// `state.fullPath` (la plantilla, ej. `/mis-servicios/:id`), no `state.matchedLocation` (que trae
/// el valor real del parámetro interpolado, distinto en cada visita).
const _protectedPaths = {
  '/perfil',
  '/solicitar',
  '/mis-servicios',
  '/mis-servicios/:id',
};

/// Puente `sessionProvider` (Riverpod) → `Listenable` (lo que espera `GoRouter.refreshListenable`)
/// — cuando la sesión cambia, `go_router` reevalúa `redirect` para la ruta ACTUAL sin recrear el
/// router ni resetear el stack de navegación (a diferencia de reconstruir el `GoRouter` entero).
class _SessionRefreshListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// El `GoRouter` se construye una sola vez (`Provider`, no se reconstruye al cambiar la sesión).
/// El logout dispara el redirect automáticamente: al pasar a `SessionUnauthenticated` estando en
/// `/perfil` (protegida), `refreshListenable` hace que `go_router` reevalúe y redirija solo. El
/// login sí necesita navegación explícita (`LoginScreen` hace `context.go('/')`) porque `/login`
/// no es una ruta protegida — no hay una regla de "ya autenticado, salir de acá" todavía.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _SessionRefreshListenable();
  ref.listen<SessionState>(sessionProvider, (previous, next) {
    refreshListenable.notify();
  });
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final isProtected = _protectedPaths.contains(
        state.fullPath ?? state.matchedLocation,
      );
      if (!isProtected) return null;
      if (session is SessionAuthenticated) return null;
      // 5xx/sin conexión NUNCA implica "no hay sesión" (ver specs/auth-and-session.md) — la
      // propia pantalla muestra el estado de error, no se redirige a login.
      if (session is SessionServiceUnavailable) return null;
      // SessionUnknown (todavía resolviendo GET /auth/scope al abrir la app) se trata igual que
      // sin sesión — solo importa si el usuario aterriza directo en una ruta protegida antes de
      // que la sesión inicial resuelva (deep linking, fuera de alcance hoy).
      return '/login';
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/solicitar',
        builder: (context, state) => const RequestServiceScreen(),
      ),
      GoRoute(
        path: '/mis-servicios',
        builder: (context, state) => const MyServicesScreen(),
      ),
      GoRoute(
        path: '/mis-servicios/:id',
        builder: (context, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
      ),
    ],
  );
});

class TekoApp extends ConsumerWidget {
  const TekoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
