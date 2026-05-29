import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/utils/formatters.dart';
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
  
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    _applyFilters(query, _selectedFilterIndex);
  }

  void _applyFilters(String query, int filterIndex) {
    setState(() {
      _filteredOrders = _orders.where((o) {
        // Filtro por texto
        final profile = o['profiles'] ?? {};
        final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.toLowerCase();
        bool matchesSearch = name.contains(query);

        // Filtro por estado
        bool matchesStatus = true;
        if (filterIndex == 1) matchesStatus = o['status'] == 'approved';
        if (filterIndex == 2) matchesStatus = o['status'] == 'pending';
        if (filterIndex == 3) matchesStatus = o['status'] == 'rejected';

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final tenantId = await TenantService.getCurrentUserTenantId();
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final orders = await OrderService.getOrdersForTenant(tenantId);
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _filteredOrders = orders;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Historial',
      sectionTitle: 'Historial de Pedidos',
      sectionSubtitle: 'Todas las transacciones de tu negocio',
      accentColor: AppColors.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary, size: 20),
          tooltip: 'Ordenar',
          onPressed: () {},
        ),
      ],
      body: _loading
          ? const Center(child: AppShimmerLoader(height: 100, borderRadius: 16))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buscador
                AppTextField(
                  controller: _searchCtrl,
                  hint: 'Buscar pedido por cliente...',
                  icon: Icons.search_rounded,
                ),
                const SizedBox(height: 16),

                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(0, 'Todos'),
                      const SizedBox(width: 8),
                      _buildFilterChip(1, 'Aprobados'),
                      const SizedBox(width: 8),
                      _buildFilterChip(2, 'Pendientes'),
                      const SizedBox(width: 8),
                      _buildFilterChip(3, 'Rechazados'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_filteredOrders.isEmpty)
                  AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _orders.isEmpty ? 'Sin historial de pedidos' : 'No se encontraron resultados',
                    subtitle: _orders.isEmpty ? 'Los pedidos que realicen tus clientes aparecerán aquí.' : 'Intenta buscar con otro nombre o filtro.',
                    iconColor: AppColors.primary,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      final profile = order['profiles'] ?? {};
                      final name = '${profile['first_name'] ?? 'Anónimo'} ${profile['last_name'] ?? ''}'.trim();
                      final phone = profile['phone'] ?? 'Sin número';
                      final date = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
                      final total = order['total_amount'] is num ? (order['total_amount'] as num).toDouble() : 0.0;
                      final status = order['status'] ?? 'pending';

                      return _ClientHistoryCard(
                        name: name,
                        phone: phone,
                        date: AppFormatters.dateTime(date),
                        total: AppFormatters.price(total),
                        status: status,
                        onTap: () {
                          // TODO: Detalle del pedido
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
      onTap: () {
        setState(() => _selectedFilterIndex = index);
        _applyFilters(_searchCtrl.text.toLowerCase(), index);
      },
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
    required this.total,
    required this.status,
    required this.onTap,
  });

  final String name;
  final String phone;
  final String date;
  final String total;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.accentAmber;
    String statusLabel = 'Pendiente';
    if (status == 'approved') {
      statusColor = AppColors.accentGreen;
      statusLabel = 'Aprobado';
    } else if (status == 'rejected') {
      statusColor = AppColors.error;
      statusLabel = 'Rechazado';
    }

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(total, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
