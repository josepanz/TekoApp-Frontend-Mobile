# Selectores E2E (Maestro)

Los ids se exponen como `Semantics(identifier: ...)` (Android: `resource-id`; iOS: `accessibilityIdentifier`). Convencion: `feature.pantalla.elemento`. Los `Key(...)` existentes se mantienen para los widget tests.

Maestro: `tapOn: { id: 'auth.login.submit_button' }`.

Los ids de quick access de Home se derivan de la Key (`home_X_button` -> `home.home.X_button`): `nearby_map_button`, `my_services_button`, `payment_methods_button`, `payment_history_button`, `my_contracts_button`, `my_rating_stats_button`.

| Id | Archivo |
|---|---|
| `auth.login.biometric_button` | `lib/features/auth/widgets/login_screen.dart` |
| `auth.login.email_field` | `lib/features/auth/widgets/login_screen.dart` |
| `auth.login.password_field` | `lib/features/auth/widgets/login_screen.dart` |
| `auth.login.register_link` | `lib/features/auth/widgets/login_screen.dart` |
| `auth.login.submit_button` | `lib/features/auth/widgets/login_screen.dart` |
| `auth.register.email_field` | `lib/features/auth/widgets/register_screen.dart` |
| `auth.register.first_name_field` | `lib/features/auth/widgets/register_screen.dart` |
| `auth.register.last_name_field` | `lib/features/auth/widgets/register_screen.dart` |
| `auth.register.login_link` | `lib/features/auth/widgets/register_screen.dart` |
| `auth.register.password_field` | `lib/features/auth/widgets/register_screen.dart` |
| `auth.register.phone_field` | `lib/features/auth/widgets/register_screen.dart` |
| `auth.register.submit_button` | `lib/features/auth/widgets/register_screen.dart` |
| `budgets.comparison.option_select_button` | `lib/features/budgets/widgets/budget_comparison_screen.dart` |
| `budgets.comparison.toggle_details_button` | `lib/features/budgets/widgets/budget_comparison_screen.dart` |
| `home.home.${quickAccessKey.replaceFirst(` | `lib/features/home/widgets/home_screen.dart` |
| `home.home.<quick_access>` | `lib/features/home/widgets/home_screen.dart` |
| `home.home.professional_mode_button` | `lib/features/home/widgets/home_screen.dart` |
| `home.home.recruit_professional_cta` | `lib/features/home/widgets/home_screen.dart` |
| `home.home.request_service_cta` | `lib/features/home/widgets/home_screen.dart` |
| `payments.history.item` | `lib/features/payments/widgets/payment_history_screen.dart` |
| `payments.pay.add_method_button` | `lib/features/payments/widgets/pay_service_screen.dart` |
| `payments.pay.confirm_button` | `lib/features/payments/widgets/pay_service_screen.dart` |
| `payments.pay.method_field` | `lib/features/payments/widgets/pay_service_screen.dart` |
| `payments.pay.promo_code_field` | `lib/features/payments/widgets/pay_service_screen.dart` |
| `payments.pay.validate_promo_button` | `lib/features/payments/widgets/pay_service_screen.dart` |
| `professional.home.back_to_client_button` | `lib/features/professional_profile/widgets/professional_home_screen.dart` |
| `professional.home.my_contracts_button` | `lib/features/professional_profile/widgets/professional_home_screen.dart` |
| `professional.home.my_documents_button` | `lib/features/professional_profile/widgets/professional_home_screen.dart` |
| `professional.home.my_portfolio_button` | `lib/features/professional_profile/widgets/professional_home_screen.dart` |
| `professional.home.my_rating_stats_button` | `lib/features/professional_profile/widgets/professional_home_screen.dart` |
| `professional.home.my_services_button` | `lib/features/professional_profile/widgets/professional_home_screen.dart` |
| `professional.home.online_switch` | `lib/features/professional_profile/widgets/professional_home_screen.dart` |
| `profile.profile.biometric_switch` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.change_avatar_button` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.delete_account_button` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.first_name_field` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.language_selector` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.last_name_field` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.logout_button` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.phone_field` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.privacy_button` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.save_button` | `lib/features/profile/widgets/profile_screen.dart` |
| `profile.profile.share_contact_checkbox` | `lib/features/profile/widgets/profile_screen.dart` |
| `ratings.rate.cancel_button` | `lib/features/ratings/widgets/rate_dialog.dart` |
| `ratings.rate.comment_field` | `lib/features/ratings/widgets/rate_dialog.dart` |
| `ratings.rate.star_$star` | `lib/features/ratings/widgets/rate_dialog.dart` |
| `ratings.rate.submit_button` | `lib/features/ratings/widgets/rate_dialog.dart` |
| `services.detail.pay_button` | `lib/features/services/widgets/service_detail_screen.dart` |
| `services.detail.rate_button` | `lib/features/services/widgets/service_detail_screen.dart` |
| `services.request.address_field` | `lib/features/services/widgets/request_service_screen.dart` |
| `services.request.ai_assisted_checkbox` | `lib/features/services/widgets/request_service_screen.dart` |
| `services.request.category_field` | `lib/features/services/widgets/request_service_screen.dart` |
| `services.request.description_field` | `lib/features/services/widgets/request_service_screen.dart` |
| `services.request.locate_button` | `lib/features/services/widgets/request_service_screen.dart` |
| `services.request.submit_button` | `lib/features/services/widgets/request_service_screen.dart` |
| `services.request.title_field` | `lib/features/services/widgets/request_service_screen.dart` |
| `services.request.type_field` | `lib/features/services/widgets/request_service_screen.dart` |
