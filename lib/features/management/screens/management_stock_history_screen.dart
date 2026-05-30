import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementStockHistoryScreen extends StatefulWidget {
  const ManagementStockHistoryScreen({super.key});

  @override
  State<ManagementStockHistoryScreen> createState() => _ManagementStockHistoryScreenState();
}

class _ManagementStockHistoryScreenState extends State<ManagementStockHistoryScreen> {
  static final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _tenantId;
  String _selectedType = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final tenantId = await TenantService.getCurrentUserTenantId();
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _tenantId = tenantId;
    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      var query = _supabase.from('inventory_transactions').select('''
        *,
        products:product_id (name, image_url),
        profiles:created_by (owner_name, first_name, email)
      ''').eq('tenant_id', _tenantId!);

      if (_selectedType != 'all') {
        query = query.eq('transaction_type', _selectedType);
      }

      final res = await query.order('created_at', ascending: false);
      var list = List<Map<String, dynamic>>.from(res);

      if (_searchCtrl.text.isNotEmpty) {
        final term = _searchCtrl.text.toLowerCase();
        list = list.where((t) {
          final pName = (t['products']?['name'] as String?)?.toLowerCase() ?? '';
          return pName.contains(term);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _transactions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'Venta';
      case 'purchase':
        return 'Compra';
      case 'adjustment':
        return 'Ajuste';
      case 'return':
        return 'Devolución';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'sale':
        return AppColors.error;
      case 'purchase':
        return AppColors.success;
      case 'adjustment':
        return AppColors.primary;
      case 'return':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sale':
        return Icons.shopping_basket_rounded;
      case 'purchase':
        return Icons.local_shipping_rounded;
      case 'adjustment':
        return Icons.build_rounded;
      case 'return':
        return Icons.assignment_return_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TenantThemeProvider.of(context).primaryColor;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historial de Stock',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Filters Bar
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _searchCtrl,
                      hint: 'Buscar por producto...',
                      icon: Icons.search_rounded,
                      onChanged: (_) => _fetchTransactions(),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todos',
                            isSelected: _selectedType == 'all',
                            onTap: () {
                              setState(() => _selectedType = 'all');
                              _fetchTransactions();
                            },
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Ventas',
                            isSelected: _selectedType == 'sale',
                            onTap: () {
                              setState(() => _selectedType = 'sale');
                              _fetchTransactions();
                            },
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Compras',
                            isSelected: _selectedType == 'purchase',
                            onTap: () {
                              setState(() => _selectedType = 'purchase');
                              _fetchTransactions();
                            },
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Ajustes',
                            isSelected: _selectedType == 'adjustment',
                            onTap: () {
                              setState(() => _selectedType = 'adjustment');
                              _fetchTransactions();
                            },
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Devoluciones',
                            isSelected: _selectedType == 'return',
                            onTap: () {
                              setState(() => _selectedType == 'return');
                              _fetchTransactions();
                            },
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Transactions list
              Expanded(
                child: _loading
                    ? ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, __) => const AppShimmerLoader(height: 80, borderRadius: 12),
                      )
                    : _transactions.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.history_toggle_off_rounded,
                            title: 'Sin movimientos de stock',
                            subtitle: 'No se encontraron registros de inventario con los filtros seleccionados.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _transactions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final t = _transactions[index];
                              final p = t['products'] ?? {};
                              final createdBy = t['profiles'] ?? {};
                              final qty = t['quantity_changed'] as int;
                              final operatorName = createdBy['owner_name'] as String? ??
                                  createdBy['first_name'] as String? ??
                                  createdBy['email'] as String? ??
                                  'Sistema';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(t['transaction_type']).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getTypeIcon(t['transaction_type']),
                                        color: _getTypeColor(t['transaction_type']),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'] ?? 'Producto Eliminado',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Por: $operatorName • ${_getTypeLabel(t['transaction_type'])}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                          if (t['notes'] != null && (t['notes'] as String).isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              t['notes'],
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          qty > 0 ? '+$qty' : '$qty',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: qty > 0 ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(t['created_at']),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? primaryColor : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
