# Informe de ejecución QA — unit — e2e-w1-maestro

| Campo | Valor |
|---|---|
| Fecha y hora | 2026-10-12 23:43 |
| Repo | TekoApp-Frontend-Mobile |
| Rama | `test/e2e-w1-maestro` |
| Commit | `6556120` (base de la ejecución) |
| Entorno | local (windows), flutter test sobre VM; Dio mockeado; Flutter 3.44.8 |
| Comando | `flutter test --machine --coverage > build/qa/unit.jsonl; dart run tool/qa_report.dart build/qa/unit.jsonl unit` |
| Ejecutor | agente (Claude Sonnet 5.5) |

> Tablas generadas por `tool/qa_report.dart` desde la salida JSON
> de `flutter test --machine`. Las secciones 3, 4 y 6 se completan a mano.

## 1. Resumen

| Total | Pasaron | Fallaron | Omitidos | Duración | Cobertura |
|---:|---:|---:|---:|---:|---|
| 643 | 643 | 0 | 0 | 567.2s | 5997 / 7687 líneas = 78.0 % |

Resultado global del runner: success.

## 2. Resultados por área / feature

| Área / feature | Archivos | Casos | Pasaron | Fallaron | Omitidos | Estado |
|---|---:|---:|---:|---:|---:|---|
| `test` | 2 | 8 | 8 | 0 | 0 | OK |
| `test/core/api_client` | 4 | 17 | 17 | 0 | 0 | OK |
| `test/core/auth` | 7 | 32 | 32 | 0 | 0 | OK |
| `test/core/locale` | 1 | 3 | 3 | 0 | 0 | OK |
| `test/core/location` | 1 | 1 | 1 | 0 | 0 | OK |
| `test/core/realtime` | 1 | 12 | 12 | 0 | 0 | OK |
| `test/core/theme` | 1 | 5 | 5 | 0 | 0 | OK |
| `test/core/update` | 3 | 14 | 14 | 0 | 0 | OK |
| `test/design_system` | 1 | 5 | 5 | 0 | 0 | OK |
| `test/e2e` | 1 | 1 | 1 | 0 | 0 | OK |
| `test/features/account_deletion` | 5 | 18 | 18 | 0 | 0 | OK |
| `test/features/ai_disclosures` | 1 | 6 | 6 | 0 | 0 | OK |
| `test/features/auth` | 6 | 48 | 48 | 0 | 0 | OK |
| `test/features/budgets` | 5 | 14 | 14 | 0 | 0 | OK |
| `test/features/categories` | 3 | 8 | 8 | 0 | 0 | OK |
| `test/features/contracts` | 6 | 22 | 22 | 0 | 0 | OK |
| `test/features/home` | 1 | 10 | 10 | 0 | 0 | OK |
| `test/features/legal_consents` | 7 | 24 | 24 | 0 | 0 | OK |
| `test/features/locations` | 7 | 29 | 29 | 0 | 0 | OK |
| `test/features/notifications` | 3 | 14 | 14 | 0 | 0 | OK |
| `test/features/payments` | 10 | 60 | 60 | 0 | 0 | OK |
| `test/features/professional_documents` | 5 | 16 | 16 | 0 | 0 | OK |
| `test/features/professional_portfolio` | 3 | 10 | 10 | 0 | 0 | OK |
| `test/features/professional_profile` | 4 | 14 | 14 | 0 | 0 | OK |
| `test/features/profile` | 4 | 21 | 21 | 0 | 0 | OK |
| `test/features/promotions` | 2 | 8 | 8 | 0 | 0 | OK |
| `test/features/ratings` | 4 | 16 | 16 | 0 | 0 | OK |
| `test/features/service_progress` | 4 | 19 | 19 | 0 | 0 | OK |
| `test/features/services` | 16 | 64 | 64 | 0 | 0 | OK |
| `test/shared/widgets` | 14 | 53 | 53 | 0 | 0 | OK |
| `test/tool` | 1 | 4 | 4 | 0 | 0 | OK |
| `test/tool/openapi_codegen` | 4 | 67 | 67 | 0 | 0 | OK |

