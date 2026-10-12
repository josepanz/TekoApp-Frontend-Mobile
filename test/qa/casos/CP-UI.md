# CP-UI — Componentes de design system: skeleton, empty state y toast

Repo: Mobile (MOB). Trazabilidad general: hallazgos U1 y U2 (TEKOAPP-E2E-MASTER-PLAN §6.2).

## CP-MOB-UI-001 — TekoSkeleton list renderiza itemCount cards

| Campo | Contenido |
|---|---|
| Título | `TekoSkeleton` variante list renderiza la cantidad pedida de cards |
| Tipo / Nivel | unitaria · widget |
| Prioridad | P2 |
| Trazabilidad | U1 |
| Precondiciones | Widget aislado con tema claro |
| Pasos | 1. Montar la variante list con `itemCount`. 2. Contar las cards. |
| Datos de prueba | `itemCount` definido en el test |
| Resultado esperado | Número de cards igual a `itemCount` |
| Automatizado en | `test/shared/widgets/teko_skeleton_test.dart` — `variante list renderiza itemCount cards` (grupo `TekoSkeleton`) |

## CP-MOB-UI-002 — TekoSkeleton anuncia un único "Cargando"

| Campo | Contenido |
|---|---|
| Título | El skeleton se anuncia una sola vez como "Cargando" y excluye su subárbol |
| Tipo / Nivel | a11y · widget |
| Prioridad | P2 |
| Trazabilidad | U1, U3 |
| Precondiciones | Semántica activa |
| Pasos | 1. Montar el skeleton. 2. Listar los nodos semánticos. |
| Datos de prueba | Locale `es` |
| Resultado esperado | Un único nodo "Cargando"; los hijos no se anuncian |
| Automatizado en | `test/shared/widgets/teko_skeleton_test.dart` — `anuncia un único "Cargando" y excluye el subárbol` |

## CP-MOB-UI-003 — TekoSkeleton respeta reduce-motion

| Campo | Contenido |
|---|---|
| Título | Anima por defecto y detiene la animación con `disableAnimations` |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 |
| Trazabilidad | U1; Material 3 / HIG (reduce motion) |
| Precondiciones | `MediaQuery.disableAnimations` controlable |
| Pasos | 1. Montar con animaciones normales y verificar animación activa. 2. Remontar con `disableAnimations: true`. |
| Datos de prueba | `TekoSkeleton.line(width: 100)` |
| Resultado esperado | `hasRunningAnimations` pasa de true a false |
| Automatizado en | `test/shared/widgets/teko_skeleton_test.dart` — `anima por defecto y se detiene con reduce-motion` |

## CP-MOB-UI-004 — TekoSkeleton renderiza en dark mode

| Campo | Contenido |
|---|---|
| Título | El skeleton renderiza sin excepciones con el tema oscuro |
| Tipo / Nivel | unitaria · widget |
| Prioridad | P2 |
| Trazabilidad | U1; checklist 6.3 (claro y oscuro) |
| Precondiciones | Tema oscuro |
| Pasos | 1. Montar con tema oscuro. 2. Verificar que no hay excepción. |
| Datos de prueba | Ninguno |
| Resultado esperado | Sin errores de render |
| Automatizado en | `test/shared/widgets/teko_skeleton_test.dart` — `renderiza en dark mode sin errores` |

## CP-MOB-UI-005 — AsyncStateView usa loadingBuilder

| Campo | Contenido |
|---|---|
| Título | `AsyncStateView` muestra el `loadingBuilder` cuando se provee |
| Tipo / Nivel | unitaria · widget |
| Prioridad | P2 |
| Trazabilidad | U1 |
| Precondiciones | Estado `isLoading: true` |
| Pasos | 1. Montar `AsyncStateView` con `loadingBuilder`. 2. Verificar el widget. |
| Datos de prueba | Builder de prueba |
| Resultado esperado | Se ve el widget del builder, no el spinner |
| Automatizado en | `test/shared/widgets/teko_skeleton_test.dart` — `AsyncStateView usa loadingBuilder cuando se pasa` |

