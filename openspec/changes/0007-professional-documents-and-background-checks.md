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

- `data/professional_documents_repository.dart` — `GET /professionals/me/documents`,
  `GET /professionals/:referenceId/documents/public`, `GET /professionals/:referenceId`
  (solo `verificationStatus`), `POST /professionals/me/documents` (multipart directo, mismo patrón
  de `dio` que la subida de avatar).
- `providers/` — `myDocumentsProvider`, `publicProfessionalDocumentsProvider`,
  `professionalVerifiedProvider`, `professionalDocumentFileUrlProvider` (lectura) +
  `uploadDocumentControllerProvider` (`AsyncNotifier` de mutación, invalida `myDocumentsProvider`
  tras subir).
- `widgets/my_documents_screen.dart` — lista de tipos de documento requeridos/opcionales para el
  profesional (agrupados por `DocumentCategory`: antecedentes / habilitación / portafolio), cada
  fila con badge de estado (`TekoBadge`, texto + color, nunca solo color — ver
  `.claude/rules/design-system.md`) y botón "Subir"/"Volver a subir" (rechazado o vencido).
- Antes de habilitar el picker de imagen/archivo, chequear el flujo de consentimiento de
  `0012-data-and-image-consent.md` (`RequiresActiveConsentGuard` del lado backend devuelve 403
  `CONSENT_REQUIRED` — la UI debe interceptar ese código y navegar al flujo de aceptación de
  consentimiento antes de reintentar, no mostrar un error genérico).

### Cliente — corrección: `professional_profile_screen.dart` NO existe (ver `decisions.md`)

- **Corrección tras implementar**: no hay ninguna pantalla de "perfil público de profesional" en
  mobile todavía (verificado grepeando el repo, no asumido) — la sección se embebió en
  `service_detail_screen.dart` (mismo punto real donde el cliente ya ve al profesional asignado,
  igual criterio que `ProgressTimeline`/Fase 0008), no en la pantalla que decía la spec.
- Sección "Documentos y antecedentes": badge "Antecedentes verificados" (booleano derivado,
  nunca el documento en sí — resuelto vía `GET /professionals/:referenceId`, ya que el endpoint de
  documentos públicos filtra `BACKGROUND_CHECK` server-side), lista de certificaciones/portafolio
  aprobados (`GET /professionals/:referenceId/documents/public`).
- Si el profesional no tiene nada aprobado todavía, muestra el estado vacío correspondiente, nunca
  oculta la sección entera sin explicación (mismo estándar de estados vacío del resto de la app).

## Tareas

- [x] `data/`+`providers/`+`models/` de `professional_documents` (Profesional).
- [x] Pantalla "Mis documentos" con badges de estado y flujo de subida/re-subida — solo foto
      (cámara/galería), sin PDF nativo (no hay `file_picker` en el proyecto, ver `decisions.md`).
- [x] `403 CONSENT_REQUIRED` — cubierto por el interceptor global (`ConsentRequiredInterceptor`,
      `core/api_client`), sin manejo especial nuevo en este repositorio (mismo criterio que
      `service_progress`).
- [x] Sección "Documentos y antecedentes" — embebida en `service_detail_screen.dart` (Cliente), no
      en la pantalla que decía la spec (ver corrección arriba).
- [x] Traducido a es/en todo texto nuevo de esta fase.
- [x] Tests: repositorio (4), controller de subida (2), widget de "Mis documentos" (4) — 10 tests
      nuevos.
- [x] `flutter analyze` sin issues, `flutter test` completo (330/330) en verde.

## Checkpoint de salida

- [ ] Un profesional sube un documento, staff lo aprueba desde `TekoApp-Frontend-Web`, y el estado
      cambia a "Aprobado" en mobile sin necesitar reinstalar/reloguear — verificado con tests
      unitarios (`ref.invalidate` tras la mutación); falta el checkpoint real end-to-end contra
      Web (Web Fase 0001 todavía no implementada).
- [ ] Un cliente ve el badge de verificación en el perfil de un profesional real ya aprobado — no
      verificado contra datos reales, solo con tests.
- [x] Subir sin haber aceptado el consentimiento correspondiente muestra el flujo de aceptación
      (interceptor global ya probado en la Fase 0012), no un error genérico.

## Riesgos / límites explícitos

Mismo límite que el spec de backend: qué exige cada país realmente sobre antecedentes es una
decisión de negocio real, no asumida acá — el catálogo puede llegar vacío o incompleto hasta que se
cargue con datos confirmados.
