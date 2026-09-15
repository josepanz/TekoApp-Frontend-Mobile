## [1.0.0-qa.5](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-qa.4...v1.0.0-qa.5) (2026-09-15)

### Bug Fixes

* **api:** centralizar el prefijo de version v1 en la url base ([9cdd203](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9cdd2031ba4cebaa9d34493c28cb941467eaed3a))
* **api:** prefijar /v1 en el resto de los endpoints versionados del backend ([88100d9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/88100d99ce0b9178fa885090edb68c6511502a5f))
* **auth:** configurar local_auth en android e ios para el login biometrico ([2a01885](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2a01885bbd61074bef76eada06d5822c1d38d120))
* **auth:** coordinar refrescos de token concurrentes con un solo request en vuelo ([7d6c643](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7d6c64385e3ea5fb80e14860b31f0c7dceaf7d72))
* **auth:** prefijar /v1 en las llamadas versionadas del backend ([c653576](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c65357680d94936f1e7a2d11821ecc927c88a89f))
* **consentimientos:** evitar que un 403 CONSENT_REQUIRED cuelgue la app sin salida ([08fa295](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/08fa295287b0f7c6ec6b4775a1719ff471aa3b8c))
* **contrato:** cerrar 3 hallazgos de drift tras cambios del backend ([029a505](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/029a5051f7c7ea15a6fa79f9d84d157aa4c4d5e2))
* **contrato:** migrar ProfessionalProfile a codegen desde ProfessionalDetailResponseDTO real (M-04) ([dbd8561](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dbd856157555f57caf48d745652bae9d50e4d96c))
* **contrato:** migrar Service a codegen desde ServiceDetailResponseDTO real (M-04) ([c75cb89](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c75cb8967a6e5f3d47e74a8cba3e1adb177ba619))
* **contrato:** registrar el renombre de LoginResult y documentar el falso positivo ([9ba5c70](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9ba5c70088b9e23bf67fb346029a472f6399369c))
* **design-system:** corregir accent500 al ancla exacta de marca ([#17](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/17)BEBB) ([7babcec](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7babceca349041756f81247d22b76629e4372acd)), closes [#17BEBB](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/17BEBB)
* **ios:** declarar el uso de camara y galeria en Info.plist ([71a4fab](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/71a4fabad488de353bb24b2e616a1f5a6fcd45e9))
* **portfolio:** degradar con placeholder cuando la URL presignada expira ([9f22f1f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9f22f1f53f0790acda278e5717776da4f312eae7))
* **ratings:** aceptar userId y professionalId nulos en calificaciones anonimas ([c78cd12](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c78cd12dc27e6fee3c94a69a9997c4218343a7b8))
* **realtime:** reconectar el socket de ubicacion con token fresco al caerse ([99d4f59](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/99d4f593bbb3896a66ec3eba6714a2e680d1a2ec))
* **release:** conservar las dependencias de develop al promover a qa ([6351716](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/63517161454765d1bd2c3a91f08fb346e87ad9f3))
* **ui:** traducir los textos por defecto de AsyncStateView y permitir reintentar ([f7443f0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f7443f065e31045374cf3b9330a1f820dca2fae6))

### Features

* **auth:** login biometrico opt-in tras logout explicito (I-05) ([fd15146](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fd151460d1e89b603c22f00af65526dac93ab329))
* **categorias:** agregar campos faltantes de CategoryDetailResponseDTO ([2aeec39](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2aeec39db3580d30b15791bc5b2c651341513be0))
* **contrato:** agregar verificador de drift de modelos contra el swagger ([13545a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/13545a6a95230b0f5e674941c317381dd85a1f6d))
* **contrato:** comparar valores de enum en el verificador de drift ([ba3c99b](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ba3c99b7bea62b8282db8231d6f66acd91f0311c))
* **contrato:** eximir CategoryStatus como enum espejo en model_mapping.dart ([206ce37](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/206ce37823a15db974e18cf17275f5973476307c))
* **contrato:** migrar contracts a codegen (M-04) ([2cc5873](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2cc5873cf2758ac34377e6099805656a5ba36e28))
* **contrato:** migrar Payment a codegen desde el OpenAPI real (M-04) ([6649ddd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/6649ddd5037600515b13002df0e30c1548bd3840))
* **contrato:** migrar professional_documents a codegen (M-04) ([7b42e40](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7b42e4050da4f2c62b6fa2b6910c4634933eb7c6))
* **contrato:** migrar promotions a codegen (M-04) ([2cd9ae3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2cd9ae3a42f93587e6649da1ca69958c0be48747))
* **contrato:** soportar objetos anidados en el generador de modelos ([3c523ec](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3c523ecaa73a9f08229aa6fc3831ec9a5b97a799))
* **cuenta:** implementar el borrado de cuenta con ventana de gracia ([400fce5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/400fce57a04f266a02c4548fc2dea59878ffb4e8))
* **home:** agregar CTA de reclutamiento de profesionales ([#77](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/77)) ([7122a33](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7122a3310cad75cc3eb6512db094ecb60348444f))
* **network:** reintentar requests idempotentes ante fallos transitorios ([36632b1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/36632b1818e3458260d058ce523e60f7676c3a15))
* **pagos:** agregar campos faltantes de PaymentMethodDetailResponseDTO ([94a573e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/94a573e05df4efa229dda7461cedd7e4fb11f7d8))
* **pagos:** deshabilitar los medios de pago vencidos en el selector ([bd4d1dd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bd4d1dd7367e5c8044263f376a2020a6cb821521))
* **payments:** exponer los campos de detalle que el backend ya devuelve ([957bbfb](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/957bbfb5320c7fea27959571bd34820c979a6e0b))
* **professional-portfolio:** galería de portafolio de trabajos ([#78](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/78)) ([bd8c21f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bd8c21f665dba159bc92a2070b5c40d7573ceaf4))
* **servicios:** agregar campos faltantes de ServiceUserSummaryResponseDTO ([c0d37e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c0d37e9ad425374ca5cdb8c072ad5251bbe11a90))
* **servicios:** mostrar el contacto del cliente y su consentimiento ([cc39a4b](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/cc39a4bd1884fc799faeced25f13e7e439d90f38))
* **tracking:** avisar en pantalla cuando se cae la conexion de ubicacion ([d296bf2](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d296bf264970251e46a24e2845bb9549b3ec7062))
* **ubicaciones:** agregar isAvailable y lastUpdate faltantes en locations ([3b451b4](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3b451b4be830e56420913bb7916abe6045cc5e92))

### Documentation

* **api:** corregir la referencia al lugar del corte de versionado del backend ([63e2593](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/63e25930ad57745128928c220baf23c27a4ee627))
* **api:** registrar el corte a v1 y los requisitos nativos de local_auth ([2278825](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2278825d814fc2760b0d10fbe137f403c6462f7d))
* **audit:** plan de endurecimiento de plataforma 2026-09 (Mobile) ([21aed25](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/21aed2537301e54cb13f53f95bf71b4c24a6df3b))
* **audit:** WORKPLAN autocontenido y ejecutable de la tajada Mobile ([6d945c2](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/6d945c24f73bbda40fe6637f3011e93b89056575))
* **auth:** especificar el login biometrico ([e96a907](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e96a907b428b10426f56cdf3ade990402f5a0f1e))
* **contrato:** documentar el cierre de los 20 hallazgos de M-04 ([3525380](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3525380c398bc58d834514f54af141e4c1482d6f))
* **contrato:** documentar el cierre del cabo suelto de M-04 en CODEGEN.md ([b02ed82](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b02ed820ac51d9904a2713aad9831bdd5079e838))
* **contrato:** documentar el verificador de drift y el resultado contra los 72 modelos ([5614534](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/56145343455be83ebfabdf40f235bb55c5b37243))
* **contrato:** documentar la ronda de M-04 de contracts y la reevaluación de dominios sin drift ([dc1f9ca](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dc1f9ca334fb1c64b7cb4c12b503bbcd214c0c74))
* **contrato:** documentar la ronda de M-04 de professional_documents y promotions ([5ef9455](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5ef9455baf6aa662dcf7d501c6c345b26d022f96))
* **contrato:** proponer codegen de modelos desde el OpenAPI del backend ([11a1685](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/11a168543e79d25b36667d2426c437846150f7c3))
* **cuenta:** especificar el flujo de borrado de cuenta en la app ([274f947](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/274f9475a98043db1ab307bd9adbb2224cff4f09))
* **notificaciones:** especificar preferencias y bandeja in-app ([17ae9b3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/17ae9b37df3e07ea8603a3d26f784488a7ba106d))
* **soporte:** especificar el canal de soporte in-app ([96c3529](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/96c3529eb55573038fc021373eb7be77d61ca35f))
* **workplan:** agregar M-06 (cuelgue por consentimiento) y M-07 (/v1 incompleto) ([1511ca5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1511ca5c69a23c8d8709d69514f3ba402c06551a))
* **workplan:** anotar cierre del cabo suelto de M-03 en la tabla de seguimiento ([c4943e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c4943e9cb072191f108b3dac618912f563f6701a))
* **workplan:** marcar E-01 completo en la tabla de seguimiento ([ee543d8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ee543d8f6a8f0635608d6434808016945756a3fa))
* **workplan:** marcar I-01 completo en la tabla de seguimiento ([9c82251](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9c82251fc14c9ce686ba0ca118162a8e5409bf58))
* **workplan:** marcar I-01 con el hash de implementacion ([3666d32](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3666d320b146d2e4eb91373236cd077562c8858c))
* **workplan:** marcar I-02 completo en la tabla de seguimiento ([c158374](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c1583745420e6c10feed47efce33cc799d2731c2))
* **workplan:** marcar I-03 completo en la tabla de seguimiento ([5b017e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5b017e99d78f55fcc999867cccb36ef63eb1da6c))
* **workplan:** marcar I-04 completo en la tabla de seguimiento ([eedec24](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eedec24556c91f059fa22bdfba695bb22f4d2581))
* **workplan:** marcar I-05 completo en la tabla de seguimiento ([0fceaee](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0fceaeeaa956d791472b2ccf7a1f115fb06c869e))
* **workplan:** marcar I-05 con el hash de su implementacion en la tabla de seguimiento ([a4c758a](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/a4c758ab91fc24140ddbabba9f45f2552d2d2a93))
* **workplan:** marcar M-01 completo en la tabla de seguimiento ([a4942a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/a4942a61d79c9fe18d75d01c6b4049ea8888d065))
* **workplan:** marcar M-02 completo en la tabla de seguimiento ([1096b55](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1096b55c98f2879335a1ec9e910d6b9a2ae62091))
* **workplan:** marcar M-03 completo en la tabla de seguimiento ([b96d48e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b96d48e29917333d50addb7c38dfdcfcded09dae))
* **workplan:** marcar M-04 completo en la tabla de seguimiento ([ab753cb](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ab753cb7384ff2cb645cf9635b111fd4057d5dd8))
* **workplan:** marcar M-05 completo en la tabla de seguimiento ([1860b44](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1860b44f2ff38489dceaedf6ca72475e81af9d25))
* **workplan:** marcar M-06 completo en la tabla de seguimiento ([09ca8ac](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/09ca8ac360ebada3db560dc971202283683417aa))
* **workplan:** marcar M-07 completo en la tabla de seguimiento ([47e644b](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/47e644b2206a29543c3ce7e006a067a508c84c40))
* **workplan:** marcar workflow 1 completo en la tabla de seguimiento ([4221cde](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/4221cdef4a1041f968235ace68be58d66c7243a6))
* **workplan:** registrar el hash de la config nativa de local_auth en I-05 ([2e4cae9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e4cae9c1c5492995c9da0172e81175f85a53428))

## [1.0.0-qa.4](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-qa.3...v1.0.0-qa.4) (2026-09-01)

### Documentation

* **pending:** anotar que la app sigue sin conectar, reportado por José ([f63e4f8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f63e4f8a801933747d8e0004db6fe5d92f2ce89f)), closes [#72](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/72)
* **pending:** registrar hallazgo del cold start de Render (PR [#74](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/74)) ([aeff1be](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/aeff1be1426b69433c278b9aff19375232832f71))

### Bug Fixes

* **api-client:** subir el timeout de Dio para el cold start de Render ([72db3f1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/72db3f14dc962b8d6da325ecfcef1c853bce41bf))
* **ci:** pasar BASIC_AUTH_CLIENT_ID/SECRET al build y release de Flutter ([d2a96d5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d2a96d531aa036cef0daf02dc5d2a558de9390d4))

### Features

* **auth:** botón de ojito para mostrar/ocultar contraseña ([729c4bd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/729c4bd64478045c7ee314fb4d96413d09a51410))
* **auth:** registro público de usuario ([d736f95](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d736f95d7847b8696546962c7b87b58c72aae74c))

## [1.0.0-develop.6](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.5...v1.0.0-develop.6) (2026-09-01)

### Documentation

* **pending:** anotar que la app sigue sin conectar, reportado por José ([f63e4f8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f63e4f8a801933747d8e0004db6fe5d92f2ce89f)), closes [#72](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/72)
* **pending:** registrar hallazgo del cold start de Render (PR [#74](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/74)) ([aeff1be](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/aeff1be1426b69433c278b9aff19375232832f71))

## [1.0.0-develop.5](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.4...v1.0.0-develop.5) (2026-09-01)

### Bug Fixes

* **api-client:** subir el timeout de Dio para el cold start de Render ([72db3f1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/72db3f14dc962b8d6da325ecfcef1c853bce41bf))

## [1.0.0-develop.4](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.3...v1.0.0-develop.4) (2026-08-30)

### Features

* **auth:** botón de ojito para mostrar/ocultar contraseña ([729c4bd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/729c4bd64478045c7ee314fb4d96413d09a51410))
* **auth:** registro público de usuario ([d736f95](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d736f95d7847b8696546962c7b87b58c72aae74c))

### Bug Fixes

* **ci:** pasar BASIC_AUTH_CLIENT_ID/SECRET al build y release de Flutter ([d2a96d5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d2a96d531aa036cef0daf02dc5d2a558de9390d4))

## [1.0.0-develop.3](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.2...v1.0.0-develop.3) (2026-08-29)

### Documentation

* **claude:** guardar sesion 6 ([6df7715](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/6df7715243fda217532e7733b9b152523718a2fb))
* **claude:** guardar sesion 7 ([d40b542](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d40b5428a5e58ed32541d4efdd764d0657ff808b))
* **openspec:** documentar decisiones y agregar spec de registro de usuarios ([ba0910f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ba0910f081a0bb734e6a0f5299cd91f18d778552))
* **openspec:** documentar decisiones y specs del roadmap completo ([8c5ec7c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8c5ec7c5cc1b737c3490da155eed79d124316c15))
* **pending:** agregar consolidado de pendientes y decisiones abiertas ([46fc176](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/46fc1767fb7e854fe325068779d53b49a0562b2d))

### Features

* **ai-disclosures:** agregar checkbox de autodeclaracion y badge de disclosure de ia ([437e289](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/437e289f14f1ff83fccee0556298427bc6bbf5ed))
* **app-update:** agregar chequeo y actualizacion de version de la app ([a0b0434](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/a0b043475680068816dd1adee868de88c60db61c))
* **budgets:** agregar presupuestos multi-opcion ([cb18b00](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/cb18b0038827954ece673fc78d95cd188b075c40))
* **contracts:** agregar contratos desde presupuesto aceptado ([13ee7d0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/13ee7d06e63e38516ae098304117bf0e2cc82b25))
* **home:** rediseñar la pantalla de inicio del cliente ([579fc7e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/579fc7e8b8b4f27964cccc010b0edfabb2546fd1))
* **legal-consents:** agregar cliente de consentimiento y proteccion de datos ([2da0853](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2da0853e3a2fbc216ce10a6b1af86c42d69a35b1))
* **payments:** exponer referenceId, agregar propinas y corregir navegacion ([30332a7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/30332a7be00da13c99c21f48283880fcee0847af))
* **professional-documents:** agregar antecedentes y documentos profesionales ([2ef28b2](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2ef28b2834f47e408eacf2f2889c221d807e2c1d))
* **ratings:** agregar kpis de calificaciones propias y del profesional ([e75e734](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e75e734f033d44415667dd042191f6500cdeb73c))
* **service-progress:** agregar bitacora de trabajo en el detalle de servicio ([d7eecef](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d7eecefc2719e5cec96338ae69ed80c047fcf173))
* **shared:** agregar gradiente de marca reusable en pantallas de fondo plano ([2415d81](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2415d81e1a13db6e61477f080bd015a4ef34457d))

## [1.0.0-develop.2](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.1...v1.0.0-develop.2) (2026-08-23)

### Documentation

* **memory:** agregar adenda de promocion develop-qa-master ([#67](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/67)) ([07563e8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/07563e83ea86fe153d5d5b49f5d77f25abb03ce3))

## 1.0.0-develop.1 (2026-08-23)

### Bug Fixes

* agregar conventional-changelog-conventionalcommits (preset usado por commit-analyzer/release-notes-generator) ([c17ffbd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c17ffbdde0bb038fcecfb0f258c453241928c2ac))
* bundle id iOS quedaba en tekoappMobile (camelCase), corregido a mobile ([e096ec8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e096ec8ca137c541db6cb1f1bfee75d6454b46e0))
* formato dart + brand local + CI multi-ambiente + CONTRIBUTING.md ([eef7dd1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eef7dd1675b2b000a615d6b6df81e1e985e59159))
* indentacion rota en scaffold-native.yml rompia el parseo YAML ([609acca](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/609accab8f7f47584df98d0c41e8d58cef034b3b))
* make the Firebase Gradle plugin conditional on google-services.json existing ([#65](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/65)) ([6ba7179](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/6ba7179947f786ad5b1a7c4e24e968c76a2b7eeb))
* secrets no es evaluable en if: de job/step - exponerlo via job check-secrets ([5778c00](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5778c00090cacdaeff0c7630835703545efb2cdb))
* usar mv en vez de git mv (archivos aun no trackeados) en scaffold-native.yml ([5ac3247](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5ac3247eea5ab18713ce8be655b981ccd5e036e3))

### Features

* add socket_io_client/flutter_map deps and a socket-origin helper ([b0fce35](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b0fce358366c63b41a76993c987f8979d7fc9af7))
* **auth:** cifrado RSA-OAEP, cookie jar seguro y AuthRepository real ([3f8a9eb](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3f8a9eb7e48a8b6c6fdb92dcbe322b3fab3e0bcc))
* **auth:** interceptor de refresh automatico + sessionProvider real ([8c51425](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8c51425d2421ed3993d23cbdf9ff2629500c73d2))
* **auth:** logout real + guard de go_router basado en sesion real ([83b92e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/83b92e5b24fbb1029ce34607fa9c4927000d1678))
* **auth:** pantalla de login real con los 3 estados de error ([88f65a7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/88f65a7b5ec992a16b7c4595318af7bdb0fd66f8))
* **bootstrap:** cerrar checkpoints pendientes de la Fase 0001 ([c9fe663](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c9fe6636eb9e05c35e6377b96c43cf2790e5ab34))
* **categories:** catálogo de categorías y tipos de servicio ([fcea186](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fcea186aef4b87a43ef3fbcd68d4f4c09bd050d8))
* **ci:** agregar pipeline de release (GitHub Release + firma + stores) ([785ff82](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/785ff82be1f5aab0959ca68115331724207ea0e8))
* **design-system:** tokens reales, ThemeData de marca y Poppins ([7492028](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7492028a9f330ec6dc1cc2db1fe8f352287d9940)), closes [#28A745](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/28A745) [#0D1B2A](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/0D1B2A) [#F5F7FA](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/F5F7FA)
* **design-system:** widgets base compartidos (Button, Card, Avatar, Badge, Input) ([5710469](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/571046929b1d63efde2b75f0c7846cee5780e0ea))
* Fase 0001 — bootstrap del código Flutter (esqueleto) ([eb8ea51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eb8ea51f9c830139993b38968230b4fb35bb07d8))
* Fase 0005 — mapa de profesionales cercanos ([#61](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/61)) ([bb438e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bb438e9fe652a59612f664a495457b39e55a3b9a))
* Fase 0005 — push notifications (FCM) + specs backlog 2026-08-22 ([#64](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/64)) ([c27e5d5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c27e5d58075d595c08ad78b60669c085725d5587))
* Fase 0005 — tracking en vivo del profesional asignado ([#62](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/62)) ([dbf562c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dbf562ced43870b8cd694d541fb7bf05750d21f3))
* Fase 0006 — i18n, selector de idioma y pulido ([#63](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/63)) ([1f0858c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1f0858c308db5e9966c0d54a29dafca1586a7661))
* locations REST repository for toggling online status ([ab98ef4](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ab98ef4ccabe046a58c63a23234ceda5ec6d1373))
* locations socket service wrapper (core/realtime) ([06578c7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/06578c73428911269ac8d4a5c51f25ef19b9a62d))
* online status controller — toggle + live location emission ([0747c51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0747c514c9f2b0faa9d8c9eb0d3a5b2dd5c6561a))
* online/offline switch in the professional home screen ([d6a6946](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6a694676a69c13353193d771e4109b776fe0036))
* **payments:** models and repository for payment methods ([f6e404a](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f6e404a99f8588b0140fc8bf50be2ed24a40de64))
* **payments:** pay a completed service ([01c3c2f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/01c3c2f02d90cffdac7bcd907c3cb4824ffb65ef))
* **payments:** payment history and refund screens ([128d16e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/128d16eed73557d81fdac6a2dc02d0f10cbdc6dd))
* **payments:** payment methods screen (list, add, set default, delete) ([c24f112](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c24f112577431784a8bdb43a342d60fb5e9fa5ce))
* **professional:** selector de modo + gate + onboarding de perfil ([7f6cd37](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7f6cd37c66b593078b70e7edd065f885e14baf97))
* **profile:** pantalla Mi perfil real (ver/editar + avatar) ([dc2b6b6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dc2b6b63ffcef7546fd1e767ae118af6bdfed642))
* **promotions:** models and repository for validate/apply ([f0854e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f0854e5b1157412482e2676ea26a53115fbc1730))
* **ratings:** bidirectional rating on service completion ([bd43f28](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bd43f28fdccc2778607004f62cc5b4c833235284))
* **services:** modelos y repositorio compartido de Service/ServiceRequest ([0471e38](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0471e38f130cff1a09482b84850304ef81e31d33))
* **services:** modo cliente — mis servicios (listado + detalle) ([1e0f8c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1e0f8c9478a6f34af9cb81f93b607d2901e7f6a3))
* **services:** modo cliente — pedir servicio ([e102ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e102ae545ff0493fb712732e218d4b5e1e438601))
* **services:** modo cliente — ver propuestas competidoras y elegir una ([c2effb3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c2effb38c9eea87ace7b83c7111f0627fa933a3c))
* **services:** modo profesional — marcar en progreso / completado ([d5b5ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d5b5ae5d7de9251255f60c8f4b908010a6cc9c70))
* **services:** modo profesional — servicios disponibles + proponerse ([d001222](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d001222687bcede46a567445e4ad485c1cac8b7f))

### Refactoring

* extract shared location-permission/position-stream/token-reader providers ([32e9f20](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/32e9f2035bbf4880757fc44a93b2cf5589561cfb))

### Documentation

* agregar ARCHITECTURE.md en la raiz y corregir email de contacto ([04dd62c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/04dd62c75ca0ef7dcfef2560794e12dc95577d6d))
* agregar ecosistema .claude completo y reflejar desbloqueo de FCM ([e730f6d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e730f6da00ee65a129aa5b5848541408e3c46359))
* cerrar checklist de código de la Fase 0003 ([744a2a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/744a2a6bf3dea8d3c230ffe537e743ea456d7233)), closes [41-#49](https://github.com/josepanz/41-/issues/49)
* close Fase 0004 (payments and ratings) ([e000d14](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e000d14089fc2f454c1fd67fb22840d3de098890))
* **decisions:** confirmar almacenamiento de tokens y padding RSA contra el backend real ([e7927f1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e7927f10e72a3ed287f4b8d597377526ca7ce12b))
* document backlog of 5 requested features + dev-demo guide pointer ([d6b9650](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6b9650672151009130aaeeaebacb28aaebc4f5e))
* documentacion completa SDD (OpenSpec) para arrancar el codigo de mobile ([2e282ab](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e282ab4f3819734d3b3302607b6ac054066b60c))
* Fase 0004 decisions + build knowledge graph for the repo ([2e1f0b0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e1f0b0330776103806f680d7db470972ef693d9))
* formalizar decisiones de la Fase 0003 (marketplace de servicios) ([28a41c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/28a41c93908cac4fdd89657ac591830a792b57e8))
* pick flutter_map/OSM for maps, scope location emission to foreground-only ([7cd4aa1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7cd4aa125f7bb4e7ff8fa36ea62d47484aed83a2))

## 1.0.0-develop.1 (2026-08-23)

### Features

* add socket_io_client/flutter_map deps and a socket-origin helper ([b0fce35](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b0fce358366c63b41a76993c987f8979d7fc9af7))
* **auth:** cifrado RSA-OAEP, cookie jar seguro y AuthRepository real ([3f8a9eb](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3f8a9eb7e48a8b6c6fdb92dcbe322b3fab3e0bcc))
* **auth:** interceptor de refresh automatico + sessionProvider real ([8c51425](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8c51425d2421ed3993d23cbdf9ff2629500c73d2))
* **auth:** logout real + guard de go_router basado en sesion real ([83b92e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/83b92e5b24fbb1029ce34607fa9c4927000d1678))
* **auth:** pantalla de login real con los 3 estados de error ([88f65a7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/88f65a7b5ec992a16b7c4595318af7bdb0fd66f8))
* **bootstrap:** cerrar checkpoints pendientes de la Fase 0001 ([c9fe663](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c9fe6636eb9e05c35e6377b96c43cf2790e5ab34))
* **categories:** catálogo de categorías y tipos de servicio ([fcea186](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fcea186aef4b87a43ef3fbcd68d4f4c09bd050d8))
* **ci:** agregar pipeline de release (GitHub Release + firma + stores) ([785ff82](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/785ff82be1f5aab0959ca68115331724207ea0e8))
* **design-system:** tokens reales, ThemeData de marca y Poppins ([7492028](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7492028a9f330ec6dc1cc2db1fe8f352287d9940)), closes [#28A745](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/28A745) [#0D1B2A](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/0D1B2A) [#F5F7FA](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/F5F7FA)
* **design-system:** widgets base compartidos (Button, Card, Avatar, Badge, Input) ([5710469](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/571046929b1d63efde2b75f0c7846cee5780e0ea))
* Fase 0001 — bootstrap del código Flutter (esqueleto) ([eb8ea51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eb8ea51f9c830139993b38968230b4fb35bb07d8))
* Fase 0005 — mapa de profesionales cercanos ([#61](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/61)) ([bb438e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bb438e9fe652a59612f664a495457b39e55a3b9a))
* Fase 0005 — push notifications (FCM) + specs backlog 2026-08-22 ([#64](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/64)) ([c27e5d5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c27e5d58075d595c08ad78b60669c085725d5587))
* Fase 0005 — tracking en vivo del profesional asignado ([#62](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/62)) ([dbf562c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dbf562ced43870b8cd694d541fb7bf05750d21f3))
* Fase 0006 — i18n, selector de idioma y pulido ([#63](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/63)) ([1f0858c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1f0858c308db5e9966c0d54a29dafca1586a7661))
* locations REST repository for toggling online status ([ab98ef4](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ab98ef4ccabe046a58c63a23234ceda5ec6d1373))
* locations socket service wrapper (core/realtime) ([06578c7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/06578c73428911269ac8d4a5c51f25ef19b9a62d))
* online status controller — toggle + live location emission ([0747c51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0747c514c9f2b0faa9d8c9eb0d3a5b2dd5c6561a))
* online/offline switch in the professional home screen ([d6a6946](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6a694676a69c13353193d771e4109b776fe0036))
* **payments:** models and repository for payment methods ([f6e404a](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f6e404a99f8588b0140fc8bf50be2ed24a40de64))
* **payments:** pay a completed service ([01c3c2f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/01c3c2f02d90cffdac7bcd907c3cb4824ffb65ef))
* **payments:** payment history and refund screens ([128d16e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/128d16eed73557d81fdac6a2dc02d0f10cbdc6dd))
* **payments:** payment methods screen (list, add, set default, delete) ([c24f112](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c24f112577431784a8bdb43a342d60fb5e9fa5ce))
* **professional:** selector de modo + gate + onboarding de perfil ([7f6cd37](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7f6cd37c66b593078b70e7edd065f885e14baf97))
* **profile:** pantalla Mi perfil real (ver/editar + avatar) ([dc2b6b6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dc2b6b63ffcef7546fd1e767ae118af6bdfed642))
* **promotions:** models and repository for validate/apply ([f0854e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f0854e5b1157412482e2676ea26a53115fbc1730))
* **ratings:** bidirectional rating on service completion ([bd43f28](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bd43f28fdccc2778607004f62cc5b4c833235284))
* **services:** modelos y repositorio compartido de Service/ServiceRequest ([0471e38](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0471e38f130cff1a09482b84850304ef81e31d33))
* **services:** modo cliente — mis servicios (listado + detalle) ([1e0f8c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1e0f8c9478a6f34af9cb81f93b607d2901e7f6a3))
* **services:** modo cliente — pedir servicio ([e102ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e102ae545ff0493fb712732e218d4b5e1e438601))
* **services:** modo cliente — ver propuestas competidoras y elegir una ([c2effb3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c2effb38c9eea87ace7b83c7111f0627fa933a3c))
* **services:** modo profesional — marcar en progreso / completado ([d5b5ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d5b5ae5d7de9251255f60c8f4b908010a6cc9c70))
* **services:** modo profesional — servicios disponibles + proponerse ([d001222](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d001222687bcede46a567445e4ad485c1cac8b7f))

### Refactoring

* extract shared location-permission/position-stream/token-reader providers ([32e9f20](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/32e9f2035bbf4880757fc44a93b2cf5589561cfb))

### Documentation

* agregar ARCHITECTURE.md en la raiz y corregir email de contacto ([04dd62c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/04dd62c75ca0ef7dcfef2560794e12dc95577d6d))
* agregar ecosistema .claude completo y reflejar desbloqueo de FCM ([e730f6d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e730f6da00ee65a129aa5b5848541408e3c46359))
* cerrar checklist de código de la Fase 0003 ([744a2a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/744a2a6bf3dea8d3c230ffe537e743ea456d7233)), closes [41-#49](https://github.com/josepanz/41-/issues/49)
* close Fase 0004 (payments and ratings) ([e000d14](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e000d14089fc2f454c1fd67fb22840d3de098890))
* **decisions:** confirmar almacenamiento de tokens y padding RSA contra el backend real ([e7927f1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e7927f10e72a3ed287f4b8d597377526ca7ce12b))
* document backlog of 5 requested features + dev-demo guide pointer ([d6b9650](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6b9650672151009130aaeeaebacb28aaebc4f5e))
* documentacion completa SDD (OpenSpec) para arrancar el codigo de mobile ([2e282ab](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e282ab4f3819734d3b3302607b6ac054066b60c))
* Fase 0004 decisions + build knowledge graph for the repo ([2e1f0b0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e1f0b0330776103806f680d7db470972ef693d9))
* formalizar decisiones de la Fase 0003 (marketplace de servicios) ([28a41c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/28a41c93908cac4fdd89657ac591830a792b57e8))
* pick flutter_map/OSM for maps, scope location emission to foreground-only ([7cd4aa1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7cd4aa125f7bb4e7ff8fa36ea62d47484aed83a2))

### Bug Fixes

* agregar conventional-changelog-conventionalcommits (preset usado por commit-analyzer/release-notes-generator) ([c17ffbd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c17ffbdde0bb038fcecfb0f258c453241928c2ac))
* bundle id iOS quedaba en tekoappMobile (camelCase), corregido a mobile ([e096ec8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e096ec8ca137c541db6cb1f1bfee75d6454b46e0))
* formato dart + brand local + CI multi-ambiente + CONTRIBUTING.md ([eef7dd1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eef7dd1675b2b000a615d6b6df81e1e985e59159))
* indentacion rota en scaffold-native.yml rompia el parseo YAML ([609acca](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/609accab8f7f47584df98d0c41e8d58cef034b3b))
* secrets no es evaluable en if: de job/step - exponerlo via job check-secrets ([5778c00](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5778c00090cacdaeff0c7630835703545efb2cdb))
* usar mv en vez de git mv (archivos aun no trackeados) en scaffold-native.yml ([5ac3247](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5ac3247eea5ab18713ce8be655b981ccd5e036e3))

## 1.0.0-develop.1 (2026-08-23)

### Features

* add socket_io_client/flutter_map deps and a socket-origin helper ([b0fce35](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b0fce358366c63b41a76993c987f8979d7fc9af7))
* **auth:** cifrado RSA-OAEP, cookie jar seguro y AuthRepository real ([3f8a9eb](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3f8a9eb7e48a8b6c6fdb92dcbe322b3fab3e0bcc))
* **auth:** interceptor de refresh automatico + sessionProvider real ([8c51425](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8c51425d2421ed3993d23cbdf9ff2629500c73d2))
* **auth:** logout real + guard de go_router basado en sesion real ([83b92e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/83b92e5b24fbb1029ce34607fa9c4927000d1678))
* **auth:** pantalla de login real con los 3 estados de error ([88f65a7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/88f65a7b5ec992a16b7c4595318af7bdb0fd66f8))
* **bootstrap:** cerrar checkpoints pendientes de la Fase 0001 ([c9fe663](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c9fe6636eb9e05c35e6377b96c43cf2790e5ab34))
* **categories:** catálogo de categorías y tipos de servicio ([fcea186](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fcea186aef4b87a43ef3fbcd68d4f4c09bd050d8))
* **ci:** agregar pipeline de release (GitHub Release + firma + stores) ([785ff82](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/785ff82be1f5aab0959ca68115331724207ea0e8))
* **design-system:** tokens reales, ThemeData de marca y Poppins ([7492028](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7492028a9f330ec6dc1cc2db1fe8f352287d9940)), closes [#28A745](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/28A745) [#0D1B2A](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/0D1B2A) [#F5F7FA](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/F5F7FA)
* **design-system:** widgets base compartidos (Button, Card, Avatar, Badge, Input) ([5710469](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/571046929b1d63efde2b75f0c7846cee5780e0ea))
* Fase 0001 — bootstrap del código Flutter (esqueleto) ([eb8ea51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eb8ea51f9c830139993b38968230b4fb35bb07d8))
* Fase 0005 — mapa de profesionales cercanos ([#61](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/61)) ([bb438e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bb438e9fe652a59612f664a495457b39e55a3b9a))
* Fase 0005 — tracking en vivo del profesional asignado ([#62](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/62)) ([dbf562c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dbf562ced43870b8cd694d541fb7bf05750d21f3))
* Fase 0006 — i18n, selector de idioma y pulido ([#63](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/63)) ([1f0858c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1f0858c308db5e9966c0d54a29dafca1586a7661))
* locations REST repository for toggling online status ([ab98ef4](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ab98ef4ccabe046a58c63a23234ceda5ec6d1373))
* locations socket service wrapper (core/realtime) ([06578c7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/06578c73428911269ac8d4a5c51f25ef19b9a62d))
* online status controller — toggle + live location emission ([0747c51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0747c514c9f2b0faa9d8c9eb0d3a5b2dd5c6561a))
* online/offline switch in the professional home screen ([d6a6946](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6a694676a69c13353193d771e4109b776fe0036))
* **payments:** models and repository for payment methods ([f6e404a](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f6e404a99f8588b0140fc8bf50be2ed24a40de64))
* **payments:** pay a completed service ([01c3c2f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/01c3c2f02d90cffdac7bcd907c3cb4824ffb65ef))
* **payments:** payment history and refund screens ([128d16e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/128d16eed73557d81fdac6a2dc02d0f10cbdc6dd))
* **payments:** payment methods screen (list, add, set default, delete) ([c24f112](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c24f112577431784a8bdb43a342d60fb5e9fa5ce))
* **professional:** selector de modo + gate + onboarding de perfil ([7f6cd37](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7f6cd37c66b593078b70e7edd065f885e14baf97))
* **profile:** pantalla Mi perfil real (ver/editar + avatar) ([dc2b6b6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dc2b6b63ffcef7546fd1e767ae118af6bdfed642))
* **promotions:** models and repository for validate/apply ([f0854e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f0854e5b1157412482e2676ea26a53115fbc1730))
* **ratings:** bidirectional rating on service completion ([bd43f28](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bd43f28fdccc2778607004f62cc5b4c833235284))
* **services:** modelos y repositorio compartido de Service/ServiceRequest ([0471e38](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0471e38f130cff1a09482b84850304ef81e31d33))
* **services:** modo cliente — mis servicios (listado + detalle) ([1e0f8c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1e0f8c9478a6f34af9cb81f93b607d2901e7f6a3))
* **services:** modo cliente — pedir servicio ([e102ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e102ae545ff0493fb712732e218d4b5e1e438601))
* **services:** modo cliente — ver propuestas competidoras y elegir una ([c2effb3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c2effb38c9eea87ace7b83c7111f0627fa933a3c))
* **services:** modo profesional — marcar en progreso / completado ([d5b5ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d5b5ae5d7de9251255f60c8f4b908010a6cc9c70))
* **services:** modo profesional — servicios disponibles + proponerse ([d001222](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d001222687bcede46a567445e4ad485c1cac8b7f))

### Refactoring

* extract shared location-permission/position-stream/token-reader providers ([32e9f20](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/32e9f2035bbf4880757fc44a93b2cf5589561cfb))

### Documentation

* agregar ARCHITECTURE.md en la raiz y corregir email de contacto ([04dd62c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/04dd62c75ca0ef7dcfef2560794e12dc95577d6d))
* agregar ecosistema .claude completo y reflejar desbloqueo de FCM ([e730f6d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e730f6da00ee65a129aa5b5848541408e3c46359))
* cerrar checklist de código de la Fase 0003 ([744a2a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/744a2a6bf3dea8d3c230ffe537e743ea456d7233)), closes [41-#49](https://github.com/josepanz/41-/issues/49)
* close Fase 0004 (payments and ratings) ([e000d14](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e000d14089fc2f454c1fd67fb22840d3de098890))
* **decisions:** confirmar almacenamiento de tokens y padding RSA contra el backend real ([e7927f1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e7927f10e72a3ed287f4b8d597377526ca7ce12b))
* document backlog of 5 requested features + dev-demo guide pointer ([d6b9650](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6b9650672151009130aaeeaebacb28aaebc4f5e))
* documentacion completa SDD (OpenSpec) para arrancar el codigo de mobile ([2e282ab](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e282ab4f3819734d3b3302607b6ac054066b60c))
* Fase 0004 decisions + build knowledge graph for the repo ([2e1f0b0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e1f0b0330776103806f680d7db470972ef693d9))
* formalizar decisiones de la Fase 0003 (marketplace de servicios) ([28a41c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/28a41c93908cac4fdd89657ac591830a792b57e8))
* pick flutter_map/OSM for maps, scope location emission to foreground-only ([7cd4aa1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7cd4aa125f7bb4e7ff8fa36ea62d47484aed83a2))

### Bug Fixes

* agregar conventional-changelog-conventionalcommits (preset usado por commit-analyzer/release-notes-generator) ([c17ffbd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c17ffbdde0bb038fcecfb0f258c453241928c2ac))
* bundle id iOS quedaba en tekoappMobile (camelCase), corregido a mobile ([e096ec8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e096ec8ca137c541db6cb1f1bfee75d6454b46e0))
* formato dart + brand local + CI multi-ambiente + CONTRIBUTING.md ([eef7dd1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eef7dd1675b2b000a615d6b6df81e1e985e59159))
* indentacion rota en scaffold-native.yml rompia el parseo YAML ([609acca](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/609accab8f7f47584df98d0c41e8d58cef034b3b))
* secrets no es evaluable en if: de job/step - exponerlo via job check-secrets ([5778c00](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5778c00090cacdaeff0c7630835703545efb2cdb))
* usar mv en vez de git mv (archivos aun no trackeados) en scaffold-native.yml ([5ac3247](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5ac3247eea5ab18713ce8be655b981ccd5e036e3))

## 1.0.0-develop.1 (2026-08-22)

### Features

* add socket_io_client/flutter_map deps and a socket-origin helper ([b0fce35](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b0fce358366c63b41a76993c987f8979d7fc9af7))
* **auth:** cifrado RSA-OAEP, cookie jar seguro y AuthRepository real ([3f8a9eb](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3f8a9eb7e48a8b6c6fdb92dcbe322b3fab3e0bcc))
* **auth:** interceptor de refresh automatico + sessionProvider real ([8c51425](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8c51425d2421ed3993d23cbdf9ff2629500c73d2))
* **auth:** logout real + guard de go_router basado en sesion real ([83b92e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/83b92e5b24fbb1029ce34607fa9c4927000d1678))
* **auth:** pantalla de login real con los 3 estados de error ([88f65a7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/88f65a7b5ec992a16b7c4595318af7bdb0fd66f8))
* **bootstrap:** cerrar checkpoints pendientes de la Fase 0001 ([c9fe663](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c9fe6636eb9e05c35e6377b96c43cf2790e5ab34))
* **categories:** catálogo de categorías y tipos de servicio ([fcea186](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fcea186aef4b87a43ef3fbcd68d4f4c09bd050d8))
* **ci:** agregar pipeline de release (GitHub Release + firma + stores) ([785ff82](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/785ff82be1f5aab0959ca68115331724207ea0e8))
* **design-system:** tokens reales, ThemeData de marca y Poppins ([7492028](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7492028a9f330ec6dc1cc2db1fe8f352287d9940)), closes [#28A745](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/28A745) [#0D1B2A](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/0D1B2A) [#F5F7FA](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/F5F7FA)
* **design-system:** widgets base compartidos (Button, Card, Avatar, Badge, Input) ([5710469](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/571046929b1d63efde2b75f0c7846cee5780e0ea))
* Fase 0001 — bootstrap del código Flutter (esqueleto) ([eb8ea51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eb8ea51f9c830139993b38968230b4fb35bb07d8))
* Fase 0005 — mapa de profesionales cercanos ([#61](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/61)) ([bb438e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bb438e9fe652a59612f664a495457b39e55a3b9a))
* Fase 0005 — tracking en vivo del profesional asignado ([#62](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/62)) ([dbf562c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dbf562ced43870b8cd694d541fb7bf05750d21f3))
* locations REST repository for toggling online status ([ab98ef4](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ab98ef4ccabe046a58c63a23234ceda5ec6d1373))
* locations socket service wrapper (core/realtime) ([06578c7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/06578c73428911269ac8d4a5c51f25ef19b9a62d))
* online status controller — toggle + live location emission ([0747c51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0747c514c9f2b0faa9d8c9eb0d3a5b2dd5c6561a))
* online/offline switch in the professional home screen ([d6a6946](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6a694676a69c13353193d771e4109b776fe0036))
* **payments:** models and repository for payment methods ([f6e404a](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f6e404a99f8588b0140fc8bf50be2ed24a40de64))
* **payments:** pay a completed service ([01c3c2f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/01c3c2f02d90cffdac7bcd907c3cb4824ffb65ef))
* **payments:** payment history and refund screens ([128d16e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/128d16eed73557d81fdac6a2dc02d0f10cbdc6dd))
* **payments:** payment methods screen (list, add, set default, delete) ([c24f112](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c24f112577431784a8bdb43a342d60fb5e9fa5ce))
* **professional:** selector de modo + gate + onboarding de perfil ([7f6cd37](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7f6cd37c66b593078b70e7edd065f885e14baf97))
* **profile:** pantalla Mi perfil real (ver/editar + avatar) ([dc2b6b6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dc2b6b63ffcef7546fd1e767ae118af6bdfed642))
* **promotions:** models and repository for validate/apply ([f0854e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f0854e5b1157412482e2676ea26a53115fbc1730))
* **ratings:** bidirectional rating on service completion ([bd43f28](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bd43f28fdccc2778607004f62cc5b4c833235284))
* **services:** modelos y repositorio compartido de Service/ServiceRequest ([0471e38](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0471e38f130cff1a09482b84850304ef81e31d33))
* **services:** modo cliente — mis servicios (listado + detalle) ([1e0f8c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1e0f8c9478a6f34af9cb81f93b607d2901e7f6a3))
* **services:** modo cliente — pedir servicio ([e102ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e102ae545ff0493fb712732e218d4b5e1e438601))
* **services:** modo cliente — ver propuestas competidoras y elegir una ([c2effb3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c2effb38c9eea87ace7b83c7111f0627fa933a3c))
* **services:** modo profesional — marcar en progreso / completado ([d5b5ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d5b5ae5d7de9251255f60c8f4b908010a6cc9c70))
* **services:** modo profesional — servicios disponibles + proponerse ([d001222](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d001222687bcede46a567445e4ad485c1cac8b7f))

### Refactoring

* extract shared location-permission/position-stream/token-reader providers ([32e9f20](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/32e9f2035bbf4880757fc44a93b2cf5589561cfb))

### Documentation

* agregar ARCHITECTURE.md en la raiz y corregir email de contacto ([04dd62c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/04dd62c75ca0ef7dcfef2560794e12dc95577d6d))
* agregar ecosistema .claude completo y reflejar desbloqueo de FCM ([e730f6d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e730f6da00ee65a129aa5b5848541408e3c46359))
* cerrar checklist de código de la Fase 0003 ([744a2a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/744a2a6bf3dea8d3c230ffe537e743ea456d7233)), closes [41-#49](https://github.com/josepanz/41-/issues/49)
* close Fase 0004 (payments and ratings) ([e000d14](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e000d14089fc2f454c1fd67fb22840d3de098890))
* **decisions:** confirmar almacenamiento de tokens y padding RSA contra el backend real ([e7927f1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e7927f10e72a3ed287f4b8d597377526ca7ce12b))
* document backlog of 5 requested features + dev-demo guide pointer ([d6b9650](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6b9650672151009130aaeeaebacb28aaebc4f5e))
* documentacion completa SDD (OpenSpec) para arrancar el codigo de mobile ([2e282ab](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e282ab4f3819734d3b3302607b6ac054066b60c))
* Fase 0004 decisions + build knowledge graph for the repo ([2e1f0b0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e1f0b0330776103806f680d7db470972ef693d9))
* formalizar decisiones de la Fase 0003 (marketplace de servicios) ([28a41c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/28a41c93908cac4fdd89657ac591830a792b57e8))
* pick flutter_map/OSM for maps, scope location emission to foreground-only ([7cd4aa1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7cd4aa125f7bb4e7ff8fa36ea62d47484aed83a2))

### Bug Fixes

* agregar conventional-changelog-conventionalcommits (preset usado por commit-analyzer/release-notes-generator) ([c17ffbd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c17ffbdde0bb038fcecfb0f258c453241928c2ac))
* bundle id iOS quedaba en tekoappMobile (camelCase), corregido a mobile ([e096ec8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e096ec8ca137c541db6cb1f1bfee75d6454b46e0))
* formato dart + brand local + CI multi-ambiente + CONTRIBUTING.md ([eef7dd1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eef7dd1675b2b000a615d6b6df81e1e985e59159))
* indentacion rota en scaffold-native.yml rompia el parseo YAML ([609acca](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/609accab8f7f47584df98d0c41e8d58cef034b3b))
* secrets no es evaluable en if: de job/step - exponerlo via job check-secrets ([5778c00](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5778c00090cacdaeff0c7630835703545efb2cdb))
* usar mv en vez de git mv (archivos aun no trackeados) en scaffold-native.yml ([5ac3247](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5ac3247eea5ab18713ce8be655b981ccd5e036e3))

## 1.0.0-develop.1 (2026-08-22)

### Features

* add socket_io_client/flutter_map deps and a socket-origin helper ([b0fce35](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/b0fce358366c63b41a76993c987f8979d7fc9af7))
* **auth:** cifrado RSA-OAEP, cookie jar seguro y AuthRepository real ([3f8a9eb](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/3f8a9eb7e48a8b6c6fdb92dcbe322b3fab3e0bcc))
* **auth:** interceptor de refresh automatico + sessionProvider real ([8c51425](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8c51425d2421ed3993d23cbdf9ff2629500c73d2))
* **auth:** logout real + guard de go_router basado en sesion real ([83b92e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/83b92e5b24fbb1029ce34607fa9c4927000d1678))
* **auth:** pantalla de login real con los 3 estados de error ([88f65a7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/88f65a7b5ec992a16b7c4595318af7bdb0fd66f8))
* **bootstrap:** cerrar checkpoints pendientes de la Fase 0001 ([c9fe663](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c9fe6636eb9e05c35e6377b96c43cf2790e5ab34))
* **categories:** catálogo de categorías y tipos de servicio ([fcea186](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fcea186aef4b87a43ef3fbcd68d4f4c09bd050d8))
* **ci:** agregar pipeline de release (GitHub Release + firma + stores) ([785ff82](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/785ff82be1f5aab0959ca68115331724207ea0e8))
* **design-system:** tokens reales, ThemeData de marca y Poppins ([7492028](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7492028a9f330ec6dc1cc2db1fe8f352287d9940)), closes [#28A745](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/28A745) [#0D1B2A](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/0D1B2A) [#F5F7FA](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/F5F7FA)
* **design-system:** widgets base compartidos (Button, Card, Avatar, Badge, Input) ([5710469](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/571046929b1d63efde2b75f0c7846cee5780e0ea))
* Fase 0001 — bootstrap del código Flutter (esqueleto) ([eb8ea51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eb8ea51f9c830139993b38968230b4fb35bb07d8))
* Fase 0005 — mapa de profesionales cercanos ([#61](https://github.com/josepanz/TekoApp-Frontend-Mobile/issues/61)) ([bb438e9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bb438e9fe652a59612f664a495457b39e55a3b9a))
* locations REST repository for toggling online status ([ab98ef4](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ab98ef4ccabe046a58c63a23234ceda5ec6d1373))
* locations socket service wrapper (core/realtime) ([06578c7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/06578c73428911269ac8d4a5c51f25ef19b9a62d))
* online status controller — toggle + live location emission ([0747c51](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0747c514c9f2b0faa9d8c9eb0d3a5b2dd5c6561a))
* online/offline switch in the professional home screen ([d6a6946](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6a694676a69c13353193d771e4109b776fe0036))
* **payments:** models and repository for payment methods ([f6e404a](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f6e404a99f8588b0140fc8bf50be2ed24a40de64))
* **payments:** pay a completed service ([01c3c2f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/01c3c2f02d90cffdac7bcd907c3cb4824ffb65ef))
* **payments:** payment history and refund screens ([128d16e](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/128d16eed73557d81fdac6a2dc02d0f10cbdc6dd))
* **payments:** payment methods screen (list, add, set default, delete) ([c24f112](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c24f112577431784a8bdb43a342d60fb5e9fa5ce))
* **professional:** selector de modo + gate + onboarding de perfil ([7f6cd37](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7f6cd37c66b593078b70e7edd065f885e14baf97))
* **profile:** pantalla Mi perfil real (ver/editar + avatar) ([dc2b6b6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/dc2b6b63ffcef7546fd1e767ae118af6bdfed642))
* **promotions:** models and repository for validate/apply ([f0854e5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f0854e5b1157412482e2676ea26a53115fbc1730))
* **ratings:** bidirectional rating on service completion ([bd43f28](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/bd43f28fdccc2778607004f62cc5b4c833235284))
* **services:** modelos y repositorio compartido de Service/ServiceRequest ([0471e38](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0471e38f130cff1a09482b84850304ef81e31d33))
* **services:** modo cliente — mis servicios (listado + detalle) ([1e0f8c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/1e0f8c9478a6f34af9cb81f93b607d2901e7f6a3))
* **services:** modo cliente — pedir servicio ([e102ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e102ae545ff0493fb712732e218d4b5e1e438601))
* **services:** modo cliente — ver propuestas competidoras y elegir una ([c2effb3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c2effb38c9eea87ace7b83c7111f0627fa933a3c))
* **services:** modo profesional — marcar en progreso / completado ([d5b5ae5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d5b5ae5d7de9251255f60c8f4b908010a6cc9c70))
* **services:** modo profesional — servicios disponibles + proponerse ([d001222](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d001222687bcede46a567445e4ad485c1cac8b7f))

### Refactoring

* extract shared location-permission/position-stream/token-reader providers ([32e9f20](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/32e9f2035bbf4880757fc44a93b2cf5589561cfb))

### Documentation

* agregar ARCHITECTURE.md en la raiz y corregir email de contacto ([04dd62c](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/04dd62c75ca0ef7dcfef2560794e12dc95577d6d))
* agregar ecosistema .claude completo y reflejar desbloqueo de FCM ([e730f6d](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e730f6da00ee65a129aa5b5848541408e3c46359))
* cerrar checklist de código de la Fase 0003 ([744a2a6](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/744a2a6bf3dea8d3c230ffe537e743ea456d7233)), closes [41-#49](https://github.com/josepanz/41-/issues/49)
* close Fase 0004 (payments and ratings) ([e000d14](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e000d14089fc2f454c1fd67fb22840d3de098890))
* **decisions:** confirmar almacenamiento de tokens y padding RSA contra el backend real ([e7927f1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e7927f10e72a3ed287f4b8d597377526ca7ce12b))
* document backlog of 5 requested features + dev-demo guide pointer ([d6b9650](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/d6b9650672151009130aaeeaebacb28aaebc4f5e))
* documentacion completa SDD (OpenSpec) para arrancar el codigo de mobile ([2e282ab](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e282ab4f3819734d3b3302607b6ac054066b60c))
* Fase 0004 decisions + build knowledge graph for the repo ([2e1f0b0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2e1f0b0330776103806f680d7db470972ef693d9))
* formalizar decisiones de la Fase 0003 (marketplace de servicios) ([28a41c9](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/28a41c93908cac4fdd89657ac591830a792b57e8))
* pick flutter_map/OSM for maps, scope location emission to foreground-only ([7cd4aa1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/7cd4aa125f7bb4e7ff8fa36ea62d47484aed83a2))

### Bug Fixes

* agregar conventional-changelog-conventionalcommits (preset usado por commit-analyzer/release-notes-generator) ([c17ffbd](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/c17ffbdde0bb038fcecfb0f258c453241928c2ac))
* bundle id iOS quedaba en tekoappMobile (camelCase), corregido a mobile ([e096ec8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e096ec8ca137c541db6cb1f1bfee75d6454b46e0))
* formato dart + brand local + CI multi-ambiente + CONTRIBUTING.md ([eef7dd1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/eef7dd1675b2b000a615d6b6df81e1e985e59159))
* indentacion rota en scaffold-native.yml rompia el parseo YAML ([609acca](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/609accab8f7f47584df98d0c41e8d58cef034b3b))
* secrets no es evaluable en if: de job/step - exponerlo via job check-secrets ([5778c00](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5778c00090cacdaeff0c7630835703545efb2cdb))
* usar mv en vez de git mv (archivos aun no trackeados) en scaffold-native.yml ([5ac3247](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/5ac3247eea5ab18713ce8be655b981ccd5e036e3))

## [1.0.0-develop.30](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.29...v1.0.0-develop.30) (2026-08-22)

### Features

* add socket_io_client/flutter_map deps and a socket-origin helper ([69ac4a8](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/69ac4a8d438061be53c463fb0e5b1dcb5dadeb66))
* locations REST repository for toggling online status ([542e005](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/542e0058c074ee77464e3d5cdd629b3afa395f4b))
* locations socket service wrapper (core/realtime) ([8a180c5](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8a180c52feccd4ea4efe9e6036c15f72ba53be13))
* online status controller — toggle + live location emission ([e14bcdf](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/e14bcdfc6912863292bc670e71e8134e982d60ee))
* online/offline switch in the professional home screen ([9cac128](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9cac1287314284229fead651bc1298aadff05ec9))

### Refactoring

* extract shared location-permission/position-stream/token-reader providers ([03277c0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/03277c09b302ee3c7e9034f94310f41effc56da6))

### Documentation

* pick flutter_map/OSM for maps, scope location emission to foreground-only ([11ecb41](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/11ecb41a828e7f073abf9e0f28b1481ce78b12fc))

## [1.0.0-develop.29](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.28...v1.0.0-develop.29) (2026-08-09)

### Documentation

* document backlog of 5 requested features + dev-demo guide pointer ([fc21075](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/fc21075267cf9141175a6f0a13ecb9c449d8a8dd))

## [1.0.0-develop.28](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.27...v1.0.0-develop.28) (2026-08-08)

### Documentation

* close Fase 0004 (payments and ratings) ([2a341e2](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/2a341e283ebb2f7a682d37f41a70270b0bb31e82))

## [1.0.0-develop.27](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.26...v1.0.0-develop.27) (2026-08-08)

### Features

* **ratings:** bidirectional rating on service completion ([84b0206](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/84b020698d547277c0427ae487e399e23157bb2e))

## [1.0.0-develop.26](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.25...v1.0.0-develop.26) (2026-08-08)

### Features

* **payments:** pay a completed service ([a29591f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/a29591f58778194e2cb6188dd0286605779dc997))

## [1.0.0-develop.25](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.24...v1.0.0-develop.25) (2026-08-08)

### Features

* **payments:** payment history and refund screens ([f2ae344](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/f2ae34416af8b951599820ce4af5174633aae6a9))

## [1.0.0-develop.24](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.23...v1.0.0-develop.24) (2026-08-08)

### Features

* **promotions:** models and repository for validate/apply ([9f60301](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9f603012fc3ba581c95fde565a2750f10e98c3f4))

## [1.0.0-develop.23](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.22...v1.0.0-develop.23) (2026-08-08)

### Features

* **payments:** payment methods screen (list, add, set default, delete) ([8a4d786](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/8a4d786521ee86631cade33af20470fb17e24f5f))

## [1.0.0-develop.22](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.21...v1.0.0-develop.22) (2026-08-08)

### Features

* **payments:** models and repository for payment methods ([52c9ea3](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/52c9ea33e71aa2f6d946245a1eefc4abec859989))

## [1.0.0-develop.21](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.20...v1.0.0-develop.21) (2026-08-08)

### Documentation

* Fase 0004 decisions + build knowledge graph for the repo ([9abc0d7](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/9abc0d7d892a13516c928f5b1ddbdc5f3508640d))

## [1.0.0-develop.20](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.19...v1.0.0-develop.20) (2026-08-08)

### Documentation

* cerrar checklist de código de la Fase 0003 ([886bf19](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/886bf19c731ead4783aaffb845694df421cb06aa)), closes [41-#49](https://github.com/josepanz/41-/issues/49)

## [1.0.0-develop.19](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.18...v1.0.0-develop.19) (2026-08-08)

### Features

* **services:** modo profesional — marcar en progreso / completado ([094f7b0](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/094f7b01a481f739d1cd1417f96be568be938002))

## [1.0.0-develop.18](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.17...v1.0.0-develop.18) (2026-08-08)

### Features

* **services:** modo cliente — ver propuestas competidoras y elegir una ([be8e41b](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/be8e41bfde560e7978a61d9f4da616a10a3a19d0))

## [1.0.0-develop.17](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.16...v1.0.0-develop.17) (2026-08-08)

### Features

* **services:** modo profesional — servicios disponibles + proponerse ([ed09fcc](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/ed09fcc2e56fba4744249f8b313965dbab69a836))

## [1.0.0-develop.16](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.15...v1.0.0-develop.16) (2026-08-08)

### Features

* **professional:** selector de modo + gate + onboarding de perfil ([0eaede1](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/0eaede17edfcfa3ed37066d0c3f6839e3052d0b8))

## [1.0.0-develop.15](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.14...v1.0.0-develop.15) (2026-08-08)

### Features

* **services:** modo cliente — mis servicios (listado + detalle) ([411590f](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/411590fbdfae0e4d3f84db972b1bff5aa206ad24))

## [1.0.0-develop.14](https://github.com/josepanz/TekoApp-Frontend-Mobile/compare/v1.0.0-develop.13...v1.0.0-develop.14) (2026-08-08)

### Features

* **services:** modo cliente — pedir servicio ([744e5ee](https://github.com/josepanz/TekoApp-Frontend-Mobile/commit/744e5ee5ffeef86f6fa56ae55da8acb3a5d09626))

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
