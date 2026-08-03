# Arquitectura y decisiones — TekoApp Mobile

Este documento es la referencia de arquitectura del proyecto, pensada para leerse **con o sin un
asistente de IA de por medio**. Vive en la raíz porque describe el proyecto en sí, no un flujo de
trabajo específico de IA — cualquier persona que clone este repo debería poder entender el dominio,
el contrato con el backend y las decisiones ya tomadas leyendo solo esto y el código.

> Si además usás un asistente de IA para desarrollar, [`openspec/`](openspec/) tiene el mismo
> contenido organizado como specs ejecutables (formato SDD) más el plan de implementación por
> fases — es un complemento para ese flujo de trabajo, no la fuente de verdad. Este archivo y
> `openspec/` deben decir lo mismo; si divergen, es un bug de documentación.

## El dominio

TekoApp conecta **usuarios** (piden servicios) con **profesionales** (los ofrecen) — un
marketplace de servicios de oficio (electricistas, plomeros, pintores, carpinteros, etc.),
geolocalizado, inspirado en la eficiencia logística de Uber/Bolt pero aplicado a servicios
profesionales en vez de viajes.

Una misma cuenta puede operar en ambos roles. `TekoApp-Web` (el portal de administración) ya
resuelve esto con un selector de modo (cliente/profesional/admin) sobre la misma sesión — esta app
debe replicar esa misma decisión, no separar en dos apps por rol.

Dominios de negocio ya implementados en el backend (CRUD + reglas de negocio reales): usuarios/
profesionales, categorías de servicio, solicitudes de servicio, calificaciones bidireccionales,
pagos (métodos de pago, transacciones, reembolsos), promociones, roles/permisos, ubicación en
tiempo real (Socket.io + Mongo/2dsphere), notificaciones (in-app + push vía FCM, ver más abajo).

## Ecosistema de repositorios

| Componente | Stack | Rol para esta app |
|---|---|---|
| **TekoApp-Backend** | NestJS 10, Prisma, MongoDB, Redis | La única API que esta app consume — nunca se reimplementa lógica de negocio acá |
| **TekoApp-Web** | Next.js 16, shadcn/ui, TanStack Query | Portal de administración; referencia de patrones (contrato de API, auth, tokens de diseño) ya probados en producción — no se consume directamente |
| **TekoApp-Mobile** *(este repo)* | Flutter 3, Riverpod, go_router, dio | — |

## Stack decidido

| Capa | Elección | Motivo corto |
|---|---|---|
| Framework | Flutter 3 | Un codebase para iOS + Android; modelo mental de widget tree declarativo, transferible desde React |
| Estado | Riverpod | Testeable sin depender del árbol de widgets; equivalente conceptual a TanStack Query (`FutureProvider`/`AsyncNotifier` ≈ `useQuery`/`useMutation`) |
| Ruteo | go_router | Ruteo declarativo oficial, soporta deep linking y guards de ruta (equivalente a `proxy.ts` de TekoApp-Web) |
| Cliente HTTP | dio | Interceptors (Bearer + refresh en 401), multipart nativo para subida de archivos |
| Notificaciones push | Firebase Cloud Messaging (`firebase_messaging`) | Backend ya implementado (`firebase-admin`); falta el proyecto Firebase real de esta app |
| Testing | `flutter_test` + `mocktail` | Sin code generation (a diferencia de `mockito`) |
| Diseño | Tokens compartidos desde `tokens.json` de TekoApp-Web | Una sola fuente de verdad de marca, sin reinterpretación manual |
| CI/CD | GitHub Actions, 3 ambientes (`develop`/`qa`/`master`) | Mismo proveedor y mapeo de ambientes que backend/web |

**Sin decidir todavía** (no asumir sin confirmar antes de implementar):

- Almacenamiento seguro de tokens — candidato `flutter_secure_storage`, sin confirmar.
- Cifrado RSA-OAEP en Dart — candidato `pointycastle`; verificar el padding contra el backend real
  antes de darlo por resuelto.
- Offline-first vs. online-only — decisión de producto, no técnica, pendiente de confirmar con el
  negocio.

## Estructura de carpetas

