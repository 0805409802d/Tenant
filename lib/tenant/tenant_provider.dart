import 'package:flutter/widgets.dart';
import 'tenant_config.dart';
import 'tenant_resolver.dart';

/// Expone la [TenantConfig] activa a todo el árbol de widgets
/// mediante el mecanismo nativo de Flutter (InheritedWidget).
///
/// ---
///
/// **Cómo acceder desde cualquier widget:**
/// ```dart
/// // Escucha cambios (rebuild automático si cambia el config)
/// final config = TenantProvider.of(context);
///
/// // Solo lectura sin rebuild
/// final config = TenantProvider.read(context);
///
/// // Acceder a los feature flags
/// if (config.flags.canViewDashboard) {
///   // mostrar dashboard
/// }
/// ```
///
/// ---
///
/// **Cómo instalarlo en main.dart:**
/// ```dart
/// runApp(const TenantScope(child: MyApp()));
/// ```
class TenantProvider extends InheritedWidget {
  const TenantProvider({
    super.key,
    required this.config,
    required super.child,
  });

  /// Configuración del tenant activo (tipo + feature flags).
  final TenantConfig config;

  // ─────────────────────────────────────────────
  // ACCESO DESDE EL ÁRBOL DE WIDGETS
  // ─────────────────────────────────────────────

  /// Accede a la [TenantConfig] y suscribe el widget a cambios.
  /// Usar en [build] cuando el widget deba reconstruirse si el config cambia.
  static TenantConfig of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<TenantProvider>();
    assert(
      provider != null,
      '\n\nTenantProvider.of() fue llamado fuera del árbol de TenantProvider.\n'
      'Asegúrate de que TenantScope (o TenantProvider) envuelve tu MaterialApp\n'
      'en main.dart.\n',
    );
    return provider!.config;
  }

  /// Accede a la [TenantConfig] sin suscribirse a cambios.
  /// Más eficiente cuando solo necesitas leer el valor una vez
  /// (ej: en callbacks, initState, etc.).
  static TenantConfig read(BuildContext context) {
    final provider =
        context.getInheritedWidgetOfExactType<TenantProvider>();
    assert(
      provider != null,
      '\n\nTenantProvider.read() fue llamado fuera del árbol de TenantProvider.\n'
      'Asegúrate de que TenantScope (o TenantProvider) envuelve tu MaterialApp\n'
      'en main.dart.\n',
    );
    return provider!.config;
  }

  @override
  bool updateShouldNotify(TenantProvider oldWidget) {
    return config != oldWidget.config;
  }
}

// ─────────────────────────────────────────────────────────────
// TENANT SCOPE
// Widget de conveniencia que resuelve e inyecta el TenantConfig
// automáticamente. Úsalo como raíz de tu app en main.dart.
// ─────────────────────────────────────────────────────────────

/// Wrapper raíz que detecta el tenant activo y lo inyecta en el árbol.
///
/// Internamente llama a [TenantResolver.resolveConfig()] para determinar
/// el espacio activo y envuelve [child] en un [TenantProvider].
///
/// ```dart
/// // main.dart
/// runApp(const TenantScope(child: MyApp()));
/// ```
class TenantScope extends StatelessWidget {
  const TenantScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final config = TenantResolver.resolveConfig();
    return TenantProvider(config: config, child: child);
  }
}
