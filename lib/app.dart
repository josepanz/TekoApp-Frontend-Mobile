import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/widgets/login_screen.dart';
import 'features/home/widgets/home_screen.dart';
import 'l10n/app_localizations.dart';

/// Guards de sesión reales (redirigir a `/login` sin sesión válida, ver
/// `.claude/rules/flutter-architecture.md`) se agregan en la Fase 0002, una vez que
/// `sessionProvider` deje de ser un placeholder — hoy el router no gatea ninguna ruta.
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  ],
);

class TekoApp extends StatelessWidget {
  const TekoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
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