### Inventario por archivo de test

| Archivo | Casos | Pasaron | Fallaron | Omitidos | Estado |
|---|---:|---:|---:|---:|---|
| `test/app_redirect_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/app_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/core/api_client/consent_required_interceptor_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/core/api_client/envelope_interceptor_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/core/api_client/network_smoke_check_provider_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/core/api_client/retry_on_transient_error_interceptor_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/core/auth/bearer_auth_interceptor_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/core/auth/biometric_login_service_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/core/auth/refresh_token_interceptor_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/core/auth/rsa_encryptor_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/core/auth/secure_cookie_storage_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/core/auth/session_provider_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/core/auth/user_summary_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/core/locale/locale_provider_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/core/location/current_location_provider_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/core/realtime/locations_socket_service_test.dart` | 12 | 12 | 0 | 0 | OK |
| `test/core/theme/app_theme_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/core/update/environment_release_matcher_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/core/update/update_available_dialog_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/core/update/update_check_repository_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/design_system/tokens_generated_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/e2e/login_profile_logout_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/features/account_deletion/data/account_deletion_repository_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/account_deletion/providers/cancel_deletion_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/account_deletion/providers/request_deletion_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/account_deletion/widgets/account_deletion_banner_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/account_deletion/widgets/account_deletion_screen_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/ai_disclosures/data/ai_disclosures_repository_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/auth/data/auth_repository_test.dart` | 21 | 21 | 0 | 0 | OK |
| `test/features/auth/providers/biometric_login_controller_provider_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/auth/providers/biometric_opt_in_controller_provider_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/auth/providers/login_controller_provider_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/auth/widgets/login_screen_test.dart` | 13 | 13 | 0 | 0 | OK |
| `test/features/auth/widgets/register_screen_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/budgets/data/budgets_repository_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/budgets/providers/select_budget_option_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/budgets/providers/submit_budget_options_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/budgets/widgets/budget_builder_screen_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/budgets/widgets/budget_comparison_screen_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/categories/data/categories_repository_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/categories/models/category_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/categories/providers/categories_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/contracts/data/contracts_repository_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/contracts/models/contract_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/contracts/providers/generate_contract_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/contracts/providers/sign_contract_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/contracts/widgets/contract_preview_screen_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/contracts/widgets/my_contracts_screen_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/home/widgets/home_screen_test.dart` | 10 | 10 | 0 | 0 | OK |
| `test/features/legal_consents/data/legal_consents_repository_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/features/legal_consents/models/ai_disclosure_entity_type_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/legal_consents/models/legal_document_type_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/legal_consents/providers/consent_required_bridge_provider_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/legal_consents/providers/legal_consents_controller_provider_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/legal_consents/widgets/legal_consent_screen_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/legal_consents/widgets/privacy_and_data_screen_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/locations/data/locations_repository_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/features/locations/models/nearby_professional_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/locations/models/professional_last_location_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/locations/providers/assigned_professional_location_provider_test.dart` | 9 | 9 | 0 | 0 | OK |
| `test/features/locations/providers/nearby_professionals_provider_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/locations/providers/online_status_controller_provider_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/locations/widgets/nearby_professionals_map_screen_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/features/notifications/data/notifications_repository_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/notifications/models/push_notification_payload_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/notifications/providers/push_registration_controller_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/payments/data/payments_repository_test.dart` | 20 | 20 | 0 | 0 | OK |
| `test/features/payments/models/payment_method_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/payments/models/payment_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/features/payments/providers/payment_method_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/payments/providers/payment_methods_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/payments/widgets/add_payment_method_screen_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/payments/widgets/pay_service_screen_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/payments/widgets/payment_detail_screen_test.dart` | 8 | 8 | 0 | 0 | OK |
| `test/features/payments/widgets/payment_history_screen_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/payments/widgets/payment_methods_screen_test.dart` | 8 | 8 | 0 | 0 | OK |
| `test/features/professional_documents/data/professional_documents_repository_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/professional_documents/models/professional_document_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/professional_documents/providers/upload_document_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/professional_documents/widgets/my_documents_screen_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/professional_documents/widgets/professional_documents_section_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/professional_portfolio/data/professional_portfolio_repository_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/features/professional_portfolio/providers/upload_portfolio_item_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/professional_portfolio/widgets/my_portfolio_screen_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/professional_profile/data/professional_profile_repository_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/features/professional_profile/providers/professional_onboarding_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/professional_profile/widgets/professional_home_screen_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/professional_profile/widgets/professional_onboarding_screen_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/profile/data/profile_repository_test.dart` | 8 | 8 | 0 | 0 | OK |
| `test/features/profile/providers/update_profile_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/profile/providers/upload_avatar_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/profile/widgets/profile_screen_test.dart` | 9 | 9 | 0 | 0 | OK |
| `test/features/promotions/data/promotions_repository_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/features/promotions/models/promotion_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/ratings/data/ratings_repository_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/features/ratings/models/rating_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/features/ratings/widgets/my_rating_stats_screen_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/ratings/widgets/professional_rating_stats_screen_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/service_progress/data/service_progress_repository_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/features/service_progress/providers/service_progress_controller_provider_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/service_progress/widgets/add_progress_entry_sheet_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/service_progress/widgets/progress_timeline_test.dart` | 5 | 5 | 0 | 0 | OK |
| `test/features/services/data/services_repository_test.dart` | 18 | 18 | 0 | 0 | OK |
| `test/features/services/models/service_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/services/providers/available_services_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/services/providers/my_client_services_provider_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/features/services/providers/my_professional_services_provider_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/features/services/providers/propose_on_service_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/services/providers/request_service_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/services/providers/respond_to_request_controller_provider_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/services/providers/service_detail_provider_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/features/services/providers/service_requests_provider_test.dart` | 1 | 1 | 0 | 0 | OK |
| `test/features/services/providers/service_transition_controller_provider_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/services/widgets/available_services_screen_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/features/services/widgets/my_services_screen_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/features/services/widgets/professional_services_screen_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/features/services/widgets/request_service_screen_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/features/services/widgets/service_detail_screen_test.dart` | 13 | 13 | 0 | 0 | OK |
| `test/shared/widgets/ai_disclosure_badge_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/shared/widgets/async_state_view_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/shared/widgets/resolved_network_image_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/shared/widgets/teko_avatar_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/shared/widgets/teko_badge_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/shared/widgets/teko_button_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/shared/widgets/teko_card_test.dart` | 2 | 2 | 0 | 0 | OK |
| `test/shared/widgets/teko_empty_state_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/shared/widgets/teko_gradient_background_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/shared/widgets/teko_input_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/shared/widgets/teko_password_field_test.dart` | 3 | 3 | 0 | 0 | OK |
| `test/shared/widgets/teko_semantics_test.dart` | 4 | 4 | 0 | 0 | OK |
| `test/shared/widgets/teko_skeleton_test.dart` | 6 | 6 | 0 | 0 | OK |
| `test/shared/widgets/teko_toast_test.dart` | 7 | 7 | 0 | 0 | OK |
| `test/tool/openapi_codegen/dart_enum_parser_test.dart` | 8 | 8 | 0 | 0 | OK |
| `test/tool/openapi_codegen/dart_model_parser_test.dart` | 9 | 9 | 0 | 0 | OK |
| `test/tool/openapi_codegen/drift_checker_test.dart` | 28 | 28 | 0 | 0 | OK |
| `test/tool/openapi_codegen/model_generator_test.dart` | 22 | 22 | 0 | 0 | OK |
| `test/tool/qa_junit_test.dart` | 4 | 4 | 0 | 0 | OK |

