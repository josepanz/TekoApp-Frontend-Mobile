import 'package:flutter/material.dart';

/// Input de texto base compartido — equivalente a `TekoApp-Web/src/components/ui/input.tsx`.
/// Siempre lleva `labelText` (nunca un input "pelado" sin nombre accesible, ver
/// `.claude/rules/design-system.md`); el error se asocia al campo vía `errorText` del propio
/// `TextFormField`, no un texto suelto aparte.
class TekoInput extends StatelessWidget {
  const TekoInput({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.validator,
    this.initialValue,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
