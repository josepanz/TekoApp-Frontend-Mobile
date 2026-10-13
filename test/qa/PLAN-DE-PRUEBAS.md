# Plan de pruebas — TekoApp Mobile (Flutter)

## 1. Alcance

App móvil Flutter (cliente y profesional). Trazabilidad con `TEKOAPP-E2E-MASTER-PLAN.md` §3 (módulos M0..M11) y
§6 (auditoría UI/UX, hallazgos U1 a U3). En alcance de esta etapa: componentes del design system (skeleton,
empty state, toast), accesibilidad y ids E2E, ubicación exacta del profesional asignado, y el flujo de auth.
Fuera de alcance: backend, web, entrega real de push (FCM), pagos con Stripe real.

## 2. Niveles de prueba

| Nivel | Herramienta | Ubicación | Estado |
|---|---|---|---|
| Unitaria / provider | `flutter_test` + `mocktail` + `ProviderContainer` | `test/core`, `test/features/*/providers`, `test/features/*/data` | Activo (~140 archivos `*_test.dart` en total) |
| Widget | `flutter_test`, `testWidgets` | `test/features/*/widgets`, `test/shared`, `test/design_system` | Activo |
| Accesibilidad | `meetsGuideline` (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`) y `bySemanticsId` | login, home, pagos, componentes `Teko*` | Activo |
| e2e de widgets | App real con Dio mockeado | `test/e2e/` (login -> perfil -> logout) | Activo |
| e2e real | **Maestro** 2.11.0 contra backend e2e local (aprobado por José) | `.maestro/` (8 flujos W1: M1 Auth y M2 Catálogos) | Escritos y con sintaxis validada (`maestro check-syntax`); **pendiente de ejecución: sin dispositivo** |

Los selectores para Maestro son `Semantics(identifier: ...)` documentados en `docs/e2e-selectors.md`
(convención `feature.pantalla.elemento`).

## 3. Entornos

| Entorno | Uso | Detalle |
|---|---|---|
| Local, VM de `flutter test` | unit, provider, widget, a11y, e2e de widgets | Sin red; Dio, storage y plugins mockeados; Flutter 3.x |
| Emulador/dispositivo + backend e2e local (`pnpm e2e:serve`, puerto 3100) | Maestro | APK debug con `dart_defines.e2e.json` (`10.0.2.2:3100`); cleartext http permitido solo en debug (`android/app/src/debug`); nunca apuntar a Supabase; Stripe en modo test, FCM/email en stub |

## 4. Criterios

- Entrada: rama compila, `flutter pub get` OK, `flutter analyze --fatal-infos` sin hallazgos.
- Salida (unit/widget): `flutter test` con 0 fallos; `dart format --set-exit-if-changed .` limpio; informe
  generado y commiteado con veredicto.
- Veredicto: APROBADO (0 fallos, 0 defectos abiertos), APROBADO CON OBSERVACIONES (0 fallos, desvíos o defectos
  P2/P3 documentados), RECHAZADO (algún fallo o defecto P0/P1 sin resolver).
- Maestro, entrada: (1) dispositivo o emulador Android visible en `adb devices`; (2) backend e2e arriba y sembrado, `GET :3100/tekoapp-backend/api/swagger-json` = 200; (3) `maestro --version` responde (JDK 17); (4) `dart_defines.e2e.json` presente; (5) APK debug instalado; (6) `flutter analyze --fatal-infos` y `flutter test` en verde; (7) todos los ids usados por los flujos existen en `lib/` y en `docs/e2e-selectors.md`.
- Maestro, salida: los casos P0/P1 de CP-AUTH y CP-CAT pasan con evidencia (JUnit `build/qa/maestro.xml`, capturas); informe `*_flujo_*.md` generado con `tool/qa_report.dart` desde la ejecución real (nunca sin ejecución). Ejecución con `tool/e2e_maestro.ps1`.

## 5. Casos y trazabilidad

`casos/CP-A11Y.md`, `casos/CP-UI.md`, `casos/CP-LOC.md`, `casos/CP-AUTH.md`, `casos/CP-CAT.md`. Cada caso cita archivo y nombre
real del test. Los casos manuales (tooltips con lector real, contraste del toast) están marcados como no
automatizados.

## 6. Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Los selectores `Semantics(identifier)` no se validaron en dispositivo real (Android resource-id / iOS accessibilityIdentifier) | Maestro puede no encontrarlos | Validar en el primer run con dispositivo (flujos ya escritos, sin ejecutar); si un id no resuelve, `maestro hierarchy` y ajustar `Semantics`; los widget tests solo prueban el árbol semántico de Flutter |
| Cobertura de contraste AA inexistente en tests | Regresiones de contraste no detectadas | Caso manual CP-MOB-UI-015; evaluar golden/contraste automático |
| e2e de widgets con Dio mockeado no detecta drift del contrato real | Falsos verdes ante cambios del backend | Maestro contra backend e2e local (flujos W1 escritos, pendientes de ejecución) |
| Push (FCM) sobreescrito en tests | Sin cobertura de registro real | Fuera de alcance; checkpoint con dispositivo real |
| Tests dependientes de timing (`pump` con duraciones) | Flakies | Registrar en la sección 4 de cada informe |
| Cleartext http bloqueado por Android hacia el backend e2e | La app no conecta y todos los flujos fallan | `network_security_config` solo en `src/debug` (10.0.2.2, localhost, 127.0.0.1); release intacto |
| Flujos Maestro nunca ejecutados (sin dispositivo en la oleada W1) | Selectores o tiempos pueden requerir ajuste | Primer run en dispositivo antes de dar por cerrada W1; informe real recién entonces |
