# Cómo contribuir a TekoApp Mobile — guía paso a paso

> Para alguien que sabe programar pero nunca tocó Flutter/Dart. Explica el **cómo** del día a
> día: dónde escribir código para una tarea concreta, con ejemplos reales de este repo. El **por
> qué** de las decisiones grandes (por qué Riverpod, por qué go_router, etc.) vive en
> [`openspec/decisions.md`](openspec/decisions.md).

## 0. Los conceptos que hay que tener claros antes de tocar nada

### Widget = tu unidad de UI (como un componente de React)

Todo en Flutter es un `Widget`. Hay dos tipos:

- **`StatelessWidget`**: no tiene estado propio, solo recibe datos y los pinta. Ejemplo real:
  [`lib/features/home/widgets/home_screen.dart`](lib/features/home/widgets/home_screen.dart).
  Equivalente mental: un componente de React sin `useState`.
- **`StatefulWidget`**: tiene estado mutable propio (`setState`). Se usa poco en este proyecto a
  propósito — el estado que depende del servidor vive en un **provider de Riverpod**, no en un
  `StatefulWidget` (ver el punto siguiente). Reservar `StatefulWidget` para estado 100% de UI
  efímero (ej. si un `TextField` está enfocado).

### Riverpod = tu `useQuery`/`useMutation` (si venís de `TekoApp-Web`)

Un **provider** es una función top-level que expone un valor (o un `Future`/`Stream` de un valor)
al resto de la app. Ejemplo real:
[`lib/features/auth/providers/auth_repository_provider.dart`](lib/features/auth/providers/auth_repository_provider.dart):

```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
```

- `ref.watch(unProvider)` dentro de un widget = "leer este valor y reconstruir el widget cuando
  cambie" (≈ `useQuery(...)` en React).
- `ref.read(unProvider)` = "leer el valor una vez, no reconstruir si cambia" (útil dentro de un
  callback, como `onPressed`).
- Cuando este repo empiece a pedir datos reales al backend (Fase 0002), esos providers van a ser
  `FutureProvider`/`AsyncNotifierProvider` — el equivalente exacto a un hook de TanStack Query en
  `TekoApp-Web`. Todavía no hay ninguno real en el repo (solo el placeholder de sesión), así que
  cuando llegue el momento, mirar cómo `TekoApp-Web/src/features/*/hooks.ts` resuelve
  loading/error/data y replicar la misma idea con `AsyncValue.when(...)`.

### go_router = tu ruteo declarativo (como `react-router`/`proxy.ts`)

Las rutas viven en un solo lugar: [`lib/app.dart`](lib/app.dart). Cada pantalla nueva necesita una
entrada ahí:

```dart
GoRoute(path: '/mi-ruta', builder: (context, state) => const MiPantalla()),
```

Navegar entre pantallas: `context.go('/mi-ruta')` (reemplaza la pantalla actual) o
`context.push('/mi-ruta')` (la apila arriba, con back nativo).

### La estructura de carpetas por dominio (obligatoria, ver `.claude/rules/flutter-architecture.md`)

```
lib/features/<dominio>/
├── data/        # llamadas a la API vía dio (≈ features/<dominio>/api.ts de TekoApp-Web)
├── providers/   # providers de Riverpod (≈ features/<dominio>/hooks.ts)
├── models/      # clases de datos puras (constructor + fromJson) — sin lógica de negocio
└── widgets/     # pantallas y componentes de ese dominio
```

Ejemplo real completo (aunque todavía placeholder): `lib/features/auth/`.

---

## 1. Ajuste menor: cambiar un texto o un estilo en una pantalla existente

Ejemplo: "en la pantalla de login, el botón debería decir 'Entrar' en vez de 'Ingresar'".

1. Nunca hardcodees el texto en el widget. Abrí `lib/l10n/es.arb` y `lib/l10n/en.arb`, cambiá el
   valor de la clave existente (ej. `"loginSubmit": "Entrar"`) — **en los dos archivos**.
2. Si el texto es nuevo (no existe la clave todavía), agregala en ambos `.arb` con el mismo
   nombre de clave (ver la sección de i18n más abajo).
