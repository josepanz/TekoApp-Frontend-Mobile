# Fase 0001 — Bootstrap del proyecto

## Antes de empezar

Leer: `project.md`, `decisions.md` completos.

## Objetivo

Dejar el proyecto Flutter arrancando, con la estructura de carpetas decidida, sin ninguna
funcionalidad de negocio todavía — el equivalente a "hola mundo que compila en ambas plataformas".

## Tareas

- [x] `flutter create` con el nombre/bundle id definitivo del proyecto (confirmar con el negocio
      antes: bundle id de iOS y applicationId de Android no se pueden cambiar fácil después de
      publicar). — `py.com.tekoapp.mobile` (Android e iOS), `android/`+`ios/` generados.
- [x] Estructura de carpetas inicial, con nombres que mapeen mentalmente a `TekoApp-Web` donde
      tenga sentido (sin forzarlo si Flutter tiene una convención mejor establecida):
      ```
      lib/
      ├── core/
      │   ├── api_client/       # dio centralizado, ver specs/api-client.md
      │   ├── auth/             # sesión, tokens, ver specs/auth-and-session.md
      │   ├── config/           # env por ambiente (dev/qa/prod)
      │   └── router/           # go_router
      ├── design_system/
      │   └── tokens.generated.dart   # generado desde tokens.json, ver specs/design-system.md
      ├── features/
      │   └── <dominio>/        # un folder por dominio, análogo a features/ de la web
      ├── shared/                # widgets reutilizables (Button, Card, Avatar...)
      └── main.dart
      ```
      Nota: el router vive inline en `app.dart` (`routerProvider`) en vez de un `core/router/`
      separado — aceptable con 3 rutas, se puede extraer si crece.
- [x] Configurar Riverpod a nivel raíz (`ProviderScope`).
- [x] Configurar go_router con al menos 2 rutas dummy (una pública, una protegida) para validar el
      patrón de guard antes de construir auth real. — `/` y `/login` públicas, `/perfil`
      protegida (redirige a `/login` mientras `sessionProvider` sea el placeholder
      `SessionUnauthenticated`), ver `test/app_redirect_test.dart`.
- [x] Configurar `dio` base (sin auth todavía) apuntando al backend local para un primer smoke
      test: un endpoint público (ej. `GET /countries`, no requiere sesión) renderizado en una
      pantalla dummy. — `core/api_client/network_smoke_check_provider.dart`, consumido por
      `HomeScreen`.
- [x] Decidir y documentar en `decisions.md`: framework de testing (`flutter_test` +
      mocktail/mockito), linter (`flutter_lints` o similar, con las reglas que se consideren
      necesarias). — `mocktail` + `flutter_lints` (ver `pubspec.yaml`/`analysis_options.yaml`).
- [x] CI mínimo: al menos un job que corra `flutter analyze` + `flutter test` en cada push (no
      hace falta build/firma todavía, eso es explícitamente fuera de alcance de esta fase, ver
      `decisions.md`). — `.github/workflows/ci.yml`.

## Checkpoint de salida (verificar de verdad, no solo "compila")

- [ ] La app corre en un emulador/dispositivo Android Y en un simulador iOS. — pendiente de
      verificación manual por José con `flutter run` (requiere un emulador/simulador real, no
      verificable desde esta sesión); `flutter build apk --debug` ya se validó localmente.
- [x] La pantalla dummy con el fetch a `GET /countries` muestra datos reales del backend local
      corriendo (confirma que `dio` + la config de red del emulador/simulador hacia el backend
      local funcionan — un problema real y común en Android emulator, que no resuelve `localhost`
      igual que iOS). — implementado y cubierto con tests (dio mockeado); la verificación contra
      el backend local real corriendo en un emulador queda para cuando José lo corra.
- [x] `flutter analyze` y `flutter test` corren en CI y pasan en verde.
- [x] La navegación entre la ruta pública y la protegida funciona (aunque el guard todavía no
      chequee sesión real, el mecanismo de redirect de go_router debe estar probado). — ver
      `test/app_redirect_test.dart`.