### Casos fallidos

Ninguno.

### Casos omitidos

Ninguno.

### Cobertura por directorio de `lib/`

| Directorio | Líneas cubiertas | Instrumentadas | % |
|---|---:|---:|---:|
| `lib/app.dart` | 59 | 89 | 66.3 |
| `lib/core/api_client` | 69 | 80 | 86.3 |
| `lib/core/auth` | 115 | 132 | 87.1 |
| `lib/core/config` | 0 | 4 | 0.0 |
| `lib/core/locale` | 11 | 11 | 100.0 |
| `lib/core/location` | 6 | 25 | 24.0 |
| `lib/core/mode` | 1 | 1 | 100.0 |
| `lib/core/realtime` | 70 | 99 | 70.7 |
| `lib/core/theme` | 44 | 50 | 88.0 |
| `lib/core/update` | 110 | 145 | 75.9 |
| `lib/design_system` | 1 | 2 | 50.0 |
| `lib/features/account_deletion` | 179 | 192 | 93.2 |
| `lib/features/ai_disclosures` | 59 | 64 | 92.2 |
| `lib/features/auth` | 357 | 398 | 89.7 |
| `lib/features/budgets` | 312 | 399 | 78.2 |
| `lib/features/categories` | 44 | 49 | 89.8 |
| `lib/features/contracts` | 284 | 325 | 87.4 |
| `lib/features/home` | 112 | 117 | 95.7 |
| `lib/features/legal_consents` | 284 | 343 | 82.8 |
| `lib/features/locations` | 221 | 224 | 98.7 |
| `lib/features/notifications` | 93 | 136 | 68.4 |
| `lib/features/payments` | 754 | 851 | 88.6 |
| `lib/features/professional_documents` | 217 | 363 | 59.8 |
| `lib/features/professional_portfolio` | 156 | 315 | 49.5 |
| `lib/features/professional_profile` | 244 | 276 | 88.4 |
| `lib/features/profile` | 218 | 263 | 82.9 |
| `lib/features/promotions` | 73 | 79 | 92.4 |
| `lib/features/ratings` | 251 | 270 | 93.0 |
| `lib/features/service_progress` | 195 | 287 | 67.9 |
| `lib/features/services` | 712 | 790 | 90.1 |
| `lib/l10n` | 442 | 989 | 44.7 |
| `lib/shared/widgets` | 304 | 319 | 95.3 |

