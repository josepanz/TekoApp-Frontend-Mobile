# memory.md — tekoapp-frontend-mobile

> Sistema de memoria para sesiones de Claude en este proyecto.
> Al iniciar, leer: `documentation/context.md` + última sesión en `memory/sessions/`.

---

## Protocolo de inicio de sesión

Al comenzar cualquier sesión:

1. **Leer `documentation/context.md`** — estado actual del proyecto, próximo paso concreto
2. **Leer la sesión más reciente** en `memory/sessions/` (ordenar por nombre, tomar la última)
3. Si el trabajo toca código (no solo docs), leer también `openspec/project.md` +
   `openspec/decisions.md` + el archivo de fase correspondiente en `openspec/changes/`
4. Confirmar: _"Retomando desde [resumen de 1 línea de dónde quedamos]"_
5. Si no existen esos archivos, crearlos con estructura vacía

---

## Protocolo de cierre de sesión

Cuando el usuario diga **"guarda sesión"** o **"compact"**, o al cerrar el chat sin decirlo
explícitamente (ser proactivo):

Crear `memory/sessions/session_N_usuario_accion.md` donde:

- `N` = número de sesión (incrementar del último existente)
- `usuario` = quién trabajó la sesión (varios developers pueden usar este repo)
- `accion` = slug 2-3 palabras de lo hecho (ej: `bootstrap_flutter`, `auth_login`, `fix_refresh`)

Aprender proactivamente de errores y soluciones de cada sesión — si algo costó tiempo de debugging,
documentarlo acá Y considerar si amerita ajustar una regla en `.claude/rules/`.

Archivar sesiones antiguas (> 5 sesiones atrás) en `memory/sessions/archive/` (crear la carpeta si
no existe) — mismo criterio que los otros 2 repos.

```markdown
# Sesión N — [Fecha] — [Descripción breve]

## Qué se hizo

- [Lista de cambios/decisiones]

## Errores encontrados y su solución

- [Si aplica — costó tiempo real, documentarlo para no repetirlo]

## Estado al cierre

- [Tests/lint/build: verde o qué quedó pendiente]
- [Fase de openspec en la que se quedó, próximo paso concreto]

## Pendiente para la próxima sesión

- [Lista concreta, no genérica]
```
