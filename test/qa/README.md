# QA — TekoApp Mobile

Documentación de pruebas según `QA-DOC-STANDARD.md` (base ISO/IEC/IEEE 29119-3 simplificada).

## Contenido

| Ruta | Qué es |
|---|---|
| `PLAN-DE-PRUEBAS.md` | Alcance, niveles, entornos, criterios de entrada/salida y riesgos |
| `casos/CP-A11Y.md` | Accesibilidad y selectores E2E (login, home, pagos) |
| `casos/CP-UI.md` | TekoSkeleton, TekoEmptyState, TekoToast, AsyncStateView |
| `casos/CP-LOC.md` | Ubicación exacta del profesional asignado y aviso de aproximada |
| `casos/CP-AUTH.md` | e2e de widgets login -> perfil -> logout |
| `informes/` | Un informe por ejecución real, `AAAA-MM-DD_<tipo>_<rama-corta>.md` |
| `../../tool/qa_report.dart` | Generador de informes (Dart puro, sin dependencias) |

## Cómo correr cada tipo de prueba

| Tipo | Comando |
|---|---|
| Suite completa (unit + provider + widget + a11y + e2e de widgets) | `flutter test` |
| Un área | `flutter test test/features/locations` |
| e2e de widgets con Dio mockeado | `flutter test test/e2e` |
| e2e real con Maestro | Pendiente (oleada W1); selectores en `docs/e2e-selectors.md` |

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
