# Regla de fechas / zona horaria

Mismo bug ya encontrado y corregido en `TekoApp-Backend` (ver su `.claude/rules/datetime.md`) —
aplica igual acá porque es una propiedad del dominio (Paraguay), no del stack.

## Prohibido

| Prohibido | Motivo |
|-----------|--------|
| Usar el identificador de zona `America/Asuncion` (o su equivalente en el paquete de fecha/hora de Dart que se termine usando) para cualquier cálculo o formato de "hora de pared de Paraguay" | Paraguay abolió el horario de verano (Ley 7127) pero esa zona IANA sigue cargando reglas de DST según el tzdata del dispositivo — puede desfasar ±1h según el equipo del usuario, sin que el código cambie |
| Confiar en la hora/zona local del dispositivo para cualquier cálculo que deba coincidir con el backend | El backend calcula todo en UTC y expone timestamps ISO — convertir a hora de Paraguay con un offset fijo (`UTC-3`, equivalente a `Etc/GMT+3` en el backend), no con la zona del dispositivo |

## Qué hacer en su lugar

- Recibir siempre timestamps del backend como ISO UTC y parsearlos como tal (nunca asumir que un
  string sin `Z` es hora local del dispositivo).
- Para mostrar "hora de Paraguay" al usuario, aplicar un offset fijo de `UTC-3` explícito, no
  depender de la zona horaria configurada en el teléfono.
- Si mobile necesita generar un timestamp propio (ej. un evento de tracking local antes de
  enviarlo), generarlo en UTC y dejar que el backend/la UI apliquen el offset de despliegue, igual
  que ya se resuelve en `TekoApp-Backend`/`TekoApp-Web`.
