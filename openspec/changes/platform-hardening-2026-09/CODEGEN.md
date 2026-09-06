# Propuesta — codegen de modelos desde el OpenAPI del backend (M-04)

> Contexto: B-01 (`lib/features/ratings/models/rating.dart`) crasheaba porque el modelo a mano
> casteaba `userId`/`professionalId` a `int` no-nullable cuando el backend los documenta como
> `number | null`. Nada en el repo detecta ese tipo de divergencia hoy — cada uno de los ~30
> modelos de `lib/features/*/models/*.dart` se escribe y mantiene a mano. Esta propuesta busca
> que la PRÓXIMA divergencia se vea en un diff antes de mergear, no en un stacktrace en producción.

## 1. Qué hace hoy `TekoApp-Frontend-Web` (y por qué no alcanza como estaba descrito)

`TekoApp-Frontend-Web` corre `pnpm generate:api-types` (`scripts/generate-api-types.mjs`, ~20
líneas) contra `openapi-typescript`, que baja el swagger-json del backend y genera
`src/core/api-client/types.generated.ts`. El pipeline de Web (`.github/workflows/pipeline.yml`)
corre `pnpm check:types` (`tsc --noEmit`) en cada PR.

**Aclaración importante que corrige una asunción del WORKPLAN**: `check:types` valida que el
código de Web sea consistente con `types.generated.ts` **tal como está commiteado**. El pipeline
de Web **no** corre `generate:api-types` contra un backend vivo — no hay un job que regenere y
compare. Si el backend cambia un DTO y nadie corre el script a mano, `types.generated.ts` queda
desactualizado y `tsc` no lo detecta (linter contra un contrato viejo, no contra el real). Esto no
es un defecto de esta propuesta: es una limitación real y actual de Web que esta propuesta debería
evitar repetir en Mobile en vez de copiar tal cual.

## 2. Por qué Mobile necesita más que "generar tipos"

TypeScript no tiene validación de tipos en runtime: `types.generated.ts` solo sirve para que el
compilador de Web marque un error si el código usa un campo con el tipo equivocado. Dart/Flutter
**sí** ejecuta casts en runtime (`json['x'] as int`) — ahí es donde B-01 explotó. Un generador para
Mobile tiene que producir **código que castea en runtime**, no solo declaraciones de tipo. Esto
descarta cualquier opción que solo genere una capa de tipado estático sin `fromJson`.

## 3. Opciones evaluadas

| Opción | A favor | En contra (específico de este repo) |
|---|---|---|
| **`openapi_generator`** (pub.dev) | Genera modelos + cliente completos; activamente mantenido | Necesita Java (o Docker) para el generador subyacente — nueva dependencia de infraestructura para un repo que hoy es Flutter puro. Genera también un **cliente HTTP propio**, que no encaja con `ApiClient`/los interceptors de dio (Bearer, refresh-en-401, consentimiento-en-403, retry — ver M-01/M-02/M-03/M-06): usarlo solo para modelos requiere descartar la mitad de lo que genera. |
| **`swagger_dart_code_generator`** | 100% Dart/`build_runner`, sin Java/Docker | También genera un cliente propio con el mismo choque de arquitectura que arriba. Migrar "solo modelos" de un dominio a la vez es más fricción de la que promete un generador todo-o-nada — no está pensado para adopción incremental campo por campo. |
| **Script propio** (elegida) | Mismo espíritu que `generate-api-types.mjs` de Web (pequeño, sin dependencias nuevas, hace UNA cosa); genera solo lo que hace falta (`fromJson` vía `part`/`part of`, patrón estándar de Dart — el mismo que usa `json_serializable`); adoptable dominio por dominio sin tocar los otros ~29 modelos | Cobertura de shapes de OpenAPI limitada a lo que necesite cada dominio migrado (ver §6, "Cómo extender") — no es un generador general desde el día 1, crece con el uso real |

