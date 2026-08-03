# Fase 0003 — Núcleo del marketplace de servicios

## Antes de empezar

Leer: `specs/services-marketplace.md`, `specs/i18n.md` (empezar a traducir desde este momento, no
al final).

## Objetivo

Los flujos centrales de cliente y profesional funcionando: pedir un servicio, verlo aceptado,
completarlo — sin pagos ni notificaciones push todavía (esos son fases separadas).

## Tareas

- [ ] Catálogo de categorías/tipos de servicio (`GET /categories`, listado simple, sin necesidad
      de admin todavía).
- [ ] Modo cliente: pantalla "pedir servicio" (categoría → tipo → descripción → ubicación →
      confirmar) → crea `Service` en PENDING.
- [ ] Modo cliente: listado de "mis servicios" con detalle por servicio.
- [ ] Modo profesional: activar/completar perfil profesional (crear `Professionals` si no existe
      — flujo de onboarding profesional, separado del onboarding de usuario básico).
- [ ] Modo profesional: listado de servicios disponibles en mi categoría (PENDING sin profesional
      asignado) + acción de proponer (`ServiceRequest`).
- [ ] Modo cliente: ver `ServiceRequests` competidoras sobre mi servicio PENDING, elegir una
      (acepta esa, las demás quedan implícitamente descartadas).
- [ ] Modo profesional: marcar servicio asignado como en progreso / completado.
- [ ] Manejo de 409 (conflicto de estado) en cualquier acción de cambio de estado — mensaje
      "esto cambió, actualizá la pantalla", nunca un error genérico (ver `project.md`).
- [ ] Traducir a es/en todo texto visible de esta fase a medida que se escribe, no al final.

## Checkpoint de salida

- [ ] Flujo completo de punta a punta con dos usuarios de prueba reales (uno actuando de cliente,
      otro de profesional, en dos dispositivos/emuladores distintos o alternando sesión): pedir
      servicio → profesional propone → cliente acepta → profesional marca en progreso → profesional
      marca completado. Cada paso confirmado contra la DB real del backend (no solo "la pantalla
      no tira error").
- [ ] Un listado vacío (sin servicios todavía) muestra un estado vacío, no un error.
- [ ] Provocar un conflicto real (dos acciones de cambio de estado casi simultáneas desde dos
      sesiones) y confirmar que la UI maneja el 409 sin crashear.
- [ ] Todo el texto de esta fase existe en es Y en en.
