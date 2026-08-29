# Fase 0015 — Chequeo y actualización de versión de la app

**Implementada 2026-08-28** — ver `openspec/decisions.md`, "Fase 0015", para las decisiones
tomadas al implementar (elección de `open_filex`, FileProvider duplicado descartado, downgrade de
`permission_handler` por incompatibilidad real de `compileSdk`). Contrato completo:
`openspec/specs/app-version-update.md`.

## Antes de empezar

Leer `openspec/specs/app-version-update.md` completo — en particular las 2 decisiones marcadas
como pendientes de confirmar con José antes de codear (firma de builds sin
`ANDROID_KEYSTORE_BASE64` cargado, alcance en `prod` una vez Google Play esté publicando de
verdad) y la tabla de mapeo de tags por ambiente (regla central: nunca cruzar ambientes).

## Objetivo

Que un usuario (hoy: testers internos sideloadeando el APK, en los 3 ambientes — no hay
distribución real vía store todavía) se entere dentro de la misma app de que hay una versión más
nueva para SU ambiente, y pueda actualizar con 2 taps, sin que alguien le pase el link del release
a mano.

## Tareas

- [x] **Prerrequisito de infra:** José generó el keystore de firma con `keytool` y cargó
      `ANDROID_KEYSTORE_BASE64`/`ANDROID_KEYSTORE_PASSWORD`/`ANDROID_KEY_ALIAS`/
      `ANDROID_KEY_PASSWORD` como secrets del repo (2026-08-28) — `release.yml` ya estaba armado
      para consumirlos condicionalmente, no hizo falta tocar el pipeline.
- [x] `Env.environment` nuevo en `lib/core/config/env.dart` (`APP_ENVIRONMENT` dart-define,
      default `dev`) + `--dart-define=APP_ENVIRONMENT=...` agregado en `.github/workflows/build.yml`
      (desde `inputs.environment`) y `.github/workflows/release.yml` (resuelto desde
      `github.ref_name`, mismo criterio que la resolución de track de Google Play ya existente).
- [x] Dependencias agregadas a `pubspec.yaml` (elección registrada en `decisions.md`):
      `package_info_plus`, `pub_semver`, `path_provider`, `permission_handler` (fijado en `^12.0.0`,
      no la última — ver corrección real en `decisions.md`), `open_filex` (paquete de instalación
      elegido, sobre `ota_update`/`install_plugin`).
- [x] `lib/core/update/` nuevo:
  - [x] `github_releases_client.dart`.
  - [x] `app_release.dart`.
  - [x] `environment_release_matcher.dart`.
  - [x] `update_check_repository.dart` + `update_check_provider.dart` (`FutureProvider`, compara
        con `pub_semver`, cachea con TTL vía `shared_preferences`).
  - [x] `apk_downloader.dart`.
  - [x] `apk_installer.dart`.
  - [x] `update_available_dialog.dart` + `apk_actions_providers.dart`.
  - [x] `update_check_gateway.dart` (wiring del chequeo tras el primer frame).
- [x] Wiring: `UpdateCheckGateway` agregado a `app.dart` (`MaterialApp.router(builder: ...)`,
      mismo nivel que `ConsentGateway`/`PushNotificationGateway`), guard `Platform.isAndroid`.
- [x] `AndroidManifest.xml`: permiso `REQUEST_INSTALL_PACKAGES` agregado. `<provider>` de
      `FileProvider` propio DESCARTADO — `open_filex` ya trae el suyo (ver corrección real en
      `decisions.md`), declarar uno propio hubiera sido una duplicación.
- [x] Traducido a es/en (textos del modal, mensajes de error de descarga/instalación).
- [x] Tests: 15 nuevos — `environment_release_matcher_test.dart` (6), `update_check_repository_test.dart`
      (5, incluye el caso `develop.9`/`develop.10` explícito), `update_available_dialog_test.dart` (3).
- [x] `flutter analyze` (0 issues), `flutter test` (todos verdes) — y además un build real de APK
      (`flutter build apk --debug --dart-define=APP_ENVIRONMENT=dev`) para confirmar que el
      manifest y las dependencias nativas compilan de verdad (encontró la incompatibilidad real de
      `permission_handler`/`compileSdk`, invisible para `analyze`/`pub get`).

## Checkpoint de salida

- [ ] Con un release real publicado para `dev` (ej. probar con un build number por debajo del
      último `v1.0.0-develop.N` existente), la app detecta la versión nueva y muestra el modal al
      arrancar. Cubierto por tests unitarios/mocks, sin verificación manual contra un release real
      todavía.
- [ ] Un release de otro ambiente (`qa`/`master`) NUNCA dispara el modal en un build `dev`, y
      viceversa — cubierto por `environment_release_matcher_test.dart`, sin verificación manual.
- [ ] "Actualizar" en un dispositivo/emulador Android real descarga el APK y abre el instalador
      del sistema, e instala-sobre limpio gracias a la firma real ya cargada — pendiente de probar
      en un dispositivo/emulador real, a cargo de José (mismo criterio que otros checkpoints de
      negocio).
- [x] "Cancelar" cierra el modal sin descargar nada — cubierto por test.
- [x] Sin conexión / API de GitHub caída: la app arranca normal, sin modal ni error visible al
      usuario (fail-open) — cubierto por test.