**Elegida: script propio.** El repo ya tiene un precedente de preferir "menos dependencias" sobre
"la herramienta que hace todo" — la fase 0015 rompió el build real por una dependencia transitiva
de `permission_handler`/`compileSdk`, y M-02 tomó la misma decisión (interceptor propio de
~60 líneas en vez de `dio_smart_retry`). Un script de ~150 líneas sin dependencias de pub nuevas
(usa solo `dart:io`/`dart:convert`, ya en el SDK) es consistente con ese criterio, y evita el
choque de arquitectura de cliente HTTP que tienen las otras dos opciones.

## 4. Diseño

`tool/openapi_codegen/generate_model.dart`:

```
dart run tool/openapi_codegen/generate_model.dart \
  --schema <NombreDelSchemaEnComponents> \
  --class <ClaseDart> \
  --out <archivo.g.dart> --part <archivo.dart> \
  (--openapi-file <path> | --openapi-url <url>) \
  [--int-fields campo1,campo2] [--enum-fields campo:NombreEnumDart,...]
```

- Lee `components.schemas.<Nombre>` de un documento OpenAPI (swagger-json real o un archivo
  local) y emite un archivo `part of '<modelo>.dart';` con una función
  `<Clase> _$<Clase>FromJson(Map<String, dynamic> json) => <Clase>(...)`, calcando el patrón que
  ya usa `json_serializable` en el ecosistema Flutter (el modelo hand-written declara
  `factory Rating.fromJson(json) => _$RatingFromJson(json);` y delega).
- Nullability: un campo es nullable si el schema dice `nullable: true` **o** si no aparece en el
  array `required` del schema — igual que hace el backend con `@ApiProperty({ nullable: true })`.
- Tipos cubiertos hoy (los que aparecen en `RatingDetailResponseDTO`): `string`, `string` con
  `format: date-time` → `DateTime`, `boolean`, `number` (→ `double`, o `int` si el campo está en
  `--int-fields` — ver §5, limitación de `number`), objeto libre → `Map<String, dynamic>`, y un
  mapeo manual campo→enum vía `--enum-fields` (el enum Dart debe tener su propio
  `EnumName.fromJson(String)`, mismo patrón que `RatingType` hoy).
- El modelo hand-written mantiene TODO lo que no es parsing: docstrings, semántica de negocio,
  getters derivados. Solo el `fromJson` se genera.

## 5. Limitaciones conocidas (documentadas a propósito, no descubiertas después)

- **OpenAPI/swagger no distingue `int` de `double`** sin metadata adicional (`format: int32` —
  que NestJS/`@nestjs/swagger` no agrega por default). El script requiere `--int-fields` a mano
  por dominio. Si el backend empieza a anotar `format` explícito, esto se puede automatizar.
  Same limitación existe en Web (TS tampoco distingue `number` de `int`), así que no es una
  regresión frente al estado del arte actual del monorepo.
- **No resuelve `$ref` a otros schemas ni arrays de objetos anidados** — cubre lo que
  `RatingDetailResponseDTO` necesitó. El próximo dominio que lo adopte y tenga un shape distinto
  (un array de sub-objetos, por ejemplo) extiende `_castExpressionFor` en el mismo archivo.
- **Sin tests unitarios propios todavía** — se validó corriéndolo contra el fixture de §6 y
  verificando que el modelo migrado (`ratings`) compila, analiza limpio y pasa sus tests. Si un
  segundo dominio lo adopta, vale la pena agregarle tests directos al generador.

## 6. Cómo se probó esta PoC (sin backend corriendo)

`tool/openapi_codegen/fixtures/swagger.local-example.json` es un recorte de OpenAPI con
`components.schemas.RatingDetailResponseDTO`, transcripto a mano desde
`TekoApp-Backend/src/api/ratings/dtos/response/rating-detail.response.dto.ts` (2026-09-06) —
representa lo que `GET /swagger-json` devolvería para ese schema. Se usó para poder ejercitar el
generador y migrar `ratings` sin necesitar el backend levantado en esta sesión. El flag
`--openapi-url` (contra `$BACKEND_API_URL/swagger-json`, mismo patrón que
`generate-api-types.mjs` de Web) está implementado pero no se ejecutó contra un servidor real
todavía — es la ruta a validar antes de wireearlo a CI (ver §8).

