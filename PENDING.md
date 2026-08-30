# Pendientes y decisiones abiertas — TekoApp-Frontend-Mobile

Consolidado 2026-08-29. Objetivo: un solo lugar para ver qué queda sin resolver, sin recorrer
`openspec/decisions.md` fase por fase. Actualizar esta lista al cerrar o abrir un pendiente nuevo.

## 1. Deuda técnica / limitaciones conocidas, no resueltas a propósito

- **Secret de Basic Auth de cliente embebido en el binario de la app** — a diferencia de
  `TekoApp-Frontend-Web` (secreto server-side, nunca llega al browser), Mobile no tiene servidor
  intermedio: el secreto vive en el binario/config de la app. Documentado como limitación conocida
  — falta decidir mitigación (ofuscación, verificación de integridad de la app), no implementado.
- **`TipMode.FIXED` sin UI**: el dominio soporta 3 modos de propina (`PERCENTAGE`/`FIXED`/`FREE`),
  la app solo ofrece `PERCENTAGE` (chips) y `FREE` (monto libre) — falta una config de montos
  preestablecidos (`TaxConfig`/`TipConfig` no tiene un campo para eso) antes de construir esa UI.
- **`integration_test/`** (paquete declarado en `pubspec.yaml`) sigue vacío — correr esa suite
  necesita un emulador Android o simulador iOS real, no es tarea de código.
- **Selector de pin en mapa** para ubicación en tiempo real quedó fuera del alcance de la fase que
  lo tocó — pendiente si se pide explícitamente.

## 2. Checkpoints de negocio con dispositivo/datos reales (responsabilidad de José)

- Instalación real de un APK firmado desde un GitHub Release (Fase 0015, chequeo de actualización)
  — solo verificado con `flutter analyze`/tests, nunca en un dispositivo/emulador real.
- Tracking en tiempo real: prueba con dos dispositivos reales (uno emitiendo ubicación, otro
  recibiéndola) — sigue pendiente.
- Subir un documento profesional real y verlo reflejado tras la aprobación en Web.
- Aceptar un consentimiento legal real y verificar el flujo de bloqueo/desbloqueo end-to-end.
- Armar/comparar/aceptar un presupuesto multi-opción real.
- Firmar un contrato real de punta a punta (cliente y profesional).
- Dejar una propina real sobre un pago real.
- Push notifications (FCM) — checklist de código completo, falta el checkpoint real con push
  llegando a un dispositivo.

## 3. Copy legal pendiente de asesoría real

- `es.arb`/`en.arb`: metadata marcada `TODO(legal)` en las claves de contrato — texto genérico
  placeholder, reemplazar antes de producción (mismo texto que usa el PDF generado por Backend).

## 4. Infraestructura / CI-CD

- Los 3 ambientes (`dev`/`qa`/`prod`) apuntan hoy al mismo backend/Supabase — cuando cada uno
  tenga su propia instancia, actualizar `API_BASE_URL` en `build.yml`/`release.yml` (ver
  `openspec/decisions.md`, sección CI/CD).
- Publicación a las stores (Google Play/App Store) sin secrets de firma reales cargados todavía —
  el pipeline detecta su ausencia en runtime (`check-secrets`) y publica solo instaladores sin
  firmar como asset de GitHub Release; activar cuando existan los secrets reales.
- `has_play_publish` pendiente de secrets — revisar si desactivarlo en `prod` una vez resuelto.

## 5. Reportado por José 2026-08-30 — solo anotado, sin investigar/desarrollar todavía

- **La app sigue sin conectarse al backend**, pese al fix de CI de esta sesión (PR #72,
  `BASIC_AUTH_CLIENT_ID`/`SECRET` cableados en `build.yml`/`release.yml`). **Verificado 2026-08-30
  post-merge**: el fix SÍ generó un release nuevo real —
  [`v1.0.0-develop.4`](https://github.com/josepanz/TekoApp-Frontend-Mobile/releases/tag/v1.0.0-develop.4)
  (publicado 2026-08-30T01:16Z), con `tekoapp-mobile-v1.0.0-develop.4.apk`/`.aab` adjuntos y el job
  "Release" del workflow en verde (`gh run list`, run exitoso de 7m7s). **Hipótesis más probable**:
  José probó un APK viejo (anterior al merge, ej. `v1.0.0-develop.3` o antes), que todavía no tenía
  las credenciales — no un fallo nuevo del fix. Próxima sesión: (1) confirmar que se instala
  específicamente `tekoapp-mobile-v1.0.0-develop.4.apk` (o uno posterior) antes de re-investigar,
  (2) si ESE build puntual también falla, ahí sí revisar si `BASIC_AUTH_CLIENT_ID`/`SECRET` llegaron
  con el valor correcto (typo en el nombre del secret de GitHub fallaría en silencio, sin verlo en
  logs) y que la credencial `tekoapp-mobile` siga activa en la base de Supabase compartida.

## 6. PR abierto, en pausa deliberada

**PR #68** (`feature/consent-ai-disclosure-and-account-recovery-spec` → `develop`) — quedó abierto
a propósito desde 2026-08-26 hasta cerrar el resto del roadmap en curso. **Ese roadmap ya cerró por
completo el 2026-08-28/29** — este PR es candidato a mergear ahora, confirmarlo explícitamente
antes de hacerlo.
