# Spec: Borrado de cuenta (Mobile)

Plan de fase: `openspec/changes/platform-hardening-2026-09/WORKPLAN.md`, tarea I-01. Solo spec —
sin implementación (bloqueada por el endpoint del backend, ver abajo).

Marco legal: Apple lo exige in-app desde 2022 (Guideline 5.1.1(v)), Google Play pide equivalente,
y la Ley paraguaya 6534/2020 de Protección de Datos Personales concede derecho de supresión.

## Estado real verificado (2026-09-06) — no asumido

`profile_screen.dart` hoy solo expone logout — no hay ningún flujo de borrado, ni parcial. Del lado
`TekoApp-Backend`, su propia tarea I-01 (`openspec/changes/platform-hardening-2026-09/I-01-account-deletion.md`,
commit `f38ca86`) **ya está especificada, pero no implementada** — verificado: no existe
`PENDING_DELETION` en `UserStatus` del schema de Prisma, ni las rutas
`/users/me/deletion-request*`, en ningún lugar del código del backend todavía. Es una spec
completa (contrato de endpoints, qué se anonimiza vs. qué se retiene, ventana de gracia,
bloqueantes), lista para implementar, pero sin código real detrás.

**Esta spec de Mobile depende 100% de que ese trabajo de backend se implemente primero** — el
contrato de abajo ya está definido de ese lado, así que esta spec puede diseñar la pantalla y el
flujo con precisión (no en abstracto, como suele pasar cuando se specea contra un backend
inexistente) sin tener que inventar la forma del contrato.

## Contrato que esta spec consume (definido en `TekoApp-Backend`, no en esta spec)

| Método | Ruta | Uso desde Mobile |
|---|---|---|
| `POST` | `/users/me/deletion-request` | Confirmar la solicitud de borrado (paso 2 del flujo, ver abajo) |
| `POST` | `/users/me/deletion-request/cancel` | Cancelar una solicitud en ventana de gracia |
| `GET` | `/users/me` | Ya se consume hoy (`fetchScope`/perfil) — extendida con `deletionScheduledAt: string \| null`, determina si mostrar el banner |

Errores a manejar (ver spec de backend, sección "Casos de error"):

- `409 DELETION_BLOCKED` — body con el detalle de qué bloqueantes aplican (servicio activo, pago
  pendiente, contrato sin firmar, disputa abierta) y cuántos casos de cada uno.
- `409 DELETION_ALREADY_REQUESTED` — ya hay una solicitud en curso (no debería ocurrir si la UI
  oculta el botón correctamente cuando ya hay `deletionScheduledAt`, pero manejarlo igual —
  mensaje, no crash).
- `400 DELETION_NOT_REQUESTED` — cancelar sin solicitud activa (mismo criterio: no debería
  ocurrir si la UI es consistente, pero manejarlo).

## Flujo de confirmación (2 pasos, ninguno "accidentable")

Mismo criterio que la spec de backend exige para la cancelación (\"un paso explícito para pedir el
borrado, y un paso explícito también para cancelarlo\"):

1. **Paso 1 — pantalla informativa** (`AccountDeletionScreen`, nueva, accesible desde
   `profile_screen.dart` con un botón separado del de logout, visualmente distinto — nunca el
   mismo estilo/proximidad que "Cerrar sesión", para que no se toquen por error). Explica en
   lenguaje simple (copy legal real: **pendiente de que José lo redacte con asesoría** — no
   inventar el texto legal en esta spec, ver Riesgos de la spec de backend):
   - Qué se anonimiza (nombre, email, teléfono, documento, foto) vs. qué se conserva por ley
     (pagos, contratos, calificaciones — con el nombre ya anonimizado).
   - La ventana de gracia (14 días propuestos por backend) y que es cancelable durante esa
     ventana.
   - Que pasado ese punto, no hay vuelta atrás (ver "Riesgos" de la spec de backend).
2. **Paso 2 — confirmación explícita**: un diálogo/pantalla separada que pide reescribir una
   palabra de confirmación (mismo patrón que apps que piden tipear "ELIMINAR" o similar) o, como
   mínimo, un checkbox "Entiendo que esta acción no se puede deshacer" + botón de confirmar
   deshabilitado hasta marcarlo. Al confirmar: `POST /users/me/deletion-request`.
3. **Si `409 DELETION_BLOCKED`**: no mostrar un error genérico — mapear cada bloqueante del body a
   una fila accionable ("Tenés 1 servicio en curso" → botón "Ver servicio" que navega a
   `/mis-servicios/:id`; "Tenés 1 pago pendiente" → navega a `/pagos/historial`, etc.). El usuario
   sale de esta pantalla sabiendo EXACTAMENTE qué resolver, no con un mensaje que lo deja
   trabado.
4. **Éxito**: navegar a un estado post-confirmación (banner + posiblemente logout automático —
   **a decidir con José**: ¿tiene sentido que el usuario siga logueado durante la ventana de
   gracia usando la app normalmente, o se lo desloguea y solo puede volver a entrar para
   cancelar? La spec de backend permite ambas — "el usuario sigue pudiendo loguearse
   normalmente" no obliga a que la sesión ACTUAL continúe sin interrupción).

## Banner de ventana de gracia

- Mientras `deletionScheduledAt != null` (leído de `GET /users/me`, mismo provider que ya trae el
  perfil hoy — no una llamada nueva): banner persistente (no descartable con una X, solo con la
  acción de cancelar) en la pantalla principal, con la fecha de eliminación efectiva y un botón
  "Cancelar eliminación" → `POST /users/me/deletion-request/cancel`.
- Al cancelar exitosamente: refrescar el perfil (el banner desaparece porque
  `deletionScheduledAt` vuelve a `null`), sin necesitar un mensaje de éxito grande — el banner
  desapareciendo ya es la confirmación visual.

## Fuera de alcance de esta spec

Implementación (bloqueada, ver arriba), el copy legal real (lo define José con asesoría),
exportación de datos antes de borrar (fuera de alcance también en la spec de backend), cualquier
decisión sobre si `Professionals.description` se anonimiza (abierta del lado backend, no afecta
el diseño de esta pantalla).

## Riesgos / límites explícitos

- **Esta spec no puede probarse contra nada real todavía** — cuando el backend implemente el
  contrato, revisar esta spec contra el comportamiento REAL antes de construir la UI (los nombres
  exactos de los campos del body de `409 DELETION_BLOCKED`, por ejemplo, están descriptos como
  intención en la spec de backend, no verificados contra una respuesta real todavía).
- **Logout automático vs. sesión continua durante la ventana de gracia**: decisión de producto
  abierta (ver paso 4), no resuelta acá a propósito — confirmar con José antes de implementar.
- **Mismo límite de "sin vuelta atrás" que ya declara la spec de backend** — el copy del paso 1
  tiene que ser honesto sobre esto, no suavizarlo para reducir fricción a costa de que el usuario
  no entienda lo que está pidiendo.
