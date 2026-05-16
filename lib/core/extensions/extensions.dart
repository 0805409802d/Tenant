// ─────────────────────────────────────────────────────────────────────────────
// EXTENSIONES DE DART — Fase 2+ (según necesidad)
// ─────────────────────────────────────────────────────────────────────────────
//
// Las extensiones se añadirán aquí cuando las pantallas las necesiten.
// No se crean de antemano para evitar código muerto.
//
// Extensiones planeadas:
//
// // string_ext.dart
// extension StringExt on String {
//   bool get isValidEmail => RegExp(r'...').hasMatch(this);
//   String get titleCase  => split(' ').map(...).join(' ');
//   String get slug       => AppFormatters.slug(this);
// }
//
// // datetime_ext.dart
// extension DateTimeExt on DateTime {
//   String get formatted => AppFormatters.date(this);
//   bool get isToday     => difference(DateTime.now()).inDays == 0;
// }
//
// // context_ext.dart
// extension ContextExt on BuildContext {
//   TenantConfig get tenant => TenantProvider.of(this);
//   bool get isMobile      => MediaQuery.of(this).size.width < 600;
//   void showError(String msg) => ScaffoldMessenger.of(this)...;
// }
// ─────────────────────────────────────────────────────────────────────────────
