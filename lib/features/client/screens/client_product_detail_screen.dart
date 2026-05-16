import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/widgets/app_widgets.dart';

class ClientProductDetailScreen extends StatelessWidget {
  const ClientProductDetailScreen({
    super.key,
    required this.tenantSlug,
    required this.productId,
  });

  final String tenantSlug;
  final String productId;

  @override
  Widget build(BuildContext context) {
    // TODO Fase 3: Cargar producto real por productId desde Supabase
    // Datos mockeados para MVP
    const String name = 'Camiseta Básica Negra';
    const double price = 19.99;
    const String description =
        'Camiseta de algodón 100% peinado, ajuste regular, cuello redondo. Ideal para uso diario y combinable con cualquier estilo. Disponible en varias tallas.';
    const String? imageUrl = null; // null para usar el placeholder

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tenantSlug.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagen del producto
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                color: AppColors.surface,
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.image_outlined, color: AppColors.border, size: 80),
              ),
            ),

            // 2. Información del producto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0097A7))),
                  const SizedBox(height: 24),
                  const Text('Descripción', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO Fase 3: Abrir WhatsApp directo
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Conversar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Comprar ahora',
                  onPressed: () {
                    // TODO Fase 3: Flujo de compra (WhatsApp o Aprobación)
                  },
                  color: const Color(0xFF0097A7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
