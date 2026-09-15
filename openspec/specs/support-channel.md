# Spec: Canal de soporte in-app (Mobile)

Plan de fase: `openspec/changes/platform-hardening-2026-09/WORKPLAN.md`, tarea I-03. Solo spec —
sin implementación (ver instrucción explícita de la tarea).

## Objetivo

Hoy un usuario con un pago fallido (`Payment.status == failed`, ver `payment_status.dart`) o un
profesional que no apareció a un servicio `ACCEPTED`/`IN_PROGRESS` (ver `service_status.dart`) no
tiene **ningún canal dentro de la app** para contactar a nadie — la única salida es que sepa buscar
un email o número de teléfono por fuera de la app, si es que existe uno publicado en algún lado.
Para un marketplace que mueve plata real, es el hueco más grande de los tres de este workflow
(I-03/I-04/I-05).

## Alcance

**Incluye**: una pantalla "Ayuda y soporte" accesible desde `profile_screen.dart` (mismo patrón que
el link a `/perfil/privacidad-y-datos`, ver abajo), un formulario de contacto (asunto + mensaje +
adjuntar automáticamente el contexto de dónde se abrió — ver "Contexto disparador"), y accesos
directos contextuales desde las 2 pantallas donde el problema real ocurre HOY:
`payment_detail_screen.dart` (cuando `status == failed`) y `service_detail_screen.dart` (cuando el
servicio está `ACCEPTED`/`IN_PROGRESS`, sin distinción de "no-show" — ver Decisión de alcance del
backend).

**No incluye (fuera de esta fase)**: chat en vivo, historial de conversación dentro de la app (ver
Decisión de persistencia), un sistema de tickets con estados/SLA, IA/bot de primera respuesta.

## Decisión: reusar `EmailModule` del backend, no un canal externo (WhatsApp/Intercom/Zendesk)

`TekoApp-Backend` ya tiene `src/modules/email/` (nodemailer + `EmailTypeEnum` con templates) usado
hoy para notificaciones transaccionales (ver `auth-api.service.ts`, `onboarding.service.ts`). Un
`POST /support/contact` que arma un email con `EmailService` a una casilla de soporte
(`soporte@tekoapp.com.py` o la que José confirme) es la opción de menor esfuerzo — no depende de
contratar/configurar una herramienta de terceros (costo, otra cuenta que administrar, otro punto de
falla) para resolver el hueco más urgente. Migrar a una herramienta de soporte dedicada (si el
volumen lo justifica) es una decisión de producto posterior, no un bloqueante de esta fase.

## Decisión: sí persistir el contacto en una tabla propia, no solo enviar el email

Un email que se pierde en una bandeja de entrada sin registro es tan malo como no tener canal —
nadie puede auditar "cuántos reclamos hubo esta semana" ni cruzarlo con el pago/servicio en
cuestión. Backend necesita (dependencia de esta spec, ver abajo) una entidad `SupportRequest` con
`referenceId`, `userId`, `subject`, `message`, `context` (tipo + `referenceId` del pago/servicio que
lo disparó, si vino de un acceso contextual), `createdAt`. El email sigue siendo el mecanismo de
AVISO a staff (no hay panel de admin para esto todavía — fuera de alcance), pero la fila queda
como registro auditable pase lo que pase con el email.

## Contexto disparador — qué datos viajan sin que el usuario los tipee

| Origen | Se precarga | Por qué |
|---|---|---|
| `profile_screen.dart` → "Ayuda y soporte" | Nada (formulario en blanco) | Acceso genérico, sin problema puntual todavía |
| `payment_detail_screen.dart`, botón visible si `status == failed` | `context: {type: 'payment', referenceId}`, asunto prellenado (`l10n`, ej. "Problema con mi pago") | El usuario no debería tener que explicar de qué pago habla — YA está mirando el pago con problema |
| `service_detail_screen.dart`, botón visible si `status` en `{accepted, inProgress}` | `context: {type: 'service', referenceId}`, asunto prellenado (ej. "Problema con este servicio") | Mismo criterio — el servicio problemático ya está en pantalla |

El mensaje libre lo sigue escribiendo el usuario siempre — precargar el asunto/contexto ahorra
fricción, no reemplaza la descripción del problema.

## Decisión de alcance del backend: sin "no-show" como estado propio

`ServiceStatus` no tiene un estado "no-show" (ver `service_status.dart`) y esta spec **no** propone
agregar uno — sería una decisión de dominio de servicios más grande, fuera de I-03. El botón de
soporte en `service_detail_screen.dart` se ofrece para cualquier servicio `ACCEPTED`/`IN_PROGRESS`
sin distinguir el motivo (no-show, mala calidad, etc.) — el motivo lo explica el usuario en el
mensaje libre, no un desplegable de categorías (que requeriría diseñar el catálogo de motivos,
también fuera de alcance).

## Dependencia de backend (bloqueante, no de esta fase)

Igual que I-01, esta spec depende de trabajo del lado `TekoApp-Backend` que no existe hoy:

- Migración Prisma: tabla `support_requests` (campos de la sección anterior).
- `POST /support/contact` (versionado o no según se defina la política general de versionado, ver
  M-07/nota de fondo) — auth requerida (`JwtAuthGuard`), rate-limit razonable (evitar spam desde
  una cuenta comprometida).
- Nueva entrada en `EmailTypeEnum` + template para el aviso a staff.
- Definir la casilla de destino real (`soporte@...`) — dato de producto, no técnico, que José debe
  confirmar antes de implementar.

**Implementación en Mobile cuando el endpoint exista**: `lib/features/support/` nuevo (mismo
patrón de dominio que el resto — `data/support_repository.dart`,
`providers/submit_support_request_controller_provider.dart`, `widgets/support_screen.dart`), ruta
`/ayuda` colgada de `profile_screen.dart`, más los 2 accesos contextuales de la tabla de arriba.

## Fuera de alcance de esta spec

Chat en vivo, historial de mensajes previos dentro de la app, categorías de motivo de reclamo,
integración con una herramienta de soporte de terceros, estado "no-show" en `ServiceStatus`, panel
de administración de `SupportRequest` (Web/staff) — este último es candidato natural para
`TekoApp-Frontend-Web`, coordinarlo con ese repo cuando se implemente.

## Riesgos / límites explícitos

- **Sin panel de staff**: hasta que exista uno (fuera de alcance), la única forma de atender un
  `SupportRequest` es leer el email de aviso y actuar manualmente — la fila en la tabla queda como
  registro, no como cola de trabajo gestionable.
- **Rate-limit**: sin uno, un usuario (o una cuenta comprometida) podría floodear la casilla de
  soporte. Confirmar el límite concreto con backend al implementar, no dejarlo sin límite "para
  después".
- **Contexto insuficiente si el problema no es de un pago/servicio puntual**: el acceso genérico
  desde `profile_screen.dart` no tiene contexto — si el volumen de esos casos resulta alto en la
  práctica, agregar más accesos contextuales (ej. desde `professional_documents` si un documento
  fue rechazado injustamente) es una extensión chica de esta misma spec, no un rediseño.