3. El widget ya la consume vía `AppLocalizations.of(context)!.loginSubmit` — no hace falta tocar
   el `.dart`, salvo que el string sea genuinamente nuevo.
4. Correr `flutter test` (aunque no haya tests que dependan del texto exacto, confirma que nada
   se rompió) y `flutter analyze`.

## 2. Ajuste menor: agregar un campo a una pantalla existente

Ejemplo: "agregar un campo de teléfono al formulario de login" (hoy solo tiene email/password).

1. Abrí el widget, ej. [`lib/features/auth/widgets/login_screen.dart`](lib/features/auth/widgets/login_screen.dart).
2. Agregá el nuevo texto a `lib/l10n/{es,en}.arb` primero (ej. `"loginPhoneLabel": "Teléfono"`).
3. Agregá el `TextField` nuevo en el `Column` de children, siguiendo el mismo patrón que los
   campos existentes (`TextField(decoration: InputDecoration(labelText: l10n.loginPhoneLabel))`).
4. Si el campo necesita validación o se manda al backend al enviar el form, eso ya es un cambio
   "mayor" — ver la sección 4 (`providers/`+`data/`).

## 3. Ajuste mayor: nueva pantalla dentro de un dominio que ya existe

Ejemplo: "agregar una pantalla de 'Recuperar contraseña' dentro de `features/auth`".

1. Nuevo archivo en `lib/features/auth/widgets/forgot_password_screen.dart` — mismo patrón que
   `login_screen.dart` (widget `StatelessWidget`, lee textos de `AppLocalizations`).
2. Agregá la ruta en [`lib/app.dart`](lib/app.dart):
   ```dart
   GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
   ```
3. Enlazá la navegación desde donde corresponda (ej. un botón "¿Olvidaste tu contraseña?" en
   `login_screen.dart` con `onPressed: () => context.push('/forgot-password')`).
4. Si la pantalla necesita pegarle al backend (mandar el email para el reset), eso vive en
   `features/auth/data/auth_repository.dart` (agregar el método) +
   `features/auth/providers/` (un provider/mutation nuevo que lo expone) — nunca un `dio` armado
   a mano dentro del widget.
5. Escribí el test: `test/features/auth/widgets/forgot_password_screen_test.dart` (crear la
   carpeta si no existe) — ver la sección de testing más abajo.

## 4. Nueva feature (dominio) de cero

Ejemplo: cuando llegue el momento de implementar `features/services` (listado de servicios, como
`TekoApp-Web/src/features/services`).

1. Creá la estructura completa a mano (no hay generador de scaffolding todavía en este repo, a
   diferencia de `TekoApp-Web`):
   ```
   lib/features/services/
   ├── data/services_repository.dart
   ├── providers/services_provider.dart
   ├── models/service.dart
   └── widgets/services_list_screen.dart
   ```
2. **`models/service.dart`** primero — la forma de los datos, calcada del DTO real del backend
   (mirar `TekoApp-Backend`'s Swagger o `TekoApp-Web/src/core/api-client/types.generated.ts` como
   referencia de los campos reales, nunca inventar campos):
   ```dart
   class Service {
     const Service({required this.referenceId, required this.title, required this.status});

     final String referenceId; // nunca el id interno numérico, ver regla de referenceId
     final String title;
     final String status;

     factory Service.fromJson(Map<String, dynamic> json) {
       return Service(
         referenceId: json['id'] as String, // el backend expone el referenceId bajo la key "id"
         title: json['title'] as String,
         status: json['status'] as String,
       );
     }
   }
   ```
3. **`data/services_repository.dart`** — las llamadas HTTP, usando `ApiClient` (nunca un `Dio`
   nuevo):
   ```dart
   class ServicesRepository {
     const ServicesRepository(this.apiClient);
     final ApiClient apiClient;

     Future<List<Service>> getServices() async {
       final response = await apiClient.raw.get<List<dynamic>>('/services');
       return response.data!.map((json) => Service.fromJson(json as Map<String, dynamic>)).toList();
     }
   }
   ```
