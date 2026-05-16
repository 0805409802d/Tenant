import 'package:flutter/material.dart';
import '../../core/constants/constants_theme_color.dart';

/// Pantalla de carga inicial — Se muestra mientras Supabase inicializa
/// o mientras el router verifica la sesión activa.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, this.message});

  /// Mensaje opcional debajo del spinner.
  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo / marca
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 24),

              // Spinner
              const SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),

              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      );
}
