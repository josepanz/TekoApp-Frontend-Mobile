import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_mode.dart';

/// Modo activo (cliente/profesional) — en memoria, sin persistencia entre sesiones (online-only,
/// ver `openspec/decisions.md`). Default `client`: toda cuenta opera como cliente sin
/// configuración previa.
final appModeProvider = StateProvider<AppMode>((ref) => AppMode.client);
