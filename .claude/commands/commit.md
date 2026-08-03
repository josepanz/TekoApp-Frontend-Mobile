---
description: Genera un commit siguiendo Conventional Commits
---

Creá un commit siguiendo **Conventional Commits** — mismo formato que `TekoApp-Backend`/
`TekoApp-Web` (no hay `commitlint` configurado todavía en este repo porque no hay `pubspec.yaml`
ni pipeline propio; cuando se agregue en la Fase 0001, actualizar este comando para referenciarlo).

## Formato

```
tipo(alcance): descripción
```

**Tipos válidos:** `feat`, `fix`, `refactor`, `chore`, `style`, `docs`, `test`, `perf`, `ci`.

## Reglas de escritura

- Descripción en **español**, minúsculas, sin punto final, **sin nombres de archivos ni rutas**
- Describí el **qué y el por qué** del cambio, no el cómo ni los archivos tocados
- Una línea, máximo ~72 caracteres
- El alcance es el área de negocio/dominio afectado (`auth`, `services`, `payments`, `openspec`,
  `claude`…)

**Bien — describe intención:**

- `docs(openspec): documentar el desbloqueo de FCM ahora que el backend lo implementa`
- `feat(auth): implementar login con cifrado RSA-OAEP y nonce anti-replay`

**Mal — nombra archivos o es demasiado literal:**

- `chore(claude): crear code-reviewer.md, testing-agent.md y tdd-refactor.md`

## Pasos

1. Corré `git status --short` para ver qué hay staged/modificado/sin trackear.
2. Analizá todos los cambios y agrupalos en commits temáticos atómicos — un commit por área de
   negocio/dominio coherente. Nunca mezcles cambios no relacionados en un solo commit.
3. Para cada grupo, en orden:
   a. Stageá solo los archivos de ese grupo (`git add <archivos>`).
   b. Ejecutá `git commit -m "mensaje"` **directamente, sin pedir confirmación**.
4. Al terminar todos los commits, mostrá `git log --oneline -10`.
5. **No pushees** salvo pedido explícito.
6. Recordá el guardrail de rama (`.claude/rules/auth.md`): nunca commitear directo a
   `develop`/`qa`/`master` — confirmar que la rama actual no es una de esas tres antes de commitear.
