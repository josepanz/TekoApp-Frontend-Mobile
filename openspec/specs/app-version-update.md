# Spec: Chequeo y actualización de versión de la app (Mobile)

Plan de fase: `openspec/changes/0015-app-version-update.md`. Sin contraparte en Backend ni Web —
la app consulta la API pública de GitHub directamente (ver "Decisión: por qué NO hay backend
intermediario").

## Objetivo

Hoy la única forma de que un usuario (testers internos sideloadeando el APK, en los 3 ambientes —
ninguno tiene distribución real vía store todavía) se entere de una versión nueva es que alguien
le pase el link del GitHub Release a mano. Agregar un chequeo al arrancar la app que compare la
versión instalada contra el último release publicado para su MISMO ambiente (`dev`/`qa`/`prod`,
ver `openspec/decisions.md` → "CI/CD: GitHub Actions, 3 ambientes") y, si hay una versión más
nueva, mostrar un modal con "Actualizar"/"Cancelar". Actualizar descarga el APK del release y
dispara el instalador nativo de Android, que sobrescribe la app instalada in place (mismo
`applicationId`, misma firma → upgrade, conserva datos).

## Alcance

**Incluye**: chequeo automático al arrancar la app (Android), comparación de versión
ambiente-consciente contra `api.github.com`, modal de actualización, descarga del APK con
progreso, disparo del instalador nativo de Android.

**No incluye (fuera de esta fase)**: iOS (ver decisión abajo), "recordar más tarde"/omitir una
versión específica (el modal vuelve a aparecer en el próximo chequeo mientras la versión instalada
siga desactualizada — ver Riesgos), actualización forzada/bloqueante (el usuario siempre puede
cancelar y seguir usando la versión actual), versión mínima soportada forzada desde el backend
(feature distinta, si se pide).

## Decisión: por qué NO hay backend intermediario

La fuente de verdad de "qué hay publicado por ambiente" ya es pública y ya existe: los GitHub
Releases que emite `.github/workflows/release.yml` (repo público,
`josepanz/TekoApp-Frontend-Mobile`). Agregar un endpoint propio en `TekoApp-Backend` para espejar
ese mismo dato duplicaría algo que GitHub ya sirve gratis y sin autenticación, sin beneficio real
hoy. Si en el futuro se necesita control remoto de versión mínima forzada o apagar el chequeo por
incidente sin publicar una release nueva, ESO sí justificaría un endpoint propio (`APP_CONFIG` del
backend, mismo mecanismo que ya existe para `aiDisclosure.userDeclarableTypes`) — explícitamente
fuera de esta fase.

## Decisión: alcance Android únicamente en esta fase

iOS no permite instalar un IPA descargado fuera de App Store/TestFlight sin MDM/enterprise (Apple
lo bloquea a nivel de OS) — la única forma legítima de "actualizar" en iOS es redirigir a la store
correspondiente. Hoy ese flujo no tiene destino real: `publish-ios-store` (`release.yml`) ya está
implementado pero bloqueado por falta de credenciales (`decisions.md`, sección CI/CD) — no existe
todavía un App Store/TestFlight id al que enlazar. Construir esa UI ahora sería para un link que no
existe. **Esta fase corre el chequeo y el modal solo en Android** (`Platform.isAndroid`); agregar
el flujo de redirect a TestFlight/App Store como fase separada cuando `publish-ios-store` tenga
credenciales cargadas.

## Decisión: por qué el chequeo aplica a los 3 ambientes (incluido `prod`), por ahora

Hoy NINGÚN ambiente Android tiene distribución real vía Google Play (`has_play_publish` pendiente
de secrets, `decisions.md`) — `prod` se instala hoy sideloadeando el APK del GitHub Release, igual
que `dev`/`qa`. El chequeo queda activo en los 3. **Pendiente de decisión futura, no resuelta
acá**: desactivarlo (o degradarlo a un aviso pasivo sin descarga) en `prod` una vez que Google Play
esté publicando de verdad, para no competir con el auto-update nativo de la store.

## Regla central: nunca cruzar ambientes

El release que se ofrece SIEMPRE corresponde al mismo ambiente que la build corriendo — nunca "la
versión más nueva de cualquier rama". Mapeo de `tag_name` (mismos tags que ya emite
`release.yml`, verificado contra los releases reales publicados hoy):

