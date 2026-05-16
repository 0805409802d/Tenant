/// Formateadores de datos para mostrar en la UI.
///
/// Uso:
/// ```dart
/// Text(AppFormatters.price(24.99))      // → "$24.99"
/// Text(AppFormatters.date(createdAt))   // → "13 mayo 2026"
/// Text(AppFormatters.phone('+593999'))  // → "+593 999"
/// ```
abstract final class AppFormatters {
  // ──────────────────────────────────────────
  // PRECIO
  // ──────────────────────────────────────────

  /// Formatea un precio con símbolo de moneda.
  /// Por defecto usa "$". Configurable para otros mercados.
  static String price(double amount, {String symbol = '\$', int decimals = 2}) {
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }

  /// Calcula y formatea la ganancia neta.
  /// [salePrice] - [netPrice] = ganancia en valor y porcentaje.
  static Map<String, String> profitDetails({
    required double salePrice,
    required double netPrice,
  }) {
    final profit = salePrice - netPrice;
    final percent = netPrice > 0 ? (profit / netPrice * 100) : 0.0;
    return {
      'amount':  price(profit),
      'percent': '${percent.toStringAsFixed(1)}%',
    };
  }

  /// Calcula el total con IVA.
  static double totalWithTax(double amount, double taxPercent) {
    return amount * (1 + taxPercent / 100);
  }

  // ──────────────────────────────────────────
  // FECHA
  // ──────────────────────────────────────────

  static const _months = [
    '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// "13 mayo 2026"
  static String date(DateTime dt) =>
      '${dt.day} ${_months[dt.month]} ${dt.year}';

  /// "13 may. 2026"
  static String dateShort(DateTime dt) =>
      '${dt.day} ${_months[dt.month].substring(0, 3)}. ${dt.year}';

  /// "13/05/2026"
  static String dateNumeric(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  /// "13 mayo 2026, 14:30"
  static String dateTime(DateTime dt) =>
      '${date(dt)}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ──────────────────────────────────────────
  // TELÉFONO
  // ──────────────────────────────────────────

  /// Formatea un número de teléfono eliminando caracteres no numéricos
  /// excepto el + inicial.
  static String phone(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned;
  }

  // ──────────────────────────────────────────
  // SLUG / URL
  // ──────────────────────────────────────────

  /// Convierte un nombre en slug URL-friendly.
  /// "Mi Restaurante!" → "mi-restaurante"
  static String slug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  /// Construye la URL pública de un tenant.
  /// "mi-restaurante" → "https://mi-restaurante.quinindews.com"
  static String tenantUrl(String slug) =>
      'https://$slug.quinindews.com';

  // ──────────────────────────────────────────
  // TEXTO
  // ──────────────────────────────────────────

  /// Trunca un texto a [maxChars] y añade "…".
  static String truncate(String text, {int maxChars = 80}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trimRight()}…';
  }

  /// Capitaliza la primera letra de cada palabra.
  static String titleCase(String text) {
    return text.split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Iniciales de un nombre completo: "María García" → "MG"
  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
