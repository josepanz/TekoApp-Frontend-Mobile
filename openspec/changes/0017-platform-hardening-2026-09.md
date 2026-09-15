# Fase 0017 — Endurecimiento de plataforma (Mobile)

Auditoría completa y transversal: `TekoApp-Backend/openspec/specs/platform-audit-2026-09.md`.
Contrapartes: `TekoApp-Backend/openspec/changes/0013-platform-hardening-2026-09.md`,
`TekoApp-Frontend-Web/openspec/changes/0007-platform-hardening-2026-09.md`.

## Contexto

Auditoría pedida por José 2026-09-04 sobre los 3 repos. Todos los hallazgos fueron verificados
abriendo el archivo citado.

Dato de contexto que enmarca todo lo de abajo: siguen abiertos **cuatro checkpoints de dispositivo
real** en `openspec/decisions.md` (FCM en dos dispositivos `:761`, instalación de release firmado
`:910-911`, integración de los 3 repos `:1020-1021`, firma de contrato punta a punta `:1083-1084`).
Es decir, buena parte de la app solo corrió contra `flutter test` y mocks — nunca contra un backend
vivo en un teléfono real. Los bugs de la Fase B son exactamente del tipo que ese hueco deja pasar.

## Fase B — Crashes y bloqueos de tienda (CRÍTICO)

- [ ] B1 — `lib/features/ratings/models/rating.dart:39-40`: `json['userId'] as int` y
      `json['professionalId'] as int` son casts no-nullable contra un contrato que el backend
      documenta como `number | null` (`rating-detail.response.dto.ts:24-26,34-36`, `nullable: true`,
      "null cuando `isAnonymous=true` y quien consulta no es el autor"). La primera reseña anónima
      en una lista pública lanza `type 'Null' is not a subtype of type 'int'` y tumba la pantalla.
      Fix: `int?` en ambos campos + test con payload anónimo.
- [ ] B2 — `ios/Runner/Info.plist` declara **solo** `NSLocationWhenInUseUsageDescription` (`:29-30`),
      pero `ImageSource.camera` se usa en `upload_document_sheet.dart:155` y
      `upload_portfolio_item_sheet.dart:119`. En iOS eso **no es un rechazo de review: es un crash
      inmediato** al tocar "Tomar foto", y además bloquea la submission. Agregar
      `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` con textos explicativos reales
      (el de ubicación ya está bien redactado, usarlo de modelo).
- [ ] B3 — `Image.network` sin `errorBuilder` en `public_portfolio_section.dart:72-77` y
      `my_portfolio_screen.dart:100-105`, sobre URLs presignadas que expiran a los 900s. Los widgets
      hermanos (`teko_avatar.dart:49-53`, `progress_timeline.dart:205-209`) ya tienen el patrón
      correcto. Oportunidad: extraer un `ResolvedNetworkImage` compartido y cerrar el hueco en un
      solo lugar en vez de dos (el patrón "resolver URL presignada → `Image.network` → fallback"
      está duplicado casi textual en 4 archivos).
- [ ] B4 — `shared/widgets/async_state_view.dart:35,43` hardcodea `'Ocurrió un error inesperado.'`
      y `'No hay datos para mostrar.'`, usado en 21 pantallas, **sin `l10n` y sin acción de
      reintentar**. Viola la regla propia del repo ("cero strings hardcodeados en widgets",
      `rules/i18n.md`) y es la mayor fuente de copy sin traducir de la app. Dos pantallas
      (`privacy_and_data_screen.dart:27-30`, `legal_consent_screen.dart:50`) ni siquiera pasan un
      `errorMessage`, así que muestran ese texto en español aunque el dispositivo esté en inglés.
      Fix: rutear ambos defaults por `l10n` + agregar `onRetry` opcional.
- [ ] **Checkpoint B**: `flutter analyze` 0 issues + `dart format --set-exit-if-changed` limpio +
      `flutter test` completo en verde. (Recordatorio: el CI corre `dart format` como gate — correrlo
      localmente antes de pushear, se nos escapó una vez en la fase 0016.)

## Fase M — Robustez de red y contrato

- [ ] M1 — Coordinar refreshes concurrentes en `refresh_token_interceptor.dart:13-14` (limitación ya
      documentada ahí mismo). Dos 401 simultáneos disparan dos `POST /auth/refresh-token`; si el
      backend rota el refresh al usarlo, el segundo falla y desloguea al usuario a mitad de sesión.
      Fix: un `Completer<String>` compartido para que solo haya un refresh en vuelo.
