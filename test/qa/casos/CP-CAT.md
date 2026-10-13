# CP-CAT — Catálogos (categorías y tipos de servicio)

Repo: Mobile (MOB). Trazabilidad: plan maestro M2 (Catálogos). Nota: el Home no lista categorías; el consumidor real de los catálogos es la pantalla "Pedir un servicio" (`/solicitar`).

## CP-MOB-CAT-001 — Las categorías llegan del backend

| Campo | Contenido |
|---|---|
| Título | Las categorías llegan del backend |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P0 |
| Trazabilidad | M2 categorías visibles en Mobile |
| Precondiciones | Backend e2e con seed (categoría `Plomería`); sesión como cliente_a |
| Pasos | 1. Login. 2. Tocar Pedir un servicio. 3. Abrir el selector de categoría. |
| Datos de prueba | `cliente_a@e2e.tekoapp.local` / `E2e-Passw0rd!` |
| Resultado esperado | El selector lista `Plomería` |
| Automatizado en | Automatizado en: `.maestro/m2-catalogos.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## CP-MOB-CAT-002 — Los tipos de servicio llegan del backend

| Campo | Contenido |
|---|---|
| Título | Los tipos de servicio llegan del backend |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P0 |
| Trazabilidad | M2 service-types |
| Precondiciones | Igual que CP-MOB-CAT-001 (tipo `Instalación`) |
| Pasos | 1. En Pedir un servicio, elegir categoría. 2. Abrir el selector de tipo. |
| Datos de prueba | `cliente_a@e2e.tekoapp.local` / `E2e-Passw0rd!` |
| Resultado esperado | El selector lista `Instalación` |
| Automatizado en | Automatizado en: `.maestro/m2-catalogos.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## CP-MOB-CAT-003 — Muestra estado de error si el catálogo no carga

| Campo | Contenido |
|---|---|
| Título | Muestra estado de error si el catálogo no carga |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P1 |
| Trazabilidad | M2 error del catálogo (sin red); `AsyncStateView` |
| Precondiciones | Sesión iniciada; el flujo activa modo avión antes de abrir `/solicitar` (los catálogos se cachean en memoria tras la primera carga) y lo restaura en `onFlowComplete` |
| Pasos | 1. Login. 2. Activar modo avión. 3. Tocar Pedir un servicio. |
| Datos de prueba | `cliente_a@e2e.tekoapp.local` / `E2e-Passw0rd!` |
| Resultado esperado | Texto `No se pudo cargar el catálogo`, sin crash ni spinner infinito |
| Automatizado en | Automatizado en: `.maestro/m2-catalogos-sin-red.yaml`. Estado: **pendiente de ejecución: sin dispositivo**. Limitación: el estado vacío (backend sano sin categorías) no es automatizable sin mutar la DB compartida; queda manual. |

## CP-MOB-CAT-004 — Parsea el JUnit de Maestro para el informe tipo flujo

| Campo | Contenido |
|---|---|
| Título | Parsea el JUnit de Maestro para el informe tipo flujo |
| Tipo / Nivel | unitaria |
| Prioridad | P2 |
| Trazabilidad | Infra QA; QA-DOC-STANDARD §3 (Maestro: `--format junit`) |
| Precondiciones | XML de ejemplo en memoria |
| Pasos | 1. Parsear el XML. 2. Verificar conteos, mensaje de fallo y duración. |
| Datos de prueba | XML con 4 testcases (2 OK, 1 error, 1 omitido) |
| Resultado esperado | Conteos y mensaje correctos; entidades XML decodificadas |
| Automatizado en | `test/tool/qa_junit_test.dart` — grupo `parseJunit` |
