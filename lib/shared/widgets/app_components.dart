import 'package:flutter/material.dart';
import '../../core/constants/constants_theme_color.dart';
import '../../core/utils/formatters.dart';

/// Avatar de usuario o negocio con fallback a iniciales.
///
/// Uso:
/// ```dart
/// AppAvatar(name: 'María García', radius: 20)
/// AppAvatar(name: 'Mi Negocio', imageUrl: 'https://...', radius: 28)
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.textColor = AppColors.primary,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final initials = AppFormatters.initials(name);
    final bg = backgroundColor ?? AppColors.primaryTint;
    final fontSize = radius * 0.65;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: bg,
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Indicador de carga inline (para botones o secciones parciales).
class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({super.key, this.size = 20, this.color = AppColors.primary});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size, height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
}

/// Chip de estado — para badges, tags SEO, estados de publicaciones, etc.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tint(color),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );

    if (onTap != null) return GestureDetector(onTap: onTap, child: chip);
    return chip;
  }
}

/// Tile de lista con ícono, título, subtítulo y flecha.
/// Útil para menús de settings, listas de items, etc.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.primary,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : iconColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: destructive ? AppColors.error : AppColors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Divider con etiqueta de sección.
class AppSectionDivider extends StatelessWidget {
  const AppSectionDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
      );
}
