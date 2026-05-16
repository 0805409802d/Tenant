// ─────────────────────────────────────────────────────────────────────────────
// HOOKS — No requerido para el MVP
// ─────────────────────────────────────────────────────────────────────────────
//
// Flutter no tiene hooks nativos. La librería `flutter_hooks` los añade,
// pero no es necesaria para el MVP: usamos StatefulWidget + setState
// que es suficiente y más familiar para el equipo.
//
// Esta carpeta existe como placeholder de arquitectura para cuando el proyecto
// decida adoptar flutter_hooks para simplificar el manejo de state local
// (especialmente en widgets con múltiples AnimationControllers o streams).
//
// TODO Fase futura (opcional):
//   - Añadir `flutter_hooks: ^0.21.0` a pubspec.yaml
//   - Crear `use_tenant.dart`: hook para leer TenantConfig desde contexto
//   - Crear `use_auth.dart`: hook para el stream de sesión de Supabase
//   - Crear `use_debounce.dart`: hook para búsquedas con delay
//
// Referencia: https://pub.dev/packages/flutter_hooks
// ─────────────────────────────────────────────────────────────────────────────
