# CP-A11Y — Accesibilidad y selectores E2E (login, home, pagos)

Repo: Mobile (MOB). Trazabilidad general: hallazgo U3 (TEKOAPP-E2E-MASTER-PLAN §6.2), `docs/e2e-selectors.md`.
Precondición común: `tester.ensureSemantics()` activo; Dio y providers mockeados; locale `es`.

## CP-MOB-A11Y-001 — Cumple guidelines de tap target y labels en login

| Campo | Contenido |
|---|---|
| Título | Verifica que la pantalla de login cumple tap target Android/iOS y labels en todo elemento tocable |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 |
| Trazabilidad | U3; M1 (Auth); bloquea selectores Maestro |
| Precondiciones | `LoginScreen` montada con providers de auth y biometría mockeados |
| Pasos | 1. Activar semántica. 2. Montar `LoginScreen`. 3. Evaluar `androidTapTargetGuideline`, `iOSTapTargetGuideline` y `labeledTapTargetGuideline`. |
| Datos de prueba | Ninguno (pantalla vacía) |
| Resultado esperado | Las tres guidelines pasan: sin nodos tocables menores a 48x48 dp (Android) / 44x44 pt (iOS) ni sin label |
| Automatizado en | `test/features/auth/widgets/login_screen_test.dart` — `targets táctiles y labels cumplen las guidelines` (grupo `accesibilidad`) |

## CP-MOB-A11Y-002 — Expone ids E2E estables en login

| Campo | Contenido |
|---|---|
| Título | Expone `auth.login.submit_button`, `email_field` y `password_field` como `Semantics.identifier` |
| Tipo / Nivel | a11y · widget (contrato de selectores Maestro) |
| Prioridad | P1 |
| Trazabilidad | `docs/e2e-selectors.md`; plan maestro M1 |
| Precondiciones | Igual que CP-MOB-A11Y-001 |
| Pasos | 1. Activar semántica. 2. Montar `LoginScreen`. 3. Buscar cada id con `bySemanticsId`. |
| Datos de prueba | ids `auth.login.submit_button`, `auth.login.email_field`, `auth.login.password_field` |
| Resultado esperado | Cada id aparece exactamente una vez en el árbol semántico |
| Automatizado en | `test/features/auth/widgets/login_screen_test.dart` — `expone identificadores E2E estables` (grupo `accesibilidad`) |

## CP-MOB-A11Y-003 — Home cumple guidelines y expone ids E2E

| Campo | Contenido |
|---|---|
| Título | Home cumple tap target Android y labels y expone `home.home.request_service_cta` y `professional_mode_button` |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 |
| Trazabilidad | U3; `docs/e2e-selectors.md` |
| Precondiciones | `HomeScreen` con usuario autenticado fixture, providers mockeados |
| Pasos | 1. Activar semántica. 2. Montar Home. 3. Evaluar `androidTapTargetGuideline` y `labeledTapTargetGuideline`. 4. Buscar los dos ids. |
| Datos de prueba | ids `home.home.request_service_cta`, `home.home.professional_mode_button` |
| Resultado esperado | Guidelines pasan; ambos ids presentes una vez |
| Automatizado en | `test/features/home/widgets/home_screen_test.dart` — `accesibilidad: guidelines de tap target y labels + ids E2E` |

## CP-MOB-A11Y-004 — Estado vacío de métodos de pago cumple guidelines

| Campo | Contenido |
|---|---|
| Título | Pantalla de métodos de pago sin métodos guardados cumple tap target y labels |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 (dinero) |
| Trazabilidad | U3; M6 (Pagos) |
| Precondiciones | `GET /payments/methods` mockeado con lista vacía |
| Pasos | 1. Activar semántica. 2. Montar la pantalla y esperar `pumpAndSettle`. 3. Evaluar `androidTapTargetGuideline` y `labeledTapTargetGuideline`. |
| Datos de prueba | Respuesta `[]` |
| Resultado esperado | Guidelines pasan, incluido el CTA "Agregar método de pago" del estado vacío |
| Automatizado en | `test/features/payments/widgets/payment_methods_screen_test.dart` — `estado vacío cumple las guidelines de accesibilidad` |

