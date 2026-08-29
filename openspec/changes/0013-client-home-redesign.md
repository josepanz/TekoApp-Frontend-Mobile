# Fase 0013 — Rediseño visual del home de cliente

Detectado el 2026-08-24 al probar el primer APK contra el backend cloud — ver la entrada
"Rediseño visual del home de cliente" en `openspec/decisions.md` (backlog 2026-08-22).

**Decidido e implementado (2026-08-25): Opción C**, confirmada por José. `HomeScreen` ya tiene el
nuevo layout (saludo + CTA destacada + grid secundario 2×2), `flutter analyze`/`flutter test` en
verde (268/268, incluyendo el nuevo `test/features/home/widgets/home_screen_test.dart`). Queda
pendiente únicamente la verificación visual en dispositivo real (claro/oscuro) — ver checklist al
final, no cubierto por tests automatizados.

## Antes de empezar

Leer, en este orden:

- `.claude/rules/design-system.md` de este repo (incluye la sección de accesibilidad — este repo
  no tiene un `accessibility.md` separado, está fusionado ahí a propósito, ver su encabezado "mismo
  estándar que `TekoApp-Web/.claude/rules/accessibility.md`, adaptado").
- `TekoApp-Web/.claude/rules/accessibility.md` — el estándar completo del que la sección anterior
  es un resumen adaptado a Flutter (checklist pre-cierre de 8 puntos, contraste AA, targets
  táctiles, etc.).
- `TekoApp-Web/src/design-system/tokens/tokens.json` — fuente de verdad de marca (balance 80/20
  primary/accent, escalas de color, radios).
- `lib/features/home/widgets/home_screen.dart` y
  `lib/features/professional_profile/widgets/professional_home_screen.dart` (código actual, ya
  incluye el ícono de cambio de modo movido al `AppBar` — fix puntual de sesión 2026-08-24, no
  forma parte de esta fase).
- `lib/shared/widgets/` (`teko_button.dart`, `teko_card.dart`, `teko_badge.dart`,
  `teko_avatar.dart`, `teko_input.dart`, `async_state_view.dart`) — primitivos ya existentes,
  espejo de `TekoApp-Web/src/components/ui/` (`button.tsx`, `card.tsx`).

## Contexto

`HomeScreen` (`lib/features/home/widgets/home_screen.dart`) sigue siendo el scaffold crudo de la
Fase 0001 (bootstrap): un `Column` centrado dentro de un `Center`, con una pila vertical de 5
`TekoButton` sueltos sin jerarquía visual (pedir servicio, mapa de cercanos, mis servicios, métodos
de pago, historial de pagos — solo el primero es `primary`, el resto `outline`, sin agrupación ni
íconos), más el texto `l10n.comingSoon` ("Próximamente") y el resultado del smoke test de red de la
Fase 0001 (`networkSmokeCheckProvider`, que hoy muestra literalmente "N países cargados desde el
backend" en producción) todavía visibles en pantalla. Funciona, pero no transmite "app terminada"
— se identificó en sesión 2026-08-24 al probar el primer APK apuntando al backend cloud (ver
`.claude/memory/sessions/`), junto con dos bugs reales que sí se corrigieron en esa misma sesión
(no forman parte de esta fase, ya cerrados):

- `/` no estaba en `_protectedPaths` (`lib/app.dart`) — un usuario sin sesión veía este home antes
  de loguearse. Corregido.
- El selector cliente/profesional era un botón "ghost" suelto en medio de la lista, fácil de
  confundir con un modo admin. Movido a un ícono en el `AppBar` (`Icons.swap_horiz`,
  key `home_professional_mode_button`) como fix puntual — **no** se considera terminado el pulido
  visual del selector en sí, solo se sacó de la lista de botones. El mismo patrón ya existe en
  `ProfessionalHomeScreen` (`professional_home_back_to_client_button`), simétrico.

**Hallazgo adicional de esta redacción (no visto en el borrador original)**: el catálogo de
traducciones ya tiene una key `homeGreeting` (`"Hola, {name}"` / `"Hi, {name}"`,
`lib/l10n/es.arb`/`en.arb`) generada y disponible en `AppLocalizations`, pero **nunca se usa en
ningún widget** — ni `HomeScreen` ni ningún otro lugar la invoca hoy (confirmado por grep). Es un
string huérfano, probablemente preparado en una fase anterior para un saludo personalizado que
nunca se conectó. Cualquier opción de layout que incluya un saludo con nombre debería reusar esta
key existente en vez de crear una nueva — el dato (`firstName`) ya está disponible vía
`sessionProvider` → `SessionAuthenticated.user.firstName` (`lib/core/auth/user_summary.dart`), sin
pedir nada nuevo al backend.

## Objetivo

Rediseñar `HomeScreen` (y, con el mismo criterio, revisar si `ProfessionalHomeScreen` necesita el
mismo pase) para que se vea como una pantalla de inicio real de producto — jerarquía visual clara,
balance de marca 80/20 aplicado, cero artefactos de debug — en vez de un panel de navegación de
desarrollo. **Alcance de diseño visual, no de arquitectura**: no cambia routing (`lib/app.dart`
mantiene exactamente las mismas rutas), no cambia providers existentes, no cambia ningún contrato
con el backend. Ninguna ruta nueva se inventa en esta fase — las 5 rutas ya wireadas
(`/solicitar`, `/mapa/cercanos`, `/mis-servicios`, `/pagos/metodos`, `/pagos/historial`) son el
universo completo de accesos a organizar.

## Opciones de layout (candidatas — ninguna decidida todavía)

Las 3 opciones comparten la misma base: `AppBar` con el ícono de cambio de modo tal cual está hoy
(no se toca en esta fase), y ningún texto/widget de debug visible. Difieren en cómo se organizan
los 5 accesos existentes.

### Opción A — Grid 2×N de accesos rápidos con ícono + label

Reemplaza la `Column` de botones por un `GridView` de 2 columnas, una tarjeta (`TekoCard`) por
acceso, cada una con un ícono grande + label corto + `onTap` navegando a la misma ruta que hoy.
Con 5 accesos, la grilla queda 2-2-1 (o 2-2-2 si se agrega un 6º slot "Mi perfil", ya accesible
desde otro lado de la navegación hoy — a confirmar si conviene duplicarlo acá). Un acceso (el más
usado, candidato obvio: "Pedir servicio") se destaca con `accent` como único punto de énfasis
(único uso de `accent` en la pantalla, regla 80/20); el resto usa `primary` en el ícono sobre
fondo `TekoCard` neutro.

- **Mapeo de rutas**: cada card = un `context.push` directo, igual que hoy (`/solicitar`,
  `/mapa/cercanos`, `/mis-servicios`, `/pagos/metodos`, `/pagos/historial`) — cero rutas nuevas.
- **Ventaja**: cambio más chico y contenido en `HomeScreen` solo — no toca `app.dart`,
  `Scaffold` sigue siendo uno solo, sin `BottomNavigationBar` que sincronizar con `go_router`
  (`StatefulShellRoute` no es necesario). Reutiliza `TekoCard` tal cual ya existe.
- **Desventaja**: sigue siendo "una pantalla con botones", aunque mejor organizada — no resuelve
  el problema de fondo de que pagos/mapa/mis-servicios están un nivel de navegación más lejos que
  en una bottom nav. Con 5 accesos + saludo + posible sección de estado, puede quedar apretada en
  pantallas chicas si no se cuida el `childAspectRatio`.
- **Esfuerzo estimado**: bajo — un solo archivo (`home_screen.dart`), sin tocar `app.dart` ni
  ningún provider.

### Opción B — Bottom navigation bar persistente (3-4 tabs) + FAB para "pedir servicio"

Introduce un `Scaffold` con `BottomNavigationBar` (o `NavigationBar` de Material 3) de 3-4 tabs
persistentes en el nivel del home de cliente — candidatos: "Inicio" (resumen/estado), "Mapa"
(`/mapa/cercanos`), "Mis servicios" (`/mis-servicios`), "Pagos" (podría fusionar métodos+historial
en una sub-navegación con tabs internas, ya que hoy son 2 rutas separadas). "Pedir servicio" pasa a
un `FloatingActionButton` extendido, centrado o flotante sobre la bottom bar (patrón común en apps
de marketplace) en vez de ser un ítem más de la lista — es la acción más importante, el `accent`
de marca es un candidato natural para el FAB (único punto de énfasis de la pantalla).

- **Mapeo de rutas**: **requiere tocar `lib/app.dart`** — para que la bottom nav persista entre
  tabs sin perder el `Scaffold`/estado de cada tab al cambiar, la forma correcta con `go_router` es
  `StatefulShellRoute.indexedStack` (rutas hijas `/mapa/cercanos`, `/mis-servicios`,
  `/pagos/...` anidadas bajo el shell) en vez de los `GoRoute` planos actuales. Sigue siendo el
  mismo conjunto de rutas (mismos paths, mismos guards de `_protectedPaths`), pero cambia CÓMO se
  registran en el router — es el único candidato de las 3 opciones con impacto real fuera de
  `home_screen.dart`.
- **Ventaja**: patrón más "app terminada" — es lo que un usuario espera de una app de marketplace
  mobile moderna (comparable a apps de delivery/servicios). Los accesos más usados quedan a un tap
  siempre, sin volver al home.
- **Desventaja**: mayor esfuerzo y mayor superficie de riesgo (tocar `app.dart` significa
  re-verificar los guards de sesión y el redirect de `_professionalGatedPaths` contra la nueva
  estructura de rutas anidadas) para una fase que se definió como "alcance de diseño, no de
  arquitectura". "Pagos" con 2 sub-rutas (métodos/historial) necesita una decisión de UX adicional
  (¿tab con 2 sub-tabs? ¿un solo tab que aterriza en historial con acceso a métodos desde ahí?) que
  el borrador original no había anticipado.
- **Esfuerzo estimado**: medio-alto — toca `app.dart` (estructura de rutas), potencialmente
  `test/app_redirect_test.dart` (ya cubre la lógica de guards, tendría que seguir en verde contra
  el shell nuevo).

### Opción C — Header con saludo + 1 CTA principal destacado + lista secundaria de accesos

Combina elementos de A y B sin tocar routing: un header superior (dentro del `body`, no del
`AppBar`) con el saludo `l10n.homeGreeting(firstName)` (conecta el string huérfano mencionado en
Contexto) y opcionalmente un `TekoAvatar` chico; debajo, una `TekoCard` grande y destacada solo
para "Pedir servicio" (el único uso de `accent`, con ícono + texto explicativo corto, ocupa el
ancho completo — es el CTA principal de la pantalla); debajo de eso, una lista o grid más chico
(2×2) para los 4 accesos restantes (mapa, mis servicios, métodos de pago, historial), en `primary`
o neutro, sin competir visualmente con el CTA principal.

- **Mapeo de rutas**: igual que la Opción A — 5 `context.push` a las rutas ya existentes, cero
  cambios en `app.dart`.
- **Ventaja**: resuelve el problema de jerarquía visual (que es el hallazgo real de esta fase) sin
  el riesgo/esfuerzo de tocar el router. Conecta el string `homeGreeting` huérfano, dándole un uso
  real. La separación "1 CTA destacado + accesos secundarios" comunica mejor qué es lo más
  importante de hacer en el home que una grilla donde 5 accesos compiten en igualdad de peso
  visual (Opción A).
- **Desventaja**: sigue sin persistencia de navegación entre pantallas (cada acceso es un `push`
  que apila sobre el home, como hoy) — no resuelve el mismo problema estructural que B sí resuelve,
  aunque no era parte del objetivo original de esta fase (que es visual, no de arquitectura de
  navegación).
- **Esfuerzo estimado**: bajo-medio — un solo archivo (`home_screen.dart`), reusa `TekoCard`/
  `TekoButton`/`TekoAvatar` ya existentes, agrega una key de estado de sesión (`firstName`) ya
  disponible sin pedir nada nuevo al backend.

## Recomendación (pendiente de confirmación de José — NO es una decisión tomada)

**Opción C** como default sugerido: resuelve el hallazgo real de esta fase (falta de jerarquía
visual, artefactos de debug visibles) con el menor riesgo/esfuerzo, sin tocar `app.dart` ni los
guards de sesión ya probados (`test/app_redirect_test.dart`), y de paso conecta un string de i18n
que ya existe pero está huérfano. La Opción B (bottom nav) es una mejora de navegación real y
probablemente el destino correcto a mediano plazo para esta app, pero excede el alcance declarado
de esta fase ("diseño visual, no arquitectura") y trae una superficie de riesgo (reestructurar
rutas con `StatefulShellRoute`) que amerita su propia fase dedicada si se decide perseguirla — no
mezclarla con este rediseño puntual. La Opción A es válida pero deja los 5 accesos en igualdad de
peso visual, sin comunicar cuál es la acción principal esperada ("pedir un servicio" es
razonablemente el corazón del producto del lado cliente).

**Esta es una recomendación, no una decisión final** — José confirma la opción (o pide una
variante/combinación) antes de que se escriba cualquier código de esta fase.

## Tareas

- [x] **Decisión de producto con José**: confirmada Opción C (2026-08-25).
- [x] Implementar el layout elegido en `HomeScreen`, reutilizando `shared/widgets/` existentes
      (`TekoCard`; `TekoButton`/`TekoAvatar` no se necesitaron — el CTA usa `Material`/`InkWell`
      directo para lograr la superficie `accent` de ancho completo, no hay una variante de
      `TekoButton` para eso hoy).
- [x] Quitar el texto `l10n.comingSoon` y el widget que muestra el resultado de
      `networkSmokeCheckProvider` (`AsyncStateView` + `l10n.networkSmokeCheckLoaded`/
      `networkSmokeCheckError`) de la UI visible de `HomeScreen`. **Confirmado por grep**: el
      provider (`lib/core/api_client/network_smoke_check_provider.dart`) y sus keys de traducción
      siguen usados en 5 archivos de test (`test/app_redirect_test.dart`, `test/app_test.dart`,
      `test/core/api_client/network_smoke_check_provider_test.dart`,
      `test/e2e/login_profile_logout_test.dart`,
      `test/features/profile/widgets/profile_screen_test.dart`) — todos como
      override/mock de infraestructura o su propia suite dedicada, ninguno depende de que se
      renderice en `HomeScreen`. El provider en sí puede quedar vivo para diagnóstico interno (no
      se elimina el archivo ni su test dedicado), solo se saca de la UI de cara al usuario.
      Verificar que ningún test de `HomeScreen` (nuevo, ver más abajo) dependa de encontrar ese
      texto en pantalla.
- [x] Conectar el saludo (`l10n.homeGreeting`) a `sessionProvider` →
      `SessionAuthenticated.user.firstName`. `/` ya está detrás de `_protectedPaths`, así que en la
      práctica `HomeScreen` no se monta sin sesión — el pattern-match sobre `SessionState` igual
      cae a `''` de forma defensiva si no es `SessionAuthenticated`, sin asumir el guard ciegamente.
- [x] Aplicar el balance de marca 80/20: `colorScheme.tertiary`/`onTertiary` (accent) solo en la
      CTA de "pedir servicio" (`_RequestServiceCta`, único foco teal de la pantalla); los 4 accesos
      del grid usan `colorScheme.primary` en el ícono sobre `TekoCard` neutro.
- [x] `ProfessionalHomeScreen` revisado — **decisión: no se rediseña en esta fase**. Ya tiene
      jerarquía real propia (switch de disponibilidad + `AvailableServicesScreen`), no comparte el
      problema de "pila de botones sin jerarquía" que motivó esta fase. Se aprovechó para simplificar
      su `Scaffold` (el `body` pasa a ser directamente el `switch` de estado, sin el `Column`+
      `Padding` extra que quedaba de la Fase 0001) al mover el botón de volver a modo cliente al
      `AppBar` — cambio ya hecho en la sesión 2026-08-24, no en esta fase.
- [x] Accesibilidad: `Semantics(button: true, label: ...)` en la CTA y en cada tile del grid
      (ninguno es un control solo-ícono sin label — todos llevan texto visible además). Targets
      táctiles ≥44px verificados (CTA con `minHeight: 44` + padding 20; tiles del grid muy por
      encima del mínimo con `childAspectRatio: 1.3` en un grid de 2 columnas). Contraste: reusa
      `colorScheme.primary`/`tertiary`/`onPrimary`/`onTertiary` ya verificados en el rebrand de
      `TekoApp-Web` (2026-08-02) — no se introdujo ningún color nuevo.
- [ ] Probar el layout final en tema claro y oscuro en un dispositivo/emulador real — pendiente de
      José, no cubierto por `flutter test` (que no valida percepción visual real).
- [x] Sin strings nuevos — se reusó `homeGreeting` (ya existente, antes huérfano) y las 5 keys de
      título de cada acceso, que ya estaban traducidas en `es.arb`/`en.arb` desde antes de esta fase.
- [x] **Test de widget para `HomeScreen`** — creado `test/features/home/widgets/home_screen_test.dart`
      (5 tests): saludo con nombre de la sesión mockeada, ausencia de los artefactos de debug
      (`comingSoon`/smoke test), navegación de la CTA y de un acceso del grid, y el ícono de cambio
      de modo navegando a `/profesional` + actualizando `appModeProvider`. Los tests preexistentes
      que usaban `find.byType(HomeScreen)` como ancla para obtener el router en sesión NO
      autenticada (`test/app_redirect_test.dart`, `test/e2e/login_profile_logout_test.dart`) se
      ajustaron para anclar en `LoginScreen` en su lugar — consecuencia del fix de `/` protegida
      (sesión 2026-08-24), no de este rediseño en sí.
- [x] `flutter analyze` y `flutter test` completos en verde — 268/268 tests, 0 issues de analyze.

## Checkpoint de salida

- [x] José aprueba el layout final — Opción C confirmada 2026-08-25.
- [x] Cero texto/artefacto de debug visible en el home de cara al usuario — verificado por
      `home_screen_test.dart` ("cero artefactos de debug de la Fase 0001 visibles").
- [x] `flutter analyze` y `flutter test` en verde, incluyendo
      `test/features/home/widgets/home_screen_test.dart`.
- [x] Checklist de accesibilidad aplicado en el código (`Semantics`, targets táctiles, contraste
      reusando colores ya verificados) — ver detalle en la tarea correspondiente arriba.
- [ ] Probado visualmente en claro y oscuro en al menos un dispositivo/emulador real — pendiente de
      José (no cubierto por `flutter test`).
- N/A — Opción B (bottom nav) no fue la elegida, el checkpoint de `StatefulShellRoute`/guards no
      aplica a esta fase.
