import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminAdvertisersScreen extends StatelessWidget {
  const AdminAdvertisersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Anunciantes (Advertisers)',
      accentColor: AppColors.accentPurple,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: TextEditingController(),
            hint: 'Buscar empresa anunciante...',
            icon: Icons.search_rounded,
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _AdminAdvertiserCard(
                name: ['Agencia de Marketing SEO', 'Distribuidora Global'][index],
                contractStatus: ['Activo', 'Pendiente'][index],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminAdvertiserCard extends StatelessWidget {
  const _AdminAdvertiserCard({
    required this.name,
    required this.contractStatus,
  });

  final String name;
  final String contractStatus;

  @override
  Widget build(BuildContext context) {
    final bool isActive = contractStatus == 'Activo';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded, color: AppColors.accentPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Contrato: $contractStatus', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppChip(
                label: contractStatus,
                color: isActive ? AppColors.accentGreen : AppColors.accentAmber,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Ver campañas', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
