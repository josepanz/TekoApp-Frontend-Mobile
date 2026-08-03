<div align="center">

# TekoApp テコ — App Mobile (Flutter)

![TekoApp Banner](../TekoApp-Backend/.claude/documentation/brand/banner.png)

**La misma plataforma de servicios profesionales de TekoApp-Web, en el bolsillo.**

[![Flutter](https://img.shields.io/badge/Flutter_3-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-0175C2?style=for-the-badge)](https://riverpod.dev/)

</div>

---

## Estado de este repositorio

**Todavía no hay código Flutter.** Este README y la carpeta [`openspec/`](openspec/) son el
resultado de documentar, al final de la sesión que construyó `TekoApp-Backend` y `TekoApp-Web`,
todo lo aprendido y decidido que aplica acá — para que la próxima sesión que arranque el código
Flutter no tenga que re-derivar nada de eso ni volver a preguntar.

**Empezar acá**: [`openspec/README.md`](openspec/README.md) explica cómo está organizada la
documentación y en qué orden seguirla. Este README da el contexto de producto y stack; el detalle
de decisiones, specs por capacidad y el plan de implementación por fases vive en `openspec/`.

### Cómo arrancar la próxima sesión (con un agente de IA)

Este repo tiene un ecosistema `.claude/` completo (reglas, agentes, memoria) — un agente nuevo
debería leer, en este orden:

1. [`.claude/CLAUDE.md`](.claude/CLAUDE.md) — dominio, stack decidido, estructura de `lib/`
   planeada, reglas críticas y links a `rules/`/`agents/`.
2. [`.claude/documentation/context.md`](.claude/documentation/context.md) — snapshot de estado y
   próximo paso concreto.
3. La sesión más reciente en `.claude/memory/sessions/` (orden alfabético, la última).
4. [`openspec/project.md`](openspec/project.md) → [`openspec/decisions.md`](openspec/decisions.md)
   → el archivo de fase correspondiente en `openspec/changes/` (empezar por
   [`0001-project-bootstrap.md`](openspec/changes/0001-project-bootstrap.md) si es la primera vez
   que se toca código en este repo).

Esto ya está automatizado como protocolo en `.claude/memory/memory.md` — no hace falta pedirlo
explícitamente, cualquier sesión que seguido este archivo debería auto-orientarse sola.

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

El manual de marca oficial (logo, banner, paleta, tipografía) vive en
[`TekoApp-Backend/.claude/documentation/brand/`](../TekoApp-Backend/.claude/documentation/brand/)
— es la fuente de verdad para los tres repos. Los tokens de diseño ya implementados en
`TekoApp-Web` (`src/design-system/tokens/tokens.json`, formato W3C Design Tokens) están pensados
para generar también un output Dart desde el mismo archivo cuando arranque este repo — ver
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

1. [`openspec/README.md`](openspec/README.md) — cómo está organizada esta carpeta y el flujo de
   trabajo spec-driven que se espera seguir.
2. [`openspec/project.md`](openspec/project.md) — contexto completo: qué aprendimos construyendo
   `TekoApp-Backend`/`TekoApp-Web` que aplica directo acá (auth, contrato de API, patrones a
   replicar y a evitar).
3. [`openspec/decisions.md`](openspec/decisions.md) — decisiones de arquitectura específicas de
   mobile, una por una, con su motivo.
4. [`openspec/specs/`](openspec/specs/) — el contrato de cada capacidad (auth, marketplace de
   servicios, pagos, notificaciones, etc.) tal como debería comportarse en Flutter.
5. [`openspec/changes/`](openspec/changes/) — el plan de implementación en fases, cada una con
   checkpoints concretos de "esto tiene que funcionar antes de seguir a la próxima fase".

## Contacto

José Panza — jpanza@bepsa.com.py

✨ *"Conectando talento con necesidad, donde sea, cuando sea."*
