# Fase 0007 — Documentos y antecedentes del profesional

Spec de diseño, NO implementada todavía — feature 6 del backlog 2026-08-22
(`openspec/decisions.md`). Contrato de dominio: `openspec/specs/professional-documents.md` (mobile),
`TekoApp-Backend/openspec/specs/professional-documents.md` (backend).
Web (backoffice de verificación): `TekoApp-Frontend-Web/openspec/specs/professional-documents.md`.

## Antes de empezar

Leer `openspec/specs/professional-documents.md` primero (contrato de esta capacidad para mobile),
y los 2 documentos de backend/web arriba (definen el modelo de datos y los endpoints reales) — esta
fase no repite el modelo de datos, solo lo que le toca a mobile.

## Objetivo

Dos flujos de usuario:

1. **Profesional**: cargar los documentos que su país+categoría le exigen o le permiten (antecedentes
   policiales/judiciales, títulos, certificados, portafolio), ver el estado de cada uno
   (pendiente/aprobado/rechazado/vencido) y volver a cargar si corresponde.
2. **Cliente**: ver, en el perfil de un profesional, un resumen de verificación (badges de
   "antecedentes verificados", certificaciones, galería de portafolio) antes de contratar.

## Alcance

**Incluye**: pantalla "Mis documentos" (profesional), sección "Documentos y antecedentes" en el
perfil público de un profesional (cliente), subida multipart reusando el mismo mecanismo de
`core/api_client` que ya sube el avatar.

**No incluye**: ninguna lógica de verificación automática — mobile solo sube y muestra estado, la
aprobación/rechazo la hace staff desde `TekoApp-Frontend-Web`.

## Pantallas / flujos

### Profesional — `lib/features/professional_documents/`

- `data/professional_documents_api.dart` — `GET /document-types` (filtrado por el país/categoría
  del profesional logueado), `GET /professionals/me/documents`, `POST /professionals/me/documents`
  (multipart, mismo patrón de `dio` que la subida de avatar).
- `providers/` — un provider por operación (`documentTypesProvider`, `myDocumentsProvider`,
  `uploadDocumentProvider` como `AsyncNotifier` de mutación con invalidación del listado tras
  subir).
- `widgets/my_documents_screen.dart` — lista de tipos de documento requeridos/opcionales para el
  profesional (agrupados por `DocumentCategory`: antecedentes / habilitación / portafolio), cada
  fila con badge de estado (`TekoBadge`, texto + color, nunca solo color — ver
  `.claude/rules/design-system.md`) y botón "Subir"/"Volver a subir" (rechazado o vencido).
- Antes de habilitar el picker de imagen/archivo, chequear el flujo de consentimiento de
  `0012-data-and-image-consent.md` (`RequiresActiveConsentGuard` del lado backend devuelve 403
  `CONSENT_REQUIRED` — la UI debe interceptar ese código y navegar al flujo de aceptación de
  consentimiento antes de reintentar, no mostrar un error genérico).

### Cliente — dentro de `lib/features/professionals/widgets/professional_profile_screen.dart` (ya existe)

- Nueva sección "Documentos y antecedentes": badge "Antecedentes verificados" (booleano derivado,
  nunca el documento en sí), lista de certificaciones aprobadas con nombre/tipo, galería de fotos
  de portafolio aprobadas (`GET /professionals/:referenceId/documents/public`).
- Si el profesional no tiene nada aprobado todavía, mostrar el estado vacío correspondiente, nunca
  ocultar la sección entera sin explicación (mismo estándar de estados vacío del resto de la app).

## Tareas

- [ ] `data/`+`providers/`+`models/` de `professional_documents` (Profesional).
- [ ] Pantalla "Mis documentos" con badges de estado y flujo de subida/re-subida.
- [ ] Manejo explícito de `403 CONSENT_REQUIRED` antes de cualquier subida.
- [ ] Sección "Documentos y antecedentes" en el perfil público de profesional (Cliente).
- [ ] Traducir a es/en todo texto nuevo de esta fase.
- [ ] Tests: provider de subida (happy path, error, 403 consentimiento), widget test de la pantalla
      "Mis documentos" (estados pendiente/aprobado/rechazado/vencido/vacío).

## Checkpoint de salida

- [ ] Un profesional sube un documento, staff lo aprueba desde `TekoApp-Frontend-Web`, y el estado
      cambia a "Aprobado" en mobile sin necesitar reinstalar/reloguear (refetch al volver a la
      pantalla).
- [ ] Un cliente ve el badge de verificación en el perfil de un profesional real ya aprobado.
- [ ] Subir sin haber aceptado el consentimiento correspondiente muestra el flujo de aceptación, no
      un error genérico.

## Riesgos / límites explícitos

Mismo límite que el spec de backend: qué exige cada país realmente sobre antecedentes es una
decisión de negocio real, no asumida acá — el catálogo puede llegar vacío o incompleto hasta que se
cargue con datos confirmados.