4. **`providers/services_provider.dart`** — un provider por operación de servidor:
   ```dart
   final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
     return ServicesRepository(ref.watch(apiClientProvider));
   });

   final servicesProvider = FutureProvider<List<Service>>((ref) {
     return ref.watch(servicesRepositoryProvider).getServices();
   });
   ```
5. **`widgets/services_list_screen.dart`** — consume el provider con `ref.watch` +
   `AsyncValue.when` (loading/error/data — nunca solo el caso feliz):
   ```dart
   class ServicesListScreen extends ConsumerWidget {
     const ServicesListScreen({super.key});

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final servicesAsync = ref.watch(servicesProvider);
       return Scaffold(
         body: servicesAsync.when(
           data: (services) => ListView(
             children: services.map((s) => ListTile(title: Text(s.title))).toList(),
           ),
           loading: () => const Center(child: CircularProgressIndicator()),
           error: (error, stack) => Center(child: Text('Error: $error')),
         ),
       );
     }
   }
   ```
   (Tip: `AsyncStateView` en `lib/shared/widgets/async_state_view.dart` ya envuelve este patrón
   si preferís no repetir el `when` a mano en cada pantalla.)
6. Agregá la ruta en `lib/app.dart`, los textos en `lib/l10n/{es,en}.arb`, y el/los test(s) en
   `test/features/services/`.
7. Actualizá `openspec/specs/services-marketplace.md` si el comportamiento real difiere de lo que
   ese spec asumía (es la fuente de verdad del contrato, no el código).

## 5. Textos e idiomas (i18n)

Nunca un string visible hardcodeado en un widget. Siempre:

1. Agregá la clave en **ambos** `lib/l10n/es.arb` y `lib/l10n/en.arb` (mismo nombre de clave):
   ```json
   "miTextoNuevo": "Mi texto en español"
   ```
2. Si el texto tiene una variable: usá placeholders (ver `homeGreeting` en `es.arb` como ejemplo
   de `"Hola, {name}"` con su bloque `"@homeGreeting": {"placeholders": {"name": {"type": "String"}}}`).
3. Corré `flutter gen-l10n` (se corre solo al hacer `flutter run`/`flutter test`, pero podés
   forzarlo para ver el archivo generado antes de usar la clave nueva).
4. Usalo en el widget: `AppLocalizations.of(context)!.miTextoNuevo`.

## 6. Testing

Ver [`.claude/rules/test.md`](.claude/rules/test.md) para el estándar completo. Resumen:

- **Todo provider/widget/función de `core/` nuevo lleva su test** — sin excepción.
- Nombres de test en español, describiendo el comportamiento (`'muestra un estado vacío cuando no
  hay servicios todavía'`), nunca el nombre del método.
- Mocks con `mocktail` — ver
  [`test/core/api_client/envelope_interceptor_test.dart`](test/core/api_client/envelope_interceptor_test.dart)
  como plantilla exacta del patrón (`class _MockAlgo extends Mock implements Algo {}`).
- Widget tests: `testWidgets(...)` + `WidgetTester`, envolver en `ProviderScope` si el widget lee
  algún provider — ver [`test/app_test.dart`](test/app_test.dart).

Comandos:

```bash
flutter test              # todos los tests
flutter test --coverage   # con cobertura
flutter analyze           # analizador estático — debe quedar en 0 issues
dart format .             # formateo automático (correr ANTES de cada commit, ver nota abajo)
```

**Importante**: correr `dart format .` antes de cada commit. El CI (`ci.yml`) falla el build si
algún archivo no está formateado — `dart format` lo arregla solo, no hay que adivinar el estilo a
mano.

## 7. Antes de abrir el PR

1. `flutter analyze` → 0 issues.
2. `dart format --output=none --set-exit-if-changed .` → sin cambios pendientes.
3. `flutter test` → todo verde.
4. Nunca commitear directo a `develop`/`qa`/`master` — ver el guardrail de rama en
   [`.claude/rules/auth.md`](.claude/rules/auth.md). Siempre rama + PR.