```
lib/
├── main.dart
├── core/
│   ├── api_client/       # dio + interceptors (Bearer, refresh, unwrap del envelope de respuesta)
│   ├── auth/              # sesión, guards de go_router, almacenamiento seguro de tokens
│   ├── config/            # env vars, endpoints
│   └── theme/             # ThemeData claro/oscuro generado desde tokens.json
├── features/
│   └── <dominio>/
│       ├── data/          # llamadas a la API (≈ api.ts de TekoApp-Web)
│       ├── providers/     # Riverpod providers (≈ hooks.ts)
│       ├── models/        # clases de datos
│       └── widgets/       # pantallas + componentes del dominio
├── shared/
│   └── widgets/           # Button/Card/Avatar/Badge/Input compartidos
└── l10n/                  # catálogo es/en
```

Un provider por operación de servidor (query o mutación) — nunca un provider que mezcle varias
operaciones. Las pantallas consumen providers vía `ref.watch`/`ref.read`, nunca fetching directo en
un widget (`initState` + llamada manual).

## El contrato con el backend

### Identificadores públicos: `referenceId`, nunca `id`

Todo modelo de negocio tiene un `id` entero interno (nunca sale de la API pensada para navegación)
y un `referenceId` UUID público (el que viaja en las rutas y se usa para cualquier navegación/deep
link). Excepción histórica: `Services`, `ServiceRequests`, `PaymentMethodEntity`, `Payments`,
`PaymentTransaction` y `Rating` usan UUID como PK primaria directamente — no afecta a mobile salvo
que se toque el modelo de datos del backend.

### Auth — nunca simplificar este contrato

1. `POST /auth/nonce` — pide un nonce anti-replay de un solo uso.
2. Cifrar `{ password, nonce }` con **RSA-OAEP** usando la clave pública del backend
   (`BACKEND_JWT_PUBLIC_KEY`).
3. `POST /auth/login` con Basic Auth de **cliente** (`clientId:clientSecret` de la app, no del
   usuario) + `{ email, encryptedPassword }`.
4. Resultado: `accessToken` (~15 min) + `refreshToken` (~12h). Mobile no tiene servidor intermedio
   (a diferencia de TekoApp-Web, que los guarda en cookies httpOnly) — dónde guardarlos de forma
   segura en el dispositivo está pendiente de decidir (ver "Sin decidir todavía").
5. Refresh: `POST /auth/refresh-token` — interceptor de `dio` que reintenta un 401 una vez.
6. El JWT es deliberadamente delgado (`sub`/email/status/nombre, sin `permissions`/`roles`/`id`).
   Para permisos, roles o datos frescos del usuario: siempre `GET /auth/scope`, nunca decodificar
   el JWT.
7. Autoedición de perfil: `PUT /auth/me` (no requiere permisos especiales, solo sesión activa) —
   separado a propósito de la edición admin (`PUT /users/:id`, requiere permiso).

El nonce evita que un request de login capturado (ej. por un proxy MITM comprometido) se pueda
reenviar tal cual — es una decisión ya tomada y probada en producción del lado del backend, no un
"login normal" a simplificar.

### Avatares — nunca cachear la URL

`avatarUrl` es una URL presignada de S3 que **expira en 900 segundos**. Se persiste el `avatarKey`
(permanente, vía `PUT /auth/me`) y se resuelve una URL fresca en cada `GET /auth/scope` o el
endpoint de detalle correspondiente — nunca cachear `avatarUrl` más allá de la sesión/pantalla
actual (bug real ya encontrado y corregido en TekoApp-Web).

### Otras reglas del contrato

- **Envelope de respuesta**: toda respuesta exitosa viene envuelta en
  `{ success, data, message, timestamp, path }` — el cliente HTTP centraliza el unwrap en un
  interceptor de `dio`, nunca asumir que el body es el DTO "pelado".
- **Listados vacíos son `200` con `data: []`**, nunca un error — no tratarlos como tal en la UI.
- **Transiciones de estado esperan 409**: el backend usa `updateMany` + chequeo de `count` (no
  `findUnique` + `update`) para evitar condiciones de carrera en acciones que cambian estado
  (aceptar/cancelar un servicio, reembolsar un pago). La UI debe manejar el 409 con un mensaje claro
  ("esto cambió, actualizá la pantalla"), nunca como error genérico.
