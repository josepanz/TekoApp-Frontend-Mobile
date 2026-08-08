/// Detalle mínimo de una `Promotion` — solo lo que la UI de esta fase muestra al confirmar un
/// código aplicado (nombre + código), no el resto de reglas de negocio (`maxUsage`, vigencia,
/// etc.), que el backend ya valida server-side.
class Promotion {
  const Promotion({required this.code, required this.name});

  final String code;
  final String name;

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}
