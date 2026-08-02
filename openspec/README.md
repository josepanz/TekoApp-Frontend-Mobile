# OpenSpec en TekoApp-Mobile — cómo trabajar acá

Esta carpeta implementa **SDD (Specification-Driven Development)** al estilo OpenSpec: antes de
escribir una línea de Dart, el comportamiento esperado se escribe como spec; el código se
implementa contra esa spec; cuando la capacidad está construida y estable, la spec pasa a ser la
documentación viva de "cómo se comporta esto hoy".

## Por qué esto en vez de arrancar directo a codear

Este repo arranca de cero, pero **el dominio no es nuevo** — `TekoApp-Backend` y `TekoApp-Web` ya
resolvieron auth, el contrato de la API, el modelo de datos y varias decisiones de diseño no
triviales (algunas por prueba y error, con bugs reales encontrados y corregidos). Si la
implementación de mobile arranca directo a codear sin pasar por esta carpeta, se corre el riesgo
real de:

- Repetir decisiones ya tomadas y descartadas (ej.: exponer el `id` interno en vez de
  `referenceId`, ya identificado como anti-patrón en el backend).
- Reinventar el contrato de auth sin conocer las 3 fricciones que ya resolvió el BFF de
  `TekoApp-Web` (cifrado RSA del password, Basic Auth de cliente, traducción Bearer↔Cookie) — acá
  se resuelven distinto (mobile no tiene un servidor propio), pero hay que conocer el motivo para
  no romper el contrato del lado del backend.
- Construir UI para una arquitectura de notificaciones (push) que todavía no está decidida en el
  backend — ya está, ver `specs/notifications-push.md`.

## Estructura de esta carpeta

```
openspec/
├── README.md            ← este archivo
├── project.md            ← contexto heredado de backend/web — leer ANTES que nada
├── decisions.md          ← decisiones de arquitectura específicas de mobile (ADR-style)
├── specs/                ← el contrato de cada capacidad, tal como debe comportarse
│   ├── auth-and-session.md
│   ├── api-client.md
│   ├── design-system.md
│   ├── i18n.md
│   ├── services-marketplace.md
│   ├── payments.md
│   ├── notifications-push.md
│   └── realtime-location.md
└── changes/              ← el plan de implementación en fases, con tasks y checkpoints
    ├── 0001-project-bootstrap.md
    ├── 0002-auth-and-design-system.md
    ├── 0003-services-marketplace-core.md
    ├── 0004-payments-and-ratings.md
    ├── 0005-realtime-and-push.md
    └── 0006-i18n-and-polish.md
```

## Flujo de trabajo esperado (por fase, ver `changes/`)

1. Abrir el archivo de la fase correspondiente en `changes/`. Cada uno tiene una sección
   **"Antes de empezar"** (qué specs leer) y una sección **"Checkpoint de salida"** (qué debe
   funcionar, verificado de verdad — no solo "compila" — antes de pasar a la fase siguiente).
2. Si la fase toca una capacidad con spec en `specs/`, leer esa spec primero — ahí está el
   contrato esperado (qué recibe, qué devuelve, qué casos de error, qué decisiones de UX ya están
   tomadas).
3. Implementar. Si en el camino aparece una decisión no cubierta por ninguna spec, agregarla a
   `decisions.md` con su motivo ANTES de seguir — no dejarla solo en el código.
4. Al cerrar la fase: correr el checkpoint completo, marcar los ítems de `tasks` en el archivo de
   la fase, y recién ahí pasar a la próxima.

## Ahorro de costo / uso de agentes

Cuando se retome este repo con agentes de IA, el patrón recomendado (evita relecturas completas de
todo el código en cada tarea):

- Para **una tarea acotada dentro de una fase ya en curso** (ej. "agregá el campo teléfono al
  form de perfil"): un solo agente directo, sin research previo — la spec de la capacidad ya tiene
  el contrato, no hace falta re-derivarlo.
- Para **iniciar una fase nueva completa**: un agente de "Understand" que lea la spec + el código
  ya escrito de la fase anterior (no todo el repo) y arme un plan concreto de archivos a
  crear/tocar, ANTES de empezar a escribir código — barato porque el scope ya está acotado por la
  spec, no es exploración abierta.
- Nunca lanzar un agente a "implementar mobile" sin acotar a una fase — es exactamente el tipo de
  tarea que dispara research/código redundante y gasta presupuesto sin necesidad.
