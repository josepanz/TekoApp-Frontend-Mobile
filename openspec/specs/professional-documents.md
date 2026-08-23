# Spec: Documentos y antecedentes del profesional

Backend: `TekoApp-Backend/openspec/specs/professional-documents.md` (modelo de datos completo,
parametrización, endpoints). Web: `TekoApp-Frontend-Web/openspec/specs/professional-documents.md`
(backoffice de verificación). Plan de fase: `openspec/changes/0007-professional-documents-and-background-checks.md`.

## Modelo de dominio (ya definido en el backend, replicar el contrato tal cual)

- **DocumentTypes**: catálogo parametrizable por país/categoría de profesional — `category`
  (`BACKGROUND_CHECK`/`QUALIFICATION`/`PORTFOLIO`), `isRequired`, `validityDays` (null = no vence),
  `isVisibleToClient`.
- **ProfessionalDocuments**: el documento cargado por un profesional — `status`
  (`PENDING`/`APPROVED`/`REJECTED`/`EXPIRED`), `fileKey` (S3, mismo patrón que `avatarKey`),
  `expiresAt`, `rejectionReason`.
- `Professionals.verificationStatus` (ya existe) se deriva de si todos los `DocumentTypes`
  obligatorios están `APPROVED` y vigentes.

## Flujos de UI esperados

### Profesional

1. "Mis documentos": ver qué tipos le corresponden (según su país+categoría), estado de cada uno,
   subir/re-subir.

### Cliente

1. En el perfil de un profesional: ver un resumen de verificación — badge "Antecedentes
   verificados" (booleano derivado, nunca el documento en sí), certificaciones aprobadas, galería
   de portafolio aprobada.

## Reglas de negocio a respetar en la UI

- **Nunca mostrar el contenido de un antecedente policial/judicial a un cliente** — solo el
  booleano derivado de verificación. El endpoint público (`/professionals/:referenceId/documents/public`)
  ya filtra esto server-side, pero la UI tampoco debería intentar mostrar un campo que ese endpoint
  no devuelve.
- Subir un documento requiere consentimiento vigente (ver `specs/data-and-media-consent.md`) — un
  `403 CONSENT_REQUIRED` debe interceptarse y llevar al flujo de aceptación, nunca mostrarse como
  error genérico.
- Un documento `REJECTED`/`EXPIRED` debe ofrecer re-subida directamente, no obligar a buscar la
  opción en otro lado.

## Fuera de alcance de esta spec

Verificación automática contra un organismo oficial (ver spec de backend).
