# Graph Report - TekoApp-Frontend-Mobile  (2026-08-08)

## Corpus Check
- 223 files · ~168,363 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1740 nodes · 2909 edges · 114 communities (109 shown, 5 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `63021b58`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- tokens.generated.dart
- service.dart
- auth_repository_test.dart
- openspec/README.md
- upload_avatar_controller_provider_test.dart
- professional_home_screen_test.dart
- login_screen.dart
- _MockDio
- Sesión 2 — Ecosistema .claude + desbloqueo FCM
- services_repository_test.dart
- TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)
- CLAUDE.md (config raíz)
- openspec/decisions.md
- profile_screen.dart
- app.dart
- AppDelegate
- request_service_screen.dart
- rsa_encryptor_test.dart
- request_service_screen_test.dart
- payment_history_screen_test.dart
- rateControllerProvider
- auth_repository.dart
- session_provider.dart
- login_screen_test.dart
- my_services_screen_test.dart
- openspec/specs/i18n.md
- service_transition_controller_provider.dart
- openspec/specs/services-marketplace.md
- devDependencies
- app_theme.dart
- professional_onboarding_screen.dart
- professional_profile.dart
- app_redirect_test.dart
- package:mocktail/mocktail.dart
- pay_service_screen.dart
- package:flutter_test/flutter_test.dart
- openspec/changes/0005-realtime-and-push.md
- service_request.dart
- session_provider_test.dart
- services_repository.dart
- Mock
- profile_repository.dart
- available_services_screen.dart
- professional_services_screen.dart
- package:tekoapp_mobile/core/api_client/api_client.dart
- ../../../core/api_client/api_client.dart
- ConsumerState
- teko_button.dart
- professional_onboarding_screen_test.dart
- professional_profile_repository.dart
- sessionProvider
- refresh_token_interceptor.dart
- refresh_token_interceptor_test.dart
- category.dart
- teko_input.dart
- package:go_router/go_router.dart
- payment.dart
- async_state_view.dart
- bearer_auth_interceptor_test.dart
- api_client.dart
- upload_avatar_controller_provider.dart
- package:dio/dio.dart
- secure_cookie_storage.dart
- user_summary.dart
- envelope_interceptor_test.dart
- professional_services_screen_test.dart
- env.dart
- package:flutter_riverpod/flutter_riverpod.dart
- dart:async
- add_payment_method_screen.dart
- StatelessWidget
- payment_method.dart
- payment_detail_screen.dart
- payment_history_screen.dart
- respond_to_request_controller_provider.dart
- service_transition_controller_provider_test.dart
- package:flutter/material.dart
- String?
- request_status.dart
- current_location_provider.dart
- pay_service_controller_provider.dart
- ratings_repository.dart
- rating.dart
- service_type.dart
- payments_repository.dart
- service_status.dart
- rate_controller_provider.dart
- FormState
- pay_service_screen_test.dart
- tokens.json (W3C Design Tokens) como única fuente de verdad de marca
- MainActivity
- promotions_repository.dart
- Cost-saving AI agent workflow pattern
- replace-version.sh
- Custom lint rules (prefer_single_quotes, require_trailing_commas, avoid_print)
- iOS LaunchImage asset customization
- payment_method_controller_provider.dart
- add_payment_method_screen_test.dart
- payments_repository_test.dart
- ratings_repository_test.dart
- ConsumerWidget
- promotion_apply_result.dart
- promotion_validation.dart
- payment_method_controller_provider_test.dart
- promotions_repository_test.dart
- _ProfileScreenState
- rating_type.dart
- payment_failure.dart
- my_client_services_provider_test.dart
- promotion.dart

## God Nodes (most connected - your core abstractions)
1. `CLAUDE.md (config raíz)` - 25 edges
2. `Sesión 2 — Ecosistema .claude + desbloqueo FCM` - 20 edges
3. `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)` - 17 edges
4. `Sesión 3 — Fase 0001 bootstrap Flutter` - 14 edges
5. `Sesión 1 — Documentación SDD inicial` - 13 edges
6. `auth.md rules doc` - 13 edges
7. `flutter-architecture.md rules doc` - 11 edges
8. `test.md rules doc` - 11 edges
9. `ApiClient` - 10 edges
10. `SessionState` - 10 edges

## Surprising Connections (you probably didn't know these)
- `E2E como test de widgets (no integration_test/) por falta de emulador/dispositivo` --conceptually_related_to--> `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)`  [INFERRED]
  .claude/rules/test.md → README.md
- `Formato Conventional Commits (tipo(alcance): descripción, en español)` --semantically_similar_to--> `Versionado con semantic-release a partir de Conventional Commits`  [INFERRED] [semantically similar]
  .claude/commands/commit.md → .github/workflows/release.yml
- `Notificaciones push (Firebase Cloud Messaging) — endpoints fcm-tokens` --conceptually_related_to--> `Desbloqueo de FCM del lado backend (SSE+WebPush+FCM real)`  [INFERRED]
  ARCHITECTURE.md → .claude/memory/sessions/session_2_ecosistema_claude_y_desbloqueo_fcm.md