## 3. Defectos encontrados

- DEF-MOB-AUTH-001 (P0): la ruta `/perfil` no tenía punto de entrada en la UI (logout y Mi perfil inalcanzables). Detectado al escribir el flujo Maestro de logout (CP-MOB-AUTH-006). Corregido con el ícono `home.home.profile_button` en el AppBar de Home; cubierto por CP-MOB-AUTH-002 (widget test nuevo).

## 4. Desvíos y observaciones

- Sin flakies, sin omitidos. Se agregan 5 tests (CP-MOB-CAT-004: 4 del parser JUnit; CP-MOB-AUTH-002: 1 del acceso a perfil).
- Esta ejecución es solo `flutter test` (VM). Los flujos Maestro (`.maestro/`, CP-MOB-AUTH-003..008 y CP-MOB-CAT-001..003) **no se ejecutaron: sin dispositivo ni emulador**; solo se validó su sintaxis con `maestro check-syntax` 2.11.0. No existe informe de ejecución de Maestro.
- Se compiló `flutter build apk --debug` con `dart_defines.e2e.json` y el manifiesto fusionado contiene `networkSecurityConfig` (solo debug).

## 5. Evidencia

- Salida cruda: `build/qa/unit.jsonl` (no se commitea).
- Cobertura: `coverage/lcov.info` (no se commitea).

## 6. Veredicto

APROBADO para el nivel unit/widget (643/643, 0 fallos, defecto DEF-MOB-AUTH-001 corregido). El nivel e2e real queda pendiente de ejecución con dispositivo.
