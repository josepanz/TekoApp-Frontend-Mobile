# CP-LOC — Ubicación exacta del profesional asignado y aviso de aproximada

Repo: Mobile (MOB). Trazabilidad general: plan maestro M8 (Tracking en vivo), commit `feat(locations): seguir la ubicación exacta del profesional asignado vía exactLocationUpdated`.
Precondición común: socket de ubicaciones y repositorio falsos (fakes/mocktail); sin red ni backend.

## CP-MOB-LOC-001 — Suscribe a la sala del profesional al montar

| Campo | Contenido |
|---|---|
| Título | Al montar el provider se suscribe a la sala con el id interno del profesional |
| Tipo / Nivel | unitaria · provider |
| Prioridad | P2 |
| Trazabilidad | M8 |
| Precondiciones | Socket falso; `ProviderContainer` con overrides |
| Pasos | 1. Leer `assignedProfessionalLocationProvider(2)`. 2. Revisar las suscripciones registradas. |
| Datos de prueba | Id interno de profesional `2` |
| Resultado esperado | `subscribed == [2]` y `unsubscribed` vacío |
| Automatizado en | `test/features/locations/providers/assigned_professional_location_provider_test.dart` — `se suscribe al montar con el id interno del profesional` (grupo `suscripción a la sala del profesional`) |

## CP-MOB-LOC-002 — Desuscribe al dispose

| Campo | Contenido |
|---|---|
| Título | Al cerrar la escucha del provider se desuscribe de la sala |
| Tipo / Nivel | unitaria · provider |
| Prioridad | P2 |
| Trazabilidad | M8 |
| Precondiciones | Igual que CP-MOB-LOC-001 |
| Pasos | 1. Escuchar el provider. 2. Cerrar la suscripción. 3. Revisar las desuscripciones. |
| Datos de prueba | Id `2` |
| Resultado esperado | `unsubscribed == [2]` |
| Automatizado en | `test/features/locations/providers/assigned_professional_location_provider_test.dart` — `se desuscribe al dispose` |

## CP-MOB-LOC-003 — Cambio de profesional cierra la sala anterior y abre la nueva

| Campo | Contenido |
|---|---|
| Título | Al cambiar el profesional se desuscribe del anterior y se suscribe al nuevo |
| Tipo / Nivel | unitaria · provider |
| Prioridad | P2 |
| Trazabilidad | M8 |
| Precondiciones | Dos ids de profesional |
| Pasos | 1. Montar con el primero. 2. Montar con el segundo. 3. Revisar las llamadas. |
| Datos de prueba | Dos ids definidos en el test |
| Resultado esperado | Desuscripción del anterior y suscripción del nuevo |
| Automatizado en | `test/features/locations/providers/assigned_professional_location_provider_test.dart` — `al cambiar de profesional se cierra el anterior y abre el nuevo` |

## CP-MOB-LOC-004 — Aplica exactLocationUpdated del asignado e ignora otros

| Campo | Contenido |
|---|---|
| Título | Aplica la ubicación exacta del profesional asignado e ignora la de otro profesional |
| Tipo / Nivel | unitaria · provider |
| Prioridad | P1 |
| Trazabilidad | M8 |
| Precondiciones | Stream `exactLocationUpdated` controlable |
| Pasos | 1. Emitir evento del asignado y verificar el estado. 2. Emitir evento de otro profesional y verificar que no cambia. |
| Datos de prueba | Coordenadas del test |
| Resultado esperado | Estado actualizado solo con el asignado |
| Automatizado en | `test/features/locations/providers/assigned_professional_location_provider_test.dart` — `se actualiza con exactLocationUpdated del profesional asignado` y `ignora eventos exactos de otro profesional` |

## CP-MOB-LOC-005 — Fallback a aproximada ante subscriptionError

| Campo | Contenido |
|---|---|
| Título | Ante `subscriptionError` del profesional asignado cae a la posición aproximada; el error de otro profesional no activa el fallback |
| Tipo / Nivel | unitaria · provider |
| Prioridad | P1 |
| Trazabilidad | M8; degradación controlada |
| Precondiciones | Stream `subscriptionError` controlable; repositorio con última ubicación conocida |
| Pasos | 1. Emitir `subscriptionError` del asignado y verificar el fallback. 2. Repetir con otro profesional. |
| Datos de prueba | Ids y coordenadas del test |
| Resultado esperado | Fallback activo solo para el asignado |
| Automatizado en | `test/features/locations/providers/assigned_professional_location_provider_test.dart` — `ante subscriptionError cae a la posición aproximada` y `un subscriptionError de otro profesional no activa el fallback` |

## CP-MOB-LOC-006 — Servicio socket suscribe antes de conectar y re-suscribe al reconectar

| Campo | Contenido |
|---|---|
| Título | Suscribir antes de conectar emite al conectarse; tras reconectar re-suscribe; unsubscribe retira la sala de las re-suscripciones |
| Tipo / Nivel | unitaria · servicio |
| Prioridad | P1 |
| Trazabilidad | M8 (WS subscribe/unsubscribe); M-03 |
| Precondiciones | Socket.IO falso en el test |
| Pasos | 1. Suscribir y luego conectar. 2. Simular reconexión. 3. Desuscribir y reconectar. |
| Datos de prueba | Id de profesional del test |
| Resultado esperado | Emisión al conectar, re-emisión al reconectar, ninguna tras unsubscribe |
| Automatizado en | `test/core/realtime/locations_socket_service_test.dart` — `suscribir antes de conectar emite al conectarse`, `re-suscribe tras reconectar` y `unsubscribe saca al profesional de las re-suscripciones` (grupo `SocketIoLocationsSocketService — salas de ubicación exacta`) |

## CP-MOB-LOC-007 — Servicio expone exactLocationUpdated y subscriptionError como streams

| Campo | Contenido |
|---|---|
| Título | El servicio expone ambos eventos como streams |
| Tipo / Nivel | unitaria · servicio |
| Prioridad | P2 |
| Trazabilidad | M8 |
| Precondiciones | Igual que CP-MOB-LOC-006 |
| Pasos | 1. Emitir cada evento desde el socket falso. 2. Escuchar el stream correspondiente. |
| Datos de prueba | Payloads del test |
| Resultado esperado | Cada evento llega por su stream |
| Automatizado en | `test/core/realtime/locations_socket_service_test.dart` — `expone exactLocationUpdated y subscriptionError como streams` |

## CP-MOB-LOC-008 — El mapa muestra el aviso de ubicación aproximada

| Campo | Contenido |
|---|---|
| Título | El mapa de profesionales cercanos muestra "Ubicación aproximada · solo profesionales en línea" |
| Tipo / Nivel | funcional · widget |
| Prioridad | P2 |
| Trazabilidad | M8; privacidad (la ubicación de cercanos es aproximada) |
| Precondiciones | `mapCenterProvider` y controller de cercanos sobreescritos; locale `es` |
| Pasos | 1. Montar `NearbyProfessionalsMapScreen`. 2. Buscar la key del aviso y el texto. |
| Datos de prueba | Centro -25.3, -57.6; un profesional fixture |
| Resultado esperado | Aviso presente (key `nearby_professionals_approximate_notice`) con el texto exacto |
| Automatizado en | `test/features/locations/widgets/nearby_professionals_map_screen_test.dart` — `muestra el aviso de ubicación aproximada sobre el mapa` |
