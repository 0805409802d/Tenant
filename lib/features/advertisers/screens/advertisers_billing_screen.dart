import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';

class AdvertisersBillingScreen extends StatelessWidget {
  const AdvertisersBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Facturación',
      accentColor: AppColors.accentGreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HISTORIAL DE PAGOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _BillingCard(
                concept: ['Carga de Presupuesto - Campaña Verano', 'Carga de Presupuesto Inicial', 'Suscripción Plataforma'][index],
                date: ['12 May 2026', '10 Abr 2026', '10 Mar 2026'][index],
                amount: [250.00, 150.00, 29.99][index],
                status: index == 0 ? 'Procesando' : 'Pagada',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({
    required this.concept,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String concept;
  final String date;
  final double amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final bool isPaid = status == 'Pagada';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(concept, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                AppChip(
                  label: status,
                  color: isPaid ? AppColors.accentGreen : AppColors.accentAmber,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              if (isPaid)
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () {},
                  tooltip: 'Descargar Factura PDF',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
