# Fase 0012 — Protección de datos, imágenes y su uso

Spec de diseño, NO implementada todavía — feature 11 del backlog 2026-08-22
(`openspec/decisions.md`), y extensión concreta del backlog 2026-08-08 ítem 4 (marco legal/
tributario). Contrato de dominio: `openspec/specs/data-and-media-consent.md` (mobile),
`TekoApp-Backend/openspec/specs/data-and-media-consent.md` (backend).
Web (config/auditoría): `TekoApp-Frontend-Web/openspec/specs/data-and-media-consent-admin.md`.

**Spec más fundacional del backlog 2026-08-22 en mobile también** — `0007`
(documentos/antecedentes) y `0008` (bitácora) dependen del guard de consentimiento de esta fase
para sus flujos de subida. Recomendado implementar el esqueleto de esta fase (aceptación de
términos + interceptor de `403 CONSENT_REQUIRED`) antes o junto con `0007`/`0008`, aunque se
numera último por ser el orden en que José pidió las features — ver
`openspec/specs/data-and-media-consent.md`.

## Antes de empezar

Leer `openspec/specs/data-and-media-consent.md` y el spec de backend completo, en particular los
límites legales explícitos.

## Objetivo

Implementar el flujo de aceptación de documentos legales versionados, el manejo transversal de
`403 CONSENT_REQUIRED` en cualquier subida, y la pantalla de auto-gestión de consentimiento del
usuario.

## Alcance

**Incluye**: `lib/features/legal_consents/`, interceptor/helper reusable para `403
CONSENT_REQUIRED`, pantalla "Privacidad y datos" en "Mi perfil".

**No incluye**: redacción de contenido legal (consume el `contentUrl` real del backend, no lo
genera).

## Pantallas / flujos

- `data/legal_consents_api.dart` — `GET /legal/consents/pending`, `POST .../accept`,
  `GET /users/me/data-consents`, `DELETE /users/me/content/:referenceId/consent`.
- `providers/legal_consents_provider.dart` — `FutureProvider` de pendientes, `AsyncNotifier` de
  aceptar/revocar con invalidación de providers dependientes.
- Interceptor/helper en `core/api_client` (mismo espíritu que `BearerAuthInterceptor`/
  `LocaleHeaderInterceptor` ya existentes): detecta `403 CONSENT_REQUIRED` en cualquier response,
  expone un evento/estado que la UI puede escuchar para navegar al flujo de aceptación y reintentar
  la acción original al volver.
- `widgets/legal_consent_screen.dart` — presenta el/los documentos pendientes (texto real desde
  `contentUrl`, en WebView o abierto externamente), checkbox de aceptación, botón confirmar.
- `widgets/privacy_and_data_screen.dart` — dentro de "Mi perfil": historial de aceptaciones +
  contenidos con consentimiento de uso otorgado, opción de revocar con manejo de `409
  LEGAL_HOLD_ACTIVE`.

## Tareas

- [x] `data/`+`providers/`+`models/` de `legal_consents` — nombrado `legal_consents_repository.dart`
      en vez de `legal_consents_api.dart` (spec literal), para seguir la convención real ya usada
      en el resto del repo (`AuthRepository`, `PaymentsRepository`, etc.).
- [x] Interceptor de `403 CONSENT_REQUIRED` en `core/api_client`
      (`ConsentRequiredInterceptor`) + puente `ConsentRequiredBridge`/`ConsentGateway` (mismo
      patrón que `PushNotificationGateway`) para conectar el interceptor (sin `BuildContext`) con
      la navegación real de `go_router`.
- [x] Pantalla de aceptación de documento legal (`LegalConsentScreen`, ruta
      `/legal/consentimiento`) — muestra TODOS los pendientes (el guard del backend no indica cuál
      documentType puntual disparó el 403), checkbox por documento, "leer documento completo" abre
      el `contentUrl` real en el navegador (`url_launcher`, se prefirió a un WebView embebido por
      peso de dependencia).
- [x] Pantalla "Privacidad y datos" (`PrivacyAndDataScreen`, ruta
      `/perfil/privacidad-y-datos`, enlazada desde "Mi perfil") con historial + revocación.
- [ ] Selector de `usageScope` en formularios de subida (portafolio, avatar) — **diferido**: no
      existen todavía formularios de subida de portafolio/documentos (llegan con `0007`/`0008`),
      así que no hay dónde integrarlo hoy. `ContentConsentGrant.usageScope` y
      `LegalConsentsDbService.createContentGrant` (backend) ya existen, listos para cuando esos
      formularios se implementen.
- [x] Traducido a es/en (`lib/l10n/es.arb`/`en.arb`).
- [x] Tests: 22 tests nuevos — interceptor (6, incluyendo reintento tras aceptar y no-loop en
      rutas `/legal/consents`), repositorio (7), controller/provider (3), widget de aceptación (3),
      widget de privacidad (3). Suite completa del repo: 290/290 en verde.

## Checkpoint de salida

- [x] Un usuario sin consentimiento vigente que intenta subir un documento/foto es interceptado,
      completa la aceptación, y la subida original se reintenta automáticamente — cubierto por
      test unitario del interceptor (`ConsentRequiredInterceptor`); sin endpoint real de `0007`/
      `0008` todavía para un checkpoint end-to-end real, igual que el backend.
- [x] La pantalla "Privacidad y datos" refleja el historial — cubierto por widget test contra un
      repositorio mockeado; falta el checkpoint real de José contra el backend desplegado.
- [x] Revocar un consentimiento con `requiresLegalHold=true` muestra el motivo real (no un error
      genérico) — cubierto por widget test, verificado que el mensaje del backend se muestra tal
      cual.

## Amendment 2026-08-25 — `errorCode` en el backend

Durante esta fase se detectó que el backend (`0006`) no exponía ningún identificador
máquina-legible para que este interceptor distinga `CONSENT_REQUIRED` de cualquier otro 403 en
cualquier endpoint (el status 403 solo no alcanza, a diferencia de otros casos ya resueltos en la
app donde el status code es inequívoco por endpoint). Se agregó `errorCode` opcional al envelope
de error del backend (`HttpExceptionFilter`) — ver `TekoApp-Backend/openspec/decisions.md`. Sin
este campo, la única alternativa hubiera sido un interceptor global 403→consentimiento que también
secuestraría 403 de permisos genéricos en cualquier otro endpoint — riesgo real, no una
simplificación aceptable.

## Riesgos / límites explícitos

Mismo límite que el backend: el contenido legal real requiere asesoría legal por país — esta fase
solo construye el flujo técnico de consentimiento.