## CP-MOB-A11Y-005 — TekoButton deriva label semántico y expone id

| Campo | Contenido |
|---|---|
| Título | `TekoButton` toma el label del texto y publica su id |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 |
| Trazabilidad | U3; base de todos los ids E2E |
| Precondiciones | `TekoButton` aislado en `MaterialApp` |
| Pasos | 1. Montar con texto e id. 2. Inspeccionar el nodo semántico. |
| Datos de prueba | Texto e id definidos en el test |
| Resultado esperado | Label igual al texto e `identifier` igual al id |
| Automatizado en | `test/shared/widgets/teko_semantics_test.dart` — `TekoButton deriva el label semántico del texto y expone id` |

## CP-MOB-A11Y-006 — TekoButton acepta label semántico explícito

| Campo | Contenido |
|---|---|
| Título | `TekoButton` prioriza `semanticLabel` sobre el texto visible |
| Tipo / Nivel | a11y · widget |
| Prioridad | P2 |
| Trazabilidad | U3 |
| Precondiciones | Igual que CP-MOB-A11Y-005 |
| Pasos | 1. Montar con `semanticLabel`. 2. Inspeccionar el nodo. |
| Datos de prueba | Label explícito del test |
| Resultado esperado | El nodo anuncia el label explícito |
| Automatizado en | `test/shared/widgets/teko_semantics_test.dart` — `TekoButton acepta semanticLabel explícito` |

## CP-MOB-A11Y-007 — TekoInput se anuncia con su label y expone id

| Campo | Contenido |
|---|---|
| Título | `TekoInput` anuncia su label y publica su id |
| Tipo / Nivel | a11y · widget |
| Prioridad | P1 |
| Trazabilidad | U3 (labels en inputs) |
| Precondiciones | `TekoInput` aislado |
| Pasos | 1. Montar con label e id. 2. Inspeccionar semántica. |
| Datos de prueba | Definidos en el test |
| Resultado esperado | Label e identifier presentes en el nodo del campo |
| Automatizado en | `test/shared/widgets/teko_semantics_test.dart` — `TekoInput se anuncia con su label y expone id` |

## CP-MOB-A11Y-008 — TekoAvatar tiene label o es decorativo

| Campo | Contenido |
|---|---|
| Título | `TekoAvatar` expone label y puede marcarse decorativo (excluido de semántica) |
| Tipo / Nivel | a11y · widget |
| Prioridad | P2 |
| Trazabilidad | U3 |
| Precondiciones | `TekoAvatar` aislado |
| Pasos | 1. Montar con label. 2. Montar en modo decorativo. 3. Comparar el árbol semántico. |
| Datos de prueba | Definidos en el test |
| Resultado esperado | Con label: nodo anunciado; decorativo: sin nodo |
| Automatizado en | `test/shared/widgets/teko_semantics_test.dart` — `TekoAvatar tiene label y puede ser decorativo` |

## CP-MOB-A11Y-009 — Tooltips en botones de ícono con lector real (manual)

| Campo | Contenido |
|---|---|
| Título | Los botones de ícono de login/home/pagos se anuncian con nombre (tooltip/label) |
| Tipo / Nivel | a11y · funcional (manual) |
| Prioridad | P2 |
| Trazabilidad | U3 (`tooltip` en botones de ícono) |
| Precondiciones | App en dispositivo o emulador con TalkBack o VoiceOver |
| Pasos | 1. Navegar con el lector de pantalla a cada botón de ícono. 2. Verificar el anuncio. |
| Datos de prueba | Usuario fixture `cliente_a` |
| Resultado esperado | Cada botón de ícono se anuncia con su nombre |
| Automatizado en | Parcial: `labeledTapTargetGuideline` en los tests de CP-MOB-A11Y-001, -003 y -004 detecta la ausencia de label; la verificación con lector real no está automatizada |
