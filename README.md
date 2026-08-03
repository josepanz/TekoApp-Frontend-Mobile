<div align="center">

# TekoApp テコ — App Mobile (Flutter)

![TekoApp Banner](brand/banner.png)

**La misma plataforma de servicios profesionales de TekoApp-Web, en el bolsillo.**

[![Flutter](https://img.shields.io/badge/Flutter_3-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-0175C2?style=for-the-badge)](https://riverpod.dev/)

</div>

---

## Estado de este repositorio

**Fase 0001 (bootstrap) ejecutada** — existe el esqueleto de `lib/` (estructura de carpetas,
tema, cliente HTTP, routing, l10n es/en, CI de analyze+test, workflow de build Android/iOS sin
firma) descrito en `openspec/changes/0001-project-bootstrap.md`. Todavía **no hay login real ni
ninguna feature de negocio implementada** — eso es la Fase 0002 en adelante (auth real con
nonce+RSA-OAEP, almacenamiento seguro de tokens, primera pantalla de dominio real).

**Empezar acá**: [`openspec/README.md`](openspec/README.md) explica cómo está organizada la
documentación y en qué orden seguirla. Este README da el contexto de producto y stack; el detalle
de decisiones, specs por capacidad y el plan de implementación por fases vive en `openspec/`.
Ver [`CONTRIBUTING.md`](CONTRIBUTING.md) para la guía paso a paso de cómo hacer un cambio en este
repo (pensada para alguien sin experiencia previa en Flutter).

---

## Descripción

**TekoApp** es una plataforma de economía colaborativa que conecta usuarios con profesionales de
servicios de oficio (electricistas, plomeros, pintores, carpinteros, etc.) de forma rápida, segura
y geolocalizada — inspirada en la eficiencia logística de Uber/Bolt pero para servicios
profesionales, no viajes.

Un usuario puede operar como **cliente** (pide servicios) o **profesional** (los ofrece) con la
misma cuenta — el backend expone ambos roles sobre el mismo `Users`, y `TekoApp-Web` ya resuelve
esto con un selector de modo (cliente/profesional/admin) en la misma sesión. Esta app debería
replicar esa misma decisión: no hay una app "de cliente" y otra "de profesional" separadas.

## El poder detrás del nombre "Teko"

| Idioma | Escritura | Significado | Simbolismo |
|---|---|---|---|
| **Guaraní** | Teko | *"Vida / Estilo de vida"* | La misión: mejorar el día a día de quien pide y de quien ofrece el servicio |
| **Japonés** | テコ | *"Palanca"* | La app como herramienta que multiplica oportunidades, en ambos lados del mercado |

## Ecosistema de repositorios

| Componente | Repositorio | Stack | Rol para este repo |
|---|---|---|---|
| **Backend** | [TekoApp-Backend](https://github.com/josepanz/TekoApp-Backend) | NestJS 10, Prisma, MongoDB, Redis | La única API que esta app consume — nunca se reimplementa lógica de negocio acá |
| **Web Admin** | [TekoApp-Web](https://github.com/josepanz/TekoApp-Frontend-Web) | Next.js 16, shadcn/ui, TanStack Query | Referencia de patrones (BFF, i18n, design tokens) — no se consume directamente, pero sus decisiones ya probadas se heredan |
| **Mobile** *(este repo)* | TekoApp-Mobile | Flutter 3, Riverpod, go_router, dio | — |

## Marca

Los assets de marca (logo, banner, manual completo) viven en [`brand/`](brand/) — copia local,
independiente de la IA que asista en cada sesión. La fuente canónica es el manual de marca oficial
de TekoApp (mismos archivos también en `TekoApp-Backend/brand/` y `TekoApp-Web/brand/`); si el
manual cambia, actualizar los 3 repos. Los tokens de diseño ya implementados en `TekoApp-Web`
(`src/design-system/tokens/tokens.json`, formato W3C Design Tokens) están pensados para generar
también un output Dart desde el mismo archivo cuando arranque este repo — ver
`openspec/specs/design-system.md` para el detalle de cómo replicar la paleta/tipografía sin
duplicar la definición de marca a mano.

## Stack decidido (ver `openspec/decisions.md` para el razonamiento completo de cada ítem)

| Capa | Elección |
|---|---|
| Framework | Flutter 3 |
| Lenguaje | Dart |
| Estado | Riverpod |
| Ruteo | go_router |
| Cliente HTTP | dio |
| Notificaciones push | Firebase Cloud Messaging (`firebase_messaging`) |
| Diseño | Tokens compartidos desde `TekoApp-Web` (mismo `tokens.json`, output Dart nuevo) |

## Cómo seguir la documentación de este repo

Toda la documentación de referencia vive en la raíz del repo — se puede leer y usar con o sin un
asistente de IA de por medio:

1. [`ARCHITECTURE.md`](ARCHITECTURE.md) — dominio, contrato con el backend, stack, decisiones de
   arquitectura y bugs ya encontrados. Punto de entrada si querés entender el proyecto sin depender
   de ninguna herramienta de IA.
2. [`CONTRIBUTING.md`](CONTRIBUTING.md) — guía paso a paso de cómo hacer un cambio en este repo
   (pensada para alguien sin experiencia previa en Flutter).

Si además trabajás con un asistente de IA, [`openspec/`](openspec/) tiene el mismo contenido de
`ARCHITECTURE.md` organizado como specs ejecutables (formato SDD) más el plan de implementación
por fases — es un complemento para ese flujo de trabajo, no una fuente de verdad distinta:

3. [`openspec/README.md`](openspec/README.md) — cómo está organizada esa carpeta y el flujo
   spec-driven que se espera seguir.
4. [`openspec/specs/`](openspec/specs/) — el contrato de cada capacidad (auth, marketplace de
   servicios, pagos, notificaciones, etc.) tal como debería comportarse en Flutter.
5. [`openspec/changes/`](openspec/changes/) — el plan de implementación en fases, cada una con
   checkpoints concretos de "esto tiene que funcionar antes de seguir a la próxima fase".

## Cómo correr esta app localmente

### Requisitos previos (Mac o PC)

1. Instalar el [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal `stable`).
2. Correr `flutter doctor` y resolver todo lo que marque en rojo antes de seguir — en particular
   la licencia de Android (`flutter doctor --android-licenses`) y, en Mac, Xcode + CocoaPods
   (`sudo gem install cocoapods`) para iOS.
3. Clonar `TekoApp-Backend` como repo hermano (mismo directorio padre que este repo) y tenerlo
   corriendo localmente (`pnpm run start:dev` — ver su propio README) — la app apunta ahí por
   default en desarrollo.
4. `flutter pub get` en la raíz de este repo.

### Levantar la app

```bash
# Emulador/dispositivo Android, apuntando al backend local (10.0.2.2 = alias del host desde el
# emulador Android; en un dispositivo físico o iOS Simulator, reemplazar por la IP LAN de la
# máquina que corre el backend, ej. 192.168.1.50)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/tekoapp-backend/api
```

### Android — dispositivo físico por USB

1. Habilitar "Opciones de desarrollador" → "Depuración USB" en el teléfono.
2. Conectar por USB, aceptar el diálogo de confianza en el teléfono.
3. `flutter devices` debería listarlo. `flutter run` (con el `--dart-define` de arriba, usando la
   IP LAN de la máquina, no `10.0.2.2` — un dispositivo físico no tiene ese alias).

### Android — emulador

1. Abrir Android Studio → Device Manager → crear/iniciar un AVD (API 33+ recomendado).
2. Con el emulador corriendo, `flutter run` lo detecta solo.

### iOS — solo desde una Mac

**Simulador**:

```bash
open -a Simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000/tekoapp-backend/api
```

**Dispositivo físico**: conectar por USB, confiar en la computadora desde el teléfono, abrir
`ios/Runner.xcworkspace` en Xcode una vez para seleccionar un Team de firma (cuenta de Apple ID
gratuita alcanza para correr en tu propio dispositivo) y después `flutter run` funciona directo
sin volver a abrir Xcode. Usar la IP LAN de la Mac en `API_BASE_URL`, no `localhost`.

### CI/CD

- `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` en cada push/PR a
  `develop`/`qa`/`master`.
- `.github/workflows/build.yml` — build de validación por ambiente (disparo manual, elegís
  `dev`/`qa`/`prod` — mismo mapeo de ramas que el resto del ecosistema, ver
  `openspec/decisions.md`): APK debug de Android + build de iOS para simulador, sin firma.
  **No publica a ninguna store todavía** — falta la cuenta de Google Play Console y Apple
  Developer Program + sus certificados/keystore, el proyecto Firebase real, y un backend
  desplegado en qa/prod (hoy solo corre local). Ver `openspec/decisions.md` para el detalle
  completo de qué falta y cómo se extiende cuando esas cuentas existan.

## Contacto

José Panza — josepanza1@gmail.com

✨ *"Conectando talento con necesidad, donde sea, cuando sea."*
