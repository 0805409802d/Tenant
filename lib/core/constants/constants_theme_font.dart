import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema tipográfico de la plataforma Tenant / Quinindews.
///
/// Dos familias complementarias:
///
///   · **Inter** (sans-serif) — Cuerpo, UI, etiquetas, botones.
///     Moderna, legible en pantalla. Fallback: Segoe UI → Arial → sans-serif.
///
///   · **Playfair Display** (serif) — Títulos de display, encabezados grandes.
///     Elegante, combina con la identidad premium del proyecto.
///     Fallback: Georgia → Times New Roman → serif.
///
/// Google Fonts descarga ambas automáticamente. Si el CDN falla (sin internet
/// en primera carga web), Flutter usa la fuente del sistema gracias a
/// fontFamilyFallback.
///
/// Regla: nunca usar TextStyle inline en pantallas.
/// Siempre importar [AppTextStyles] o [AppFonts].
abstract final class AppFonts {
  // ──────────────────────────────────────────
  // NOMBRES DE FAMILIA (para referencias directas)
  // ──────────────────────────────────────────

  static const String sansSerifFamily = 'Inter';
  static const String serifFamily     = 'Playfair Display';

  // Cadena de fallback — aplicada automáticamente por Google Fonts
  static const List<String> sansFallback  = ['Segoe UI', 'Helvetica Neue', 'Arial'];
  static const List<String> serifFallback = ['Georgia', 'Times New Roman'];

  // ──────────────────────────────────────────
  // MÉTODOS BASE — retornan TextStyle de Google Fonts
  // ──────────────────────────────────────────

  /// Inter con fallbacks sans-serif.
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize:      fontSize,
        fontWeight:    fontWeight,
        color:         color,
        letterSpacing: letterSpacing,
        height:        height,
        fontFamilyFallback: sansFallback,
      );

  /// Playfair Display con fallbacks serif.
  static TextStyle playfair({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize:      fontSize,
        fontWeight:    fontWeight,
        color:         color,
        letterSpacing: letterSpacing,
        height:        height,
        fontFamilyFallback: serifFallback,
      );
}

/// Estilos tipográficos predefinidos listos para usar en widgets.
///
/// Jerarquía visual:
///   display  → Playfair (serif)   — headings grandes de página
///   heading  → Inter (sans)       — títulos de sección y card
///   body     → Inter (sans)       — párrafos y contenido
///   label    → Inter (sans, bold) — etiquetas de formulario
///   caption  → Inter (sans)       — hints, metadata, pies
///   button   → Inter (sans, bold) — texto de botones
abstract final class AppTextStyles {
  // ──────────────────────────────────────────
  // DISPLAY — Playfair, para títulos grandes de pantalla
  // ──────────────────────────────────────────

  /// "Panel de Administración", "Mi Negocio" — hero text.
  static TextStyle displayLarge({Color? color}) => AppFonts.playfair(
        fontSize: 28, fontWeight: FontWeight.w700, color: color, height: 1.2);

  /// Títulos de pantallas de auth y landing sections.
  static TextStyle displayMedium({Color? color}) => AppFonts.playfair(
        fontSize: 22, fontWeight: FontWeight.w700, color: color, height: 1.25);

  /// Subtítulo display — debajo de hero text.
  static TextStyle displaySmall({Color? color}) => AppFonts.playfair(
        fontSize: 18, fontWeight: FontWeight.w600, color: color, height: 1.3);

  // ──────────────────────────────────────────
  // HEADING — Inter, títulos de sección y card
  // ──────────────────────────────────────────

  /// Encabezado de página / sección principal.
  static TextStyle headingLarge({Color? color}) => AppFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w800, color: color);

  /// Título de card o sección secundaria.
  static TextStyle headingMedium({Color? color}) => AppFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w700, color: color);

  /// Título compacto — modales, tooltips.
  static TextStyle headingSmall({Color? color}) => AppFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w700, color: color);

  // ──────────────────────────────────────────
  // BODY — Inter, texto de contenido
  // ──────────────────────────────────────────

  /// Párrafos y descripciones principales.
  static TextStyle bodyLarge({Color? color}) => AppFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w400, color: color, height: 1.6);

  /// Texto estándar de la interfaz.
  static TextStyle bodyMedium({Color? color}) => AppFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5);

  /// Texto pequeño — subtítulos de card, metadata.
  static TextStyle bodySmall({Color? color}) => AppFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.5);

  // ──────────────────────────────────────────
  // LABEL — Inter bold, formularios
  // ──────────────────────────────────────────

  /// Etiqueta de campo de formulario.
  static TextStyle label({Color? color}) => AppFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.2);

  /// Etiqueta pequeña — chips, badges.
  static TextStyle labelSmall({Color? color}) => AppFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3);

  // ──────────────────────────────────────────
  // BUTTON — Inter semibold
  // ──────────────────────────────────────────

  /// Texto de botones normales.
  static TextStyle button({Color? color}) => AppFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.2);

  /// Texto de botón pequeño.
  static TextStyle buttonSmall({Color? color}) => AppFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.15);

  // ──────────────────────────────────────────
  // CAPTION / HINT — texto de apoyo muy pequeño
  // ──────────────────────────────────────────

  /// Pie de campo, mensajes de ayuda, timestamps.
  static TextStyle caption({Color? color}) => AppFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.4);

  /// Placeholder de input, descripción de acción.
  static TextStyle hint({Color? color}) => AppFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: color);
}
