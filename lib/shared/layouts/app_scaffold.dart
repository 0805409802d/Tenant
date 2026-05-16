import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants_theme_color.dart';
import '../../core/constants/constants_theme_size.dart';

/// Scaffold base para pantallas internas autenticadas.
///
/// Proporciona:
///   - AppBar consistente con botón de regreso opcional
///   - Divider inferior en el AppBar
///   - Header de sección (barra de color + título + subtítulo)
///   - Body con scroll y padding estándar
///
/// Uso:
/// ```dart
/// AppScaffold(
///   title: 'Ajustes',
///   accentColor: AppColors.primary,
///   sectionTitle: 'Personalización',
///   sectionSubtitle: 'Configura cómo se ve tu negocio',
///   body: Column(children: [...]),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.accentColor = AppColors.primary,
    this.sectionTitle,
    this.sectionSubtitle,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
  });

  final String title;
  final Widget body;
  final Color accentColor;
  final String? sectionTitle;
  final String? sectionSubtitle;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        actions: actions,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pagePaddingH,
          vertical: AppSizes.pagePaddingV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionTitle != null) ...[
              _SectionHeader(
                title: sectionTitle!,
                subtitle: sectionSubtitle,
                accentColor: accentColor,
              ),
              const SizedBox(height: AppSizes.space24),
            ],
            body,
          ],
        ),
      ),
    );
  }
}

/// Header de sección reutilizable (barra de color + título + subtítulo).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, required this.accentColor});

  final String title;
  final String? subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4, height: 28,
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ],
      );
}

// ─────────────────────────────────────────────
// VARIANTE: layout centrado para formularios de auth
// ─────────────────────────────────────────────

/// Scaffold para pantallas de autenticación (login, register).
/// Centra el contenido en la pantalla sobre fondo gris.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.maxWidth = 420});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        ),
      );
}
