/// Sistema de espaciado, radios y tamaños de la plataforma Tenant.
///
/// Basado en una escala de 4px para mantener proporción visual consistente.
/// Importar esta clase en lugar de usar valores numéricos inline en widgets.
abstract final class AppSizes {
  // ──────────────────────────────────────────
  // ESPACIADO — escala de 4px
  // ──────────────────────────────────────────

  static const double space2  = 2.0;
  static const double space4  = 4.0;
  static const double space6  = 6.0;
  static const double space8  = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ──────────────────────────────────────────
  // PADDING — contenedores principales
  // ──────────────────────────────────────────

  /// Padding lateral estándar de pantallas.
  static const double pagePaddingH = 20.0;

  /// Padding vertical estándar de pantallas.
  static const double pagePaddingV = 24.0;

  /// Padding interno de cards y modales.
  static const double cardPadding  = 20.0;

  // ──────────────────────────────────────────
  // BORDER RADIUS
  // ──────────────────────────────────────────

  /// Radio mínimo — chips, badges pequeños.
  static const double radiusXs  = 6.0;

  /// Radio estándar — inputs, botones, chips de selección.
  static const double radiusSm  = 10.0;

  /// Radio de card y modal.
  static const double radiusMd  = 14.0;

  /// Radio grande — bottom sheets, paneles.
  static const double radiusLg  = 20.0;

  /// Radio redondo — avatares, íconos circulares.
  static const double radiusFull = 999.0;

  // ──────────────────────────────────────────
  // TAMAÑOS DE COMPONENTES
  // ──────────────────────────────────────────

  /// Altura estándar de botones.
  static const double buttonHeight = 46.0;

  /// Altura de inputs y campos de texto.
  static const double inputHeight  = 48.0;

  /// Altura de AppBar personalizado.
  static const double appBarHeight = 56.0;

  /// Tamaño de ícono estándar.
  static const double iconMd  = 20.0;

  /// Tamaño de ícono pequeño (dentro de inputs).
  static const double iconSm  = 18.0;

  /// Tamaño de ícono grande.
  static const double iconLg  = 24.0;

  /// Tamaño de avatar pequeño (en listas).
  static const double avatarSm = 36.0;

  /// Tamaño de avatar mediano (perfil en settings).
  static const double avatarMd = 52.0;

  /// Tamaño de avatar grande (hero de perfil).
  static const double avatarLg = 72.0;

  // ──────────────────────────────────────────
  // ANCHOS MÁXIMOS — para layouts de formularios web
  // ──────────────────────────────────────────

  /// Ancho máximo de formularios de auth (login, register).
  static const double formMaxWidth = 420.0;

  /// Ancho máximo de cards de contenido.
  static const double cardMaxWidth = 600.0;

  // ──────────────────────────────────────────
  // TIPOGRAFÍA — tamaños de fuente
  // ──────────────────────────────────────────

  static const double fontXs   = 11.0;
  static const double fontSm   = 12.0;
  static const double fontBase  = 13.0;
  static const double fontMd   = 14.0;
  static const double fontLg   = 15.0;
  static const double fontXl   = 16.0;
  static const double font2xl  = 18.0;
  static const double font3xl  = 20.0;
  static const double font4xl  = 22.0;
  static const double font5xl  = 28.0;

  // ──────────────────────────────────────────
  // SOMBRAS — valores de blur/offset para BoxShadow
  // ──────────────────────────────────────────

  /// Sombra ligera de card estándar (opacidad: 0.04).
  static const double shadowCardBlur   = 16.0;
  static const double shadowCardOffset = 4.0;

  /// Sombra de modal/overlay (opacidad: 0.10).
  static const double shadowModalBlur   = 32.0;
  static const double shadowModalOffset = 8.0;
}
