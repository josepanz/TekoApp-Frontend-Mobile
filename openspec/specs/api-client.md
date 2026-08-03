# Spec: Cliente de API

## Comportamiento esperado

Un único punto centralizado de configuración de `dio` (equivalente a `core/api-client/client.ts`
de `TekoApp-Web`) del que dependen todos los repositorios/servicios de datos de la app. Nunca
instanciar un `Dio()` suelto por feature.

### Responsabilidades del cliente centralizado

1. **Base URL**: configurable por ambiente (dev/qa/prod) — nunca hardcodeada en el código de
   features, vive en un archivo de configuración/env único.
2. **Adjuntar `Authorization: Bearer <accessToken>`** a toda request autenticada, leyendo el token
   del almacenamiento seguro (ver `specs/auth-and-session.md`).
3. **Desenvolver el envelope del backend**: toda respuesta exitosa viene como
   `{ success, data, message, timestamp, path }` — el cliente centralizado desenvuelve `data`
   antes de devolver el resultado a quien llamó, igual que `isBackendEnvelope()` en
   `TekoApp-Web/core/api-client/client.ts`. Ningún código de feature debería tener que lidiar con
   el envelope.
4. **Interceptor de refresh** (ver `specs/auth-and-session.md`) — un 401 dispara refresh + retry
   automático, transparente para el código que hizo la request original.
5. **Manejo de errores tipado**: un tipo de error propio (equivalente a `ApiError` de
   `TekoApp-Web`) que expone `statusCode` + `message` + el body crudo, para que la UI pueda
   distinguir 400 (validación) de 403 (permisos) de 409 (conflicto de estado, ver `project.md`) de
   5xx (servicio no disponible).
6. **Nunca placeholder de datos con mocks en producción** — si en desarrollo se necesita un fake
   backend (para poder avanzar UI mientras el backend real no está disponible), que sea un
   mecanismo explícito y removible (interceptor de dio que se activa solo con una flag de
   ambiente), nunca código de producción con datos hardcodeados "por las dudas".

### Generación de tipos desde el backend

`TekoApp-Web` genera sus tipos TypeScript automáticamente desde el Swagger del backend
(`pnpm generate:api-types`, usando `openapi-typescript`) — nunca escribe DTOs a mano. Evaluar el
equivalente en Dart antes de escribir un solo modelo a mano: existen generadores de clientes Dart
desde OpenAPI (ej. `openapi-generator-cli` con el generador `dart-dio`, u otros activos al momento
de implementar — verificar cuál está mantenido cuando se llegue a esta tarea, el ecosistema
cambia). Si no se encuentra un generador confiable, la alternativa es escribir los modelos a mano
pero **documentar explícitamente esa decisión** en `decisions.md` (no dejarlo como un default
silencioso) porque implica mantenimiento manual cada vez que el backend cambia un DTO.

### Paginación

Los listados del backend devuelven `{ data: T[], pagination: { total, page, pageSize, totalPages
} }` — replicar este contrato en los modelos de respuesta paginada de mobile, no inventar una
forma distinta.

### Nunca confundir "lista vacía" con "error"

Ver `project.md` — un `200` con `data: []` es un resultado válido, no dispara ningún manejo de
error. La UI muestra un estado vacío ("no hay servicios todavía"), no un mensaje de error.
