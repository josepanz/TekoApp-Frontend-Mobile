# Sesión 7 — 2026-08-27/29 — Cierre completo del roadmap (bitácora, documentos, presupuestos, contratos, ratings, propinas, actualización de versión)

## Qué se hizo

Cierre de todo el roadmap que quedó pendiente al final de la sesión 6, más un segundo roadmap
completo de 5 features grandes pedidas después, más la Fase 0015 (fuera de ambos roadmaps).
Detalle completo en `openspec/decisions.md` — acá solo el resumen ejecutivo.

- **Bitácora de trabajo**: `service_progress/`, timeline embebido en el detalle de servicio.
- **Documentos y antecedentes profesionales**: `professional_documents/`, sección embebida en el
  detalle de servicio y pantalla propia de "mis documentos".
- **Presupuestos multi-opción**: `budgets/`, armado (profesional) y comparación (cliente).
- **Contratos**: `contracts/`, firma secuencial + visualización de PDF (`url_launcher`).
- **KPIs de calificaciones**: pantallas propias `/mis-calificaciones` (cliente) y
  `/profesional/mis-calificaciones` (profesional).
- **Propinas**: `TipDialog` desde el detalle de pago, solo `PERCENTAGE`/`FREE` (sin `FIXED`).
- **id/referenceId estandarizado**: modelos `Service`/`ServiceRequest`/`Payment`/`PaymentMethod`/
  `Rating` migrados de `id: String` (UUID) a `id: int` + `referenceId` nuevo — 2 bugs de
  navegación reales encontrados (`payment_history_screen.dart`, `my_services_screen.dart`
  armaban la ruta con `.id` en vez de `.referenceId`).
- **Fase 0015 — Chequeo y actualización de versión**: `core/update/` completo (GitHub Releases,
  comparación semver, descarga + instalador nativo Android).

## Errores encontrados y su solución

- **2 migraciones en paralelo (agentes en background) se cortaron por límite de sesión** a mitad
  del barrido de id/referenceId — se completaron a mano verificando cada error real de
  `flutter analyze`/`flutter test` en vez de rehacer el barrido desde cero.
- **`FileProvider` duplicado innecesario** en la Fase 0015 — `open_filex` ya trae el suyo.
- **`permission_handler` bajado a `^12.0.0`** por incompatibilidad real de `compileSdk` detectada
  recién al compilar un APK real, no por `flutter analyze`.

## Estado al cierre

- Mobile: `flutter analyze` 0 issues, `flutter test` 388/388 (roadmap post-Fase 0004) → verificar
  contador final tras esta sesión completa (ver `decisions.md` de cada fase para el detalle
  incremental).
- Todos los puntos de ambos roadmaps y la Fase 0015 están **cerrados por completo**.
- `PENDING.md` nuevo en la raíz — consolida todos los pendientes reales en un solo lugar.
- PR #68 (`feature/consent-ai-disclosure-and-account-recovery-spec` → `develop`) actualizado con
  todos los commits de este roadmap — la nota "no mergear todavía" ya no aplica.

## Pendiente para la próxima sesión

Ver `PENDING.md` en la raíz del repo para el detalle completo y actualizado.