- `Prohibido usar America/Asuncion — Ley 7127 abolió DST pero tzdata puede desfasar ±1h` --conceptually_related_to--> `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)`  [INFERRED]
  .claude/rules/datetime.md → README.md
- `Componentes compartidos — revisar variantes de TekoApp-Web/components/ui/` --references--> `TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)`  [EXTRACTED]
  .claude/rules/design-system.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Contrato de autenticación (nonce + RSA-OAEP + Basic Auth cliente + scope + refresh)** — claude_rules_auth_rsa_oaep_login_flow, claude_rules_auth_no_decode_jwt, claude_rules_auth_refresh_interceptor, architecture_auth_contract [INFERRED 0.85]
- **Ecosistema .claude creado en conjunto (Sesión 2): reglas, agentes, memoria y comandos** — claude_claude_doc, claude_agents_code_reviewer_doc, claude_agents_testing_agent_doc, claude_agents_tdd_refactor_doc, claude_rules_test_doc, claude_rules_auth_doc, claude_memory_memory_doc, claude_commands_commit_doc [EXTRACTED 1.00]
- **Pipeline de release aditivo gateado por secrets (firma + publicación a stores)** — github_workflows_release_doc, github_workflows_release_secrets_gating, architecture_release_secrets_checklist, github_workflows_release_android_ios_publish [INFERRED 0.85]
- **Deliberate KISS scope-reduction pattern (pagination, geolocation, payment methods)** — openspec_decisions_pagination_first_page_only, openspec_decisions_geolocation_geolocator, changes_0004_payment_flow [EXTRACTED 1.00]
- **Native equivalents required for BFF-only patterns (RSA, Basic Auth secret, cookies)** — openspec_project_bff_patterns_not_replicated, openspec_decisions_secure_token_storage, openspec_decisions_rsa_oaep_encryption [EXTRACTED 1.00]
- **"Verify against the real running backend, don't trust docs alone" pattern** — changes_0005_locations_gateway_jwt_mismatch, openspec_specs_notifications_push, changes_0005_fcm_push_flow [INFERRED 0.85]

## Communities (114 total, 5 thin omitted)

### Community 0 - "tokens.generated.dart"
Cohesion: 0.04
Nodes (55): accent, accent100, accent200, accent300, accent400, accent50, accent500, accent600 (+47 more)

### Community 1 - "service.dart"
Cohesion: 0.05
Nodes (39): additionalNotes, address, cancellationReason, cancelledAt, category, categoryId, client, color (+31 more)

### Community 2 - "auth_repository_test.dart"
Cohesion: 0.16
Nodes (15): InvalidCredentialsFailure, LoginFailure, NoConnectionFailure, ServiceUnavailableFailure, ScopeFailure, ScopeUnavailableFailure, SessionExpiredFailure, cookieJar (+7 more)

### Community 3 - "openspec/README.md"
Cohesion: 0.10
Nodes (30): TekoApp-Web core/auth/session.ts (401 vs 5xx fix), BearerAuthInterceptor, Login screen with 3 distinguished error states, "Mi perfil" screen (view/edit profile + avatar upload), RefreshTokenInterceptor, Shared widgets: TekoButton, TekoCard, TekoAvatar, TekoBadge, TekoInput, tokens.generated.dart (hand-generated from tokens.json), Sesión 1 — Documentación SDD inicial (+22 more)

### Community 4 - "upload_avatar_controller_provider_test.dart"
Cohesion: 0.12
Nodes (18): ProfileRepository, _MockAuthRepository, _MockProfileRepository, package:tekoapp_mobile/features/profile/providers/profile_repository_provider.dart, package:tekoapp_mobile/features/profile/providers/update_profile_controller_provider.dart, package:tekoapp_mobile/features/profile/providers/upload_avatar_controller_provider.dart, authRepository, container (+10 more)

### Community 5 - "professional_home_screen_test.dart"
Cohesion: 0.06
Nodes (35): class, ProfessionalProfileFailure, ProfessionalProfileServiceUnavailableFailure, ProfessionalProfileValidationFailure, package:tekoapp_mobile/core/mode/app_mode.dart, package:tekoapp_mobile/core/mode/app_mode_provider.dart, package:tekoapp_mobile/features/professional_profile/data/professional_profile_repository.dart, package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart (+27 more)

### Community 6 - "login_screen.dart"
Cohesion: 0.05
Nodes (37): api_client_provider.dart, app_mode.dart, AsyncValue, auth_repository_provider.dart, apiClient, data, map, networkSmokeCheckProvider (+29 more)

### Community 7 - "_MockDio"
Cohesion: 0.08
Nodes (26): DioException, _MockDio, package:tekoapp_mobile/core/api_client/api_client_provider.dart, package:tekoapp_mobile/features/professional_profile/providers/professional_onboarding_controller_provider.dart, package:tekoapp_mobile/features/services/providers/my_professional_services_provider.dart, package:tekoapp_mobile/features/services/providers/propose_on_service_controller_provider.dart, package:tekoapp_mobile/features/services/providers/service_requests_provider.dart, ProviderContainer (+18 more)

