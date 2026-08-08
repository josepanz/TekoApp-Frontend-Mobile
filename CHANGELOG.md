## [1.0.0-develop.13](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.12...v1.0.0-develop.13) (2026-08-08)

### Features

* **services:** modelos y repositorio compartido de Service/ServiceRequest ([717d7a8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/717d7a89975df19083ceacc873944347a8963828))

## [1.0.0-develop.12](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.11...v1.0.0-develop.12) (2026-08-08)

### Features

* **categories:** catálogo de categorías y tipos de servicio ([142f450](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/142f45080c028ed5742a38ac9893d3f205705b34))

## [1.0.0-develop.11](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.10...v1.0.0-develop.11) (2026-08-08)

### Documentation

* formalizar decisiones de la Fase 0003 (marketplace de servicios) ([9e6ef28](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9e6ef28baedcb7092ab99afce104671231669820))

## [1.0.0-develop.10](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.9...v1.0.0-develop.10) (2026-08-08)

### Features

* **profile:** pantalla Mi perfil real (ver/editar + avatar) ([cf67422](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/cf67422600983c76e52cae5c77fef6d8b283d4bc))

## [1.0.0-develop.9](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.8...v1.0.0-develop.9) (2026-08-08)

### Features

* **design-system:** widgets base compartidos (Button, Card, Avatar, Badge, Input) ([7caccaf](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7caccaf15417a623f46b02e90914e6d3bc05d24b))

## [1.0.0-develop.8](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.7...v1.0.0-develop.8) (2026-08-08)

### Features

* **design-system:** tokens reales, ThemeData de marca y Poppins ([db15ed1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/db15ed1189bfbf9647a80de9754ece9acbbb5307)), closes [#28A745](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/28A745) [#0D1B2A](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/0D1B2A) [#F5F7FA](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/F5F7FA)

## [1.0.0-develop.7](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.6...v1.0.0-develop.7) (2026-08-08)

### Features

* **auth:** logout real + guard de go_router basado en sesion real ([fc79655](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fc796557bed16a307d80a7b914284f6084865b6e))

## [1.0.0-develop.6](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.5...v1.0.0-develop.6) (2026-08-08)

### Features

* **auth:** pantalla de login real con los 3 estados de error ([e48dbec](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e48dbec55a5fc9f15953589fe6c4163bbe48c109))

## [1.0.0-develop.5](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.4...v1.0.0-develop.5) (2026-08-08)

### Features

* **auth:** interceptor de refresh automatico + sessionProvider real ([e729c0d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e729c0dbe2d645cf6f8ef5a9ac9436bf744b6bb1))

## [1.0.0-develop.4](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.3...v1.0.0-develop.4) (2026-08-08)

### Features

* **auth:** cifrado RSA-OAEP, cookie jar seguro y AuthRepository real ([d91c183](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d91c183a288e9e0a53920da176c2ccece6f41937))

## [1.0.0-develop.3](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.2...v1.0.0-develop.3) (2026-08-08)

### Documentation

* **decisions:** confirmar almacenamiento de tokens y padding RSA contra el backend real ([548939d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/548939dd596f187822e935000f582b6d439a6e8e))

## [1.0.0-develop.2](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.1...v1.0.0-develop.2) (2026-08-07)

### Features

* **bootstrap:** cerrar checkpoints pendientes de la Fase 0001 ([91d56d5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/91d56d557987711531e2dd502a72f5c7e35dd6b5))

## 1.0.0-develop.1 (2026-08-03)

### Bug Fixes

* agregar conventional-changelog-conventionalcommits (preset usado por commit-analyzer/release-notes-generator) ([30f3b65](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/30f3b652b7dec829b9b1375a139e73538b39eaad))
* bundle id iOS quedaba en tekoappMobile (camelCase), corregido a mobile ([6fc90dc](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/6fc90dc8de0e2458fecc23daf17af4bd00abd20e))
* formato dart + brand local + CI multi-ambiente + CONTRIBUTING.md ([539424a](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/539424a51b4eea66bf6bd9bb89c669731649d9f1))
* indentacion rota en scaffold-native.yml rompia el parseo YAML ([6ef6ba3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/6ef6ba3fbfb52d3ea66523f5663786bd0274d2ea))
* secrets no es evaluable en if: de job/step - exponerlo via job check-secrets ([bff24a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bff24a688103c332df35aa1d6a2adbe9258ceec0))
* usar mv en vez de git mv (archivos aun no trackeados) en scaffold-native.yml ([871650d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/871650d9e3cde38f973947dc09baaa6d8b92b520))

### Features

* **ci:** agregar pipeline de release (GitHub Release + firma + stores) ([175a850](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/175a85066bd6e4e01c18f2692678d620b5efed1c))
* Fase 0001 — bootstrap del código Flutter (esqueleto) ([26d06b2](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/26d06b21e9c317bfa0f1c2a51aec7630e0a82e84))

### Documentation

* agregar ARCHITECTURE.md en la raiz y corregir email de contacto ([5588815](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5588815a62c3f792eded7f67196d49aea61e1f67))
* agregar ecosistema .claude completo y reflejar desbloqueo de FCM ([1a02007](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1a02007a0aa48e06de36740ce084950999af5d44))
* documentacion completa SDD (OpenSpec) para arrancar el codigo de mobile ([b966159](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b96615936c2765be57b140e42a45082413557be8))