**Hallazgo real de este PoC**: al escribir el fixture desde el DTO real, aparecieron 5 campos que
`Rating` nunca parseaba — `serviceId`, `criteria`, `isReported`, `reportReason`, `createdBy` — el
backend los devuelve siempre pero el modelo a mano los ignoraba en silencio (mismo patrón que
M-05 con `Payment`). Migrar `ratings` a codegen los expuso y los agregó de una — evidencia
concreta de que esta clase de bug es real y recurrente, no hipotética.

## 7. Dominio migrado: `ratings`

- `lib/features/ratings/models/rating.dart` — hand-written, ahora con `part 'rating.g.dart';` y
  los 5 campos nuevos (todos nullable u opcionales, sin consumidor en la UI todavía — no se
  cablearon a ninguna pantalla, eso es trabajo aparte si alguna pantalla los llega a necesitar).
- `lib/features/ratings/models/rating.g.dart` — generado, no editar a mano. Regenerar con el
  comando de §4 si `RatingDetailResponseDTO` cambia.
- Tests actualizados: los fixtures JSON de `ratings_repository_test.dart`,
  `professional_services_screen_test.dart` y `service_detail_screen_test.dart` ahora incluyen
  `isReported` (campo nuevo, requerido) — sin este campo, el `fromJson` generado lanza en vez de
  ignorar en silencio, que es exactamente el comportamiento que queremos (falla rápido y
  explícito ante un campo faltante, en vez de nunca fallar y nunca enterarse).
- `rating_test.dart` suma 2 tests: uno cubre los 5 campos nuevos con valores presentes, otro
  confirma que su ausencia en el JSON (no solo `null` explícito) sigue resultando en `null`.

**No se migró ningún otro de los ~29 modelos restantes** — es explícitamente fuera de alcance de
esta tarea.

## 8. Plan de migración incremental

1. **Hecho en esta PoC**: `ratings`, con `--openapi-file` contra el fixture local.
2. **Próximo paso, antes de tocar otro dominio**: correr el generador con `--openapi-url` contra
   un backend real (local o el ambiente de QA desplegado) y confirmar que produce el mismo
   `rating.g.dart` que el fixture — valida que el camino "real" funciona igual que el camino de
   prueba usado acá.
3. **CI**: agregar un job (o un step en el pipeline existente) que:
   - Corra `dart run tool/openapi_codegen/generate_model.dart` para cada dominio ya migrado,
     apuntando `--openapi-url` al swagger-json del ambiente de QA desplegado (no hace falta
     levantar el backend en el runner de CI — ver §1, ni Web lo hace).
   - Falle si `git diff --exit-code` sobre los `.g.dart` generados no está limpio — mismo
     principio que `check:types` en Web, pero verificando contra el contrato REAL en vez de
     contra lo último que alguien generó a mano.
   - Este job es aditivo (no reemplaza `flutter analyze`/`flutter test`) y se agrega recién
     cuando haya más de un dominio migrado — con uno solo, no vale la pena el costo de mantenerlo.
4. **Selección del próximo dominio**: candidatos naturales son los que ya se sabe que tienen
   drift real — `payments` (ver M-05, campos que `Payment.fromJson` descarta) es el más obvio.
5. **Nunca migrar un modelo por migrar** — cada dominio se adopta cuando alguien lo toca por otra
   razón (un bug, una feature nueva) o cuando se confirma drift real, igual que la política de
   "no agregues campos a un modelo sin consumidor" ya vigente en el repo (ver M-05).

## 9. Qué NO cambia

- La arquitectura por dominio (`lib/features/<dominio>/{data,providers,models,widgets}/`) sigue
  igual — el `part`/`part of` vive DENTRO del mismo dominio, no introduce una capa nueva.
- `ApiClient`/los interceptors de dio no cambian — este script no genera ni reemplaza nada de la
  capa de red, solo el parsing de modelos.
- Los 29 modelos no migrados siguen exactamente como están — cero riesgo de regresión fuera de
  `ratings`.