- [ ] M2 — Retry/backoff para fallos transitorios: hoy `api_client.dart:47-61` solo tiene un timeout
      plano de 90s (tuneado para cold starts de Render). Un paquete perdido falla el request entero,
      y el usuario mira un spinner sin explicación hasta minuto y medio. Evaluar `dio_smart_retry`
      con backoff exponencial acotado a métodos idempotentes.
- [ ] M3 — `locations_socket_service.dart:38-56`: `connect()` no registra `onConnectError`/
      `onDisconnect` ni reconexión con token fresco. Con `JWT_ACCESS_EXPIRATION=15m`, una sesión
      larga pierde el socket en silencio, sin feedback ni reintento.
- [ ] M4 — **Estructural**: adoptar codegen OpenAPI→Dart. Web genera sus tipos del swagger real y se
      auto-corrige (`pnpm check:types` falla ante un drift); Mobile escribe cada modelo a mano, así
      que nada detecta una divergencia hasta que explota en runtime en un teléfono. B1 es la primera
      materialización de esto; sin codegen va a haber más. Ver §1.2 de la spec de auditoría.
- [ ] M5 — `Payment.fromJson` (`lib/features/payments/models/payment.dart:66-92`) descarta campos
      que el backend sí devuelve (`isRecurring`, `professionalNetAmount`, `paymentDetails`,
      `metadata`, `processedAt`/`paidAt`/`failedAt`, `failureReason`, `externalTransactionId`, ver
      `payment-detail.response.dto.ts:64-104`). No es un crash, pero bloquea construir una pantalla
      de recibo/disputa sin volver a tocar el modelo. (Ojo con `professionalNetAmount`: hoy el
      backend lo expone pero nunca lo escribe — ver Backend D3 antes de mostrarlo.)
- [ ] **Checkpoint M**: analyze + format + tests verdes.

## Fase I — Sostenibilidad

- [ ] I1 — **Borrado de cuenta** (bloqueante de tienda + legal): no existe ni en Mobile
      (`profile_screen.dart` solo expone logout) ni en el backend. Apple lo exige desde 2022
      (Guideline 5.1.1(v)), Google Play pide equivalente, y la Ley PY 6534/2020 concede derecho de
      supresión. Depende del endpoint que defina Backend I1.
- [ ] I2 — Ofuscación del binario: `env.dart:17-27` embebe el secreto Basic Auth de cliente vía
      `--dart-define`, extraíble con `strings` sobre el APK. `rules/auth.md:43-48` pidió decidir
      esto y quedó documentado como limitación conocida, pero no se agregó
      `--obfuscate --split-debug-info` a `build.yml`/`release.yml`. No elimina el riesgo (es
      inherente a no tener BFF), lo sube de trivial a molesto.
- [ ] I3 — Canal de soporte in-app: hoy un usuario con un pago fallido o un profesional que no
      apareció no tiene **ningún** camino dentro de la app para contactar a nadie.
- [ ] I4 — Pantalla de preferencias de notificación + bandeja in-app. `lib/features/notifications/`
      hoy es solo el gateway de token push.
- [ ] I5 — Login biométrico (`local_auth`): el login nonce+RSA-OAEP es más fricción que el promedio
      móvil; una vez estable el flujo, esto mejora retención. Baja prioridad.

## Detalles menores registrados

- `lib/design_system/tokens.generated.dart:45`: `accent500 = Color(0xFF19BEBB)` con comentario
  admitiendo "~#17BEBB" — la conversión OKLCH→sRGB derivó 2 unidades hex respecto del ancla de
  marca, mientras `primary500` sí clava `#28A745`. Imperceptible, pero inconsistente con el
  estándar de "ancla exacta" del design system.
- Paridad `es.arb`/`en.arb`: **limpia**, 383/383 claves. La deuda real de i18n es B4, no el catálogo.
- `response.data!` sin guard en ~15 métodos de repositorio: individualmente de bajo riesgo (el
  `EnvelopeInterceptor` garantiza `data` en un 2xx), pero sin aserción compartida una regresión del
  backend que devuelva `200` con `data: null` tumbaría todas las pantallas a la vez.

## Checkpoint de salida (Mobile)

- [ ] Una lista de reseñas con al menos una calificación anónima se renderiza sin crashear.
- [ ] Tocar "Tomar foto" en iOS abre la cámara en vez de matar la app.
- [ ] Un error de red muestra copy traducido y un botón de reintentar, no un texto fijo en español.
- [ ] Dos requests que expiran a la vez producen **un** refresh, no dos, y no desloguean al usuario.
