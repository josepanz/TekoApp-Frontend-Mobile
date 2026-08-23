# Spec: Protección de datos, imágenes y su uso

Backend: `TekoApp-Backend/openspec/specs/data-and-media-consent.md`. Web (config/auditoría):
`TekoApp-Frontend-Web/openspec/specs/data-and-media-consent-admin.md`. Plan de fase:
`openspec/changes/0012-data-and-image-consent.md`.

**Spec más fundacional de las 6 en mobile también** — `specs/professional-documents.md` y
`specs/work-progress-log.md` (y potencialmente `specs/multi-option-quotes.md`) dependen del guard
de consentimiento descrito acá para cualquier subida de foto/documento.

## Modelo de dominio (ya definido en el backend, replicar el contrato tal cual)

- **LegalDocumentVersions**: catálogo versionado por país (`documentType`:
  `TERMS_OF_SERVICE`/`PRIVACY_POLICY`/`DATA_PROCESSING_CONSENT`/`IMAGE_USAGE_CONSENT`).
- **UserConsents**: aceptación de una versión por el usuario, con auditoría (`acceptedAt`, hash).
- **ContentConsentGrants**: alcance de uso (`APP_INTERNAL_ONLY`/`PUBLIC_PROFILE_DISPLAY`/
  `MARKETING`) elegido por el uploader para un contenido puntual, revocable.

## Flujos de UI esperados

1. Al detectar (vía `GET /legal/consents/pending`) que hay documentos legales sin aceptar, mostrar
   el flujo de aceptación antes de continuar con la acción que lo disparó — nunca bloquear toda la
   app de entrada si no hace falta para la pantalla actual.
2. Cualquier subida (documento, foto de avance, avatar, portafolio) que reciba `403
   CONSENT_REQUIRED` debe interceptar ese código específico y llevar al flujo de aceptación,
   reintentando la subida original al volver — nunca mostrar un error genérico de subida fallida.
3. Al subir contenido con alcance de uso relevante (ej. portafolio), ofrecer la elección de
   `usageScope` en el propio formulario de subida (no como un paso separado).
4. Pantalla "Privacidad y datos" (dentro de "Mi perfil"): historial propio de aceptaciones +
   contenidos con consentimiento de uso otorgado, con opción de revocar (maneja `409
   LEGAL_HOLD_ACTIVE` mostrando por qué no se puede retirar, no un error genérico).

## Reglas de negocio a respetar en la UI

- Nunca inventar el texto legal — siempre el `contentUrl` real que devuelve el backend
  (`LegalDocumentVersions`), renderizado en un WebView o abierto externamente, nunca reescrito.
- Revocar un consentimiento de uso puede ocultar contenido ya visible en otras pantallas
  (portafolio, avatar) — invalidar los providers relevantes tras una revocación exitosa.

## Fuera de alcance de esta spec

Redacción del contenido legal real (ver backend — límite explícito, no asesoría legal).
