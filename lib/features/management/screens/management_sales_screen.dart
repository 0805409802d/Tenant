import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/order_service.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';

class ManagementSalesScreen extends StatefulWidget {
  const ManagementSalesScreen({super.key});

  @override
  State<ManagementSalesScreen> createState() => _ManagementSalesScreenState();
}

class _ManagementSalesScreenState extends State<ManagementSalesScreen> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    
    final tenant = await _db.from('tenants').select('id').eq('owner_id', uid).maybeSingle();
    if (tenant == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    
    _orders = await OrderService.getOrdersForTenant(tenant['id']);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateStatus(String orderId, String currentStatus) async {
    final newStatus = currentStatus == 'pending' ? 'approved' : 'pending';
    setState(() => _loading = true);
    await OrderService.updateOrderStatus(orderId, newStatus);
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Gestión de Pedidos',
      accentColor: AppColors.accentAmber,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: _loadOrders,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentAmber))
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('Aún no tienes pedidos.', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final o = _orders[index];
                    final client = o['profiles'] ?? {};
                    final isPending = o['status'] == 'pending';
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pedido #${o['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? AppColors.accentAmber.withValues(alpha: 0.1) : AppColors.accentGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isPending ? 'Pendiente' : 'Aprobado',
                                  style: TextStyle(fontSize: 12, color: isPending ? AppColors.accentAmber : AppColors.accentGreen, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Cliente: ${client['first_name'] ?? 'Anónimo'} ${client['last_name'] ?? ''}'),
                          Text('Teléfono: ${client['phone'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total: \$${o['total_amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              TextButton(
                                onPressed: () => _updateStatus(o['id'], o['status']),
                                child: Text(isPending ? 'Marcar Aprobado' : 'Marcar Pendiente', style: TextStyle(color: isPending ? AppColors.accentGreen : AppColors.accentAmber)),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
