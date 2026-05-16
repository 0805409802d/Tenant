import 'package:flutter/material.dart';

/// Sistema de colores de la plataforma Tenant / Quinindews.
///
/// Paleta de 3 pilares:
///   · Blanco   — color dominante (fondos, superficies, cards)
///   · Negro    — textos, títulos, íconos, controles
///   · Azul     — acento principal (acciones, links, bordes decorativos)
///
/// Regla de uso:
///   Siempre importar esta clase. NUNCA escribir colores en hex
///   directamente en widgets o pantallas.
abstract final class AppColors {
  // ──────────────────────────────────────────
  // BLANCO — dominante
  // ──────────────────────────────────────────

  /// Fondo general de todas las pantallas.
  static const Color background    = Color(0xFFFFFFFF);

  /// Superficie de cards, modales, contenedores.
  static const Color surface       = Color(0xFFFFFFFF);

  /// Fondo gris muy claro — Scaffold, inputs, chips.
  static const Color surfaceGrey   = Color(0xFFF4F5F7);

  /// Gris aún más suave — fondos alternativos secundarios.
  static const Color surfaceAlt    = Color(0xFFFAFAFB);

  // ──────────────────────────────────────────
  // NEGRO — tipografía y controles
  // ──────────────────────────────────────────

  /// Texto principal: títulos, párrafos, etiquetas.
  static const Color textPrimary   = Color(0xFF0A0A0A);

  /// Texto secundario: subtítulos, hints, descripciones apagadas.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Texto terciario: placeholders, metadata, captions.
  static const Color textHint      = Color(0xFF9CA3AF);

  // ──────────────────────────────────────────
  // AZUL — acento principal
  // ──────────────────────────────────────────

  /// Azul primario — botones CTA, links, foco de inputs, íconos de acción.
  static const Color primary       = Color(0xFF1E6BFF);

  /// Azul ligeramente más oscuro — estado hover/pressed.
  static const Color primaryDark   = Color(0xFF1558D6);

  /// Azul oscuro — estado activo/seleccionado profundo.
  static const Color primaryDeep   = Color(0xFF1147AE);

  /// Tinte azul muy suave — fondos de sección con acento, badges.
  static const Color primaryTint   = Color(0xFFEEF4FF);

  /// Borde azul suave — bordes decorativos, separadores con acento.
  static const Color primaryBorder = Color(0xFFBFD7FF);

  // ──────────────────────────────────────────
  // BORDES Y SEPARADORES
  // ──────────────────────────────────────────

  /// Borde estándar de cards e inputs.
  static const Color border        = Color(0xFFDDE1E9);

  /// Borde más suave — divisores internos de secciones.
  static const Color borderLight   = Color(0xFFEEF0F4);

  // ──────────────────────────────────────────
  // ESTADOS — feedback visual
  // ──────────────────────────────────────────

  // · Error
  static const Color error         = Color(0xFFE53935);
  static const Color errorBg       = Color(0xFFFFF0F0);
  static const Color errorBorder   = Color(0xFFFFCDD2);
  static const Color errorText     = Color(0xFFB71C1C);

  // · Éxito
  static const Color success       = Color(0xFF00B37E);
  static const Color successBg     = Color(0xFFF0FFF4);
  static const Color successBorder = Color(0xFFC6F6D5);
  static const Color successText   = Color(0xFF276749);

  // · Advertencia
  static const Color warning       = Color(0xFFFF8C00);
  static const Color warningBg     = Color(0xFFFFF8E1);
  static const Color warningBorder = Color(0xFFFFE082);
  static const Color warningText   = Color(0xFF6D4C00);

  // ──────────────────────────────────────────
  // ACENTOS SECUNDARIOS — íconos de sección, badges de roles
  // ──────────────────────────────────────────

  /// Violeta — seguridad, contraseñas.
  static const Color accentPurple  = Color(0xFF6C47FF);

  /// Teal — trabajadores, mensajes.
  static const Color accentTeal    = Color(0xFF0097A7);

  /// Verde esmeralda — teléfono, éxito, confirmaciones.
  static const Color accentGreen   = Color(0xFF00B37E);

  /// Rojo coral — eliminar, alertas, preguntas de seguridad.
  static const Color accentRed     = Color(0xFFE53935);

  /// Ámbar — advertencias, estados pendientes.
  static const Color accentAmber   = Color(0xFFFF8C00);

  // ──────────────────────────────────────────
  // UTILIDADES
  // ──────────────────────────────────────────

  /// Negro con opacidad — overlays de modales y bottom sheets.
  static Color overlay(double opacity) =>
      const Color(0xFF0A0A0A).withValues(alpha: opacity);

  /// Tinte de un color con opacidad baja — fondos de íconos en cards.
  static Color tint(Color color, {double opacity = 0.10}) =>
      color.withValues(alpha: opacity);

  // ──────────────────────────────────────────
  // ALIASES DE COMPATIBILIDAD
  // Mantienen compilando screens escritos antes de la migración semántica.
  // ──────────────────────────────────────────
  static const Color white      = surface;
  static const Color black      = textPrimary;
  static const Color blue       = primary;
  static const Color greyLight  = surfaceGrey;
  static const Color greyBorder = border;
  static const Color greyText   = textSecondary;
  static const Color greyCard   = surfaceAlt;
}
