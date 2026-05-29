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
  int _selectedFilterIndex = 0;

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
          const SizedBox(height: 16),

          // Filtros (Simulados)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(0, 'Todos'),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'Recientes'),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'Más compras'),
                const SizedBox(width: 8),
                _buildFilterChip(3, 'Inactivos'),
              ],
            ),
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

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Último acceso', style: TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
