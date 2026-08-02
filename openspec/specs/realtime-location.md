# Spec: Ubicación en tiempo real

## Contexto heredado

El backend ya tiene un `LocationsGateway` (Socket.io) para tracking de profesionales en vivo,
con histórico pesado en MongoDB usando índices `2dsphere` (geoespaciales). `TekoApp-Web` consume
esto para mostrar profesionales cercanos en un mapa (`features/locations/`).

**Riesgo ya identificado, sin confirmar** (ver `TekoApp-Web/.claude/documentation/architecture.md`,
sección de hallazgos del mapeo de API): el `LocationsGateway` podría estar verificando el JWT del
socket con una config de `JwtModule` que usa un secreto simétrico distinto del par RS256 de los
access tokens REST — si el handshake de socket falla en la práctica al implementar esto en mobile,
esta es la primera hipótesis a revisar (no asumir que es un bug del cliente mobile antes de
descartar esto).

## Comportamiento esperado

### Como profesional (emisor de ubicación)

- Mientras el perfil profesional está `isOnline: true`, enviar la posición actual del dispositivo
  periódicamente vía el socket de Locations (frecuencia a definir en la Fase 5 — balancear
  precisión vs. batería, no enviar en cada frame de GPS).
- Dejar de enviar posición al pasar a offline o cerrar la app — no seguir trackeando en background
  sin que el usuario lo sepa explícitamente (permisos de ubicación en background requieren
  disclosure explícito en ambas plataformas, revisar los requisitos de las stores al implementar).
- Pedir permiso de ubicación con el disclosure correcto (foreground vs. background) — Android e
  iOS difieren en cómo piden esto, no asumir que el flujo es idéntico entre plataformas.

### Como cliente (consumidor de ubicación)

- Ver profesionales cercanos disponibles en un mapa, con su posición actualizándose en vivo
  mientras la pantalla está abierta.
- Durante un servicio ACCEPTED/IN_PROGRESS, ver la posición en vivo del profesional asignado (caso
  de uso tipo "tu profesional está en camino").

## Fuera de alcance de esta spec

El detalle de qué librería de mapas usar (Google Maps SDK para Flutter es el candidato obvio dado
que el backend ya usa Google Maps API para geocoding, pero no está confirmado) — decidir en
`decisions.md` cuando se llegue a la Fase 5, no asumirlo de entrada.