### Community 8 - "Sesión 2 — Ecosistema .claude + desbloqueo FCM"
Cohesion: 0.09
Nodes (33): Tres workflows CI/CD con propósitos distintos (ci/build/release), tdd-refactor agent doc, Flujo TDD de 6 fases (Orient→Diagnosis→Characterization Test→Plan→Execute→Spec Update), testing-agent doc, Generación/revisión de tests (AAA, mock del límite de red), context.md snapshot, Qué NO hacer — no asumir patrón BFF, no implementar FCM sin confirmar backend, memory.md protocolo de sesión (+25 more)

### Community 9 - "services_repository_test.dart"
Cohesion: 0.06
Nodes (40): Exception, PromotionRejected, AvatarTooLargeFailure, AvatarUnsupportedTypeFailure, AvatarUploadFailure, AvatarUploadServiceFailure, ProfileFailure, ProfileServiceUnavailableFailure (+32 more)

### Community 10 - "TekoApp-Web (Next.js 16, shadcn/ui, TanStack Query)"
Cohesion: 0.18
Nodes (16): Formato Conventional Commits (tipo(alcance): descripción, en español), /commit command doc, Guardrail de rama nuevo — todo trabajo nuevo va en rama + PR, Bug: service.professional.user undefined por include mal anidado en backend, Guardrail de rama — nunca commitear directo a develop/qa/master, Estructura por dominio lib/features/<dominio>/{data,providers,models,widgets}, go_router = ruteo declarativo (GoRoute, context.go/push), Guía de nueva feature de cero (data/providers/models/widgets) (+8 more)

### Community 11 - "CLAUDE.md (config raíz)"
Cohesion: 0.09
Nodes (30): Contrato de auth de 7 pasos (nonce→RSA-OAEP→login→tokens→refresh→scope→PUT /auth/me), Avatares — nunca cachear avatarUrl (S3 presignada, expira 900s), El contrato con el backend (identificadores, auth, avatares, envelope, 409, timezone), Errores ya encontrados que esta app debería evitar (timezone, race conditions, listados vacíos, avatar URL, include anidado), Dominio: marketplace de servicios de oficio geolocalizado, Notificaciones push (Firebase Cloud Messaging) — endpoints fcm-tokens, Excepción histórica: Services/ServiceRequests/PaymentMethodEntity/Payments/PaymentTransaction/Rating usan UUID como PK directa, Tabla de stack decidido con motivo corto (+22 more)

### Community 12 - "openspec/decisions.md"
Cohesion: 0.08
Nodes (29): flutter_lints package (lint base), .github/workflows/ci.yml (flutter analyze + test), go_router dummy public/protected routes + guard test, Decision: GitHub Actions CI/CD, 3 environments, Decision: dio HTTP client, Decision: Flutter 3 framework, Decision: geolocator, no interactive map picker yet, Decision: go_router for declarative routing/guards (+21 more)

### Community 13 - "profile_screen.dart"
Cohesion: 0.11
Nodes (17): ../../../core/auth/session_state.dart, _avatarErrorMessage, createState, dispose, _ensureControllersInitialized, _firstNameController, _formKey, _initializedFor (+9 more)

### Community 14 - "app.dart"
Cohesion: 0.06
Nodes (34): @immutable, ChangeNotifier, ../../core/theme/app_theme.dart, features/auth/widgets/login_screen.dart, features/home/widgets/home_screen.dart, features/payments/widgets/add_payment_method_screen.dart, features/payments/widgets/pay_service_screen.dart, features/payments/widgets/payment_detail_screen.dart (+26 more)

### Community 15 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 16 - "request_service_screen.dart"
Cohesion: 0.11
Nodes (18): ../../categories/models/service_type.dart, ../../categories/providers/service_types_provider.dart, ../../../core/location/current_location_provider.dart, _addressController, createState, _descriptionController, dispose, _formKey (+10 more)

### Community 17 - "rsa_encryptor_test.dart"
Cohesion: 0.12
Nodes (16): ../config/env.dart, dart:convert, ClientBasicAuth, options, encryptLoginPayload, _publicKey, RsaEncryptor, package:basic_utils/basic_utils.dart (+8 more)

### Community 18 - "request_service_screen_test.dart"
Cohesion: 0.11
Nodes (18): package:tekoapp_mobile/features/categories/models/category.dart, package:tekoapp_mobile/features/categories/models/service_type.dart, package:tekoapp_mobile/features/categories/providers/categories_provider.dart, package:tekoapp_mobile/features/categories/providers/service_types_provider.dart, package:tekoapp_mobile/features/services/widgets/request_service_screen.dart, container, dio, main (+10 more)

