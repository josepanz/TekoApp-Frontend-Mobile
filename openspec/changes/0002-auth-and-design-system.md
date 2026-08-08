# Fase 0002 — Auth completo + sistema de diseño

## Antes de empezar

Leer: `specs/auth-and-session.md`, `specs/api-client.md`, `specs/design-system.md`.

## Objetivo

Login/logout/sesión funcionando de punta a punta contra el backend real, con la app ya vestida
con la paleta/tipografía de marca (no con los colores default de Flutter).

## Tareas — Auth

- [x] Confirmar en `decisions.md` el paquete de almacenamiento seguro de tokens (candidato:
      `flutter_secure_storage`) y el paquete de cifrado RSA-OAEP (candidato: `pointycastle`) —
      **verificar que el padding OAEP produzca un resultado que el backend descifre
      correctamente antes de dar esto por resuelto** (probar contra el backend local real, no
      solo contra una implementación RSA genérica — el detalle exacto del padding importa). —
      verificado empíricamente con un round-trip cross-language (pointycastle → Node), no solo
      leyendo RFCs. `refreshToken` viaja solo como cookie httpOnly (hallazgo real, no asumido) →
      `cookie_jar` + adapter sobre `flutter_secure_storage`.
- [x] Implementar el flujo completo: `POST /auth/nonce` → cifrar → `POST /auth/login` → guardar
      tokens → `GET /auth/scope` → navegar a home. — requirió agregar `GET /auth/public-key` al
      backend (mobile no tiene BFF para guardar la clave server-side, ver
      josepanz/TekoApp-Backend#23).
- [x] Interceptor de `dio`: adjuntar Bearer token, refresh automático en 401 (ver
      `specs/api-client.md`). — `BearerAuthInterceptor` + `RefreshTokenInterceptor`.
- [x] Pantalla de login con los 3 estados de error distinguidos (credenciales inválidas / sin
      conexión / servidor no disponible) — ver `specs/auth-and-session.md`.
- [x] Logout: limpiar tokens, navegar a login. — `AuthRepository.clearSession()` limpia
      `accessToken` + la cookie `refreshToken`; la navegación a `/login` la dispara sola el guard
      de `go_router` (`refreshListenable` en `app.dart`, ver `openspec/decisions.md`).
- [ ] Pantalla "Mi perfil": ver + editar nombre/apellido/teléfono + avatar (`PUT /auth/me`,
      `POST /uploads/avatar`) — ver `project.md` sobre `avatarKey` vs `avatarUrl`.

## Tareas — Sistema de diseño

- [x] Resolver la generación del output Dart desde `tokens.json` (ver `specs/design-system.md`) —
      generado a mano con un script Node de un solo uso (OKLCH→sRGB, ver `openspec/decisions.md`).
      **Pendiente real**: agregar el formato nuevo a `TekoApp-Web/src/design-system/tokens/build.mjs`
      para que se regenere solo — toca el OTRO repo, no se hizo en esta sesión sin pedido explícito.
- [x] `ThemeData` de Flutter (claro + oscuro) armado desde esos tokens — nunca colores
      hardcodeados en widgets. `core/theme/app_theme.dart`, colores semánticos extra
      (éxito/alerta/info) vía `TekoSemanticColors` (`ThemeExtension`).
- [ ] Widgets base compartidos en `shared/`: Button, Card, Avatar, Badge, Input — con las
      variantes que ya existen en `TekoApp-Web/src/components/ui/` como referencia de qué
      variantes hacen falta (no reinventar desde cero qué botones/estados existen).
- [x] Tipografía Poppins cargada (4 pesos) y aplicada como default de la app. — vía `google_fonts`
      (runtime, no asset local empaquetado — ver `decisions.md`).

## Checkpoint de salida

- [ ] Login real contra el backend local funciona con una cuenta de prueba real (ver
      `TekoApp-Backend/prisma/seed.ts` para credenciales de seed conocidas).
- [ ] Cerrar la app y volver a abrirla mantiene la sesión (tokens persistidos correctamente).
- [ ] Forzar un access token vencido (esperar su expiración o modificarlo manualmente) y confirmar
      que el refresh automático funciona sin que el usuario note nada.
- [ ] La UI completa (login + perfil) usa los tokens de diseño de marca — comparar visualmente
      contra `TekoApp-Web` corriendo en paralelo, deberían verse como "la misma marca en otra
      plataforma", no como una app distinta.
- [ ] Subida de avatar funciona de punta a punta (sube, se persiste la key, se muestra la URL
      resuelta al volver a pedir el perfil).
