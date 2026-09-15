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

## 10. Cambio de estrategia 2026-09-12: parar la migración por dominio, construir un verificador de drift

`lib/features/*/models/` tiene **72 archivos de modelo** (sin contar los `.g.dart` generados);
esta propuesta había migrado 7 dominios en 4 rondas de trabajo (§7.1-§7.3). A ese ritmo, migrar
los 65 archivos restantes hubiera tomado 10-14 tandas más. José decidió frenar acá la migración
dominio por dominio y construir en su lugar un **verificador de drift** — la razón, con
evidencia concreta:

**El valor nunca estuvo en generar código: estuvo en comparar contra el swagger real.** La
migración a codegen era el VEHÍCULO para forzar esa comparación, no el fin en sí mismo. Prueba:
de los 9 dominios verificados contra el backend real en la ronda de `contracts` (§7.3, tabla),
4 tenían campos que el modelo a mano descartaba en silencio sin que nada lo detectara
(`promotions`: 16 campos: `ratings`: 5 vía `Rating`; `payments`/`professional_documents` ya
documentados en §7.1/§7.2) y otros 5 no tenían ningún drift (`contracts`, `budgets`,
`legal_consents`, `professional_portfolio`, `service_progress`). El generador solo migra un
modelo cuando alguien decide tocarlo — el verificador, en cambio, puede cubrir los 72 desde el
día uno, generados o a mano, y detectar el PRÓXIMO drift sin esperar a que alguien migre ese
dominio en particular.

**Requisito de diseño más importante**: el verificador tiene que funcionar IGUAL para un modelo
escrito a mano que para uno generado. Compara el modelo Dart tal cual vive en el repo (parseando
sus declaraciones de campo, no regenerando nada) contra el schema real — así José puede seguir
escribiendo modelos a mano cuando le convenga sin perder la red de seguridad. Ver §12 para cómo
usar cada camino día a día.

## 11. Diseño del verificador (`tool/openapi_codegen/check_drift.dart`)

Cuatro archivos nuevos bajo `tool/openapi_codegen/`, cada uno con una responsabilidad:

- **`model_mapping.dart`** (raíz del tool, versionado): la única fuente de verdad de qué clase
  Dart corresponde a qué schema. Declara `modelMappings` (clase Dart -> schema, con
  `renameFields` para los pocos casos donde la clave JSON no coincide con el nombre del campo
  Dart, y `schemaFieldExemptions`/`modelFieldExemptions` para campos que a propósito no se
  mapean) y `localModelExemptions` (modelos que NO corresponden a ningún schema — enums espejo,
  jerarquías de errores de dominio, estado local de UI). Ver §12.1/§12.6 para cómo editarlo.
