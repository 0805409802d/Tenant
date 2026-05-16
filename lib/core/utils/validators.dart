/// Validadores de formulario reutilizables para toda la plataforma.
///
/// Uso en TextFormField:
/// ```dart
/// AppTextField(
///   validator: AppValidators.email,
/// )
/// ```
abstract final class AppValidators {
  // ──────────────────────────────────────────
  // EMAIL
  // ──────────────────────────────────────────

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo electrónico.';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'El formato del correo no es válido.';
    return null;
  }

  // ──────────────────────────────────────────
  // CONTRASEÑA
  // ──────────────────────────────────────────

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma la contraseña.';
    if (value != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  // ──────────────────────────────────────────
  // TELÉFONO
  // ──────────────────────────────────────────

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu número de teléfono.';
    final phoneRegex = RegExp(r'^\+?[\d\s\-()]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) return 'El formato del número no es válido.';
    return null;
  }

  // ──────────────────────────────────────────
  // TEXTO REQUERIDO (genérico)
  // ──────────────────────────────────────────

  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName es obligatorio.';
    return null;
  }

  static String? requiredMin(String? value, int minLength, {String fieldName = 'Este campo'}) {
    final base = required(value, fieldName: fieldName);
    if (base != null) return base;
    if (value!.trim().length < minLength) return '$fieldName debe tener al menos $minLength caracteres.';
    return null;
  }

  // ──────────────────────────────────────────
  // NOMBRE DE NEGOCIO / EMPRESA
  // ──────────────────────────────────────────

  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa el nombre del negocio.';
    if (value.trim().length < 3) return 'El nombre debe tener al menos 3 caracteres.';
    if (value.trim().length > 60) return 'El nombre no puede superar los 60 caracteres.';
    return null;
  }

  // ──────────────────────────────────────────
  // PREGUNTAS DE SEGURIDAD
  // ──────────────────────────────────────────

  static String? securityQuestion(String? value) =>
      required(value, fieldName: 'La pregunta');

  static String? securityAnswer(String? value) {
    if (value == null || value.trim().isEmpty) return 'La respuesta es obligatoria.';
    if (value.trim().length < 2) return 'La respuesta es muy corta.';
    return null;
  }

  // ──────────────────────────────────────────
  // PRECIO / NÚMERO
  // ──────────────────────────────────────────

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa el precio.';
    final num = double.tryParse(value.trim().replaceAll(',', '.'));
    if (num == null || num < 0) return 'El precio debe ser un número positivo.';
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'El valor'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName es obligatorio.';
    final num = double.tryParse(value.trim().replaceAll(',', '.'));
    if (num == null || num <= 0) return '$fieldName debe ser un número mayor a 0.';
    return null;
  }
}
