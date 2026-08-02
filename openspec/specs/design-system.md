# Spec: Sistema de diseño

## Fuente de verdad

`TekoApp-Web/src/design-system/tokens/tokens.json` (formato W3C Design Tokens) — **nunca**
redefinir colores/tipografía a mano en Dart. El archivo ya fue rebrandeado (2026-08-02) a la
paleta oficial del manual de marca:

| Token | Valor | Uso |
|---|---|---|
| `primary` | Verde TekoApp `#28A745` | Color dominante (~80%): botones primarios, nav activo, focus |
| `accent` | Teal TekoApp `#17BEBB` | Minoritario (~20%): un único punto de énfasis por pantalla |
| `neutral.900` (dark bg) | Navy TekoApp `#0D1B2A` | Fondo de modo oscuro, nunca negro puro |
| `neutral.50` (light bg) | Gris claro `#F5F7FA` | Fondo de modo claro |
| Tipografía | Poppins (Light/Regular/SemiBold/Bold) | Única familia, todo el texto |

Ver `TekoApp-Web/.claude/rules/design-system.md` para la regla completa de dominancia 80/20 y
`TekoApp-Web/.claude/rules/accessibility.md` para por qué los shades exactos de `primary`/`accent`
usados como fondo sólido con texto no son los valores "puros" de marca (contraste WCAG AA
verificado matemáticamente, no a ojo — el verde/teal puros de marca fallan contraste con texto
blanco encima, se usa un shade más oscuro específicamente para esos casos).

## Generación del output Dart (tarea de la Fase 1, no decidida en detalle todavía)

`tokens.json` ya se procesa con Style Dictionary (`TekoApp-Web/src/design-system/tokens/build.mjs`)
para generar `theme.generated.css`. La tarea pendiente es agregar un **formato de output nuevo al
mismo `build.mjs`** que genere un archivo Dart (ej. `lib/design_system/tokens.generated.dart` con
constantes `Color(0x...)` y quizás un `ThemeData` de Material/Cupertino armado desde esos tokens) —
no duplicar la definición de marca escribiendo los mismos hex a mano en este repo.

Investigar en la Fase 1: cómo Style Dictionary expresa un formato Dart custom (probablemente un
`formats.registerFormat` que itera los tokens resueltos y emite `const Color primary500 =
Color(0xFF...)`) — no asumir que existe un formato oficial "dart" listo para usar sin configurar.

## Componentes

`TekoApp-Web` usa shadcn/ui sobre Base UI con Storybook como catálogo. Flutter no tiene un
equivalente directo — el patrón a replicar conceptualmente es: **componentes reutilizables
propios** (no una librería de UI de terceros pesada) que resuelven los primitivos del design
system (botón, input, card, badge, avatar) usando los tokens, con nombres análogos a los de
`TekoApp-Web/src/components/ui/` para que el mapeo mental entre repos sea directo (`Button`,
`Badge`, `Avatar`, `Card`, etc.).

## Accesibilidad

Los criterios de `TekoApp-Web/.claude/rules/accessibility.md` (contraste WCAG AA, targets táctiles
≥44px, el estado nunca se comunica solo por color) aplican igual acá — mobile no es una excepción,
y los targets táctiles son si acaso MÁS relevantes en un dispositivo táctil real que en web.

## Modo oscuro

`TekoApp-Web` usa modo oscuro por default (fondo navy, nunca negro puro). Replicar el mismo
default y la misma regla de "nunca negro puro" en el tema oscuro de Flutter.

## Idioma de la tipografía

Poppins está disponible en Google Fonts — usar el paquete `google_fonts` de Flutter (o empaquetar
los archivos `.ttf` localmente si se prefiere no depender de descarga en runtime) con los mismos 4
pesos que usa la web (Light 300, Regular 400, SemiBold 600, Bold 700).