### Community 19 - "payment_history_screen_test.dart"
Cohesion: 0.08
Nodes (25): package:flutter_localizations/flutter_localizations.dart, package:tekoapp_mobile/features/payments/widgets/payment_detail_screen.dart, package:tekoapp_mobile/features/payments/widgets/payment_methods_screen.dart, package:tekoapp_mobile/l10n/app_localizations.dart, dio, main, _MockDio, _paymentJson (+17 more)

### Community 20 - "rateControllerProvider"
Cohesion: 0.21
Nodes (13): rateControllerProvider, serviceRatingsProvider, myProfessionalServicesProvider, respondToRequestControllerProvider, serviceRequestsProvider, build, _rate, _RateClientButton (+5 more)

### Community 21 - "auth_repository.dart"
Cohesion: 0.10
Nodes (19): CookieJar, ../../../core/auth/client_basic_auth.dart, ../../../core/auth/rsa_encryptor.dart, ../../../core/auth/token_storage_keys.dart, ../../../core/auth/user_summary.dart, accessTokenStorageKey, _apiClient, _classifyLogin (+11 more)

### Community 22 - "session_provider.dart"
Cohesion: 0.12
Nodes (17): ../../features/auth/data/auth_repository.dart, ../../features/auth/models/scope_failure.dart, ../../features/auth/providers/auth_repository_provider.dart, build, logout, refreshAfterLogin, _refreshScope, _restoreSession (+9 more)

### Community 23 - "login_screen_test.dart"
Cohesion: 0.17
Nodes (11): FilledButton, Object?, Object? error,
  bool, package:tekoapp_mobile/features/auth/models/login_failure.dart, package:tekoapp_mobile/features/auth/providers/login_controller_provider.dart, build, error, loading (+3 more)

### Community 24 - "my_services_screen_test.dart"
Cohesion: 0.11
Nodes (16): package:tekoapp_mobile/features/services/widgets/my_services_screen.dart, package:tekoapp_mobile/features/services/widgets/service_detail_screen.dart, dio, main, _MockDio, pumpAndSettle, _pumpScreen, pumpWidget (+8 more)

### Community 25 - "openspec/specs/i18n.md"
Cohesion: 0.15
Nodes (15): Analyzer exclusions for generated code, TekoApp-Web accessibility.md checklist (adapted to Flutter), Product decision: admin/backoffice mode on mobile or web-only, Hardcoded-string audit + explicit language selector, Catálogo es/en propio (flutter_localizations + intl), i18n.md rules doc, Traducir sobre la marcha, no acumular deuda de traducción, Flujo de textos e idiomas (.arb es/en, flutter gen-l10n) (+7 more)

### Community 26 - "service_transition_controller_provider.dart"
Cohesion: 0.14
Nodes (10): watch, ref, watch, build, complete, _run, start, my_professional_services_provider.dart (+2 more)

### Community 27 - "openspec/specs/services-marketplace.md"
Cohesion: 0.17
Nodes (13): PRs #41-#49 (TekoApp-Frontend-Mobile), Professional onboarding gate (mode selector + GET /professionals/me), Competing ServiceRequests flow (propose/accept), Pay-completed-service flow (method + server-computed amount + promo), Bidirectional rating flow, hide option once rated, Partial refund flow (available amount only, no full-amount assumption), Phase 0004 payments findings verified against real backend, Decision: ServiceRequests competing-offers model (diverges from Web) (+5 more)

### Community 28 - "devDependencies"
Cohesion: 0.12
Nodes (16): conventional-changelog-conventionalcommits, description, devDependencies, conventional-changelog-conventionalcommits, semantic-release, @semantic-release/changelog, @semantic-release/exec, @semantic-release/git (+8 more)

### Community 29 - "app_theme.dart"
Cohesion: 0.12
Nodes (15): @visibleForTesting, Color, ../../design_system/tokens.generated.dart, AppTheme, colorSchemeFrom, copyWith, dark, info (+7 more)

### Community 30 - "professional_onboarding_screen.dart"
Cohesion: 0.12
Nodes (17): ../../categories/models/category.dart, ../../categories/providers/categories_provider.dart, professionalOnboardingControllerProvider, build, createState, _descriptionController, dispose, _fixedRateController (+9 more)

### Community 31 - "professional_profile.dart"
Cohesion: 0.10
Nodes (19): categoryId, description, fixedRate, fromJson, hourlyRate, id, isAvailable, isOnline (+11 more)

### Community 32 - "app_redirect_test.dart"
Cohesion: 0.09
Nodes (28): package:flutter/services.dart, package:tekoapp_mobile/app.dart, package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart, package:tekoapp_mobile/core/auth/session_provider.dart, package:tekoapp_mobile/core/auth/user_summary.dart, package:tekoapp_mobile/features/auth/widgets/login_screen.dart, package:tekoapp_mobile/features/home/widgets/home_screen.dart, package:tekoapp_mobile/features/professional_profile/widgets/professional_onboarding_screen.dart (+20 more)

