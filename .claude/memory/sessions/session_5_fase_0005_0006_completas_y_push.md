# Sesión 5 — 2026-08-23 — Fases 0005 y 0006 completas + specs del backlog 2026-08-22

## Qué se hizo

Sesión larga bajo mandato explícito de economía de tokens (José: "ahorra tokenes... un solo
agente... sin exploración innecesaria"). Se cerró todo el código pendiente de las Fases 0005 y
0006, y se documentaron (sin implementar) 6 features nuevas del backlog.

**Fase 0005 (realtime-and-push) — código 100% cerrado:**
- Mapa de profesionales cercanos (modo cliente): `flutter_map` + OpenStreetMap, sin costo ni API
  key (PR #61). Requirió un fix de backend primero: `GET /locations/nearby` devolvía la fila cruda
  de Postgres (snake_case, NUMERIC como string) porque usa `$queryRaw` — nunca pasa por el
  `$extends` de Prisma que normaliza el resto de la API (PR #32 en `TekoApp-Backend`).
- Tracking en vivo del profesional asignado (servicio ACCEPTED/IN_PROGRESS): reusa el mismo socket
  de `/locations` del mapa de cercanos, filtrando por `professionalId` — sin tocar backend (PR
  #62). Bug de riverpod encontrado con tests: `StreamProvider.autoDispose` puede tirar el provider
  mientras un `await` está en vuelo; riverpod 2.x no tiene `ref.mounted` (recién en 3.x), hubo que
  trackear el dispose a mano.
- Push notifications (FCM), cliente completo contra el backend ya listo:
  - Registro/baja de token FCM reaccionando a `sessionProvider` (login/logout), vía
    `PushNotificationGateway` montado en `MaterialApp.router(builder: ...)`.
  - Permiso pedido con contexto (diálogo propio antes del picker nativo, una sola vez).
  - 3 estados manejados: foreground → banner propio (`ScaffoldMessenger` con `GlobalKey`, no
    `flutter_local_notifications` — decisión de alcance, ver `decisions.md`); background/cerrada →
    el SO ya muestra la notificación, solo se resuelve el deep link al tocarla.
  - Deep linking por `type` de notificación → ruta de `go_router` (servicios y pagos tienen
    pantalla propia; ratings/promos/system no, caen a home).
  - **Hallazgo real**: ningún flujo de negocio del backend llama todavía a
    `NotificationsService.create()` — la infraestructura de push está lista pero nada la dispara
    hoy. Cablear esos triggers es trabajo de backend, fuera de esta fase.
  - Configuración real de Firebase para Android (`google-services.json` ya colocado por José,
    plugin Gradle wireado) — `flutter build apk --debug` verificado exitoso con la config real.
    iOS sin `GoogleService-Info.plist` todavía (Mac aparte) — `Firebase.initializeApp()` en
    try/catch para no tumbar el boot si falta config en alguna plataforma.

**Fase 0006 (i18n-and-polish) — checklist de tareas 100% cerrado:**
- Auditoría de strings hardcodeados: limpia.
- Selector de idioma explícito en "Mi perfil" (`LocaleController`, nueva dependencia
  `shared_preferences` — la otra opción de storage local del proyecto, `flutter_secure_storage`,
  es para secretos, no para una preferencia de UI).
- Decisión: sin admin/backoffice en mobile, queda exclusivo de `TekoApp-Web`.
- Accesibilidad: 1 hallazgo real corregido (estrellas de calificar sin `tooltip`).
- Offline-first: ya estaba decidido (2026-08-08, online-only), sin cambios.
- **Hallazgo real adicional**: la app nunca mandaba el header `x-lang` al backend — los mensajes
  de error del servidor nunca respetaban el idioma activo de la UI. Agregado
  `LocaleHeaderInterceptor` en `core/api_client/`.

**Limpieza de historia git (`TekoApp-Backend` y este repo)**: se encontraron commits con
`Co-Authored-By: Claude` colados después de un rewrite previo — reescrita la historia de `develop`
en ambos repos con `git filter-repo` (ver `[[feedback_no_coauthor_claude_trailer]]` en memoria
persistente), force-pusheada. `master`/`qa` NO se tocaron (fuera de alcance pedido).

**Backlog 2026-08-22 — 6 features documentadas, NO implementadas** (José: "hazme recordar"):
antecedentes/documentos del profesional, bitácora de trabajo, presupuestos multi-opción, contratos
desde presupuesto, disclosure de IA, protección de datos/imágenes. Specs completas creadas en
`openspec/` de los 3 repos (`changes/0007`-`0012` acá, `openspec/` nuevo en `TekoApp-Backend` y
`TekoApp-Frontend-Web` — antes un agente había puesto esto por error en `TekoApp-Backend/docs/`,
que está reservado para compodoc; corregido a mitad de tarea). Quedan para implementar en otra
sesión — ver `openspec/decisions.md` sección del backlog para el detalle completo y los paths
reales de cada spec en los 3 repos.

## Errores encontrados y su solución

- **Mocktail necesita `registerFallbackValue()` para tipos custom** (`DeviceType`) usados con
  `any(named:)` en `verifyNever` — sin esto, el error de fallback faltante corrompe el estado
  interno de mocktail y hace fallar tests SIGUIENTES no relacionados en la misma corrida.
- **`PushNotificationGateway` rompe cualquier widget test que pumpee `TekoApp`** (llama a
  `firebase_messaging` real en `initState`, sin Firebase inicializado en `flutter test`) — hubo que
  overridear `onForegroundMessageProvider`/`onMessageOpenedAppProvider`/
  `initialPushMessageReaderProvider`/`pushRegistrationControllerProvider` en los 4 archivos de
  test que pumpean `TekoApp` (`app_test.dart`, `app_redirect_test.dart`, `profile_screen_test.dart`,
  `e2e/login_profile_logout_test.dart`).
- **El selector de idioma empuja el botón de logout fuera del viewport fijo de los widget tests**
  — hubo que agregar `tester.ensureVisible(...)` antes de tapearlo en 2 tests existentes.
- Un agente delegado para escribir specs las puso en `TekoApp-Backend/docs/specs/` — corregido a
  mitad de tarea (`docs/` es de compodoc), reescribió todo bajo `openspec/` en los 3 repos.

## Estado al cierre

- Mobile: `flutter analyze` 0 issues, `flutter test` 263/263 verde, `flutter build apk --debug`
  exitoso. PRs #61/#62/#63 ya mergeados a `develop` antes de esta entrada de sesión; el trabajo de
  push notifications + specs del backlog se está por pushear/PR/mergear a continuación de esto.
- Backend: PR #32 mergeado; PR de specs (`openspec/`) pendiente de push/PR/merge.
- Web: specs (`openspec/`) pendientes de commit/push/PR/merge todavía.
- `develop` de mobile y backend con historia reescrita (sin `Co-Authored-By: Claude`) — `master`/
  `qa` de ambos siguen con la historia vieja, sin tocar.

## Pendiente para la próxima sesión

- Promover `develop → qa → master` en los 3 repos (pedido explícito de José en esta misma sesión,
  en curso al momento de escribir esto).
- Push (FCM): checkpoint de salida con dispositivos reales (José) — cablear los triggers de
  negocio en el backend (aceptar servicio, pago recibido, etc.) sigue sin hacerse, es lo que falta
  para que un push realmente se dispare en producción.
- Implementar las 6 features del backlog 2026-08-22, cada una ya con spec propia en `openspec/`.
- iOS: agregar `GoogleService-Info.plist` cuando José tenga el Mac disponible.

## Adenda — promoción develop → qa → master (misma sesión)

Al promover, aparecieron 2 bugs reales de CI, ambos corregidos:

1. **Colisión de tags de semantic-release**: el rewrite de historia de esta sesión dejó tags
   `v1.0.0-develop.N`/`v1.0.0-qa.N`/`v1.0.0` viejos en origin que semantic-release ya no reconocía
   como "última release" pero seguían "existiendo" — chocaba al intentar crear el mismo tag de
   nuevo. Fix: borrar del remoto los tags huérfanos (autorizado explícitamente por José) para que
   semantic-release los recree limpio.
2. **`google-services.json` (gitignored) rompía el build de Android release en CI** —
   `com.google.gms.google-services` no puede funcionar sin ese archivo. Fix real (no solo del CI):
   aplicar el plugin de forma condicional (`if (file("google-services.json").exists())`) en
   `android/app/build.gradle.kts` — local con Firebase real, CI compila igual sin él.

**`develop`/`qa`/`master` quedaron con historias no relacionadas** (el rewrite fue la primera vez
que corrió en este repo, cambió TODOS los hashes) — resuelto con un reset duro de `qa` y luego
`master` al contenido de `develop`/`qa` (autorizado explícitamente por José), no un merge. Backend
sí conservó ancestro común (ya tenía un rewrite previo de julio) y se resolvió con un merge normal
(`chore/sync-qa-with-develop`); ver la sesión de Backend correspondiente.

**Estado final**: los 3 repos con `develop`/`qa`/`master` en verde (CI + Release) al cierre de la
sesión.
