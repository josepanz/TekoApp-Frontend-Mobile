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
import 'l10n/app_localizations.dart';

/// Rutas que requieren sesión — hoy `sessionProvider` es un placeholder siempre-sin-sesión (ver
/// `core/auth/session_provider.dart`), así que esto redirige siempre a `/login`. El propósito de
/// esta lista no es gatear nada todavía, es dejar probado el mecanismo de redirect de `go_router`
/// antes de conectar sesión real en la Fase 0002 (ver checkpoint de
/// `openspec/changes/0001-project-bootstrap.md`).
const _protectedPaths = {'/perfil'};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final isProtected = _protectedPaths.contains(state.matchedLocation);
      if (isProtected && session is SessionUnauthenticated) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const ProfileScreen(),
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