- **Zona horaria**: nunca usar el identificador `America/Asuncion` — Paraguay abolió el horario de
  verano (Ley 7127) pero esa zona IANA sigue aplicando reglas de DST según el dispositivo, causando
  desfasajes de ±1h. Usar un offset fijo `UTC-3` para "hora de pared de Paraguay".

### Qué NO replicar de TekoApp-Web

TekoApp-Web resuelve varias cosas con un servidor Next.js intermedio (BFF) que mobile no tiene:
cifrado RSA del lado servidor, Basic Auth sin exponerlo al cliente, cookies httpOnly. Mobile
necesita el equivalente nativo (el secreto de cliente vive en el binario/config de la app —
extraíble con suficiente esfuerzo de reversing, es una limitación conocida, no un descuido).

## Notificaciones push (Firebase Cloud Messaging)

El backend ya conectó `firebase-admin` de verdad y expone:

- `POST /notifications/fcm-tokens` — registrar/actualizar el token FCM del dispositivo.
- `DELETE /notifications/fcm-tokens/:referenceId` — dar de baja un token.
- Envío real vía `admin.messaging().send()` cuando una notificación declara el canal `fcm`, con
  desactivación automática del token si Firebase reporta
  `messaging/registration-token-not-registered`.

Lo único que falta es un **proyecto Firebase real** para esta app (sin `google-services.json`/
`GoogleService-Info.plist` todavía) y el código Flutter que consuma esos endpoints — no es un
bloqueo de arquitectura backend, es trabajo de una fase futura de este repo.

## Diseño — una sola fuente de verdad

`tokens.json` (formato W3C Design Tokens, definido en TekoApp-Web) es la única fuente de verdad de
marca. Está pensado para generar un output Dart adicional desde el mismo generador (Style
Dictionary) cuando se implemente el theming real — nunca reinterpretar la paleta/tipografía a mano
en Flutter.

## CI/CD

`.github/workflows/ci.yml` corre `flutter analyze` + `flutter test` en cada push/PR a
`develop`/`qa`/`master`. `.github/workflows/build.yml` (disparo manual, input `environment`) valida
que compile un APK Android debug y un build de iOS para simulador, pasando el `API_BASE_URL` del
ambiente elegido.

**No publica a ninguna store todavía** — falta, en los 4 puntos siguientes, infraestructura externa
(no decisiones técnicas pendientes):

1. Cuenta de Google Play Console + keystore de firma.
2. Cuenta de Apple Developer Program + certificado de distribución.
3. Proyecto Firebase real (uno por ambiente o con flavors).
4. Backend real desplegado en `qa`/`prod` (hoy solo corre local).

## Errores ya encontrados que esta app debería evitar de entrada

Bugs reales, no hipotéticos, ya encontrados y corregidos construyendo backend/web:

1. **Zona horaria** `America/Asuncion` con DST fantasma — ver arriba.
2. **Condiciones de carrera en cambios de estado** — siempre esperar un 409 posible.
3. **Listados vacíos no son error** — `200` con `[]`.
4. **Avatar URL presignada, no persistir** — ver arriba.
5. **`services.professional.user` puede venir `undefined`** si el backend no anida el `include`
   correctamente (bug real encontrado y corregido en el backend el 2026-08-03) — siempre manejar
   con optional chaining del lado del cliente además de confiar en el contrato documentado.

## Qué no está decidido todavía (pendiente explícito, no un olvido)

- Almacenamiento seguro de tokens y el flujo de login real (nonce + RSA-OAEP).
- Offline-first vs. online-only.
- Firma de release y publicación en Google Play / App Store — bloqueado por cuentas/infra, no por
  decisión técnica.

---

Para el detalle spec por spec de cada capacidad (auth, marketplace, pagos, notificaciones, etc.)
tal como debe comportarse, y el plan de implementación en fases con checkpoints concretos, ver
[`openspec/`](openspec/).
