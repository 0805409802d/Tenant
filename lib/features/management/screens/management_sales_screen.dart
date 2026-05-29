import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementSalesScreen extends StatefulWidget {
  const ManagementSalesScreen({super.key});

  @override
  State<ManagementSalesScreen> createState() => _ManagementSalesScreenState();
}

class _ManagementSalesScreenState extends State<ManagementSalesScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filter = 'all'; // all, pending, approved

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);

    final tenantId = await TenantService.getCurrentUserTenantId();
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _orders = await OrderService.getOrdersForTenant(tenantId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateStatus(String orderId, String currentStatus) async {
    final newStatus = currentStatus == 'pending' ? 'approved' : 'pending';
    setState(() => _loading = true);
    await OrderService.updateOrderStatus(orderId, newStatus);
    _loadOrders();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> result;
    if (_filter == 'all') {
      result = List.from(_orders);
    } else {
      result = _orders.where((o) => o['status'] == _filter).toList();
    }
    // Always sort: pending first, then by creation date desc
    result.sort((a, b) {
      final aPending = a['status'] == 'pending' ? 0 : 1;
      final bPending = b['status'] == 'pending' ? 0 : 1;
      if (aPending != bPending) return aPending.compareTo(bPending);
      return (b['created_at'] as String).compareTo(a['created_at'] as String);
    });
    return result;
  }

  Future<void> _approveNext() async {
    final next = _orders.firstWhere((o) => o['status'] == 'pending', orElse: () => {});
    if (next.isEmpty) return;
    await _updateStatus(next['id'], 'pending');
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;
    final approvedCount = _orders.where((o) => o['status'] == 'approved').length;

    return AppScaffold(
      title: 'Gestión de Pedidos',
      showBack: false,
      accentColor: AppColors.accentAmber,
      floatingActionButton: pendingCount > 0
          ? FloatingActionButton.extended(
              onPressed: _approveNext,
              backgroundColor: AppColors.accentAmber,
              icon: const Icon(Icons.check_rounded, color: AppColors.white),
              label: const Text('Aprobar siguiente', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      actions: [
        if (pendingCount > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$pendingCount pendientes', style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: _loadOrders,
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _FilterChip(label: 'Todos (${_orders.length})', isSelected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Pendientes ($pendingCount)', isSelected: _filter == 'pending', onTap: () => setState(() => _filter = 'pending'), color: AppColors.accentAmber),
                const SizedBox(width: 8),
                _FilterChip(label: 'Aprobados ($approvedCount)', isSelected: _filter == 'approved', onTap: () => setState(() => _filter = 'approved'), color: AppColors.accentGreen),
              ],
            ),
          ),
          
          Expanded(
            child: _loading
                ? ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => const AppShimmerLoader(height: 140, borderRadius: 16),
                  )
                : _filteredOrders.isEmpty
                    ? AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: _filter == 'all' ? 'Aún no tienes pedidos' : 'No hay pedidos en este estado',
                        subtitle: 'Cuando tus clientes hagan un pedido en tu sitio web, aparecerán aquí.',
                        iconColor: AppColors.accentAmber,
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, pendingCount > 0 ? 100 : 20),
                        shrinkWrap: true,
                        itemCount: _filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final o = _filteredOrders[index];
                          final client = o['profiles'] ?? {};
                          final isPending = o['status'] == 'pending';
                          
                          return _OrderCard(
                            order: o,
                            clientName: '${client['first_name'] ?? 'Anónimo'} ${client['last_name'] ?? ''}'.trim(),
                            clientPhone: client['phone'] ?? 'N/A',
                            isPending: isPending,
                            onToggleStatus: () => _updateStatus(o['id'], o['status']),
                          );
                        },
                      ),
          ),
        ],
      ),
    )));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color = AppColors.primary});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tint(color) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.3) : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({
    required this.order,
    required this.clientName,
    required this.clientPhone,
    required this.isPending,
    required this.onToggleStatus,
  });

  final Map<String, dynamic> order;
  final String clientName;
  final String clientPhone;
  final bool isPending;
  final VoidCallback onToggleStatus;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isPending ? AppColors.accentAmber : AppColors.accentGreen;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pedido #${widget.order['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tint(statusColor, opacity: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isPending)
                                AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (context, child) => Opacity(
                                    opacity: _pulseCtrl.value,
                                    child: child,
                                  ),
                                  child: Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                  ),
                                ),
                              Text(
                                widget.isPending ? 'Pendiente' : 'Aprobado',
                                style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(widget.clientName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(widget.clientPhone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text('\$${widget.order['total_amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        AppButton(
                          label: widget.isPending ? 'Aprobar' : 'Marcar Pendiente',
                          onPressed: widget.onToggleStatus,
                          color: statusColor,
                          fullWidth: false,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
