import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementHistoryScreen extends StatefulWidget {
  const ManagementHistoryScreen({super.key});
  @override
  State<ManagementHistoryScreen> createState() => _ManagementHistoryScreenState();
}

class _ManagementHistoryScreenState extends State<ManagementHistoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Historial',
      sectionTitle: 'Cuentas activas',
      sectionSubtitle: 'Clientes registrados en tu plataforma',
      accentColor: AppColors.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary, size: 20),
          tooltip: 'Ordenar',
          onPressed: () {},
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          AppTextField(
            controller: _searchCtrl,
            hint: 'Buscar cliente por nombre...',
            icon: Icons.search_rounded,
          ),
          const SizedBox(height: 24),

          // Lista de clientes (Placeholder Fase 3)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ClientHistoryCard(
                name: ['Juan Pérez', 'María Gómez', 'Carlos Ruiz'][index],
                phone: ['+593 99 123 4567', '+593 98 765 4321', '+593 97 111 2222'][index],
                date: ['Hace 2 horas', 'Ayer', '10 May 2026'][index],
                onTap: () {
                  // TODO Fase 3: Abrir detalle de historial de compras
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClientHistoryCard extends StatelessWidget {
  const _ClientHistoryCard({
    required this.name,
    required this.phone,
    required this.date,
    required this.onTap,
  });

  final String name;
  final String phone;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AppAvatar(name: name, radius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Registro', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
