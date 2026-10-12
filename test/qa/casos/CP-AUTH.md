# CP-AUTH — Login, perfil y logout (e2e de widgets con Dio mockeado)

Repo: Mobile (MOB). Trazabilidad: plan maestro M1 (Auth y sesión).

## CP-MOB-AUTH-001 — Login, home, Mi perfil y logout de punta a punta

| Campo | Contenido |
|---|---|
| Título | Completa el ciclo login -> home -> Mi perfil -> logout con la app real y Dio mockeado |
| Tipo / Nivel | e2e (widgets; no es Maestro) |
| Prioridad | P0 |
| Trazabilidad | M1 Auth/Sesión; nonce + RSA -> login; logout limpia la sesión |
| Precondiciones | `TekoApp` montada; Dio mockeado (nonce, login, perfil, logout); par de claves RSA generado en el test (nunca la clave real del backend); `flutter_secure_storage` y `shared_preferences` mockeados; providers de push FCM sobreescritos (no-op) |
| Pasos | 1. Abrir la app sin sesión y ver `LoginScreen`. 2. Completar email y contraseña y enviar. 3. Verificar la llegada a `HomeScreen`. 4. Navegar a Mi perfil (`ProfileScreen`). 5. Ejecutar logout. 6. Verificar el regreso a login. |
| Datos de prueba | Credenciales y respuestas simuladas definidas en el test (sin secretos reales) |
| Resultado esperado | Navegación Login -> Home -> Perfil -> Login; la sesión se limpia al cerrar sesión |
| Automatizado en | `test/e2e/login_profile_logout_test.dart` — `login -> home -> Mi perfil -> logout de punta a punta` |

Nota: el equivalente real contra backend local queda para Maestro (oleada W1, ver `PLAN-DE-PRUEBAS.md`).
