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

## 7.1 Dominios migrados al cerrar el cabo suelto de M-04: `payments`, `services`, `professionals`

Extensión del generador (`tool/openapi_codegen/generate_model.dart`) para poder migrar estos tres
dominios, ya documentada en su comentario de cabecera:

- **`--ref-fields campo:Clase`** — objeto anidado vía `$ref` directo o `allOf: [{$ref}]}` (patrón
  que usa `@nestjs/swagger` para adjuntar `nullable` junto a un `$ref`, ver `Payment.tip`). Delega
  en el `factory <Clase>.fromJson(Map<String, dynamic>)` que el dominio ya tiene escrito a mano —
  no resuelve el schema referenciado.
- **`--rename-fields claveJson:campoDart`** — para el único caso real encontrado de una clave JSON
  que no coincide con el nombre del campo Dart: `ServiceDetailResponseDTO.users` → `Service.client`.
- **Arrays de `string`** (`type: array, items: {type: string}` → `List<String>`) — sin flag nueva,
  se detecta directo del schema. Sigue sin resolver arrays de objetos anidados.

**Validado por primera vez contra un backend real** (paso 2 del plan original, §8): las tres
migraciones corrieron con `--openapi-url` contra un `TekoApp-Backend` local levantado en esta
sesión, no contra un fixture a mano — cierra la brecha que dejaba abierta el PoC de `ratings`.

**Drift real encontrado** (además de lo ya sabido por B-01/M-05):

| Dominio | Campos que el modelo a mano descartaba en silencio | Otro hallazgo |
|---|---|---|
| `payments` (`Payment`) | Ninguno | M-05 ya había expuesto todo lo que el DTO real devuelve |
| `services` (`Service`) | `actualHours`, `images`, `scheduledAt` | `client` (clave JSON `users`) se trataba como opcional pese a que el backend lo devuelve siempre — se corrigió a no-nullable |
| `professional_profile` (`ProfessionalProfile`) | `userId`, `certifications`, `verificationStatus`, `requiredDocumentsVerified`, `currentLatitude`/`currentLongitude`/`lastLocationUpdate`, `totalServices`, `averageRating`, `totalRatings`, `createdAt`, `user`, `category` | `yearsOfExperience`/`skills` se trataban como opcionales pese a ser requeridos; `userId` es el hallazgo más notable — nunca se expuso pese a que el DTO lo devuelve siempre |

Ningún campo nuevo tiene consumidor en la UI todavía — mismo criterio que `ratings`: se exponen
para que la próxima pantalla que los necesite no tenga que volver a tocar el modelo primero.

Commits: `6649ddd` (payments + extensión del generador), `c75cb89` (services), `dbd8561`
(professional_profile).

## 7.2 Dominios migrados 2026-09-11: `professional_documents`, `promotions`