### Community 33 - "package:mocktail/mocktail.dart"
Cohesion: 0.17
Nodes (10): package:mocktail/mocktail.dart, package:tekoapp_mobile/core/auth/secure_cookie_storage.dart, package:tekoapp_mobile/features/services/providers/request_service_controller_provider.dart, main, secureStorage, storage, container, dio (+2 more)

### Community 34 - "pay_service_screen.dart"
Cohesion: 0.10
Nodes (21): payServiceControllerProvider, _confirm, createState, dispose, _PayServiceBody, _PayServiceBodyState, _promoCodeController, _promoMessage (+13 more)

### Community 35 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.08
Nodes (22): ElevatedButton, package:flutter/painting.dart, package:flutter_test/flutter_test.dart, package:tekoapp_mobile/core/theme/app_theme.dart, package:tekoapp_mobile/design_system/tokens.generated.dart, package:tekoapp_mobile/features/payments/models/payment.dart, package:tekoapp_mobile/features/services/models/service.dart, package:tekoapp_mobile/shared/widgets/teko_avatar.dart (+14 more)

### Community 36 - "openspec/changes/0005-realtime-and-push.md"
Cohesion: 0.20
Nodes (12): TekoApp-Backend notifications-push-architecture.md, FCM push registration/deregistration + notification handling flow, LocationsGateway JWT secret mismatch hypothesis to verify, Push notifications: SSE + Web Push + FCM implementado en backend, Desbloqueo de FCM del lado backend (SSE+WebPush+FCM real), Decision: Firebase Cloud Messaging for push, referenceId (UUID) vs internal id — never expose internal id, Deep linking from notification via referenceId (+4 more)

### Community 37 - "service_request.dart"
Cohesion: 0.15
Nodes (12): double?, createdAt, fromJson, id, message, professionalId, proposedHours, proposedPrice (+4 more)

### Community 38 - "session_provider_test.dart"
Cohesion: 0.15
Nodes (17): SessionAuthenticated, SessionServiceUnavailable, SessionState, SessionUnauthenticated, SessionUnknown, user, package:tekoapp_mobile/core/auth/session_state.dart, package:tekoapp_mobile/features/auth/data/auth_repository.dart (+9 more)

### Community 39 - "services_repository.dart"
Cohesion: 0.12
Nodes (15): _apiClient, cancelService, _classify, completeService, createService, fetchAvailableServices, fetchMyServices, fetchServiceDetail (+7 more)

### Community 40 - "Mock"
Cohesion: 0.17
Nodes (16): Dio, AuthRepository, Mock, package:tekoapp_mobile/features/payments/providers/payment_methods_provider.dart, _MockDio, _MockAuthRepository, _MockAuthRepository, _MockDio (+8 more)

### Community 41 - "profile_repository.dart"
Cohesion: 0.15
Nodes (11): accessToken, TokenStorageKeys, allowedAvatarMimeTypes, _apiClient, _classify, maxAvatarBytes, updateMe, uploadAvatar (+3 more)

### Community 42 - "available_services_screen.dart"
Cohesion: 0.14
Nodes (16): availableServicesProvider, profile, ref, proposeOnServiceControllerProvider, AvailableServicesScreen, _AvailableServicesScreenState, build, createState (+8 more)

### Community 43 - "professional_services_screen.dart"
Cohesion: 0.11
Nodes (22): Service, serviceTransitionControllerProvider, _actingServiceId, _complete, createState, ProfessionalServicesScreen, _ProfessionalServicesScreenState, _run (+14 more)

### Community 44 - "package:tekoapp_mobile/core/api_client/api_client.dart"
Cohesion: 0.15
Nodes (11): package:tekoapp_mobile/core/api_client/api_client.dart, package:tekoapp_mobile/features/categories/data/categories_repository.dart, package:tekoapp_mobile/features/services/providers/respond_to_request_controller_provider.dart, dio, listResponse, main, repository, container (+3 more)

### Community 45 - "../../../core/api_client/api_client.dart"
Cohesion: 0.18
Nodes (9): categories_repository_provider.dart, ../../../core/api_client/api_client.dart, _apiClient, fetchCategories, fetchServiceTypes, watch, watch, ../models/category.dart (+1 more)

### Community 46 - "ConsumerState"
Cohesion: 0.18
Nodes (15): ConsumerState, ConsumerStatefulWidget, currentPositionFetcherProvider, categoriesProvider, serviceTypesProvider, AddPaymentMethodScreen, _AddPaymentMethodScreenState, ProfessionalOnboardingScreen (+7 more)

### Community 47 - "teko_button.dart"
Cohesion: 0.17
Nodes (11): IconData?, build, icon, label, loading, onPressed, size, TekoButtonSize (+3 more)

### Community 48 - "professional_onboarding_screen_test.dart"
Cohesion: 0.15
Nodes (12): _category, dio, ensureVisible, enterText, _fillValidForm, main, _MockDio, pumpAndSettle (+4 more)

### Community 49 - "professional_profile_repository.dart"
Cohesion: 0.11
Nodes (15): ../data/professional_profile_repository.dart, _apiClient, _classify, fetchMe, ProfessionalProfileRepository, register, watch, build (+7 more)

