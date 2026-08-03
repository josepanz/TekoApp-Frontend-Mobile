# tekoapp-frontend-mobile

## Estado de este repo

**Todavía no hay código Flutter.** Lo que existe hoy es documentación SDD completa en
`openspec/` (contexto heredado, decisiones, specs por capacidad, plan de implementación en 6
fases) — ver `openspec/README.md` para cómo está organizada y en qué orden seguirla.

**Protocolo de inicio de sesión** (antes de escribir código o responder cualquier pregunta de
arquitectura): leer, en este orden, `openspec/project.md` → `openspec/decisions.md` → la sesión
más reciente en `.claude/memory/sessions/` → el archivo de la fase correspondiente en
`openspec/changes/`. Ver `.claude/memory/memory.md` para el protocolo completo.

## Dominio

App Flutter (iOS + Android, un solo codebase) para el mismo marketplace de servicios
profesionales que `TekoApp-Web`: conecta usuarios (piden servicios) con profesionales (los
ofrecen), mismo backend (`TekoApp-Backend`, NestJS). Un usuario opera como cliente o profesional
con la misma cuenta — no hay apps separadas por rol (ver `openspec/project.md`).

## Stack decidido (ver `openspec/decisions.md` para el motivo de cada uno)

- **Flutter 3** — un codebase para iOS + Android.
- **Riverpod** — manejo de estado (`FutureProvider`/`AsyncNotifier` ≈ `useQuery`/`useMutation` de
  TanStack Query en `TekoApp-Web` — mismo patrón mental "hook por operación de servidor").
- **go_router** — ruteo declarativo + guards de ruta (≈ `proxy.ts` de `TekoApp-Web`).
- **dio** — cliente HTTP (interceptors para Bearer + refresh en 401, multipart nativo).
- **Sin decidir todavía** (no asumir sin confirmar en la fase correspondiente): almacenamiento
  seguro de tokens (candidato `flutter_secure_storage`), cifrado RSA-OAEP (candidato
  `pointycastle` — **verificar el padding contra el backend real antes de dar por resuelto**, ver
  `openspec/project.md`), testing framework, CI/CD, offline-first vs. online-only.

## Estructura de carpetas (planeada, se crea en Fase 0001 — `openspec/changes/0001-project-bootstrap.md`)

Espejo del patrón `features/<dominio>/` ya validado en `TekoApp-Web` (`api.ts`/`hooks.ts`/
`schemas.ts`/`components/`), adaptado a Riverpod/Flutter:

```
lib/
├── main.dart
├── core/
│   ├── api_client/       # dio + interceptors (Bearer, refresh, envelope unwrap)
│   ├── auth/              # sesión, guards de go_router, secure storage
│   ├── config/            # env vars, endpoints
│   └── theme/             # ThemeData claro/oscuro generado desde tokens.json
├── features/
│   └── <dominio>/
│       ├── data/          # llamadas a la API (≈ api.ts)
│       ├── providers/     # Riverpod providers (≈ hooks.ts)
│       ├── models/        # clases de datos (≈ types del OpenAPI generado en TekoApp-Web)
│       └── widgets/       # pantallas + componentes del dominio (≈ components/)
├── shared/
│   └── widgets/           # Button/Card/Avatar/Badge/Input compartidos (≈ components/ui/)
└── l10n/                  # es/en (mismo patrón de traducción incremental que TekoApp-Web)
```

**No crear esta estructura antes de la Fase 0001** — es el plan, no el estado actual (no hay
`lib/` todavía).

## Reglas críticas

- **`referenceId` (UUID) en URLs y estado de UI, nunca el `id` interno** — mismo patrón que
  `TekoApp-Backend`/`TekoApp-Web` (ver `openspec/project.md`).
- **`avatarKey` (persistido) vs. `avatarUrl` (resuelto, expira en 900s)** — nunca persistir una
  URL presignada de S3, siempre resolver fresca en cada request (bug real ya encontrado y
  corregido en `TekoApp-Web`, ver `openspec/project.md`).
- **Nunca reimplementar lógica de negocio** — este repo es un cliente puro de
  `TekoApp-Backend`, igual que `TekoApp-Web`. Si una regla de negocio no está clara, confirmarla
  contra el backend real (Swagger/`GET /swagger-json`) antes de asumir.
- **Nunca asumir un patrón de `TekoApp-Web` aplica 1:1** — mobile no tiene servidor propio (no hay
  equivalente al BFF de Next.js), así que el manejo de secrets/tokens es distinto. Ver
  "Qué NO replicar del BFF web" en `openspec/project.md`.
- **Transiciones de estado esperan 409** — el backend usa `updateMany` condicional para evitar
  TOCTOU en cambios de estado concurrentes (aceptar/completar un servicio, etc.) — la UI debe
  manejar el 409 con un mensaje claro ("esto cambió, actualizá la pantalla"), nunca un error
  genérico.
- **Un listado vacío es 200 con `[]`, nunca 404** — no tratar "sin resultados" como error.

## Reglas de proyecto

- @./rules/flutter-architecture.md
- @./rules/test.md
- @./rules/datetime.md
- @./rules/auth.md
- @./rules/design-system.md
- @./rules/i18n.md

## Agentes

- @./agents/code-reviewer.md
- @./agents/testing-agent.md
- @./agents/tdd-refactor.md

## Comandos

- `/commit` — genera un commit siguiendo Conventional Commits (ver `.claude/commands/commit.md`)

## graphify

Todavía no hay código para generar un grafo (`lib/` no existe). Una vez que la Fase 0001 cree las
primeras carpetas, correr `/graphify .` para generar `graphify-out/` — a partir de ahí, mismo
protocolo que los otros 2 repos: `graphify query "<pregunta>"` antes de grep crudo,
`graphify update .` después de cada cambio de código.