| Ambiente (`Env.environment`) | Patrón de tag a buscar               | Ejemplo real ya publicado |
|---|---|---|
| `dev`  | `vX.Y.Z-develop.N`                   | `v1.0.0-develop.31` |
| `qa`   | `vX.Y.Z-qa.N`                         | `v1.0.0-qa.2` |
| `prod` | `vX.Y.Z` (sin sufijo de prerelease)   | `v1.0.0` |

Un build `dev` jamás debe ofrecer/considerar un tag `-qa.`/`-develop.` de otro ambiente ni un
`vX.Y.Z` de prod, y viceversa.

## `Env.environment` — dato nuevo, no existe hoy

`lib/core/config/env.dart` hoy solo tiene `apiBaseUrl`/`isProduction` (este último es el flag de
compilación de Dart, `dart.vm.product` — no el ambiente de negocio). Agregar `Env.environment`
(`String.fromEnvironment('APP_ENVIRONMENT', defaultValue: 'dev')`), pasado por
`--dart-define=APP_ENVIRONMENT=dev|qa|prod` igual que ya se pasa `API_BASE_URL` hoy. Es dato nuevo
end-to-end: hoy ni `build.yml` ni `release.yml` pasan ese define — agregarlo en ambos.

## Fuente de datos: GitHub REST API, sin autenticación

- `GET https://api.github.com/repos/josepanz/TekoApp-Frontend-Mobile/releases?per_page=100` (repo
  público → no requiere token; **nunca embeber un GitHub PAT en el binario de la app** — innecesario
  para lectura pública y es un secreto más para filtrar en el APK descompilado, mismo riesgo ya
  documentado para el Basic Auth secret en `.claude/rules/auth.md`).
- **No usar** `GET /releases/latest`: ese endpoint devuelve el último release que NO es prerelease
  y NO es draft. Como `qa`/`develop` están marcados `"prerelease": true` en `.releaserc.json`, ese
  endpoint jamás devolvería un release de esos 2 ambientes (siempre el último de `master`).
  Listar y filtrar client-side por `tag_name` según la tabla de arriba, tomar el primer match (la
  lista ya viene ordenada por fecha de creación descendente).
- Los releases en estado `draft` no aparecen en una llamada sin autenticar (confirmado: hoy existen
  releases `develop` en estado Draft en el repo real, y no saldrían en esta llamada) — no hace
  falta filtrarlos a mano, pero dejar el check (`draft == false`) como defensivo por si el llamado
  pasa a autenticarse en el futuro.
- Cachear el resultado del chequeo (`shared_preferences`, ya en `pubspec.yaml`) con un TTL (ej. 6
  horas) — la API sin auth tiene límite de 60 req/hora por IP; varios usuarios detrás del mismo
  NAT/wifi corporativo pueden agotarlo rápido si cada apertura de app pega sin caché.

## Comparación de versiones — semver real, no comparación de strings

`PackageInfo.fromPlatform().version` da el semver actual (ej. `1.0.0-develop.9`, mismo valor que
`scripts/replace-version.sh` escribe en `pubspec.yaml`). El `tag_name` del release es ese mismo
string con un prefijo `v`. Comparar con un parser semver real (candidato: paquete `pub_semver`,
`Version.parse` — entiende que `1.0.0-develop.9 < 1.0.0-develop.10`; una comparación de strings
ingenua falla ese caso, ej. `"9" > "10"` lexicográficamente). Nunca comparar el `buildNumber`
(`+N`, el run number de CI) — no es significativo para semver y no forma parte del `tag_name`.

## Selección del asset a descargar

El release trae 1+ assets (`tekoapp-mobile-<tag>.apk`/`.aab`, y `.ipa` en qa/master — ver
`release.yml`). Buscar el asset cuyo `name` sea exactamente `tekoapp-mobile-${tag_name}.apk` (el
único instalable directamente en Android) — si no existe (ej. release sin ese build todavía
subido), no ofrecer la actualización (fail-open: no mostrar el modal, no romper el arranque de la
app).

