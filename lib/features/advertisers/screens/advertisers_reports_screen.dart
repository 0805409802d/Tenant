import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';

class AdvertisersReportsScreen extends StatelessWidget {
  const AdvertisersReportsScreen({super.key});

  static const _accent = Color(0xFF6C47FF);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reportes y Métricas',
      accentColor: AppColors.accentTeal,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen
          Row(
            children: [
              Expanded(
                child: _StatBox(title: 'Impresiones Totales', value: '16.7K', icon: Icons.visibility_outlined, color: AppColors.accentTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(title: 'Clics Totales', value: '842', icon: Icons.ads_click_rounded, color: AppColors.accentAmber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatBox(title: 'Tasa de Conversión (CTR)', value: '5.04%', icon: Icons.data_usage_rounded, color: _accent),
          const SizedBox(height: 32),

          // Gráfico
          const Text('RENDIMIENTO (ÚLTIMOS 30 DÍAS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart_rounded, size: 40, color: AppColors.border),
                  SizedBox(height: 8),
                  Text('Gráfico de rendimiento en construcción', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.title, required this.value, required this.icon, required this.color});
  final String title, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