### Community 50 - "sessionProvider"
Cohesion: 0.40
Nodes (6): sessionProvider, LoginController, profileRepositoryProvider, UpdateProfileController, UploadAvatarController, _FixedLoginController

### Community 51 - "refresh_token_interceptor.dart"
Cohesion: 0.14
Nodes (14): client_basic_auth.dart, FlutterSecureStorage, onRequest, _secureStorage, _dio, _excludedPaths, onError, _secureStorage (+6 more)

### Community 52 - "refresh_token_interceptor_test.dart"
Cohesion: 0.18
Nodes (10): ErrorInterceptorHandler, package:tekoapp_mobile/core/auth/refresh_token_interceptor.dart, dio, handler, interceptor, main, _MockDio, _MockErrorHandler (+2 more)

### Community 53 - "category.dart"
Cohesion: 0.18
Nodes (10): int?, Category, color, fromJson, icon, id, name, parentCategoryId (+2 more)

### Community 54 - "teko_input.dart"
Cohesion: 0.18
Nodes (10): build, controller, enabled, initialValue, keyboardType, label, maxLines, obscureText (+2 more)

### Community 55 - "package:go_router/go_router.dart"
Cohesion: 0.16
Nodes (13): ../../../core/api_client/network_smoke_check_provider.dart, ../../../core/mode/app_mode.dart, ../../../core/mode/app_mode_provider.dart, fetchPayments, mode, repository, services, _ProfessionalActiveBody (+5 more)

### Community 56 - "payment.dart"
Cohesion: 0.06
Nodes (33): double get, amount, amountAvailableForRefund, createdAt, currencyCode, status, description, fee (+25 more)

### Community 57 - "async_state_view.dart"
Cohesion: 0.22
Nodes (8): build, data, emptyMessage, errorMessage, hasError, isEmpty, isLoading, T

### Community 58 - "bearer_auth_interceptor_test.dart"
Cohesion: 0.20
Nodes (9): _MockSecureStorage, package:tekoapp_mobile/core/auth/bearer_auth_interceptor.dart, package:tekoapp_mobile/core/auth/token_storage_keys.dart, RequestInterceptorHandler, handler, interceptor, main, _MockHandler (+1 more)

### Community 59 - "api_client.dart"
Cohesion: 0.14
Nodes (12): ../auth/bearer_auth_interceptor.dart, ../auth/refresh_token_interceptor.dart, Dio get, envelope_interceptor.dart, _buildDefaultDio, _dio, raw, cookieJarProvider (+4 more)

### Community 60 - "upload_avatar_controller_provider.dart"
Cohesion: 0.25
Nodes (7): ../../../core/auth/session_provider.dart, dart:typed_data, build, submit, build, submit, profile_repository_provider.dart

### Community 61 - "package:dio/dio.dart"
Cohesion: 0.22
Nodes (7): onResponse, package:dio/dio.dart, package:tekoapp_mobile/features/services/providers/service_detail_provider.dart, container, dio, main, _MockDio

### Community 62 - "secure_cookie_storage.dart"
Cohesion: 0.22
Nodes (8): delete, deleteAll, init, read, SecureCookieStorage, _secureStorage, write, Storage

### Community 63 - "user_summary.dart"
Cohesion: 0.22
Nodes (8): avatarUrl, email, firstName, fromJson, lastName, phoneNumber, referenceId, UserSummary

### Community 64 - "envelope_interceptor_test.dart"
Cohesion: 0.15
Nodes (12): Interceptor, EnvelopeInterceptor, BearerAuthInterceptor, RefreshTokenInterceptor, _MockHandler, package:tekoapp_mobile/core/api_client/envelope_interceptor.dart, ResponseInterceptorHandler, buildResponse (+4 more)

### Community 65 - "professional_services_screen_test.dart"
Cohesion: 0.20
Nodes (9): package:tekoapp_mobile/features/services/widgets/professional_services_screen.dart, completedServiceWithClientJson, dio, main, _MockDio, pumpAndSettle, _pumpScreen, pumpWidget (+1 more)

### Community 66 - "env.dart"
Cohesion: 0.25
Nodes (7): apiBaseUrl, basicAuthClientId, basicAuthClientSecret, Env, isProduction, static const bool, static const String

### Community 67 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.13
Nodes (14): ../../../core/api_client/api_client_provider.dart, ../../../core/auth/cookie_jar_provider.dart, ../data/auth_repository.dart, ../data/categories_repository.dart, ../data/payments_repository.dart, ../data/profile_repository.dart, ../data/ratings_repository.dart, ../data/services_repository.dart (+6 more)

### Community 68 - "dart:async"
Cohesion: 0.13
Nodes (16): AsyncNotifier, available_services_provider.dart, dart:async, build, RefundPaymentController, submit, build, ProposeOnServiceController (+8 more)

