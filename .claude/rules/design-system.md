# Design system — reglas

## Fuente de verdad: `tokens.json`, no una reinterpretación

`TekoApp-Web/src/design-system/tokens/tokens.json` (formato W3C Design Tokens) es la ÚNICA fuente
de verdad de marca (color OKLCH, tipografía Poppins, radios). Está preparado explícitamente para
agregar un output Dart adicional al mismo `build.mjs` (Style Dictionary) — **nunca rediseñar la
paleta/tipografía a mano en Flutter**. Ver `openspec/specs/design-system.md` y
`openspec/decisions.md` (mecanismo de generación del archivo Dart: no decidido todavía, evaluar en
Fase 0002).

## Balance de marca 80/20 (mismo que `TekoApp-Web`, rebrand 2026-08-02)

- `primary` (verde TekoApp, `#28A745`) domina ~80% del color de marca visible: nav activo, botones
  primarios, focus rings, links.
- `accent` (teal TekoApp, `#17BEBB`) es minoritario, ~20%: un único punto de énfasis por pantalla
  (el CTA más importante, un badge de "nuevo").
- Nunca dos focos de `accent` compitiendo en la misma pantalla — si ya hay un elemento teal, el
  siguiente candidato pasa a `primary` o a un color neutro/semántico.
- Estados (éxito/alerta/error/info) usan sus propios slots semánticos, nunca `accent` — el teal
  significa "marca", no "atención". `success` ya es verde (mismo hue que `primary`) — no reusar
  `primary` para comunicar éxito, son conceptos distintos aunque el color se vea casi idéntico.

## Dark mode — obligatorio desde el primer widget

Todo widget nuevo se prueba visualmente en claro Y oscuro antes de darse por terminado — los
tokens ya proveen ambos temas (`theme.light`/`theme.dark` en `tokens.json`), no hay excusa para un
widget que solo "funciona" en un tema por coincidencia.

## Accesibilidad (mismo estándar que `TekoApp-Web/.claude/rules/accessibility.md`, adaptado)

- Contraste WCAG AA: texto normal ≥4.5:1, texto grande/UI ≥3:1 — los tokens ya están pensados para
  esto, no oscurecer/aclarar un color de marca sin volver a verificar el contraste resultante.
  Verificado 2026-08-02: el rebrand de `TekoApp-Web` ya corrigió 3 fallas reales de contraste
  encontradas matemáticamente (no a ojo) — reusar esos valores corregidos, no los "de manual"
  crudos, si en algún momento hay que elegir entre ambos.
- Targets táctiles ≥44×44px (más crítico en mobile que en web).
- Ningún estado se comunica solo por color — siempre texto o ícono acompañando.
- Controles solo-ícono llevan un label accesible (`Semantics`/`tooltip` en Flutter, equivalente al
  `aria-label` de `TekoApp-Web`).

## Componentes compartidos

Antes de escribir un widget nuevo en `shared/widgets/`, revisar qué variantes ya existen en
`TekoApp-Web/src/components/ui/` (Button, Card, Avatar, Badge, Input) como referencia de qué
estados/variantes hacen falta — no reinventar desde cero qué botones/estados existen.
