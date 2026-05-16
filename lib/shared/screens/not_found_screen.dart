import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants_theme_color.dart';

/// Pantalla 404 — Se muestra cuando el router no encuentra la ruta.
/// El router la pasa como [GoRouter.errorBuilder].
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.error});

  /// Error de GoRouter, opcional (puede ser null si se instancia directamente).
  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        body: Center(
          child: Container(
            width: 380,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: AppColors.overlay(0.05), blurRadius: 24, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono decorativo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.search_off_rounded, color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 24),

                // Código
                Text(
                  '404',
                  style: TextStyle(
                    fontFamily: 'Georgia', fontSize: 48, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, height: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Mensaje
                const Text(
                  'Página no encontrada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'La dirección que buscas no existe o fue eliminada.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Botón
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: const Text('Volver al inicio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}