### Community 69 - "add_payment_method_screen.dart"
Cohesion: 0.13
Nodes (17): PaymentMethodType, PaymentProviderType, paymentMethodControllerProvider, build, createState, _detailController, dispose, _formKey (+9 more)

### Community 70 - "StatelessWidget"
Cohesion: 0.15
Nodes (12): EdgeInsetsGeometry?, _ServiceDetailBody, AsyncStateView, TekoAvatar, TekoButton, build, child, padding (+4 more)

### Community 71 - "payment_method.dart"
Cohesion: 0.12
Nodes (16): bepsa, crypto, details, externalId, fromJson, id, isActive, isDefault (+8 more)

### Community 72 - "payment_detail_screen.dart"
Cohesion: 0.15
Nodes (15): bool get, Payment, paymentDetailProvider, refundPaymentControllerProvider, build, _isRefundable, _openRefundDialog, payment (+7 more)

### Community 73 - "payment_history_screen.dart"
Cohesion: 0.18
Nodes (12): paymentHistoryProvider, build, PaymentHistoryScreen, myClientServicesProvider, build, MyServicesScreen, payment_status_badge.dart, ../providers/my_client_services_provider.dart (+4 more)

### Community 74 - "respond_to_request_controller_provider.dart"
Cohesion: 0.29
Nodes (6): accept, build, RespondToRequestController, ../models/request_status.dart, service_detail_provider.dart, service_requests_provider.dart

### Community 75 - "service_transition_controller_provider_test.dart"
Cohesion: 0.29
Nodes (6): package:tekoapp_mobile/features/services/providers/service_transition_controller_provider.dart, container, dio, main, _MockDio, _serviceJson

### Community 76 - "package:flutter/material.dart"
Cohesion: 0.12
Nodes (16): app.dart, ../../../l10n/app_localizations.dart, build, PaymentStatusBadge, status, commentController, l10n, selectedStars (+8 more)

### Community 77 - "String?"
Cohesion: 0.33
Nodes (5): accessToken, LoginResult, requiresNewPassword, success, String?

### Community 78 - "request_status.dart"
Cohesion: 0.33
Nodes (5): expired, fromJson, RequestStatus, toJson, pending,
  accepted,
  rejected,

### Community 79 - "current_location_provider.dart"
Cohesion: 0.14
Nodes (14): CurrentPositionFetcher, DeviceLatLng, _fetchCurrentPosition, latitude, LocationFailure, LocationPermissionDeniedFailure, LocationServiceDisabledFailure, longitude (+6 more)

### Community 80 - "pay_service_controller_provider.dart"
Cohesion: 0.14
Nodes (11): build, message, submit, watch, watch, paymentMethodTypeLabel, paymentProviderLabel, ../models/payment.dart (+3 more)

### Community 81 - "ratings_repository.dart"
Cohesion: 0.14
Nodes (12): api_client.dart, ../auth/cookie_jar_provider.dart, ApiClient, apiClientProvider, _apiClient, _classify, _extractBackendMessage, fetchForService (+4 more)

### Community 82 - "rating.dart"
Cohesion: 0.15
Nodes (12): DateTime, createdAt, type, fromJson, id, isActive, isAnonymous, professionalId (+4 more)

### Community 83 - "service_type.dart"
Cohesion: 0.40
Nodes (4): fromJson, id, name, ServiceType

### Community 84 - "payments_repository.dart"
Cohesion: 0.17
Nodes (11): _apiClient, _classify, createPayment, createPaymentMethod, deletePaymentMethod, _extractBackendMessage, fetchPaymentById, fetchPaymentMethods (+3 more)

### Community 85 - "service_status.dart"
Cohesion: 0.40
Nodes (4): cancelled, fromJson, ServiceStatus, pending,
  accepted,
  inProgress,
  completed,

### Community 86 - "rate_controller_provider.dart"
Cohesion: 0.17
Nodes (10): build, rateClient, RateController, rateProfessional, _run, ratingsRepositoryProvider, watch, ../models/rating.dart (+2 more)

### Community 87 - "FormState"
Cohesion: 0.50
Nodes (3): FormState, package:tekoapp_mobile/shared/widgets/teko_input.dart, main

### Community 88 - "pay_service_screen_test.dart"
Cohesion: 0.17
Nodes (11): package:tekoapp_mobile/features/payments/widgets/pay_service_screen.dart, package:tekoapp_mobile/features/payments/widgets/payment_history_screen.dart, dio, main, _methodJson, _MockDio, pumpAndSettle, _pumpScreen (+3 more)

### Community 89 - "tokens.json (W3C Design Tokens) como única fuente de verdad de marca"
Cohesion: 0.22
Nodes (10): Checklist de secrets a cargar (Android/iOS/stores) para release.yml, Serie de releases 1.0.0-develop.1 a .20 — historial de features/fixes por fase, Fase 0002 (auth) en curso — progreso detallado, Fase 0003 (marketplace de servicios) completa — 9 PRs #41-#49, Login = nonce + RSA-OAEP + Basic Auth cliente — contrato del backend, no simplificar, tokens.json (W3C Design Tokens) como única fuente de verdad de marca, Build+publish Android (APK+AAB) e iOS (IPA) condicionado a secrets de firma, release.yml workflow (+2 more)

