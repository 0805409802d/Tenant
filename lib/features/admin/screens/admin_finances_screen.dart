import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';

class AdminFinancesScreen extends StatelessWidget {
  const AdminFinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Finanzas Plataforma',
      accentColor: AppColors.accentGreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta MRR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.textPrimary, Color(0xFF1E1E2E)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.overlay(0.1), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MRR (Ingreso Mensual Recurrente)', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                const Text('\$4,520.00', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, color: AppColors.accentGreen, size: 16),
                    const SizedBox(width: 4),
                    const Text('12% vs mes anterior', style: TextStyle(fontSize: 12, color: AppColors.accentGreen)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('INGRESOS POR SUSCRIPCIONES (OWNERS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          _FinanceItem(title: 'Suscripción Básica - Restaurante El Sabor', date: '14 May 2026', amount: 29.99),
          _FinanceItem(title: 'Suscripción Pro - Boutique Elegance', date: '12 May 2026', amount: 49.99),
          
          const SizedBox(height: 32),

          const Text('INGRESOS PUBLICITARIOS (ADVERTISERS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          _FinanceItem(title: 'Campaña Moda Verano - Distribuidora Global', date: '10 May 2026', amount: 150.00),
          _FinanceItem(title: 'Campaña Local - Agencia SEO', date: '05 May 2026', amount: 300.00),
        ],
      ),
    );
  }
}

class _FinanceItem extends StatelessWidget {
  const _FinanceItem({required this.title, required this.date, required this.amount});
  final String title;
  final String date;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('+\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentGreen)),
        ],
      ),
    );
  }
}