Continuación de M-04 (backend NO disponible en esta sesión — verificado, `curl localhost:3000`
sin respuesta — así que las dos migraciones de esta ronda corrieron con `--openapi-file` contra
fixtures locales nuevos, transcriptos a mano desde los DTOs reales del backend, mismo método que
la PoC de `ratings`. **Esto es una limitación real, no un detalle**: un fixture a mano puede
quedar desactualizado igual que un modelo a mano — si el backend cambia el DTO real después de
esta transcripción, el codegen contra el fixture viejo no lo va a detectar. La validación
definitiva sigue siendo `--openapi-url` contra un backend vivo (ver §7.1, ya probado), pendiente
de repetir cuando haya uno disponible.

**Criterio de priorización de esta ronda**: riesgo de drift por plata/estado movido, no orden
alfabético de los ~25 modelos restantes de aquel momento.

- **`professional_documents`** — elegido porque I-01 (borrado de cuenta, esta misma sesión)
  **acababa de cambiar su contrato real**: `ProfessionalDocumentResponseDTO.fileKey` pasó de
  `string` a `string | null` (`null` cuando la cuenta del profesional se anonimiza). No es un
  riesgo hipotético de "podría cambiar" — ya había cambiado. La migración expuso que
  `ProfessionalDocument.fileKey` seguía casteado a `String` no-nullable en Mobile: se corrigió el
  tipo y se ajustó el único consumidor real (`professional_documents_section.dart`, la vista
  pública de documentos de un profesional) para ocultar el botón "Ver documento" cuando
  `fileKey` es `null`, en vez de ofrecer una acción que fallaría. `ProfessionalDocumentType`
  además descartaba en silencio `countryId`/`professionalCategoryId` (sin consumidor, se exponen
  igual que M-05).
- **`promotions`** — elegido porque, junto a `payments`, es el dominio que más directamente mueve
  el monto final que paga un cliente (código de descuento → `finalAmount`). Hallazgo del mayor
  alcance de todos los dominios migrados hasta ahora: el modelo `Promotion` a mano solo exponía
  `code`/`name`; el backend (`PromotionDetailResponseDTO`) siempre devuelve otros 16 campos
  descartados en silencio (`id`, `type`, `status`, `discountPercentage`, `discountAmount`,
  `minimumAmount`, `maximumDiscount`, `maxUsage`, `maxUsagePerUser`, `currentUsage`, `validFrom`,
  `validUntil`, `allowedUserTypes`, `specificUserIds`, `createdById`, `createdAt`,
  `lastChangedAt`). Ninguno tiene consumidor todavía — se exponen igual que M-05/`ratings`.

**Extensión del generador que esto requirió**: arrays de `number` (`specificUserIds: number[]`)
→ `List<int>`/`List<double>` según `--int-fields`, mismo criterio que ya existía para el escalar
equivalente. Documentada en la cabecera de `generate_model.dart` (v3). Sigue sin resolver arrays
de objetos anidados (no lo necesitó ninguno de los 6 dominios migrados hasta ahora).

Commits: `7b42e40` (professional_documents), `2cd9ae3` (promotions + extensión de arrays de
number).

## 7.3 Extensión del generador + dominio migrado 2026-09-12: `contracts`

**Backend real disponible esta sesión** (a diferencia de §7.2): `cd TekoApp-Backend && node
dist/main.js` levantó contra el `dist/` ya compilado y el `.env` existente, sin necesitar
`start:dev`. `curl http://localhost:3000/tekoapp-backend/api/swagger-json` devolvió 200 — todo lo
de esta ronda (extensión del generador + migración de `contracts`) se validó con
`--openapi-url` contra ese backend real, no contra un fixture transcripto a mano.

**Extensión del generador** (`tool/openapi_codegen/src/model_generator.dart`, v4): agrega arrays
de objetos anidados (`type: array, items: {$ref: ...}` → `List<Clase>`) — la limitación
documentada desde la v1 que bloqueaba migrar `contracts`
(`ContractContentSnapshotDTO.lineItems: ContractLineItemSnapshotDTO[]`). Reutiliza el mismo mapa
`--ref-fields campo:Clase` que ya resolvía un objeto anidado singular: ahora también resuelve el
elemento de un array, delegando en el `fromJson` que esa clase Dart ya tiene escrito a mano. Sin
flag nueva. De paso, la lógica de generación (`castExpressionFor`/`generateModelSource`) se separó
a `tool/openapi_codegen/src/model_generator.dart` para poder testearla directo (22 tests nuevos en
`test/tool/openapi_codegen/model_generator_test.dart` — el generador no tenía tests propios hasta
ahora, ver la limitación que cerraba el §5 original).

**Dominio migrado: `contracts`** — elegido porque es el candidato de mayor riesgo documentado en
este archivo (§8, ronda anterior): mueve dinero (`contentSnapshot.budgetOption`) y estado legal
(firma electrónica, `legalTermsVersion`), y era el que justificó la extensión del generador. Se
migraron 3 clases:

- `Contract` (`ContractResponseDTO`)
- `MyContractSummary` (`MyContractSummaryResponseDTO`)
- `ContractContentSnapshot` (`ContractContentSnapshotDTO`) — el primer dominio cuyo `lineItems`
  (array de `ContractLineItemSnapshot`) se genera vía la extensión de arrays de `$ref`, en vez de
  a mano.

`ContractServiceSnapshot`/`ContractBudgetOptionSnapshot`/`ContractLineItemSnapshot`/
`LegalTermsVersionSummary` quedan hand-written, referenciadas vía `--ref-fields` — mismo patrón
que `Tip` en `payments` (§7.1): son hojas simples, sin drift encontrado, no ameritan su propia
migración todavía (regla del §8: no migrar un modelo sin razón).

**Drift encontrado: ninguno.** A diferencia de `ratings`/`Payment`/`promotions`, los 3 schemas
reales de `contracts` coinciden campo a campo con lo que ya escribía el modelo a mano — ni un
campo descartado en silencio. Es un resultado real y esperable a veces (mismo patrón que
`payments` en §7.1, tabla de drift: "Ninguno"), no evidencia de que la migración no haya valido la
pena: sigue cerrando la brecha de "nada detecta un drift futuro" que motiva M-04, y fue la que
desbloqueó la extensión de arrays de objetos anidados.

**Otros dominios evaluados esta ronda (con el backend real) y NO migrados — sin drift
encontrado:**

| Dominio | Schema(s) real(es) comparado(s) | Resultado |
|---|---|---|
| `budgets` | `BudgetOptionResponseDTO`, `BudgetLineItemResponseDTO` | Sin drift — coincide campo a campo con `BudgetOption`/`BudgetLineItem`. Ya se había evaluado sin backend en la ronda anterior (§8, "Descartados"); esta ronda lo reconfirma contra el contrato real. |
| `legal_consents` | `UserConsentResponseDTO`, `ContentConsentGrantResponseDTO`, `DataConsentsHistoryResponseDTO` | Sin drift. Candidato de riesgo comparable a `contracts` (estado legal) y con el mismo shape de array-de-\$ref (`consents`/`contentGrants`) que motivó la extensión del generador — pero sin drift confirmado, no se migra todavía (regla del §8). |
| `professional_portfolio` | `PortfolioItemResponseDTO` | Sin drift — a diferencia de `ProfessionalDocument.fileKey` (§7.2), acá `fileKey` sigue siendo requerido en el DTO real; I-01 no lo tocó. |
| `service_progress` | `ServiceProgressEntryResponseDTO` | Sin drift — coincide campo a campo con `ServiceProgressEntry`. |

Commits: `3c523ec` (extensión del generador + tests), `2cc5873` (migración de `contracts`).

## 8. Plan de migración incremental

1. **Hecho en la PoC original**: `ratings`, con `--openapi-file` contra el fixture local.
2. **Hecho al cerrar el cabo suelto de 2026-09-07**: `payments`, `services`,
   `professional_profile`, los tres con `--openapi-url` contra un backend real — ver §7.1.
3. **Hecho 2026-09-11**: `professional_documents`, `promotions` — ver §7.2. Contra fixture local
   (backend no disponible esa sesión), no contra `--openapi-url` real — pendiente de re-validar
   contra un backend vivo cuando haya uno disponible (mismo riesgo que cualquier fixture a mano,
   ver advertencia en §7.2).
4. **Hecho 2026-09-12**: `contracts` (`Contract`, `MyContractSummary`,
   `ContractContentSnapshot`) — ver §7.3. Contra `--openapi-url` de un backend real levantado en
   esta sesión (`node dist/main.js`), cerrando además la re-validación pendiente que dejó abierta
   el paso 3: con el backend disponible, se reconfirmó sin drift `budgets` (evaluado sin backend
   en la ronda de `professional_documents`/`promotions`) y se evaluaron por primera vez
   `legal_consents`, `professional_portfolio` y `service_progress` — ninguno con drift, ninguno
   migrado (ver tabla en §7.3).
5. **CI**: agregar un job (o un step en el pipeline existente) que:
   - Corra `dart run tool/openapi_codegen/generate_model.dart` para cada dominio ya migrado,
     apuntando `--openapi-url` al swagger-json del ambiente de QA desplegado (no hace falta
     levantar el backend en el runner de CI — ver §1, ni Web lo hace).
   - Falle si `git diff --exit-code` sobre los `.g.dart` generados no está limpio — mismo
     principio que `check:types` en Web, pero verificando contra el contrato REAL en vez de
     contra lo último que alguien generó a mano.
   - Este job es aditivo (no reemplaza `flutter analyze`/`flutter test`) y se agrega recién
     cuando haya más de un dominio migrado — con 7 dominios migrados (`ratings`, `payments`,
     `services`, `professional_profile`, `professional_documents`, `promotions`, `contracts`), ya
     vale la pena el costo de mantenerlo. Pendiente.
6. **Selección del próximo dominio**: de los ~20 modelos restantes, ninguno tiene drift
   confirmado a esta fecha (ver tabla de evaluados en §7.3: `budgets`, `legal_consents`,
   `professional_portfolio`, `service_progress`). Aplicar §7.1/§7.2/§7.3 cuando alguien toque un
   modelo por otra razón o se confirme drift nuevo — no hay un candidato obvio por riesgo sin
   evidencia pendiente hoy.
7. **Nunca migrar un modelo por migrar** — cada dominio se adopta cuando alguien lo toca por otra
   razón (un bug, una feature nueva) o cuando se confirma drift real, igual que la política de
   "no agregues campos a un modelo sin consumidor" ya vigente en el repo (ver M-05).

### Descartados (evaluados, no elegidos — acumulado, ver también §7.3)

- **`budgets`** (`BudgetOption`/`BudgetLineItem`) — dinero real (tarifas/presupuestos). Evaluado
  dos veces: sin backend (ronda de `professional_documents`/`promotions`) y contra el contrato
  real (ronda de `contracts`, §7.3). Ninguna de las dos encontró drift. No se prioriza sobre un
  dominio con drift confirmado.
- **`legal_consents`** (`UserConsent`/`ContentConsentGrant`/`DataConsentsHistory`) — estado legal,
  riesgo comparable a `contracts`, y con el mismo shape de array-de-\$ref que motivó extender el
  generador. Evaluado contra el backend real en la ronda de `contracts` (§7.3): sin drift.
- **`professional_portfolio`** (`PortfolioItem`) — evaluado contra el backend real en la ronda de
  `contracts` (§7.3): sin drift (`fileKey` sigue requerido, a diferencia de
  `ProfessionalDocument.fileKey`).
- **`service_progress`** (`ServiceProgressEntry`) — evaluado contra el backend real en la ronda de
  `contracts` (§7.3): sin drift.

## 9. Qué NO cambia

- La arquitectura por dominio (`lib/features/<dominio>/{data,providers,models,widgets}/`) sigue
  igual — el `part`/`part of` vive DENTRO del mismo dominio, no introduce una capa nueva.
- `ApiClient`/los interceptors de dio no cambian — este script no genera ni reemplaza nada de la
  capa de red, solo el parsing de modelos.
- Los ~20 modelos restantes siguen exactamente como están — cero riesgo de regresión fuera de los
  7 dominios migrados (`ratings`, `payments`, `services`, `professional_profile`,
  `professional_documents`, `promotions`, `contracts`).
