import 'package:flutter/foundation.dart';
import 'tenant_config.dart';

/// Detecta el tenant activo según el entorno de ejecución.
///
/// En **web**: usa el subdominio y la ruta de la URL actual.
/// En **móvil/escritorio**: devuelve [TenantType.management] por defecto.
///
/// Esta clase es la única fuente de verdad para saber en qué espacio
/// está corriendo la app. El router y el [TenantProvider] la consumen.
class TenantResolver {
  TenantResolver._(); // clase estática — no instanciar

  // ─────────────────────────────────────────────
  // DEV OVERRIDE — Solo para entrypoints de desarrollo
  // En builds de producción (--release) los asserts se eliminan
  // y esta variable nunca se asigna, por lo que no tiene efecto.
  // ─────────────────────────────────────────────

  static TenantType? _devOverride;
  static String _devClientSlug = 'demo';

  /// Fuerza un tenant específico durante el desarrollo.
  /// **Solo funciona en modo debug** — los asserts se eliminan en --release.
  ///
  /// Llamar antes de [runApp] en los entrypoints de la carpeta `entrypoints/`.
  static void setDevOverride(TenantType type, {String clientSlug = 'demo'}) {
    assert(() {
      _devOverride = type;
      _devClientSlug = clientSlug;
      return true;
    }());
  }

  // ─────────────────────────────────────────────
  // RESOLVER TIPO DE TENANT
  // ─────────────────────────────────────────────

  /// Detecta y devuelve el [TenantType] activo.
  ///
  /// En desarrollo: si se llamó [setDevOverride], devuelve ese valor.
  /// En producción: usa la URL (subdominio + ruta secreta).
  static TenantType resolve() {
    // Dev override tiene prioridad (solo en debug)
    if (_devOverride != null) return _devOverride!;
    if (!kIsWeb) return TenantType.management;

    final host = Uri.base.host;
    final path = Uri.base.path;

    // Soporte para desarrollo local: emular subdominios usando ?tenant=slug
    if (kDebugMode && Uri.base.queryParameters.containsKey('tenant')) {
      return TenantType.client;
    }

    // Admin: ruta secreta
    if (path.startsWith('/d8t1-admin-panel')) return TenantType.admin;

    // Management: dominio raíz
    if (host == 'quinindews.com' || host == 'www.quinindews.com') {
      return TenantType.management;
    }

    // Advertisers: subdominio ads
    if (host == 'ads.quinindews.com') return TenantType.advertisers;

    // Client: cualquier otro subdominio de quinindews.com
    // ej: "mitienda.quinindews.com"
    final parts = host.split('.');
    if (parts.length >= 3 && host.endsWith('quinindews.com')) {
      return TenantType.client;
    }

    return TenantType.management; // fallback
  }

  // ─────────────────────────────────────────────
  // SLUG DEL CLIENTE
  // ─────────────────────────────────────────────

  /// Extrae el slug del negocio desde el subdominio.
  ///
  /// `"mitienda.quinindews.com"` → `"mitienda"`
  ///
  /// En desarrollo: devuelve el slug configurado en [setDevOverride].
  /// Devuelve cadena vacía si no estamos en web o no aplica.
  static String clientSlug() {
    // Dev override
    if (_devOverride == TenantType.client) return _devClientSlug;
    if (!kIsWeb) return '';

    // Soporte para desarrollo local: emular subdominios usando ?tenant=slug
    if (kDebugMode && Uri.base.queryParameters.containsKey('tenant')) {
      return Uri.base.queryParameters['tenant']!;
    }

    final host = Uri.base.host;
    final parts = host.split('.');
    if (parts.length >= 3 && host.endsWith('quinindews.com')) {
      return parts.first;
    }
    return '';
  }

  // ─────────────────────────────────────────────
  // RESOLVER CONFIG COMPLETA
  // ─────────────────────────────────────────────

  /// Combina [resolve] y [TenantConfig.fromType] en un solo paso.
  /// Úsalo cuando necesitas la config completa con feature flags.
  static TenantConfig resolveConfig() {
    return TenantConfig.fromType(resolve());
  }
}
