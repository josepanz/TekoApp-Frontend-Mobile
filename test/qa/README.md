# QA — TekoApp Mobile

Documentación de pruebas según `QA-DOC-STANDARD.md` (base ISO/IEC/IEEE 29119-3 simplificada).

## Contenido

| Ruta | Qué es |
|---|---|
| `PLAN-DE-PRUEBAS.md` | Alcance, niveles, entornos, criterios de entrada/salida y riesgos |
| `casos/CP-A11Y.md` | Accesibilidad y selectores E2E (login, home, pagos) |
| `casos/CP-UI.md` | TekoSkeleton, TekoEmptyState, TekoToast, AsyncStateView |
| `casos/CP-LOC.md` | Ubicación exacta del profesional asignado y aviso de aproximada |
| `casos/CP-AUTH.md` | Auth y sesión: e2e de widgets + flujos Maestro (CP-MOB-AUTH-001..008) |
| `casos/CP-CAT.md` | Catálogos (categorías y tipos de servicio) con Maestro + parser JUnit |
| `../../.maestro/` | Flujos Maestro (`config.yaml`, `subflows/login.yaml`, `subflows/logout.yaml`, M1 y M2) |
| `../../tool/e2e_maestro.ps1` | Orquesta backend check, build, install, Maestro e informe |
| `informes/` | Un informe por ejecución real, `AAAA-MM-DD_<tipo>_<rama-corta>.md` |
| `../../tool/qa_report.dart` | Generador de informes (Dart puro, sin dependencias) |

## Cómo correr cada tipo de prueba

| Tipo | Comando |
|---|---|
| Suite completa (unit + provider + widget + a11y + e2e de widgets) | `flutter test` |
| Un área | `flutter test test/features/locations` |
| e2e de widgets con Dio mockeado | `flutter test test/e2e` |
| Sintaxis de los flujos Maestro (sin dispositivo) | `maestro check-syntax <flujo.yaml>` por archivo (acepta un archivo, no carpetas; `config.yaml` es config de workspace y no se valida así) |
| e2e real con Maestro | `pwsh tool/e2e_maestro.ps1` (requiere dispositivo y backend e2e); selectores en `docs/e2e-selectors.md` |

## Regenerar un informe

```bash
mkdir -p build/qa
flutter test --machine --coverage > build/qa/unit.jsonl
dart run tool/qa_report.dart build/qa/unit.jsonl unit
```

El tercer argumento opcional es la ruta del lcov (por defecto `coverage/lcov.info`). Variables opcionales:
`QA_COMMAND`, `QA_EXECUTOR`, `QA_ENV`. El generador escribe
`test/qa/informes/AAAA-MM-DD_unit_<rama-corta>.md` con encabezado, resumen, tabla por área/feature,
inventario por archivo, fallidos, omitidos y cobertura de líneas calculada desde lcov.
Las secciones 3 (defectos), 4 (desvíos) y 6 (veredicto) se completan a mano.

El `.jsonl` y `coverage/` no se commitean (`build/` y `coverage/` están en `.gitignore`).

## Convención de ids

`CP-MOB-<MOD>-NNN` (MOD: A11Y, UI, LOC, AUTH). Cada test nuevo o modificado lleva un encabezado `//` con
Suite, Casos, Tipo, Precondiciones y Trazabilidad (§4 del estándar). Los tests viejos se documentan al tocarlos.

## Maestro (e2e real, Mobile <-> backend e2e)

### Instalación (Windows)

1. JDK 17 en el PATH (`java -version`).
2. Descargar el zip oficial `https://github.com/mobile-dev-inc/maestro/releases/latest/download/maestro.zip` (~300 MB).
3. Extraer de modo que quede `%USERPROFILE%\.maestro\bin\maestro.bat` y agregar `%USERPROFILE%\.maestro\bin` al PATH de usuario.
4. Verificar: `maestro --version` (instalada: **2.11.0**, 2026-10-12).

Los flujos viven en `.maestro/` (convención de Maestro: `maestro test .maestro`; evita una carpeta propia y funciona
con `config.yaml` de workspace). `appId`: `py.com.tekoapp.mobile` (sin flavors).

### Configuración del backend e2e

1. En el repo Backend: `pnpm e2e:up && pnpm e2e:seed && pnpm e2e:serve` (puerto 3100).
2. Copiar `dart_defines.e2e.example.json` a `dart_defines.e2e.json` (ignorado por git). Emulador: `10.0.2.2:3100`.
   Dispositivo físico: `adb reverse tcp:3100 tcp:3100` y `API_BASE_URL=http://localhost:3100/tekoapp-backend/api`.
3. El backend e2e es http: Android bloquea cleartext desde targetSdk 28. `android/app/src/debug/res/xml/network_security_config.xml`
   (referenciado solo desde `src/debug/AndroidManifest.xml`) lo permite únicamente para `10.0.2.2`, `localhost` y
   `127.0.0.1` en builds debug; release/profile no se tocan.

### Ejecución

```powershell
pwsh tool/e2e_maestro.ps1            # verifica backend, compila, instala, corre Maestro y genera el informe
pwsh tool/e2e_maestro.ps1 -Reverse   # dispositivo físico con adb reverse
```

El informe `test/qa/informes/AAAA-MM-DD_flujo_<rama>.md` se genera con
`dart run tool/qa_report.dart build/qa/maestro.xml flujo` (parser en `tool/qa_junit.dart`, test en
`test/tool/qa_junit_test.dart`). No se genera informe si no hubo ejecución real.
