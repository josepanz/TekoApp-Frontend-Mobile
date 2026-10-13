import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Campo de contraseña compartido — equivalente a
/// `TekoApp-Web/src/components/ui/password-input.tsx`: mismo `TextFormField` de siempre, con un
/// botón de ojito (mostrar/ocultar) como único agregado. Toda pantalla que pida una contraseña usa
/// este widget, nunca un `TextFormField(obscureText: true)` suelto sin forma de revisar lo tipeado
/// (ver `.claude/rules/design-system.md`, accesibilidad — ningún control solo-ícono sin label).
class TekoPasswordField extends StatefulWidget {
  const TekoPasswordField({
    super.key,
    required this.labelText,
    this.controller,
    this.enabled = true,
    this.validator,
    this.autofillHints,
    this.showLabel,
    this.hideLabel,
    this.semanticsIdentifier,
  });

  final String labelText;
  final TextEditingController? controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final String? showLabel;
  final String? hideLabel;

  /// Identificador estable (`feature.pantalla.elemento`) para selectores E2E.
  final String? semanticsIdentifier;

  @override
  State<TekoPasswordField> createState() => _TekoPasswordFieldState();
}

class _TekoPasswordFieldState extends State<TekoPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showLabel =
        widget.showLabel ?? l10n?.passwordShowTooltip ?? 'Mostrar contraseña';
    final hideLabel =
        widget.hideLabel ?? l10n?.passwordHideTooltip ?? 'Ocultar contraseña';
    final field = TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      validator: widget.validator,
      obscureText: !_visible,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          tooltip: _visible ? hideLabel : showLabel,
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
    if (widget.semanticsIdentifier == null) return field;
    return Semantics(identifier: widget.semanticsIdentifier, child: field);
  }
}
