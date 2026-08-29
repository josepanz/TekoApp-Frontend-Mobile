/// `TipMode` — la UI de esta fase solo ofrece `percentage`/`free` (chips de % sugerido + monto
/// libre); `fixed` existe en el dominio/backend pero no tiene una config de montos preestablecidos
/// todavía, así que no se expone ningún control propio para elegirlo (ver decisions.md).
enum TipMode {
  percentage,
  fixed,
  free;

  static TipMode fromJson(String value) {
    switch (value) {
      case 'PERCENTAGE':
        return TipMode.percentage;
      case 'FIXED':
        return TipMode.fixed;
      case 'FREE':
        return TipMode.free;
      default:
        throw ArgumentError('TipMode desconocido: $value');
    }
  }

  String toJson() {
    switch (this) {
      case TipMode.percentage:
        return 'PERCENTAGE';
      case TipMode.fixed:
        return 'FIXED';
      case TipMode.free:
        return 'FREE';
    }
  }
}