- **`src/dart_model_parser.dart`**: lee un archivo `.dart` y extrae, de UNA clase puntual, sus
  campos de instancia (nombre, tipo tal cual aparece en el código, nulabilidad). Es un parser por
  línea + conteo de llaves (no usa el paquete `analyzer`, mismo criterio "sin dependencias
  nuevas" que ya eligió §3) que confía en que el repo corre `dart format` — una declaración por
  línea. Funciona igual sobre un modelo a mano que sobre uno generado: no le importa de dónde
  salió el archivo, solo lee lo que hay.
- **`src/drift_checker.dart`**: el motor de comparación. Clasifica cada campo del lado del schema
  y del lado Dart en una categoría gruesa (`string`/`datetime`/`number`/`boolean`/`object`/
  `ref`/`enumString`/arrays de cada uno/`custom`) reusando `refNameOf`/`arrayItemsOf` de
  `src/schema_utils.dart` — el mismo helper que ya usa `model_generator.dart` para resolver
  `$ref`/`allOf`/arrays, extraído para que ninguno de los dos lo duplique. Compara campo a campo
  y devuelve una lista de `DriftFinding` (ver §12.4 para qué significa cada `DriftKind`).
- **`check_drift.dart`**: el CLI. Carga el documento OpenAPI (mismo `--openapi-file`/
  `--openapi-url` que el generador, vía `src/openapi_document.dart` — extraído de
  `generate_model.dart` para que ambos compartan la misma lectura), corre `checkMapping` sobre
  cada entrada de `modelMappings`, descubre todos los `.dart` bajo `lib/features/*/models/` en
  disco y corre `checkCoverage` para detectar un modelo que nadie registró, imprime el reporte y
  sale con código 1 si hay algún hallazgo de severidad crítica.

**Por qué las categorías son gruesas a propósito**: el schema de OpenAPI no distingue `int` de
`double` (misma limitación que el generador, §5), y el mapeo no declara por-campo si un `string`
es en realidad un enum Dart o qué clase resuelve un `$ref` — exigir esa precisión sin esa
metadata llevaría a falsos positivos constantes sobre modelos sanos (cada enum, cada objeto
anidado, dispararía una alarma). El verificador tolera esa ambigüedad y en cambio es preciso
donde más importa: **nulabilidad** (el caso `fileKey`: si el schema dice que un campo puede ser
`null` y el modelo lo castea no-nullable, es CRÍTICO — puede crashear en runtime) y **presencia**
(un campo que el schema tiene y el modelo no lee, o al revés).

**Limitaciones conocidas de esta v1** (documentadas a propósito, no descubiertas después):

- ~~No compara valores de enum~~ — cerrado en v2, ver §11.1 inmediatamente abajo.
- No entiende un `fromJson` que "aplana" un objeto anidado a campos de nivel superior (ver
  `ServiceProfessionalSummary`, que lee `json['user']['firstName']` en vez de
  `json['firstName']`) — ese caso queda como exención local con motivo explícito, no como un
  bug del verificador.
- El parser de Dart es un parser por línea, no un analizador completo: confía en que el repo
  corre `dart format` (una declaración por línea). Un modelo con varios campos en la misma línea,
  o con anotaciones/formas de constructor muy atípicas, puede no reconocerse bien — en ese caso
  el síntoma es que el verificador reporta campos de menos/de más que no son drift real; la
  solución es reformatear (`dart format`) o, si el shape es genuinamente distinto, extender
  `dart_model_parser.dart`.

## 11.1 v2 (2026-09-15): comparación de VALORES de enum

Cierra la limitación de arriba — el caso real que la motivó (documentado en la v1 de este
archivo): `LegalDocumentType` (Dart) cubría 4 valores, `LegalDocumentVersionResponseDTO.documentType`
(schema real) ya tenía 6 (`SERVICE_CONTRACT_TERMS`/`USER_CONTENT_LIABILITY_DISCLAIMER`
agregados en fases del backend posteriores a cuando se escribió el enum Dart). Un reporte limpio
de la v1 nunca lo habría marcado — el campo "tenía forma de string" en los dos lados, que era todo
lo que la v1 comparaba.

**Diseño**: dos piezas nuevas, sumadas a las 4 de §11:

- **`tool/openapi_codegen/src/dart_enum_parser.dart`** (`parseEnumFromJson`): dado el código fuente
  de un archivo y el nombre de un enum, ubica su `fromJson` (con conteo de llaves, no línea a
  línea — tolera que `dart format` parta un caso largo en 2 líneas, ver el caso real
  `ContractStatus.pendingProfessionalSignature`) y extrae TODOS los literales
  `'MAYÚSCULA_CON_GUIONES'` que aparecen en su cuerpo. Deliberadamente NO distingue la sintaxis
  exacta del switch (arrow de una expression vs `case`/`return` de un statement clásico) — ver su
  docstring para el motivo: un literal enteramente en mayúsculas dentro de un `fromJson(String
  value)` de un enum siempre es un valor reconocido en este repo, nunca coincide por casualidad
  con un mensaje de error (que acá siempre se escribe en minúscula/mixta). También detecta si el
  catch-all (`_ => throw ...` / `default: throw ...`) relanza ante un valor desconocido
  (`throwsOnUnknown`) — determina la severidad del hallazgo (ver tabla abajo).
- **`ModelMapping.enumFields`** (`model_mapping.dart`): `Map<String campo del schema,
  EnumFieldMapping>` — declara qué enum Dart (y en qué archivo) le corresponde a un campo `string`
  con `enum:` del schema. Mismo criterio "opt-in" que el resto de `model_mapping.dart`: un campo
  enum del schema que no se declara acá simplemente no se compara por valor (no genera ningún
  hallazgo, ni positivo ni negativo).

**Nuevos tipos de hallazgo** (`drift_checker.dart`, función `checkEnumFields`):

| Marca | Qué significa | Severidad |
|---|---|---|
| `[VALOR DE ENUM FALTANTE EN MODELO]` | El schema declara un valor que el `fromJson` del enum Dart no reconoce. | CRÍTICA si el `fromJson` relanza ante un valor desconocido (crashea la próxima vez que llegue); ADVERTENCIA si tiene un catch-all que absorbe en silencio (no crashea, solo se mezcla con otro miembro sin que nada lo note). |
| `[VALOR DE ENUM SOBRA EN MODELO]` | El enum Dart reconoce un literal que el schema ya no declara. | Siempre ADVERTENCIA — no crashea, el valor solo queda inalcanzable. |
| `[CAMPO NO ES ENUM EN EL SCHEMA]` | `enumFields` declara un campo que en el schema real ya no es un `string` con `enum:` (o dejó de existir). | ADVERTENCIA — el mapeo quedó desactualizado, hay que corregirlo o borrarlo. |
| `[ENUM SIN PARSEAR]` | `parseEnumFromJson` no pudo leer el `fromJson` de ese enum con ninguna forma reconocida. | ADVERTENCIA — señal EXPLÍCITA de "este campo no se comparó", nunca se asume en silencio que no hay drift. |

**Cobertura real alcanzada**: se catalogaron los 23 enums de `lib/features/*/models/` que tienen
un `fromJson` que parsea un `String` (ver el catálogo completo armado al construir esto) — las
únicas 2 formas reales que aparecen son exactamente las que `parseEnumFromJson` cubre (`factory
Enum.fromJson` con switch expression, `static Enum fromJson` con switch statement clásico); NINGÚN
enum del repo usa una forma distinta. De esos 23, se declararon **22 bindings campo→enum** en
`enumFields` a través de 19 `ModelMapping` — el resto, sin `enumFields`, queda sin comparar por
valor A PROPÓSITO, no por una limitación del parser:

- **`DeviceType`** (`notifications/models/device_type.dart`) — no tiene `fromJson`, solo `toJson`
  (nunca se lee de una respuesta HTTP en esta fase). No hay nada que parsear.
- **`DeletionBlockerType`** y **`ContractViewerRole`** — enums locales sin ningún schema
  correspondiente (ya exentos en `localModelExemptions` con ese motivo, ver §12.6). No hay un
  `enum:` del lado del schema contra el cual comparar.

En otras palabras: **para este repo, hoy, `parseEnumFromJson` no tiene ningún caso real sin
cubrir** — las 3 exclusiones de arriba son por falta de contraparte (schema o `fromJson`), no
porque el parser sea frágil ante alguna de las formas de `switch` que este repo usa. Si en el
futuro aparece una forma nueva que `parseEnumFromJson` no reconozca, el síntoma es
`[ENUM SIN PARSEAR]` en el reporte — explícito, nunca un reporte limpio que esconda cobertura
parcial.

Corrida contra el swagger real (2026-09-15): encontró exactamente el caso documentado
(`LegalDocumentType`, 2 hallazgos críticos) más 2 advertencias nuevas no vistas antes
(`AiDisclosureEntityType.entityType`/`contentType` no reconocían `OTHER` explícitamente — llegaban
ahí solo vía su catch-all silencioso). Los 3 se cerraron: `LegalDocumentType` sumó
`serviceContractTerms`/`userContentLiabilityDisclaimer` (sin consumidor en la UI todavía, ninguno
de los dos gatea nada en el backend tampoco — ver `openspec/decisions.md` de `TekoApp-Backend`),
`AiDisclosureEntityType.fromJson` sumó un `case 'OTHER':` explícito. `check_drift` vuelve a dar
`sin drift` contra los 72 modelos.

## 12. Cómo contribuir con modelos

### 12.1 Agregar un modelo nuevo a mano

1. Creá el archivo en `lib/features/<dominio>/models/<nombre_snake_case>.dart` (una clase por
   concepto; varias clases relacionadas SÍ pueden compartir archivo, ver `contract.dart` o
   `service.dart`, que anidan sus resúmenes hermanos en el mismo archivo que la clase principal).
2. Seguí la convención ya establecida en el repo (ver `lib/features/budgets/models/budget_option.dart`
   como ejemplo simple, o `lib/features/ratings/models/rating.dart` para uno con muchos campos
   nullable):
   - Constructor `const` con parámetros nombrados (`required` para los campos no-nullable).
   - Un campo `final Tipo campo;` por línea (o `final Tipo? campo;` si puede faltar/venir
     `null`) — coincidiendo la nulabilidad EXACTAMENTE con lo que dice el schema real
     (`nullable: true` o ausente de `required`), no con lo que "parece razonable". Este es
     el punto exacto donde falló B-01/`fileKey`: verificar contra el swagger, no adivinar.
   - `factory Clase.fromJson(Map<String, dynamic> json) { return Clase(...); }` casteando cada
     campo (`json['x'] as Tipo` / `json['x'] as Tipo?` / `DateTime.parse(...)` / etc.).
3. Registralo en `tool/openapi_codegen/model_mapping.dart`, agregando una entrada a
   `modelMappings`:
   ```dart
   const ModelMapping(
     dartFile: 'lib/features/<dominio>/models/<archivo>.dart',
     className: 'TuClase',
     schemaName: 'NombreDelSchemaEnComponents', // el mismo que ves en /swagger-json
   ),
   ```
   Si alguna clave JSON no coincide con el nombre del campo Dart, agregá `renameFields: {'claveJson': 'campoDart'}`
   (ver el caso real `Service.client` <- `ServiceDetailResponseDTO.users`). Si el modelo NO
   corresponde a ningún schema (estado local de UI, un enum espejo, una jerarquía de errores),
   no lo mapees: exentalo en `localModelExemptions` (ver §12.6) — si no hacés ninguna de las dos
   cosas, el verificador lo reporta como "SIN REGISTRAR" la próxima vez que corra.
4. Corré el verificador (§12.3) contra un backend real o un snapshot para confirmar que tu modelo
   nuevo coincide campo a campo con el schema.

### 12.2 Agregar un modelo nuevo con el generador

Para un modelo grande o muy anidado, generar el `fromJson` ahorra tipeo y, al mismo tiempo,
fuerza la comparación contra el schema real en el momento de crearlo (no hace falta esperar a
correr el verificador aparte, aunque igual conviene registrarlo — ver paso 4 más abajo).

```
dart run tool/openapi_codegen/generate_model.dart \
  --schema <NombreDelSchemaEnComponents> --class <ClaseDart> \
  --out lib/features/<dominio>/models/<archivo>.g.dart --part <archivo>.dart \
  (--openapi-file <path-al-snapshot> | --openapi-url <url-del-swagger-json>) \
  [--int-fields campo1,campo2] \
  [--enum-fields campo:NombreEnumDart,...] \
  [--ref-fields campo:ClaseDart,...] \
  [--rename-fields claveJson:campoDart,...]
```

1. El archivo `.dart` (a mano) declara `part '<archivo>.g.dart';` arriba y
   `factory Clase.fromJson(Map<String, dynamic> json) => _$ClaseFromJson(json);` en vez de un
   `fromJson` escrito a mano — todo lo demás de la clase (constructor, campos, docstrings,
   getters derivados) se sigue escribiendo a mano exactamente igual que en §12.1.
2. `--ref-fields campo:ClaseDart` hace falta cuando el schema tiene un objeto anidado (`$ref`
   directo, o `allOf: [{$ref}]` — el patrón que usa `@nestjs/swagger` para adjuntar `nullable`
   junto a un `$ref`) o un array de objetos anidados (`items: {$ref: ...}`). El generador NO
   resuelve el schema referenciado: delega en el `factory <ClaseDart>.fromJson(...)` que esa
   clase ya tiene escrita a mano — por eso las clases "hoja" (`Tip`, `LegalTermsVersionSummary`,
   `ContractLineItemSnapshot`, etc.) siguen siendo hand-written aunque la clase que las contiene
   esté generada.
3. `--int-fields`/`--enum-fields`/`--rename-fields` cubren, respectivamente: la limitación de que
   OpenAPI no distingue `int` de `double` (ver §5), campos `string` con `enum:` que corresponden
   a un enum Dart con su propio `fromJson(String)`, y los pocos casos donde la clave JSON no
   coincide con el nombre del campo Dart.
4. Registralo en `model_mapping.dart` igual que en el paso 3 de §12.1 — el verificador no sabe
   que el modelo está generado, así que lo cubre exactamente igual que a uno a mano.

### 12.3 Cómo correr el verificador de drift

```
dart run tool/openapi_codegen/check_drift.dart --openapi-url http://localhost:3000/tekoapp-backend/api/swagger-json
```

o, sin backend disponible, contra un snapshot local:

```
dart run tool/openapi_codegen/check_drift.dart --openapi-file tool/openapi_codegen/fixtures/swagger.local-example.json
```

Correlo desde la raíz del repo (`lib/features/...` en `model_mapping.dart` es relativo a ahí).
Sale con código 0 si no hay drift de severidad crítica, 1 si lo hay — pensado para engancharse a
un chequeo de CI (ver §14) o correr a mano antes de un PR que toque modelos.

### 12.4 Cómo interpretar un reporte de drift

El reporte agrupa cada hallazgo en CRÍTICO o ADVERTENCIA:

| Marca | Qué significa | Qué hacer |
|---|---|---|
| `[FALTA EN MODELO]` | El schema tiene un campo que el modelo Dart no lee — el patrón de B-01/M-05/`Category`/`PaymentMethod`: el backend lo manda siempre y la app lo descarta en silencio. | Agregá el campo al modelo (nullable u obligatorio según diga el schema). Si de verdad no hace falta consumirlo todavía, agregalo igual (sin cablearlo a la UI, mismo criterio ya usado en `ratings`/`professional_profile`) — así no se vuelve a perder si alguien lo necesita después. |
| `[SOBRA EN MODELO]` | El modelo Dart declara un campo que ya no está en el schema. | Puede ser (a) el backend eliminó ese campo — confirmalo y borralo del modelo; o (b) el nombre nunca coincidió con la clave JSON real — agregá `renameFields` en vez de borrar nada (ver el ejemplo trabajado de `LoginResult` más abajo). |
| `[TIPO]` | La forma del campo no coincide (ej. el schema dice array y el modelo un escalar). | Revisá cuál de los dos está desactualizado — normalmente el modelo, pero si el backend cambió un contrato sin avisar, es una conversación con el equipo de backend, no solo un fix silencioso acá. |
| `[NULABILIDAD]` cuando el schema es nullable y el modelo no | El caso `fileKey`: el backend puede mandar `null` y el modelo lo castea no-nullable — **crashea en runtime la próxima vez que llegue `null`**. Severidad crítica. | Cambiá el tipo del campo a `Tipo?` y revisá los consumidores (¿asumen que nunca es `null`?). |
| `[NULABILIDAD]` cuando el schema NO es nullable pero el modelo sí | El modelo es más defensivo de lo necesario — no crashea, no es urgente. Severidad advertencia. | Opcional: podés endurecer el tipo a no-nullable si querés que el compilador te avise si el backend alguna vez lo relaja, pero no es obligatorio arreglarlo. |
| `[SCHEMA NO ENCONTRADO]` | `model_mapping.dart` apunta a un `schemaName` que no existe en el documento OpenAPI cargado. | Si es un typo, corregilo. Si el backend renombró/eliminó el schema, es una señal real de que el contrato cambió — confirmá con backend antes de tocar el modelo. |
| `[MODELO NO ENCONTRADO]` | El archivo o la clase de `model_mapping.dart` ya no existen en el repo. | El modelo se borró/renombró y nadie actualizó el mapeo — actualizá `dartFile`/`className` o eliminá la entrada si el modelo ya no aplica. |
| `[SIN REGISTRAR]` | Un archivo bajo `lib/features/*/models/` declara una clase/enum que no está ni mapeada ni exenta. | Es la señal de "alguien agregó un modelo nuevo y se olvidó del paso 3 de §12.1/§12.2" — mapealo o exentalo (§12.6). |

**El caso especial: "el modelo está bien y lo que cambió es el backend".** No todo drift es un
bug del lado Mobile. Si el reporte dice que faltó un campo o cambió una nulabilidad, y confirmás
contra el equipo de backend que el cambio fue intencional (un DTO nuevo, un campo que dejó de
tener sentido), el fix puede ser tan simple como actualizar el modelo para seguir el nuevo
contrato — el verificador no asume de qué lado está el bug, solo que hay una diferencia real que
alguien tiene que mirar.

**Ejemplo trabajado: cuando el "drift" es en realidad un mapeo que vive fuera del modelo.** Este
es el escenario que más fácil se resuelve mal, porque el reflejo natural es tocar el modelo (o
peor, silenciar el hallazgo con una exención sin pensarlo) en vez de mirar quién construye ese
modelo. `LoginResult` (`lib/features/auth/models/login_result.dart`) lo disparó en la primera
corrida contra los 72 modelos (§13, versión anterior de este documento):

```
[FALTA EN MODELO] LoginResult.login       (el schema lo tiene, el modelo no lo lee)
[FALTA EN MODELO] LoginResult.requiredNewPassword
[SOBRA EN MODELO] LoginResult.success     (el modelo lo tiene, el schema no)
[SOBRA EN MODELO] LoginResult.requiresNewPassword
```

Parece un caso de campos perdidos, pero `LoginResult` **no tiene `fromJson`** — no se genera con
el generador ni se parsea genéricamente. `AuthRepository.login()`
(`lib/features/auth/data/auth_repository.dart:141-146`) lo construye a mano:

```dart
return LoginResult(
  success: response.data?['login'] as bool? ?? false,
  requiresNewPassword:
      response.data?['requiredNewPassword'] as bool? ?? false,
  accessToken: accessToken,
);
```

El mapeo real EXISTE, solo que vive en el repositorio, no en un `fromJson`: `login` (clave real
del backend) se traduce a `success` (nombre Dart más legible), y `requiredNewPassword` a
`requiresNewPassword`. No hay campo ignorado ni bug — es un falso positivo del verificador, que
no puede ver código fuera de la clase del modelo.

La resolución, ya aplicada en `model_mapping.dart`, distingue DOS situaciones distintas dentro
del mismo caso:

- `login` -> `success` es un **rename limpio** (`renameFields: {'login': 'success'}`): mismo
  tipo (`boolean`), misma nulabilidad (ambos requeridos) en los dos lados. Registrarlo como
  rename alcanza — el verificador vuelve a comparar tipo/nulabilidad normalmente, con el nombre
  correcto, y no encuentra nada más.
- `requiredNewPassword` -> `requiresNewPassword` **no** se registró como rename, a propósito: el
  schema lo declara opcional (`nullable`), pero el repositorio lo normaliza con `?? false` al
  campo Dart (`bool` no-nullable). Si se registrara como rename plano, el verificador compararía
  nulabilidad (schema nullable vs modelo no-nullable) y reportaría un `[NULABILIDAD]` **crítico**
  nuevo — otro falso positivo, porque el verificador no puede ver el `?? false` que hace ese
  cambio de nulabilidad seguro. La solución fue exención de campo en los dos lados
  (`schemaFieldExemptions`/`modelFieldExemptions`), con el motivo apuntando a las líneas exactas
  de `auth_repository.dart` donde ocurre la normalización.

**La lección general**: cuando el verificador marca drift en un modelo que NO tiene `fromJson` (o
cuyo `fromJson` no es un cast directo campo a campo), el primer paso es preguntar "¿dónde se
arma este objeto realmente?" antes de tocar el modelo o el schema. Si el mapeo real es un simple
cambio de nombre, es un `renameFields`. Si además cambia la nulabilidad (o el tipo) a propósito
con lógica de por medio (un `?? default`, una transformación), un rename plano introduce un
segundo falso positivo — ahí corresponde una exención de campo con el motivo apuntando al código
real que hace esa traducción, no un rename ni un silenciamiento sin explicación.

### 12.5 Cuándo conviene cada camino

Ninguno de los dos es obligatorio. Con criterio, no con regla fija:

- **A mano** es lo más simple para un modelo chico (2-6 campos), o cuando la clase tiene lógica
  propia no trivial (getters derivados, invariantes, un `fromJson` con casos especiales que no
  encajan en el patrón genérico del generador — ver `ServiceProfessionalSummary`, que aplana un
  objeto anidado). También es la única opción hoy para un modelo que no viene de JSON HTTP (ver
  `PushNotificationPayload`, que parsea un `RemoteMessage` de Firebase).
- **El generador** ahorra tiempo en un modelo grande (10+ campos, como `Promotion` o `Contract`)
  o muy anidado (objetos/arrays de `$ref`), donde tipear cada cast a mano es tedioso y propenso a
  error — y, de paso, fuerza mirar el schema real en el momento de crear el modelo.
- **En ambos casos**, registrá el modelo en `model_mapping.dart` (§12.1 paso 3) — el verificador
  es lo que realmente cierra la brecha, no la elección de cómo se escribió el `fromJson`.

### 12.6 Cómo declarar una exención

Dos tipos, ambos en `tool/openapi_codegen/model_mapping.dart`, ambos con `reason` como parámetro
NOMBRADO REQUERIDO — el constructor tira `ArgumentError` si el motivo tiene menos de 8
caracteres, así que no se puede declarar una exención con un placeholder vacío:

- **`LocalModelExemption`** — para un modelo (clase o enum) que no corresponde a ningún schema.
  Con `className: null` (el default), cubre TODAS las clases/enums de ese archivo — útil para un
  archivo enteramente local (una jerarquía `sealed class XFailure`, un enum espejo). Con
  `className` puntual, cubre solo esa clase dentro de un archivo que también tiene clases
  mapeadas (ver `ServiceProfessionalSummary` dentro de `service.dart`, que convive con `Service`
  y `ServiceCategorySummary`, ambas mapeadas).
- **`FieldExemption`** (dentro de un `ModelMapping`, en `schemaFieldExemptions` o
  `modelFieldExemptions`) — para un campo puntual que a propósito no se mapea, dentro de un
  modelo que sí está mapeado a un schema. Ejemplo real: `LoginResult` mapea a
  `LoginUserResponseDTO`, pero `refreshToken` se exime del lado del schema porque nunca viaja en
  el body (solo como cookie httpOnly, ver `openspec/decisions.md`).

Qué justifica una exención (y qué no): "no tengo tiempo de arreglarlo ahora" **no** es un motivo
válido — el campo/modelo simplemente queda sin registrar hasta que alguien lo mapee. Un motivo
válido explica POR QUÉ este campo/modelo nunca va a tener contraparte (una decisión de diseño,
una limitación de una API externa, un dato que vive solo del lado del cliente).

### 12.7 Advertencia: un fixture a mano puede quedar desactualizado igual que un modelo a mano

Ya nos mordió una vez (ver §7.2): cuando no había backend disponible, se migraron
`professional_documents`/`promotions` contra un fixture JSON transcripto a mano desde el DTO real
del backend. Ese fixture es, en esencia, OTRO modelo a mano — puede quedar desactualizado
exactamente igual que el modelo Dart que reemplaza, y nada lo re-verifica automáticamente contra
el contrato real. **Usá `--openapi-url` contra un backend corriendo cada vez que puedas** — es
la única fuente que no puede quedar desactualizada por definición, porque ES el contrato actual.
Reservá `--openapi-file` (snapshot) para cuando el backend genuinamente no esté disponible, y
tratá cualquier hallazgo de "sin drift" contra un snapshot viejo como una confirmación parcial,
no definitiva — repetí la corrida contra `--openapi-url` en cuanto haya un backend a mano (mismo
criterio que ya aplicó §7.3 al re-confirmar `budgets` contra el contrato real después de haberlo
evaluado antes solo contra un fixture).

## 13. Resultado de correr el verificador contra los 72 modelos reales (2026-09-12)

Corrido con `--openapi-url` contra un backend real (`TekoApp-Backend`, `node dist/main.js`,
swagger en `/tekoapp-backend/api/swagger-json`) — no contra un fixture, ver §12.7. Los 72
archivos de modelo están cubiertos: 45 clases/enums mapeadas a un schema real (§ ver
`model_mapping.dart`, `modelMappings`) y el resto exento con motivo (`localModelExemptions`) —
sin ningún hallazgo `[SIN REGISTRAR]`.

La primera corrida dio **24 hallazgos (22 críticos, 2 advertencias) en 6 dominios**. Uno de
esos 6 (`auth`/`LoginResult`) resultó ser un falso positivo: `LoginResult` no tiene `fromJson`,
`AuthRepository.login()` lo arma a mano y ya traduce `login`/`requiredNewPassword` (claves reales
del backend) a `success`/`requiresNewPassword` (nombres Dart) correctamente — ver el ejemplo
trabajado completo en §12.4. Una vez registrado ese mapeo en `model_mapping.dart` (rename para
`login`->`success`, exención de campo para `requiredNewPassword`/`requiresNewPassword` — el
detalle de por qué no ambos son un simple rename está en §12.4), el resultado real y vigente
contra los 72 modelos es:

**20 hallazgos (todos críticos) en 5 dominios** — todos campos que el schema real devuelve y el
modelo a mano descarta en silencio (mismo patrón que B-01/M-05/`ratings`/`promotions`/
`professional_profile`):

| Dominio (clase) | Hallazgo |
|---|---|
| `categories` (`Category`) | 9 campos descartados en silencio: `description`, `sortOrder`, `status`, `isVisible`, `requiresVerification`, `maxBudgetOptionsPerRequest`, `metadata`, `createdAt`, `lastChangedAt`. El modelo a mano solo exponía `id`/`referenceId`/`name`/`slug`/`icon`/`color`/`parentCategoryId`. |
| `payments` (`PaymentMethod`) | 6 campos descartados en silencio: `userId`, `metadata`, `lastUsedAt`, `expiresAt`, `createdAt`, `updatedAt`. |
| `services` (`ServiceClientSummary`) | 3 campos descartados en silencio: `id`, `email`, `phoneNumber` (el modelo solo exponía `referenceId`/`firstName`/`lastName` del `ServiceUserSummaryResponseDTO` que anida `ServiceDetailResponseDTO.users`). |
| `locations` (`NearbyProfessional`) | 1 campo: `isAvailable` (booleano — distinto de `isOnline`, que sí se lee). |
| `locations` (`ProfessionalLastLocation`) | 1 campo: `lastUpdate` (fecha de la última actualización de posición). |

Dominios ya migrados a codegen (`ratings`, `payments`/`Payment`, `services`/`Service`,
`professional_profile`, `professional_documents`, `promotions`, `contracts`) y los evaluados sin
backend en rondas previas (`budgets`, `legal_consents`, `professional_portfolio`,
`service_progress`) se re-confirmaron sin drift en esta corrida — el verificador no encontró
nada nuevo ahí, consistente con el trabajo ya hecho.

**Hallazgo manual adicional (no detectado por el verificador v1, ver limitación en §11)**: el
enum Dart `LegalDocumentType` (`legal_consents`) cubre 4 valores
(`termsOfService`/`privacyPolicy`/`dataProcessingConsent`/`imageUsageConsent`); el schema real
(`LegalDocumentVersionResponseDTO.documentType`) ya lista 6, agregando
`SERVICE_CONTRACT_TERMS`/`USER_CONTENT_LIABILITY_DISCLAIMER`. Encontrado al construir el mapeo a
mano (comparando el `enum:` del schema contra el `switch` del enum Dart), no por una corrida del
verificador — comparar valores de enum es candidato a v2 (ver §11).

**Ningún fix se aplicó en esta tanda** — por pedido explícito: reportar el drift es esta tarea,
arreglarlo dominio por dominio es una decisión de José.

## 13.1 Los 20 hallazgos cerrados (2026-09-14)

Corrido contra un backend real levantado en esta sesión (`node dist/main.js`, `--openapi-url`).
Un commit por dominio, los 5 completados a mano (ninguno migrado al generador — todos son
6-9 campos, sin objetos/arrays anidados que justifiquen el generador, ver criterio de §12.5):

- **`categories` (`Category`, 2aeec39)** — 9 campos: `description`, `sortOrder`, `status`,
  `isVisible`, `requiresVerification`, `maxBudgetOptionsPerRequest`, `metadata`, `createdAt`,
  `lastChangedAt`. `status` sumó un enum nuevo (`CategoryStatus`), exento en `model_mapping.dart`
  como enum espejo (206ce37) — mismo patrón que `PaymentMethodType`.

  **Sin cambio de UI, y no por omisión**: la hipótesis inicial de esta tarea era que la app
  "probablemente" mostraba categorías ocultas/inactivas porque no podía leer `isVisible`/`status`.
  Se verificó contra el código real (`CategoriesRepository.fetchCategories` -> `GET /categories`
  -> `CategoriesService.findAll`, `TekoApp-Backend/src/api/categories/services/categories.service.ts:67-72`)
  y el backend YA filtra `status: ACTIVE, isVisible: true` del lado del servidor para ese endpoint
  — el único que los dos consumidores de Mobile (`professional_onboarding_screen.dart`,
  `request_service_screen.dart`) usan. Filtrar de nuevo en el cliente hubiera sido código muerto
  redundante, no una corrección real. Documentado en el docstring de `Category`.

- **`locations` (`NearbyProfessional`/`ProfessionalLastLocation`, 3b451b4)** —
  `isAvailable` (bool, distinto de `isOnline`) y `lastUpdate` (datetime nullable).
  `isAvailable` SÍ tuvo cambio de UI: `nearby_professionals_map_screen.dart` atenúa el marcador
  (gris en vez de rojo) y agrega una aclaración al tooltip cuando el profesional no está tomando
  servicios nuevos — no se filtra del mapa (sigue siendo útil ver dónde está). `lastUpdate` quedó
  sin consumidor: las actualizaciones vía socket (`locationUpdated`) no traen esa marca de tiempo,
  solo la carga inicial por REST la tiene.

- **`payments` (`PaymentMethod`, 94a573e)** — 6 campos: `userId`, `metadata`, `lastUsedAt`,
  `expiresAt`, `createdAt`, `updatedAt`. `expiresAt` se muestra en `payment_methods_screen.dart`
  (debajo de tipo/proveedor, formateado con `intl`). **Decisión pendiente, dejada sin resolver a
  propósito**: no se agregó lógica para deshabilitar o filtrar un método ya vencido en el selector
  de `pay_service_screen.dart` — no está claro en el código si el backend igual permite pagar con
  un método vencido (y esto queda solo como aviso visual) o si lo rechaza; es una decisión de
  negocio que le corresponde a José.

- **`services` (`ServiceClientSummary`, c0d37e9)** — `id`, `email`, `phoneNumber`. Sin cambio de
  UI: se verificó que `service.client` hoy solo se usa para `clientReferenceId` (calificar al
  cliente en `professional_services_screen.dart`), nunca se le muestra contacto al profesional.
  Mostrarle email/teléfono del cliente es una decisión de producto (¿contacto directo? ¿requiere
  consentimiento?) que no está resuelta en el código — se deja anotada en el docstring del modelo,
  no se decidió acá.

`check_drift` vuelve a dar `sin drift — todos los modelos mapeados coinciden con el swagger` contra
los 72 modelos.

## 13.2 Drift cerrado tras el cierre de 10 tareas del backend (2026-09-15)

El backend cerró 10 tareas que tocaban DTOs que Mobile ya mapea (nombres en `ratings`,
consentimiento de contacto en el resumen del cliente, preferencias de notificación nuevas).
`check_drift` contra un backend real (`node dist/main.js`, `--openapi-url`) dio **3 hallazgos (3
críticos)** en 2 dominios:

- **`ratings` (`Rating`)** — `RatingDetailResponseDTO` sumó `userName`/`professionalName`
  (`string?`), que el modelo generado no leía. Regenerado `rating.g.dart` con el mismo comando de
  §7 (`--int-fields id,userId,professionalId --enum-fields type:RatingType`) contra el backend
  real. Ambos campos nullable (mismo criterio que `userId`/`professionalId`: `null` cuando
  `isAnonymous=true`), sin consumidor en la UI todavía.
- **`services` (`ServiceClientSummary`)** — `ServiceUserSummaryResponseDTO.email` pasó de
  requerido a nullable: es la contraparte del nuevo `Users.shareContactInfo` (ver tarea de
  consentimiento de contacto de esta misma sesión) — el backend enmascara `email` a `null` cuando
  el cliente no comparte sus datos. `ServiceClientSummary.email` cambió de `String` a `String?`
  (`phoneNumber` ya era nullable desde antes, así que no generó hallazgo propio aunque el mismo
  mecanismo de enmascarado lo cubre).

Las preferencias de notificación nuevas que mencionó la consigna no generaron hallazgo de
`check_drift` — y es esperable, no un hueco del verificador: el backend agregó una familia de
schemas nueva (`NotificationPreferencesResponseDTO`, `NotificationPreferenceItemResponseDTO`,
`UpdateNotificationPreferenceRequestDTO`) para la que **no existe ningún modelo Dart todavía**, ni
mapeado ni exento. `check_drift` solo compara campo a campo un modelo que ya está registrado, y
solo reporta `[SIN REGISTRAR]` para un archivo `.dart` que exista bajo `lib/features/*/models/`
sin registrar — un schema nuevo del lado del backend sin ningún archivo Dart del lado de Mobile no
dispara ninguno de los dos casos. Consumir esa preferencia de notificaciones es una feature nueva
(pantalla + repositorio + modelo), no un fix de drift — queda fuera de las 4 tareas de esta sesión.

`check_drift` vuelve a dar `sin drift` tras estos dos fixes.

## 14. CI: qué encontramos y qué haría falta

`.github/workflows/ci.yml` corre en `ubuntu-latest`, hace checkout SOLO de este repo (Mobile) y
no levanta ningún servicio de backend — `flutter analyze`/`dart format`/`flutter test`, nada
más. No hay ninguna URL de un ambiente QA/staging commiteada acá: `Env.apiBaseUrl`
(`lib/core/config/env.dart`) se recibe por `--dart-define` en build time, nunca hardcodeada en el
repo ni en el workflow.

Conclusión: **el CI de Mobile hoy NO puede alcanzar un swagger real**, ni del backend levantado
localmente (obviamente no existe en un runner efímero de GitHub) ni de un ambiente QA desplegado
(no hay URL ni secret configurado para eso). Agregar un step que corra `check_drift.dart` tal
cual fallaría siempre por no poder conectarse — o, peor, alguien terminaría committeando un
snapshot (`--openapi-file`) "para que ande en CI", reintroduciendo exactamente el problema que
señala §12.7 (un fixture puede quedar tan desactualizado como el modelo que reemplaza, y encima
esta vez el CI lo daría por bueno indefinidamente).

**No se agregó nada al pipeline en esta tanda** — por pedido explícito, dado este hallazgo.

**Cómo se correría si se resuelve lo anterior**: agregar un job/step nuevo, aditivo (no reemplaza
`analyze`/`format`/`test`), del estilo:

```yaml
  check-model-drift:
    name: Verificar drift de modelos contra el swagger
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - name: Verificar drift contra el swagger de QA
        run: |
          dart run tool/openapi_codegen/check_drift.dart \
            --openapi-url ${{ secrets.QA_API_BASE_URL }}/tekoapp-backend/api/swagger-json
```

Hace falta, ANTES de agregar esto: (1) un ambiente QA de `TekoApp-Backend` desplegado y
alcanzable desde un runner de GitHub Actions (confirmar que no está detrás de una VPN/IP
allowlist que excluya a los runners hosteados), (2) esa URL cargada como secret del repo
(`QA_API_BASE_URL`), y (3) una decisión de si un hallazgo de severidad "advertencia" (no crítico)
también debería fallar el job, o solo imprimirse — hoy el código de salida usado por
`check_drift.dart` (§12.3) solo falla ante hallazgos críticos.
