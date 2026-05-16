import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';

class AdvertisersCampaignsScreen extends StatelessWidget {
  const AdvertisersCampaignsScreen({super.key});

  static const _accent = Color(0xFF6C47FF);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mis Campañas',
      accentColor: _accent,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textPrimary),
          onPressed: () {
            // TODO Fase 3: Crear nueva campaña
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.info_outline_rounded, color: _accent, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Las campañas te permiten mostrar tu marca en los catálogos de los negocios (tenants) asociados a la plataforma.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _CampaignCard(
                name: ['Campaña Moda Verano 2026', 'Promoción Local - Centro'][index],
                status: ['Activa', 'Pausada'][index],
                budget: [500.00, 150.00][index],
                spent: [340.50, 150.00][index],
                impressions: [12500, 4200][index],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.name,
    required this.status,
    required this.budget,
    required this.spent,
    required this.impressions,
  });

  final String name;
  final String status;
  final double budget;
  final double spent;
  final int impressions;

  @override
  Widget build(BuildContext context) {
    final bool isActive = status == 'Activa';
    const Color accent = Color(0xFF6C47FF);
    final double progress = spent / budget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? accent.withValues(alpha: 0.5) : AppColors.border),
        boxShadow: isActive ? [BoxShadow(color: accent.withValues(alpha: 0.05), blurRadius: 16)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    AppChip(label: status, color: isActive ? AppColors.accentGreen : AppColors.textSecondary),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Presupuesto gastado: \$${spent.toStringAsFixed(2)} / \$${budget.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceGrey,
              valueColor: AlwaysStoppedAnimation<Color>(isActive ? accent : AppColors.textSecondary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('$impressions impresiones', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: accent, padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                child: const Text('Ver detalle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