## CP-MOB-UI-006 — AsyncStateView sin loadingBuilder conserva el spinner

| Campo | Contenido |
|---|---|
| Título | Sin `loadingBuilder`, `AsyncStateView` mantiene el spinner (regresión) |
| Tipo / Nivel | regresión · widget |
| Prioridad | P2 |
| Trazabilidad | U1 |
| Precondiciones | Estado `isLoading: true` |
| Pasos | 1. Montar sin builder. 2. Buscar el indicador de progreso. |
| Datos de prueba | Ninguno |
| Resultado esperado | Spinner presente |
| Automatizado en | `test/shared/widgets/teko_skeleton_test.dart` — `AsyncStateView sin loadingBuilder mantiene el spinner` |

## CP-MOB-UI-007 — TekoEmptyState muestra ícono, título y descripción

| Campo | Contenido |
|---|---|
| Título | Renderiza ícono, título y descripción sin CTA |
| Tipo / Nivel | unitaria · widget |
| Prioridad | P2 |
| Trazabilidad | U2 |
| Precondiciones | Widget aislado |
| Pasos | 1. Montar sin acción. 2. Buscar ícono y textos; verificar que no hay botón. |
| Datos de prueba | Textos del test |
| Resultado esperado | Ícono, título y descripción visibles; sin CTA |
| Automatizado en | `test/shared/widgets/teko_empty_state_test.dart` — `muestra ícono, título y descripción sin CTA` (grupo `TekoEmptyState`) |

## CP-MOB-UI-008 — TekoEmptyState dispara onAction y cumple tap target

| Campo | Contenido |
|---|---|
| Título | El CTA invoca `onAction` y cumple las guidelines de tap target |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 |
| Trazabilidad | U2, U3 |
| Precondiciones | Semántica activa |
| Pasos | 1. Montar con label y `onAction`. 2. Evaluar guidelines. 3. Tocar el CTA. |
| Datos de prueba | Callback contador |
| Resultado esperado | Guidelines pasan y el callback se llama |
| Automatizado en | `test/shared/widgets/teko_empty_state_test.dart` — `el CTA dispara onAction y cumple tap target` |

## CP-MOB-UI-009 — TekoEmptyState anuncia el título como unidad

| Campo | Contenido |
|---|---|
| Título | El título se anuncia como una unidad semántica |
| Tipo / Nivel | a11y · widget |
| Prioridad | P2 |
| Trazabilidad | U2, U3 |
| Precondiciones | Semántica activa |
| Pasos | 1. Montar con título `Vacío`. 2. Buscar por label semántico. |
| Datos de prueba | Título `Vacío` |
| Resultado esperado | Un único nodo con el label `Vacío` |
| Automatizado en | `test/shared/widgets/teko_empty_state_test.dart` — `el título se anuncia como una unidad semántica` |

## CP-MOB-UI-010 — AsyncStateView usa TekoEmptyState en el estado vacío

| Campo | Contenido |
|---|---|
| Título | `AsyncStateView` con datos vacíos muestra `TekoEmptyState` con mensaje y CTA |
| Tipo / Nivel | integración · widget |
| Prioridad | P2 |
| Trazabilidad | U2 |
| Precondiciones | `isEmpty: true`, `emptyMessage`, `emptyActionLabel` |
| Pasos | 1. Montar `AsyncStateView`. 2. Buscar `TekoEmptyState`, mensaje y CTA. |
| Datos de prueba | Mensaje `Nada por acá`, CTA `Agregar` |
| Resultado esperado | Se renderiza `TekoEmptyState` con ambos textos |
| Automatizado en | `test/shared/widgets/teko_empty_state_test.dart` — `AsyncStateView lo usa para el estado vacío` |

