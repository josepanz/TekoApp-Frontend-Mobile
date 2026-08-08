# Fase 0003 — Núcleo del marketplace de servicios

## Antes de empezar

Leer: `specs/services-marketplace.md`, `specs/i18n.md` (empezar a traducir desde este momento, no
al final).

## Objetivo

Los flujos centrales de cliente y profesional funcionando: pedir un servicio, verlo aceptado,
completarlo — sin pagos ni notificaciones push todavía (esos son fases separadas).

## Tareas

- [x] Catálogo de categorías/tipos de servicio (`GET /categories`, listado simple, sin necesidad
      de admin todavía).
- [x] Modo cliente: pantalla "pedir servicio" (categoría → tipo → descripción → ubicación →
      confirmar) → crea `Service` en PENDING.
- [x] Modo cliente: listado de "mis servicios" con detalle por servicio.
- [x] Modo profesional: activar/completar perfil profesional (crear `Professionals` si no existe
      — flujo de onboarding profesional, separado del onboarding de usuario básico).
- [x] Modo profesional: listado de servicios disponibles en mi categoría (PENDING sin profesional
      asignado) + acción de proponer (`ServiceRequest`).
- [x] Modo cliente: ver `ServiceRequests` competidoras sobre mi servicio PENDING, elegir una
      (acepta esa, las demás quedan implícitamente descartadas).
- [x] Modo profesional: marcar servicio asignado como en progreso / completado.
- [x] Manejo de 409 (conflicto de estado) en cualquier acción de cambio de estado — mensaje
      "esto cambió, actualizá la pantalla", nunca un error genérico (ver `project.md`).
- [x] Traducir a es/en todo texto visible de esta fase a medida que se escribe, no al final.

Checklist de código completo — ver PRs #41-#49 en `TekoApp-Frontend-Mobile`. Divergencias
deliberadas respecto al plan original, documentadas en `openspec/decisions.md`:
- Se implementó el flujo de `ServiceRequests` competidoras (no el atajo `POST /services/:id/accept`
  que usa `TekoApp-Web` hoy) porque la spec de esta fase lo pide explícitamente.
- Los Pasos 5 y 6 del plan de ejecución se fusionaron en un solo PR (selector de modo + gate +
  onboarding) — resultaron ser una sola unidad real de trabajo, el gate necesita `GET
  /professionals/me` para decidir el redirect.
- Proponerse (`ServiceRequest`) es de un solo toque, sin capturar precio/horas/mensaje en esta
  fase — el checkpoint no lo exige, queda como mejora de UX futura.
- El nombre del profesional en las propuestas competidoras se omite (`ServiceRequestDetailResponseDTO`
  no lo anida) — se muestra solo por `id`, resolverlo requeriría `GET /professionals/:id` por
  propuesta, fuera de alcance.

## Checkpoint de salida

Pendiente — requiere backend local corriendo + dos cuentas de prueba reales (una cliente, una
profesional) en dispositivo/emulador real, no verificable desde esta sesión sin esos recursos.
Responsabilidad de José, mismo criterio que las Fases 0001/0002.

- [ ] Flujo completo de punta a punta con dos usuarios de prueba reales (uno actuando de cliente,
      otro de profesional, en dos dispositivos/emuladores distintos o alternando sesión): pedir
      servicio → profesional propone → cliente acepta → profesional marca en progreso → profesional
      marca completado. Cada paso confirmado contra la DB real del backend (no solo "la pantalla
      no tira error").
- [ ] Un listado vacío (sin servicios todavía) muestra un estado vacío, no un error.
- [ ] Provocar un conflicto real (dos acciones de cambio de estado casi simultáneas desde dos
      sesiones) y confirmar que la UI maneja el 409 sin crashear.
- [ ] Todo el texto de esta fase existe en es Y en en.
