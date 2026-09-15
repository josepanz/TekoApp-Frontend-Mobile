# Arquitectura Flutter — reglas de estructura

> `lib/` ya existe desde la Fase 0001 (`openspec/changes/0001-project-bootstrap.md`) — esta regla
> aplica al código real, no solo al plan.

## Estructura por dominio (espejo de `features/<dominio>/` en `TekoApp-Web`)

```
lib/features/<dominio>/
├── data/           # llamadas a la API vía dio (≈ features/<dominio>/api.ts)
├── providers/      # Riverpod: FutureProvider/AsyncNotifier (≈ features/<dominio>/hooks.ts)
├── models/         # clases de datos del dominio (≈ tipos de types.generated.ts)
└── widgets/        # pantallas + componentes específicos del dominio (≈ components/)
```

- Un provider por operación de servidor (query o mutación), igual que un hook de TanStack Query
  en `TekoApp-Web` — nunca un provider gigante que mezcle 3 operaciones distintas.
- `models/` son clases de datos puras (constructor + `fromJson`/`toJson`), sin lógica de negocio.
- Las pantallas (`widgets/`) consumen providers vía `ref.watch`/`ref.read` — nunca lógica de
  fetching directa dentro de un widget (`initState` + llamada manual a `data/` es el anti-patrón
  equivalente a "useEffect + fetch manual" que las reglas de `TekoApp-Web` prohíben).

## `core/` — infraestructura compartida, sin lógica de negocio de dominio

```
lib/core/
├── api_client/     # instancia de dio + interceptors (Bearer, refresh en 401, unwrap del
│                     envelope {success,data,message,timestamp,path})
├── auth/           # sesión, guards de go_router, almacenamiento seguro de tokens
├── config/         # env vars, endpoints, flags
└── theme/          # ThemeData claro/oscuro generado desde tokens.json (ver rules/design-system.md)
```

`core/api_client` es el único lugar que conoce la URL real del backend y arma el interceptor de
auth — ningún `data/` de un dominio construye su propio cliente HTTP.

## `shared/widgets/` — primitivos reusables

Equivalente a `components/ui/` de `TekoApp-Web` (Button, Card, Avatar, Badge, Input). Antes de
escribir un widget nuevo acá, revisar qué variantes ya existen en
`TekoApp-Web/src/components/ui/` como referencia de qué estados/variantes hacen falta — no
reinventar desde cero qué botones/estados existen (ver `openspec/changes/0002-...`).

## Identificadores — `referenceId`, nunca `id`

Cualquier modelo (`models/`) que represente una entidad de negocio del backend debe exponer
`referenceId` (String, UUID) para navegación/deep-linking — el `id` interno (si el backend lo
incluye en la respuesta) nunca se usa en rutas de `go_router` ni se persiste como identificador de
UI. Ver `openspec/project.md`.

## Multi-rol en una sola app

Un usuario puede operar como cliente o profesional con la misma cuenta (ver `openspec/project.md`)
— replicar el selector de modo de `TekoApp-Web`, no separar en flujos de navegación
completamente distintos que dupliquen pantallas.

## Prefijo `/v1` centralizado en `ApiClient`

El prefijo de versionado `/v1` vive en UN SOLO lugar: `lib/core/api_client/api_client.dart`,
en el método `_buildDefaultDio()` como parte del `baseUrl`:
`baseUrl: '${Env.apiBaseUrl}/v1'`.

Está **prohibido** escribir `/v1` a mano en rutas individuales de ningún repositorio de feature
(`lib/features/<dominio>/data/`). La razón técnica: en Dio 5.x, el getter `RequestOptions.uri`
de un interceptor recibe `requestOptions.path` exactamente como el string pasado a
`dio.get(path)` — el `baseUrl` nunca se reescribe dentro de `path`, solo se concatena al
resolver `.uri`. Por eso los interceptores que usan `_excludedPaths` (como el de refresh token)
comparan contra `requestOptions.path` SIN el prefijo `/v1`. Si alguien vuelve a escribir `/v1`
manualmente en `_excludedPaths`, el matcheo falla silenciosamente y funcionalidades como el
refresh automático de token se rompen sin avisar. Verificar: `openspec/decisions.md`, sección
"Versionado centralizado de API".

## Setup nativo de plugins de Flutter — verificación en device

Cuando se agrega una dependencia de Flutter que declara requisitos de configuración nativa
(AndroidManifest, Info.plist, MainActivity, etc.), los tests unitarios NO la ejercitan. Hay que:

1. **Leer los requisitos de setup** del plugin (en su README o docs de pub.dev).
2. **Verificar en un device real** (Android `adb devices`, iOS Simulator o device Mac).

Caso concreto: `local_auth` exige `FlutterFragmentActivity` en `MainActivity.kt` y
`NSFaceIDUsageDescription` en `Info.plist`. Sin eso, `flutter test` da 476 tests en verde pero
`authenticate()` falla en runtime. Los mockeos de tests no evocan la configuración nativa —
es imposible detectar esta clase de bug sin un device. Documentación completa:
`openspec/decisions.md`, sección "Login biométrico opt-in".
