# Spec: Contratos generados desde el presupuesto aceptado

Backend: `TekoApp-Backend/openspec/specs/service-contracts.md`. Plan de fase:
`openspec/changes/0010-contracts-from-accepted-budget.md`. **Depende de
`specs/multi-option-quotes.md`.**

## Modelo de dominio (ya definido en el backend, replicar el contrato tal cual)

- **Contracts**: `status` (`DRAFT`/`PENDING_CLIENT_SIGNATURE`/`PENDING_PROFESSIONAL_SIGNATURE`/
  `SIGNED`/`CANCELLED`), `contentSnapshot` (JSON inmutable del presupuesto aceptado + alcance del
  servicio), campos de firma por rol (`clientSignedAt`/`clientSignatureName`/
  `professionalSignedAt`/`professionalSignatureName`), `pdfKey` (recién disponible cuando
  `status = SIGNED`).

## Flujos de UI esperados

1. Tras seleccionar una opción de presupuesto (`specs/multi-option-quotes.md`), generar el
   contrato (automático o explícito, confirmar contra el backend real).
2. Vista previa del contrato: renderizar `contentSnapshot` de forma legible (nunca JSON crudo).
3. Firma: checkbox "Leí y acepto" + nombre completo tipeado → `POST /contracts/:referenceId/sign`.
4. Descarga/visualización del PDF una vez firmado por ambas partes.

## Reglas de negocio a respetar en la UI

- **Copy honesto sobre el mecanismo de firma**: no es una firma digital calificada (ver
  `TekoApp-Backend/openspec/specs/service-contracts.md` — "Riesgos"), la UI debe reflejar esto sin
  sobre-prometer validez legal — confirmar el texto exacto con José antes de publicar.
- Estado de firma siempre con texto + ícono, nunca solo color ("Pendiente de tu firma"/"Pendiente
  de la otra parte"/"Firmado por ambos").
- Manejar 409 si se intenta firmar dos veces o fuera de turno, con el mensaje del backend.

## Fuera de alcance de esta spec

Edición del contenido del contrato desde mobile — el contenido es un snapshot inmutable armado por
el backend.
