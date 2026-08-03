import 'package:flutter/material.dart';

/// Wrapper genérico de loading/error/data para pantallas que consumen un `AsyncValue` de
/// Riverpod — evita repetir el mismo `switch`/`when` en cada widget de dominio (regla DRY, ver
/// `.claude/agents/code-reviewer.md`). Reusar esto en vez de escribir el manejo de estados a mano
/// por pantalla.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.data,
    required this.builder,
    this.errorMessage,
    this.emptyMessage,
    this.isEmpty = false,
  });

  final bool isLoading;
  final bool hasError;
  final T? data;
  final Widget Function(BuildContext context, T data) builder;
  final String? errorMessage;
  final String? emptyMessage;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError || data == null) {
      return Center(
        child: Text(
          errorMessage ?? 'Ocurrió un error inesperado.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? 'No hay datos para mostrar.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return builder(context, data as T);
  }
}
