package py.com.tekoapp.mobile

import io.flutter.embedding.android.FlutterFragmentActivity

// `local_auth` exige `FlutterFragmentActivity` en vez de `FlutterActivity` — es un paso
// obligatorio de su setup (README del plugin), no opcional. Con `FlutterActivity`,
// `authenticate()` falla en runtime con `no_fragment_activity` (ver I-05,
// openspec/specs/biometric-login.md): el biométrico nunca funciona, y sin los timeouts de
// `BiometricLoginService` el usuario ni siquiera ve un error, se queda esperando para siempre.
class MainActivity : FlutterFragmentActivity()
