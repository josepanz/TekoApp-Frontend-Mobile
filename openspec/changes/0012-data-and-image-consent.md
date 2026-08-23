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

- [ ] `data/`+`providers/`+`models/` de `legal_consents`.
- [ ] Interceptor/helper de `403 CONSENT_REQUIRED` en `core/api_client`, integrado con go_router
      para navegar al flujo de aceptación y volver.
- [ ] Pantalla de aceptación de documento legal.
- [ ] Pantalla "Privacidad y datos" con historial + revocación.
- [ ] Selector de `usageScope` integrado en los formularios de subida relevantes (portafolio,
      avatar) — coordinar con las Fases 0007/0008 si ya están implementadas o implementarlo ahí
      directamente si esta fase se hace primero.
- [ ] Traducir a es/en.
- [ ] Tests: provider (aceptar, revocar, 409 legal hold), widget test del interceptor de 403
      (reintento tras aceptar), widget test de la pantalla de privacidad.

## Checkpoint de salida

- [ ] Un usuario sin consentimiento vigente que intenta subir un documento/foto es interceptado,
      completa la aceptación, y la subida original se reintenta automáticamente sin que el usuario
      tenga que repetir el flujo desde cero.
- [ ] La pantalla "Privacidad y datos" refleja el historial real de aceptaciones contra el backend.
- [ ] Revocar un consentimiento con `requiresLegalHold=true` muestra el motivo, no un error
      genérico.

## Riesgos / límites explícitos

Mismo límite que el backend: el contenido legal real requiere asesoría legal por país — esta fase
solo construye el flujo técnico de consentimiento.
