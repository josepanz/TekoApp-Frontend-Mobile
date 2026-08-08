# Graph Report - .  (2026-08-08)

## Corpus Check
- 210 files · ~156,284 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1358 nodes · 2253 edges · 100 communities (95 shown, 5 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 88
- Community 89
- Community 90
- Community 91
- Community 92
- Community 93
- Community 94
- Community 98

## God Nodes (most connected - your core abstractions)
1. `CLAUDE.md (config raíz)` - 25 edges
2. `Sesión 2 — Ecosistema .claude + desbloqueo FCM` - 20 edges
3. `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)` - 17 edges
4. `Sesión 3 — Fase 0001 bootstrap Flutter` - 14 edges
5. `Sesión 1 — Documentación SDD inicial` - 13 edges
6. `auth.md rules doc` - 13 edges
7. `flutter-architecture.md rules doc` - 11 edges
8. `test.md rules doc` - 11 edges
9. `SessionState` - 10 edges
10. `TekoApp-Backend (NestJS 10, Prisma, MongoDB, Redis)` - 10 edges

## Surprising Connections (you probably didn't know these)
- `E2E como test de widgets (no integration_test/) por falta de emulador/dispositivo` --conceptually_related_to--> `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)`  [INFERRED]
  .claude/rules/test.md → README.md
- `Formato Conventional Commits (tipo(alcance): descripción, en español)` --semantically_similar_to--> `Versionado con semantic-release a partir de Conventional Commits`  [INFERRED] [semantically similar]
  .claude/commands/commit.md → .github/workflows/release.yml
- `Notificaciones push (Firebase Cloud Messaging) — endpoints fcm-tokens` --conceptually_related_to--> `Desbloqueo de FCM del lado backend (SSE+WebPush+FCM real)`  [INFERRED]
  ARCHITECTURE.md → .claude/memory/sessions/session_2_ecosistema_claude_y_desbloqueo_fcm.md
- `Componentes compartidos — revisar variantes de TekoApp-Web/components/ui/` --references--> `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)`  [EXTRACTED]
  .claude/rules/design-system.md → README.md
- `shared/widgets/ — primitivos reusables (≈ components/ui/)` --references--> `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)`  [EXTRACTED]
  .claude/rules/flutter-architecture.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Contrato de autenticación (nonce + RSA-OAEP + Basic Auth cliente + scope + refresh)** — claude_rules_auth_rsa_oaep_login_flow, claude_rules_auth_no_decode_jwt, claude_rules_auth_refresh_interceptor, architecture_auth_contract [INFERRED 0.85]
- **Ecosistema .claude creado en conjunto (Sesión 2): reglas, agentes, memoria y comandos** — claude_claude_doc, claude_agents_code_reviewer_doc, claude_agents_testing_agent_doc, claude_agents_tdd_refactor_doc, claude_rules_test_doc, claude_rules_auth_doc, claude_memory_memory_doc, claude_commands_commit_doc [EXTRACTED 1.00]
- **Pipeline de release aditivo gateado por secrets (firma + publicación a stores)** — github_workflows_release_doc, github_workflows_release_secrets_gating, architecture_release_secrets_checklist, github_workflows_release_android_ios_publish [INFERRED 0.85]
- **Deliberate KISS scope-reduction pattern (pagination, geolocation, payment methods)** — openspec_decisions_pagination_first_page_only, openspec_decisions_geolocation_geolocator, changes_0004_payment_flow [EXTRACTED 1.00]
- **Native equivalents required for BFF-only patterns (RSA, Basic Auth secret, cookies)** — openspec_project_bff_patterns_not_replicated, openspec_decisions_secure_token_storage, openspec_decisions_rsa_oaep_encryption [EXTRACTED 1.00]
- **"Verify against the real running backend, don't trust docs alone" pattern** — changes_0005_locations_gateway_jwt_mismatch, openspec_specs_notifications_push, changes_0005_fcm_push_flow [INFERRED 0.85]

## Communities (100 total, 5 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (55): accent, accent100, accent200, accent300, accent400, accent50, accent500, accent600 (+47 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (37): additionalNotes, address, cancellationReason, cancelledAt, category, categoryId, color, completedAt (+29 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (32): CookieJar, Exception, CurrentPositionFetcher, DeviceLatLng, _fetchCurrentPosition, latitude, LocationFailure, LocationPermissionDeniedFailure (+24 more)

### Community 3 - "Community 3"
Cohesion: 0.10
Nodes (30): TekoApp-Web core/auth/session.ts (401 vs 5xx fix), BearerAuthInterceptor, Login screen with 3 distinguished error states, "Mi perfil" screen (view/edit profile + avatar upload), RefreshTokenInterceptor, Shared widgets: TekoButton, TekoCard, TekoAvatar, TekoBadge, TekoInput, tokens.generated.dart (hand-generated from tokens.json), Sesión 1 — Documentación SDD inicial (+22 more)

### Community 4 - "Community 4"
Cohesion: 0.08
Nodes (32): ProfileRepository, AvatarTooLargeFailure, AvatarUnsupportedTypeFailure, AvatarUploadFailure, AvatarUploadServiceFailure, ProfileFailure, ProfileServiceUnavailableFailure, ProfileValidationFailure (+24 more)

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (32): package:tekoapp_mobile/core/mode/app_mode.dart, package:tekoapp_mobile/core/mode/app_mode_provider.dart, package:tekoapp_mobile/features/professional_profile/data/professional_profile_repository.dart, package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart, package:tekoapp_mobile/features/professional_profile/models/professional_profile_failure.dart, package:tekoapp_mobile/features/professional_profile/models/professional_status.dart, package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart, package:tekoapp_mobile/features/professional_profile/widgets/professional_home_screen.dart (+24 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (28): api_client_provider.dart, app_mode.dart, ../data/professional_profile_repository.dart, apiClient, data, map, networkSmokeCheckProvider, response (+20 more)

### Community 7 - "Community 7"
Cohesion: 0.08
Nodes (28): watch, _MockDio, package:flutter_riverpod/flutter_riverpod.dart, package:tekoapp_mobile/core/api_client/api_client_provider.dart, package:tekoapp_mobile/features/professional_profile/providers/professional_onboarding_controller_provider.dart, package:tekoapp_mobile/features/services/providers/my_client_services_provider.dart, package:tekoapp_mobile/features/services/providers/my_professional_services_provider.dart, package:tekoapp_mobile/features/services/providers/respond_to_request_controller_provider.dart (+20 more)

### Community 8 - "Community 8"
Cohesion: 0.09
Nodes (33): Tres workflows CI/CD con propósitos distintos (ci/build/release), tdd-refactor agent doc, Flujo TDD de 6 fases (Orient→Diagnosis→Characterization Test→Plan→Execute→Spec Update), testing-agent doc, Generación/revisión de tests (AAA, mock del límite de red), context.md snapshot, Qué NO hacer — no asumir patrón BFF, no implementar FCM sin confirmar backend, memory.md protocolo de sesión (+25 more)

### Community 9 - "Community 9"
Cohesion: 0.07
Nodes (26): ../../../core/api_client/api_client_provider.dart, ../../../core/auth/cookie_jar_provider.dart, ../data/auth_repository.dart, ../data/categories_repository.dart, ../data/profile_repository.dart, ../data/services_repository.dart, CategoriesRepository, categoriesRepositoryProvider (+18 more)

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (28): Errores ya encontrados que esta app debería evitar (timezone, race conditions, listados vacíos, avatar URL, include anidado), Transiciones de estado esperan 409 (updateMany anti-TOCTOU), CLAUDE.md (config raíz), Estructura de carpetas lib/ planeada, graphify pendiente hasta que exista código en lib/, Un listado vacío es 200 con [], nunca 404, Nunca reimplementar lógica de negocio — cliente puro del backend, Stack decidido: Flutter/Riverpod/go_router/dio (+20 more)

### Community 11 - "Community 11"
Cohesion: 0.09
Nodes (27): Contrato de auth de 7 pasos (nonce→RSA-OAEP→login→tokens→refresh→scope→PUT /auth/me), Avatares — nunca cachear avatarUrl (S3 presignada, expira 900s), El contrato con el backend (identificadores, auth, avatares, envelope, 409, timezone), Dominio: marketplace de servicios de oficio geolocalizado, Notificaciones push (Firebase Cloud Messaging) — endpoints fcm-tokens, Excepción histórica: Services/ServiceRequests/PaymentMethodEntity/Payments/PaymentTransaction/Rating usan UUID como PK directa, Checklist de secrets a cargar (Android/iOS/stores) para release.yml, Tabla de stack decidido con motivo corto (+19 more)

### Community 12 - "Community 12"
Cohesion: 0.09
Nodes (25): .github/workflows/ci.yml (flutter analyze + test), go_router dummy public/protected routes + guard test, Decision: GitHub Actions CI/CD, 3 environments, Decision: dio HTTP client, Decision: Flutter 3 framework, Decision: geolocator, no interactive map picker yet, Decision: go_router for declarative routing/guards, Decision: online-only (no offline persistence) (+17 more)

### Community 13 - "Community 13"
Cohesion: 0.10
Nodes (23): updateProfileControllerProvider, uploadAvatarControllerProvider, _avatarErrorMessage, build, createState, dispose, _ensureControllersInitialized, _firstNameController (+15 more)

### Community 14 - "Community 14"
Cohesion: 0.10
Nodes (21): ChangeNotifier, ../../../core/auth/session_state.dart, features/auth/widgets/login_screen.dart, features/home/widgets/home_screen.dart, features/professional_profile/providers/my_professional_profile_provider.dart, features/professional_profile/widgets/professional_home_screen.dart, features/professional_profile/widgets/professional_onboarding_screen.dart, features/profile/widgets/profile_screen.dart (+13 more)

### Community 15 - "Community 15"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 16 - "Community 16"
Cohesion: 0.11
Nodes (18): ../../categories/models/service_type.dart, ../../categories/providers/service_types_provider.dart, ../../../core/location/current_location_provider.dart, _addressController, createState, _descriptionController, dispose, _formKey (+10 more)

### Community 17 - "Community 17"
Cohesion: 0.12
Nodes (16): ../config/env.dart, dart:convert, ClientBasicAuth, options, encryptLoginPayload, _publicKey, RsaEncryptor, package:basic_utils/basic_utils.dart (+8 more)

### Community 18 - "Community 18"
Cohesion: 0.11
Nodes (17): package:tekoapp_mobile/features/categories/models/category.dart, package:tekoapp_mobile/features/categories/models/service_type.dart, package:tekoapp_mobile/features/categories/providers/categories_provider.dart, package:tekoapp_mobile/features/categories/providers/service_types_provider.dart, package:tekoapp_mobile/features/services/widgets/request_service_screen.dart, container, dio, main (+9 more)

### Community 19 - "Community 19"
Cohesion: 0.12
Nodes (16): AsyncValue, auth_repository_provider.dart, build, loginControllerProvider, submit, build, createState, dispose (+8 more)

### Community 20 - "Community 20"
Cohesion: 0.15
Nodes (16): ConsumerWidget, Service, respondToRequestControllerProvider, serviceDetailProvider, serviceRequestsProvider, watch, _accept, build (+8 more)

### Community 21 - "Community 21"
Cohesion: 0.11
Nodes (17): ../../../core/auth/client_basic_auth.dart, ../../../core/auth/rsa_encryptor.dart, ../../../core/auth/token_storage_keys.dart, ../../../core/auth/user_summary.dart, accessTokenStorageKey, _apiClient, _classifyLogin, clearSession (+9 more)

### Community 22 - "Community 22"
Cohesion: 0.12
Nodes (17): ../../features/auth/data/auth_repository.dart, ../../features/auth/models/scope_failure.dart, ../../features/auth/providers/auth_repository_provider.dart, build, logout, refreshAfterLogin, _refreshScope, _restoreSession (+9 more)

### Community 23 - "Community 23"
Cohesion: 0.12
Nodes (16): FilledButton, Object?, Object? error,
  bool, package:tekoapp_mobile/core/auth/session_provider.dart, package:tekoapp_mobile/features/auth/models/login_failure.dart, package:tekoapp_mobile/features/auth/models/login_result.dart, package:tekoapp_mobile/features/auth/providers/login_controller_provider.dart, container (+8 more)

### Community 24 - "Community 24"
Cohesion: 0.12
Nodes (16): package:flutter_localizations/flutter_localizations.dart, package:tekoapp_mobile/features/services/widgets/my_services_screen.dart, package:tekoapp_mobile/features/services/widgets/service_detail_screen.dart, dio, main, _MockDio, pumpAndSettle, _pumpScreen (+8 more)

### Community 25 - "Community 25"
Cohesion: 0.15
Nodes (15): Analyzer exclusions for generated code, TekoApp-Web accessibility.md checklist (adapted to Flutter), Product decision: admin/backoffice mode on mobile or web-only, Hardcoded-string audit + explicit language selector, Catálogo es/en propio (flutter_localizations + intl), i18n.md rules doc, Traducir sobre la marcha, no acumular deuda de traducción, Flujo de textos e idiomas (.arb es/en, flutter gen-l10n) (+7 more)

### Community 26 - "Community 26"
Cohesion: 0.13
Nodes (13): available_services_provider.dart, dart:async, watch, build, submit, build, submit, build (+5 more)

### Community 27 - "Community 27"
Cohesion: 0.15
Nodes (14): PRs #41-#49 (TekoApp-Frontend-Mobile), Professional onboarding gate (mode selector + GET /professionals/me), Competing ServiceRequests flow (propose/accept), Pay-completed-service flow (method + server-computed amount + promo), Bidirectional rating flow, hide option once rated, Partial refund flow (available amount only, no full-amount assumption), Fase 0003 (marketplace de servicios) completa — 9 PRs #41-#49, Phase 0004 payments findings verified against real backend (+6 more)

### Community 28 - "Community 28"
Cohesion: 0.12
Nodes (16): conventional-changelog-conventionalcommits, description, devDependencies, conventional-changelog-conventionalcommits, semantic-release, @semantic-release/changelog, @semantic-release/exec, @semantic-release/git (+8 more)

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (15): @visibleForTesting, Color, ../../design_system/tokens.generated.dart, AppTheme, colorSchemeFrom, copyWith, dark, info (+7 more)

### Community 30 - "Community 30"
Cohesion: 0.12
Nodes (15): ../../categories/models/category.dart, ../../categories/providers/categories_provider.dart, createState, _descriptionController, dispose, _fixedRateController, _formKey, _hourlyRateController (+7 more)

### Community 31 - "Community 31"
Cohesion: 0.12
Nodes (15): categoryId, description, fixedRate, fromJson, hourlyRate, id, isAvailable, isOnline (+7 more)

### Community 32 - "Community 32"
Cohesion: 0.16
Nodes (13): package:flutter/services.dart, package:tekoapp_mobile/features/auth/data/auth_repository.dart, package:tekoapp_mobile/features/auth/widgets/login_screen.dart, package:tekoapp_mobile/features/home/widgets/home_screen.dart, package:tekoapp_mobile/features/profile/widgets/profile_screen.dart, Route /perfil, main, _MockDio (+5 more)

### Community 33 - "Community 33"
Cohesion: 0.14
Nodes (12): package:flutter_test/flutter_test.dart, package:mocktail/mocktail.dart, package:tekoapp_mobile/core/auth/secure_cookie_storage.dart, package:tekoapp_mobile/features/services/providers/service_requests_provider.dart, main, secureStorage, storage, main (+4 more)

### Community 34 - "Community 34"
Cohesion: 0.14
Nodes (13): package:tekoapp_mobile/app.dart, package:tekoapp_mobile/core/auth/session_state.dart, package:tekoapp_mobile/features/professional_profile/widgets/professional_onboarding_screen.dart, Route /login, _authenticatedUser, build, _fixed, main (+5 more)

### Community 35 - "Community 35"
Cohesion: 0.16
Nodes (10): app.dart, main, package:flutter/material.dart, package:tekoapp_mobile/core/theme/app_theme.dart, package:tekoapp_mobile/shared/widgets/teko_avatar.dart, package:tekoapp_mobile/shared/widgets/teko_badge.dart, package:tekoapp_mobile/shared/widgets/teko_card.dart, main (+2 more)

### Community 36 - "Community 36"
Cohesion: 0.20
Nodes (12): TekoApp-Backend notifications-push-architecture.md, FCM push registration/deregistration + notification handling flow, LocationsGateway JWT secret mismatch hypothesis to verify, Push notifications: SSE + Web Push + FCM implementado en backend, Desbloqueo de FCM del lado backend (SSE+WebPush+FCM real), Decision: Firebase Cloud Messaging for push, referenceId (UUID) vs internal id — never expose internal id, Deep linking from notification via referenceId (+4 more)

### Community 37 - "Community 37"
Cohesion: 0.14
Nodes (13): DateTime, double?, createdAt, fromJson, id, message, professionalId, proposedHours (+5 more)

### Community 38 - "Community 38"
Cohesion: 0.22
Nodes (12): SessionAuthenticated, SessionServiceUnavailable, SessionState, SessionUnauthenticated, SessionUnknown, user, _MockAuthRepository, package:tekoapp_mobile/core/auth/user_summary.dart (+4 more)

### Community 39 - "Community 39"
Cohesion: 0.14
Nodes (13): _apiClient, cancelService, _classify, completeService, createService, fetchAvailableServices, fetchMyServices, fetchServiceDetail (+5 more)

### Community 40 - "Community 40"
Cohesion: 0.26
Nodes (13): Dio, AuthRepository, Mock, _MockAuthRepository, _MockAuthRepository, _MockDio, _MockDio, _MockAuthRepository (+5 more)

### Community 41 - "Community 41"
Cohesion: 0.15
Nodes (11): accessToken, TokenStorageKeys, allowedAvatarMimeTypes, _apiClient, _classify, maxAvatarBytes, updateMe, uploadAvatar (+3 more)

### Community 42 - "Community 42"
Cohesion: 0.19
Nodes (12): availableServicesProvider, proposeOnServiceControllerProvider, AvailableServicesScreen, _AvailableServicesScreenState, build, createState, _errorMessage, _propose (+4 more)

### Community 43 - "Community 43"
Cohesion: 0.19
Nodes (12): myProfessionalServicesProvider, serviceTransitionControllerProvider, _actingServiceId, build, _complete, createState, ProfessionalServicesScreen, _ProfessionalServicesScreenState (+4 more)

### Community 44 - "Community 44"
Cohesion: 0.15
Nodes (11): package:tekoapp_mobile/core/api_client/api_client.dart, package:tekoapp_mobile/features/categories/data/categories_repository.dart, package:tekoapp_mobile/features/services/providers/request_service_controller_provider.dart, dio, listResponse, main, repository, container (+3 more)

### Community 45 - "Community 45"
Cohesion: 0.18
Nodes (9): categories_repository_provider.dart, ../../../core/api_client/api_client.dart, _apiClient, fetchCategories, fetchServiceTypes, watch, watch, ../models/category.dart (+1 more)

### Community 46 - "Community 46"
Cohesion: 0.20
Nodes (12): ConsumerState, ConsumerStatefulWidget, currentPositionFetcherProvider, LoginScreen, _LoginScreenState, serviceTypesProvider, requestServiceControllerProvider, build (+4 more)

### Community 47 - "Community 47"
Cohesion: 0.17
Nodes (11): IconData?, build, icon, label, loading, onPressed, size, TekoButtonSize (+3 more)

### Community 48 - "Community 48"
Cohesion: 0.17
Nodes (11): _category, dio, ensureVisible, enterText, _fillValidForm, main, pumpAndSettle, _pumpScreen (+3 more)

### Community 49 - "Community 49"
Cohesion: 0.18
Nodes (9): api_client.dart, ../auth/cookie_jar_provider.dart, ApiClient, apiClientProvider, _apiClient, _classify, fetchMe, register (+1 more)

### Community 50 - "Community 50"
Cohesion: 0.27
Nodes (11): AsyncNotifier, sessionProvider, LoginController, profileRepositoryProvider, UpdateProfileController, UploadAvatarController, ProposeOnServiceController, RequestServiceController (+3 more)

### Community 51 - "Community 51"
Cohesion: 0.20
Nodes (9): client_basic_auth.dart, onRequest, _secureStorage, _dio, _excludedPaths, onError, _secureStorage, package:flutter_secure_storage/flutter_secure_storage.dart (+1 more)

### Community 52 - "Community 52"
Cohesion: 0.18
Nodes (10): ErrorInterceptorHandler, package:tekoapp_mobile/core/auth/refresh_token_interceptor.dart, dio, handler, interceptor, main, _MockDio, _MockErrorHandler (+2 more)

### Community 53 - "Community 53"
Cohesion: 0.18
Nodes (10): int?, Category, color, fromJson, icon, id, name, parentCategoryId (+2 more)

### Community 54 - "Community 54"
Cohesion: 0.18
Nodes (10): build, controller, enabled, initialValue, keyboardType, label, maxLines, obscureText (+2 more)

### Community 55 - "Community 55"
Cohesion: 0.27
Nodes (8): ../../../core/api_client/network_smoke_check_provider.dart, ../../../core/mode/app_mode.dart, ../../../core/mode/app_mode_provider.dart, package:go_router/go_router.dart, ../providers/my_professional_profile_provider.dart, ../../services/widgets/available_services_screen.dart, ../../../shared/widgets/async_state_view.dart, ../../../shared/widgets/teko_button.dart

### Community 56 - "Community 56"
Cohesion: 0.20
Nodes (9): double get, avatarUrl, build, _diameter, _fallback, name, semanticLabel, size (+1 more)

### Community 57 - "Community 57"
Cohesion: 0.20
Nodes (9): AsyncStateView, build, data, emptyMessage, errorMessage, hasError, isEmpty, isLoading (+1 more)

### Community 58 - "Community 58"
Cohesion: 0.20
Nodes (9): _MockSecureStorage, package:tekoapp_mobile/core/auth/bearer_auth_interceptor.dart, package:tekoapp_mobile/core/auth/token_storage_keys.dart, RequestInterceptorHandler, handler, interceptor, main, _MockHandler (+1 more)

### Community 59 - "Community 59"
Cohesion: 0.22
Nodes (8): ../auth/bearer_auth_interceptor.dart, ../auth/refresh_token_interceptor.dart, Dio get, envelope_interceptor.dart, _buildDefaultDio, _dio, raw, package:dio_cookie_manager/dio_cookie_manager.dart

### Community 60 - "Community 60"
Cohesion: 0.25
Nodes (7): ../../../core/auth/session_provider.dart, dart:typed_data, build, submit, build, submit, profile_repository_provider.dart

### Community 61 - "Community 61"
Cohesion: 0.22
Nodes (7): onResponse, package:dio/dio.dart, package:tekoapp_mobile/features/services/providers/propose_on_service_controller_provider.dart, container, dio, main, _MockDio

### Community 62 - "Community 62"
Cohesion: 0.22
Nodes (8): delete, deleteAll, init, read, SecureCookieStorage, _secureStorage, write, Storage

### Community 63 - "Community 63"
Cohesion: 0.22
Nodes (8): avatarUrl, email, firstName, fromJson, lastName, phoneNumber, referenceId, UserSummary

### Community 64 - "Community 64"
Cohesion: 0.22
Nodes (8): _MockHandler, package:tekoapp_mobile/core/api_client/envelope_interceptor.dart, ResponseInterceptorHandler, buildResponse, handler, interceptor, main, _MockHandler

### Community 65 - "Community 65"
Cohesion: 0.22
Nodes (8): package:tekoapp_mobile/features/services/widgets/professional_services_screen.dart, dio, main, _MockDio, pumpAndSettle, _pumpScreen, pumpWidget, _serviceJson

### Community 66 - "Community 66"
Cohesion: 0.25
Nodes (7): apiBaseUrl, basicAuthClientId, basicAuthClientSecret, Env, isProduction, static const bool, static const String

### Community 67 - "Community 67"
Cohesion: 0.25
Nodes (6): profile, ref, ref, ../models/service.dart, ../../professional_profile/providers/my_professional_profile_provider.dart, return

### Community 68 - "Community 68"
Cohesion: 0.29
Nodes (6): ../../core/theme/app_theme.dart, build, label, TekoBadge, TekoBadgeVariant, variant

### Community 69 - "Community 69"
Cohesion: 0.29
Nodes (6): DioException, package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart, container, dio, main, _MockDio

### Community 70 - "Community 70"
Cohesion: 0.29
Nodes (6): EdgeInsetsGeometry?, build, child, padding, TekoCard, Widget

### Community 71 - "Community 71"
Cohesion: 0.33
Nodes (7): categoriesProvider, professionalOnboardingControllerProvider, build, ProfessionalOnboardingScreen, _ProfessionalOnboardingScreenState, _submit, Route /profesional

### Community 72 - "Community 72"
Cohesion: 0.29
Nodes (7): _ProfessionalActiveBody, _ServiceDetailBody, ServiceStatusBadge, TekoAvatar, TekoButton, TekoInput, StatelessWidget

### Community 73 - "Community 73"
Cohesion: 0.33
Nodes (6): myClientServicesProvider, build, MyServicesScreen, ../providers/my_client_services_provider.dart, service_status_badge.dart, ../../../shared/widgets/teko_card.dart

### Community 74 - "Community 74"
Cohesion: 0.29
Nodes (6): accept, build, RespondToRequestController, ../models/request_status.dart, service_detail_provider.dart, service_requests_provider.dart

### Community 75 - "Community 75"
Cohesion: 0.29
Nodes (6): package:tekoapp_mobile/features/services/providers/service_transition_controller_provider.dart, container, dio, main, _MockDio, _serviceJson

### Community 76 - "Community 76"
Cohesion: 0.33
Nodes (5): ../../../l10n/app_localizations.dart, build, status, ../models/service_status.dart, ../../../shared/widgets/teko_badge.dart

### Community 77 - "Community 77"
Cohesion: 0.33
Nodes (5): accessToken, LoginResult, requiresNewPassword, success, String?

### Community 78 - "Community 78"
Cohesion: 0.33
Nodes (5): expired, fromJson, RequestStatus, toJson, pending,
  accepted,
  rejected,

### Community 79 - "Community 79"
Cohesion: 0.60
Nodes (4): class, ProfessionalProfileFailure, ProfessionalProfileServiceUnavailableFailure, ProfessionalProfileValidationFailure

### Community 80 - "Community 80"
Cohesion: 0.40
Nodes (4): ElevatedButton, package:tekoapp_mobile/shared/widgets/teko_button.dart, main, wrap

### Community 81 - "Community 81"
Cohesion: 0.40
Nodes (5): FlutterSecureStorage, _MockSecureStorage, _MockSecureStorage, _MockSecureStorage, _MockSecureStorage

### Community 82 - "Community 82"
Cohesion: 0.40
Nodes (4): cookieJarProvider, package:cookie_jar/cookie_jar.dart, PersistCookieJar, secure_cookie_storage.dart

### Community 83 - "Community 83"
Cohesion: 0.40
Nodes (4): fromJson, id, name, ServiceType

### Community 84 - "Community 84"
Cohesion: 0.40
Nodes (4): fromJson, ProfessionalStatus, suspended, pending,
  approved,
  rejected,

### Community 85 - "Community 85"
Cohesion: 0.40
Nodes (4): cancelled, fromJson, ServiceStatus, pending,
  accepted,
  inProgress,
  completed,

### Community 86 - "Community 86"
Cohesion: 0.50
Nodes (4): flutter_lints package (lint base), Decision: flutter_test + mocktail for testing, flutter_lints ^4.0.0, mocktail ^1.0.4

### Community 87 - "Community 87"
Cohesion: 0.50
Nodes (3): FormState, package:tekoapp_mobile/shared/widgets/teko_input.dart, main

### Community 88 - "Community 88"
Cohesion: 0.50
Nodes (4): Interceptor, EnvelopeInterceptor, BearerAuthInterceptor, RefreshTokenInterceptor

### Community 89 - "Community 89"
Cohesion: 0.50
Nodes (3): package:flutter/painting.dart, package:tekoapp_mobile/design_system/tokens.generated.dart, main

### Community 91 - "Community 91"
Cohesion: 1.00
Nodes (3): @immutable, TekoSemanticColors, ThemeExtension

## Ambiguous Edges - Review These
- `Explicitly pending/undecided items` → `Maps SDK choice (Google Maps candidate) — undecided`  [AMBIGUOUS]
  openspec/decisions.md · relation: conceptually_related_to

## Knowledge Gaps
- **584 isolated node(s):** `XCTest`, `_protectedPaths`, `_professionalGatedPaths`, `refreshListenable`, `notify` (+579 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Explicitly pending/undecided items` and `Maps SDK choice (Google Maps candidate) — undecided`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Service` connect `Community 20` to `Community 1`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `ProfessionalStatus` connect `Community 84` to `Community 31`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Why does `Category` connect `Community 53` to `Community 16`, `Community 30`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `XCTest`, `_protectedPaths`, `_professionalGatedPaths` to the rest of the system?**
  _584 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.03571428571428571 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05263157894736842 - nodes in this community are weakly interconnected._