### Community 91 - "promotions_repository.dart"
Cohesion: 0.18
Nodes (9): ../data/promotions_repository.dart, _apiClient, apply, _classify, PromotionsRepository, validate, ../models/promotion_apply_result.dart, ../models/promotion_failure.dart (+1 more)

### Community 100 - "payment_method_controller_provider.dart"
Cohesion: 0.24
Nodes (9): PayServiceController, build, create, delete, PaymentMethodController, setAsDefault, paymentsRepositoryProvider, promotionsRepositoryProvider (+1 more)

### Community 101 - "add_payment_method_screen_test.dart"
Cohesion: 0.20
Nodes (9): MaterialPageRoute, package:tekoapp_mobile/features/payments/widgets/add_payment_method_screen.dart, dio, main, _MockDio, pumpAndSettle, _pumpScreen, pumpWidget (+1 more)

### Community 102 - "payments_repository_test.dart"
Cohesion: 0.20
Nodes (9): package:tekoapp_mobile/features/payments/data/payments_repository.dart, package:tekoapp_mobile/features/payments/models/payment_failure.dart, dio, errorResponse, main, _MockDio, paymentJson, paymentMethodJson (+1 more)

### Community 103 - "ratings_repository_test.dart"
Cohesion: 0.22
Nodes (8): package:tekoapp_mobile/features/ratings/data/ratings_repository.dart, package:tekoapp_mobile/features/ratings/models/rating_failure.dart, package:tekoapp_mobile/features/ratings/models/rating_type.dart, dio, main, _MockDio, ratingJson, repository

### Community 104 - "ConsumerWidget"
Cohesion: 0.32
Nodes (8): ConsumerWidget, paymentMethodsProvider, build, PayServiceScreen, build, serviceDetailProvider, ServiceDetailScreen, Route /pagos/metodos/nuevo

### Community 105 - "promotion_apply_result.dart"
Cohesion: 0.25
Nodes (7): discountAmount, finalAmount, fromJson, message, promotion, PromotionApplyResult, success

### Community 106 - "promotion_validation.dart"
Cohesion: 0.25
Nodes (7): discountAmount, fromJson, isValid, message, promotion, PromotionValidation, promotion.dart

### Community 107 - "payment_method_controller_provider_test.dart"
Cohesion: 0.25
Nodes (7): package:tekoapp_mobile/features/payments/models/payment_method.dart, package:tekoapp_mobile/features/payments/providers/payment_method_controller_provider.dart, container, dio, main, _MockDio, _paymentMethodJson

### Community 108 - "promotions_repository_test.dart"
Cohesion: 0.25
Nodes (7): package:tekoapp_mobile/features/promotions/data/promotions_repository.dart, package:tekoapp_mobile/features/promotions/models/promotion_failure.dart, dio, main, _MockDio, okResponse, repository

### Community 109 - "_ProfileScreenState"
Cohesion: 0.33
Nodes (7): updateProfileControllerProvider, uploadAvatarControllerProvider, build, _pickAndUploadAvatar, ProfileScreen, _ProfileScreenState, _submit

### Community 110 - "rating_type.dart"
Cohesion: 0.33
Nodes (5): clientToProfessional,, fromJson, professionalToClient, RatingType, toJson

### Community 111 - "payment_failure.dart"
Cohesion: 0.53
Nodes (5): backendMessage, PaymentConflictFailure, PaymentFailure, PaymentServiceUnavailableFailure, PaymentValidationFailure

### Community 112 - "my_client_services_provider_test.dart"
Cohesion: 0.33
Nodes (5): package:tekoapp_mobile/features/services/providers/my_client_services_provider.dart, container, dio, main, _MockDio

### Community 113 - "promotion.dart"
Cohesion: 0.40
Nodes (4): code, fromJson, name, Promotion

## Ambiguous Edges - Review These
- `Explicitly pending/undecided items` → `Maps SDK choice (Google Maps candidate) — undecided`  [AMBIGUOUS]
  openspec/decisions.md · relation: conceptually_related_to

## Knowledge Gaps
- **774 isolated node(s):** `XCTest`, `_protectedPaths`, `_professionalGatedPaths`, `refreshListenable`, `notify` (+769 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Explicitly pending/undecided items` and `Maps SDK choice (Google Maps candidate) — undecided`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `PaymentStatus` connect `payment.dart` to `package:flutter/material.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `TekoSemanticColors` connect `app.dart` to `app_theme.dart`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `XCTest`, `_protectedPaths`, `_professionalGatedPaths` to the rest of the system?**
  _774 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `tokens.generated.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03571428571428571 - nodes in this community are weakly interconnected._
- **Should `service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `openspec/README.md` be split into smaller, more focused modules?**
  _Cohesion score 0.09523809523809523 - nodes in this community are weakly interconnected._