## CP-MOB-UI-011 — TekoToast muestra mensaje e ícono por variante

| Campo | Contenido |
|---|---|
| Título | Las variantes success, error e info muestran mensaje e ícono propios |
| Tipo / Nivel | unitaria · widget |
| Prioridad | P2 |
| Trazabilidad | U2 |
| Precondiciones | Tema claro; `TekoToast.show` disparado desde un botón |
| Pasos | 1. Tocar el botón por variante. 2. Buscar texto e ícono. |
| Datos de prueba | Mensaje `Hecho`; íconos `check_circle_outline`, `error_outline`, `info_outline` |
| Resultado esperado | Mensaje e ícono correctos por variante |
| Automatizado en | `test/shared/widgets/teko_toast_test.dart` — `variante success muestra mensaje e ícono`, `variante error muestra mensaje e ícono`, `variante info muestra mensaje e ícono` (generados en bucle) |

## CP-MOB-UI-012 — TekoToast se anuncia como liveRegion

| Campo | Contenido |
|---|---|
| Título | El toast se anuncia como `liveRegion` |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 |
| Trazabilidad | U2, U3 |
| Precondiciones | Semántica activa |
| Pasos | 1. Mostrar el toast. 2. Inspeccionar nodos semánticos con el label. |
| Datos de prueba | Mensaje `Guardado` |
| Resultado esperado | Al menos un nodo con `isLiveRegion` |
| Automatizado en | `test/shared/widgets/teko_toast_test.dart` — `anuncia como liveRegion` |

## CP-MOB-UI-013 — TekoToast con y sin acción

| Campo | Contenido |
|---|---|
| Título | Muestra la acción y dispara su callback; sin `onAction` no hay acción aunque haya label |
| Tipo / Nivel | unitaria · widget |
| Prioridad | P2 |
| Trazabilidad | U2 (acción "Deshacer") |
| Precondiciones | Toast con label de acción |
| Pasos | 1. Mostrar con `onAction` y tocar la acción. 2. Mostrar con label y sin `onAction`. |
| Datos de prueba | Callback bandera |
| Resultado esperado | Callback ejecutado; sin `SnackBarAction` en el segundo caso |
| Automatizado en | `test/shared/widgets/teko_toast_test.dart` — `acción opcional se muestra y dispara el callback` y `sin onAction no hay acción aunque haya label` |

## CP-MOB-UI-014 — TekoToast funciona en dark mode

| Campo | Contenido |
|---|---|
| Título | El toast se muestra sin excepciones con el tema oscuro |
| Tipo / Nivel | unitaria · widget |
| Prioridad | P2 |
| Trazabilidad | U2; checklist 6.3 |
| Precondiciones | Tema oscuro |
| Pasos | 1. Mostrar el toast. 2. Verificar el texto y que no hubo excepciones. |
| Datos de prueba | Mensaje `Oscuro` |
| Resultado esperado | Texto visible, sin excepciones |
| Automatizado en | `test/shared/widgets/teko_toast_test.dart` — `funciona en dark mode` |

## CP-MOB-UI-015 — Contraste AA del toast por variante (manual)

| Campo | Contenido |
|---|---|
| Título | El texto del toast cumple contraste AA (4.5:1) en cada variante, en claro y oscuro |
| Tipo / Nivel | a11y · funcional (manual) |
| Prioridad | P2 |
| Trazabilidad | U2; checklist 6.3 (contraste AA) |
| Precondiciones | Emulador o dispositivo; ambos temas |
| Pasos | 1. Disparar cada variante en claro y oscuro. 2. Medir el contraste texto/fondo sobre captura. |
| Datos de prueba | Variantes success, error, info |
| Resultado esperado | Ratio >= 4.5:1 en las 6 combinaciones |
| Automatizado en | No automatizado: ningún test mide el ratio de contraste (hueco documentado; los tests de dark mode solo verifican que renderice) |