## Flujo del modal

1. Al terminar de cargar la pantalla de inicio (después del primer frame, no bloquea el arranque),
   correr el chequeo en background.
2. Si hay una versión más nueva para el mismo ambiente CON asset APK disponible: mostrar un diálogo
   no descartable por fuera (`barrierDismissible: false` — evita que un tap accidental afuera lo
   cierre sin decisión explícita), con la versión nueva, notas del release (`body` del release, si
   no es demasiado largo — truncar/omitir si es markdown crudo sin parsear, no renderizar markdown
   en esta fase) y 2 botones: **Actualizar** / **Cancelar**.
3. **Cancelar**: cierra el modal, no descarga nada. Vuelve a aparecer en el próximo chequeo
   (próximo arranque de app, respetando el TTL de caché) mientras la versión instalada siga
   desactualizada — no hay lista de "versiones descartadas" (decisión de simplicidad, ver Riesgos).
4. **Actualizar**: pide el permiso `REQUEST_INSTALL_PACKAGES` si todavía no está otorgado (Android
   8+), descarga el APK (con indicador de progreso, `dio` con `onReceiveProgress`) a un directorio
   propio de la app, y dispara el instalador nativo de Android (`Intent.ACTION_VIEW` sobre un
   `content://` de `FileProvider`, MIME `application/vnd.android.package-archive`) — la
   confirmación final de instalar es del sistema operativo, no de esta app.
5. Si el permiso se niega, la descarga falla, o el instalador no puede abrir el archivo: mensaje de
   error claro (nunca uno genérico), con opción de reintentar o cancelar.

## Cambios de infraestructura Android requeridos

`AndroidManifest.xml`: agregar `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>`
(no existe hoy) + declarar un `<provider>` de `FileProvider` (tampoco existe hoy — hoy el manifest
no tiene ningún `<provider>`) con su `res/xml/file_paths.xml` apuntando al directorio donde se
descarga el APK.

## Fuera de alcance de esta spec

iOS (ver decisión arriba), actualización forzada/versión mínima obligatoria, "omitir esta
versión", parseo/renderizado de markdown de las release notes, backend propio de versiones.

## Riesgos / límites explícitos

- **Firma de la APK descargada vs. la instalada**: Android solo permite instalar-sobre (upgrade in
  place, conserva datos) si la firma del APK nuevo coincide con la de la app instalada. Hoy
  `ANDROID_KEYSTORE_BASE64` no está cargado (`decisions.md`) → los builds de `release.yml` quedan
  sin firma de release real. Con eso, esta función puede fallar con "app no instalada" en vez de
  actualizar — **confirmar con José, al implementar, si se construye igual documentando el riesgo
  conocido en builds sin firmar, o si se bloquea hasta que la firma de release esté cargada** — no
  asumir ninguna de las 2 opciones de antemano.
- **Paquete Flutter para disparar el instalador de Android**: no decidido en esta spec a
  propósito. Candidatos conocidos (`open_filex`, `ota_update`, `install_plugin`) — verificar
  mantenimiento activo (último release, compatibilidad con el `compileSdk`/AGP actual del
  proyecto) recién al implementar, no fijar uno ahora que puede estar abandonado para entonces.
- **Rate limit de GitHub sin auth** (60 req/hora/IP): mitigado con el TTL de caché de arriba, pero
  sigue siendo un límite real — si en algún momento se decide autenticar el llamado (ej. para
  levantar el límite), NUNCA con un PAT embebido en el cliente (ver arriba); un endpoint propio del
  backend como proxy sería el camino correcto en ese caso, no un secreto en el binario.
- **"Cancelar" no tiene memoria**: un usuario que cancela ve el modal de nuevo en cada arranque
  (respetando el TTL de caché) mientras no actualice. Aceptado como límite simple para esta fase;
  si en el uso real resulta molesto, agregar "recordar más tarde" es un cambio chico, no
  arquitectónico.
