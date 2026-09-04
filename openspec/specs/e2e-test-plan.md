# Spec: Plan de pruebas E2E de plataforma, por dependencia (menor a mayor)

Backend: `TekoApp-Backend/openspec/specs/e2e-test-plan.md`.
Web: `TekoApp-Frontend-Web/openspec/specs/e2e-test-plan.md`.

Pedido de José 2026-09-01: pruebas e2e sobre TODAS las funcionalidades de la plataforma, ordenadas
de menor a mayor dependencia. Este repo no tiene `integration_test/` real corriendo todavía (ver
`.claude/rules/test.md`, "E2E: decidido — flujo completo como test de widgets, no `integration_test/`
todavía") — el patrón vigente es un test de widgets normal en `test/e2e/` que arranca la app
completa sin fijar `sessionProvider` a mano, mockeando solo el límite de red (`Dio`) y el
`MethodChannel` de `flutter_secure_storage`. Este documento define el orden y alcance por tier
para seguir ese mismo patrón — no es una implementación.

## Cómo usar este documento

- Ya existe `test/e2e/login_profile_logout_test.dart` (login → home → Mi perfil → logout) — Tier 1
  ya tiene un punto de partida real, no arrancar de cero.
- Cada tier depende de que el anterior tenga cobertura razonable.
- No se busca 100% de cobertura de pantallas — un flujo representativo por dominio, mismo criterio
  que Backend/Web.
- Si en algún momento hay un emulador/dispositivo real disponible, migrar los tests de
  `test/e2e/` a `integration_test/` (paquete ya declarado en `pubspec.yaml`, vacío hoy) para
  cobertura real de gestos/cámara/GPS — no es requisito para cerrar ningún tier de este plan.

## Tier 1 — Fundación (auth)

- [ ] Login → home → Mi perfil → logout (ya existe, `test/e2e/login_profile_logout_test.dart` —
      confirmar que sigue verde).
- [ ] Registro (`/registro`, Fase 0014) de punta a punta — confirmar si ya está cubierto; si no,
      agregarlo como test de widgets nuevo en `test/e2e/`.
- [ ] Refresh de token en 401 → reintento automático → si también falla, logout limpio (sin loop).

**Checkpoint Tier 1**: un usuario nuevo se registra y opera una sesión completa sin intervención
manual, cubierto como test de widgets end-to-end.

## Tier 2 — Catálogos (depende de Tier 1)

- [ ] Selección de categoría/tipo de servicio al pedir un servicio — confirma que el catálogo
      llega bien desde el backend real de test.

## Tier 3 — Identidad extendida (depende de Tier 1)

- [ ] **Nuevo, tras `openspec/changes/0016-professional-onboarding-and-portfolio.md`**: desde el
      home, tocar el CTA de reclutamiento → completar `/profesional/onboarding` → el mode-switch
      pasa a ofrecer "modo profesional" real (antes redirigía a onboarding, ahora a
      `ProfessionalHomeScreen`).
- [ ] Subida de un documento de compliance (`UploadDocumentSheet`) → aparece en
      `my_documents_screen.dart` con estado `PENDING`.
- [ ] Portafolio (Fase 5, bloqueada por Backend): subir foto → aparece en la galería propia.

**Checkpoint Tier 3**: el flujo "postularse → onboarding → subir documentos" corre de punta a
punta en un test de widgets, sin necesidad de un profesional pre-sembrado.

## Tier 4 — Marketplace core (depende de Tier 3)

- [ ] Pedir un servicio → ver el estado cambiar (aceptado/en curso/completado) — flujo
      representativo, mismo criterio que Web.
- [ ] Presupuestos multi-opción — armar/comparar (flujo representativo).
- [ ] Contratos — ver estado y firma (flujo representativo).

## Tier 5 — Dinero y confianza (depende de Tier 4)

- [ ] Historial de pagos (`payment_history_screen.dart`) — listado, detalle, propina.
- [ ] Calificaciones — dejar una, ver `/mis-calificaciones`.

## Tier 6 — Cumplimiento y secundarios (paralelo a partir de Tier 1)

- [ ] Consentimiento de datos/imágenes — aceptar, bloqueo sin consentimiento activo.
- [ ] Chequeo de actualización de versión (Fase 0015) — mismo criterio ya documentado: probar
      contra un release real firmado es responsabilidad de José con un dispositivo/emulador, no
      un test de widgets.

## Fuera de alcance de este documento

- Gestos de cámara/GPS reales — necesitan `integration_test/` con un dispositivo/emulador, no test
  de widgets (ver nota arriba).
- Tests de carga/performance.
