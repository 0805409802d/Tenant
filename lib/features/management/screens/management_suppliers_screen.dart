import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementSuppliersScreen extends StatefulWidget {
  const ManagementSuppliersScreen({super.key});

  @override
  State<ManagementSuppliersScreen> createState() => _ManagementSuppliersScreenState();
}

class _ManagementSuppliersScreenState extends State<ManagementSuppliersScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isWorker = false;
  bool _loading = true;
  String? _tenantId;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _purchases = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tenantId = await TenantService.getCurrentUserTenantId();
    final isWorker = await TenantService.isCurrentUserWorker();
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _tenantId = tenantId;
    _isWorker = isWorker;
    
    _tabController = TabController(length: _isWorker ? 2 : 3, vsync: this);
    
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final sList = await SupplierService.getSuppliers(_tenantId!);
    final pList = await SupplierService.getPurchases(_tenantId!);
    if (mounted) {
      setState(() {
        _suppliers = sList;
        _purchases = pList;
        _loading = false;
      });
    }
  }

  void _showSupplierForm([Map<String, dynamic>? supplier]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierFormSheet(
        tenantId: _tenantId!,
        supplier: supplier,
        onSaved: () {
          Navigator.pop(context);
          _refreshData();
        },
      ),
    );
  }

  void _showPurchaseForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseFormSheet(
        tenantId: _tenantId!,
        suppliers: _suppliers,
        onSaved: () {
          Navigator.pop(context);
          _refreshData();
        },
      ),
    );
  }

  Future<void> _deleteSupplier(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => const AppConfirmDialog(
        title: 'Desactivar proveedor',
        content: '¿Estás seguro de que deseas desactivar este proveedor?',
        confirmLabel: 'Desactivar',
        isDestructive: true,
      ),
    );
    if (confirm == true) {
      setState(() => _loading = true);
      await SupplierService.deleteSupplier(id);
      _refreshData();
    }
  }

  Future<void> _annulPurchase(String purchaseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => const AppConfirmDialog(
        title: 'Anular reabastecimiento',
        content: '¿Estás seguro de que deseas anular esta compra? Esto descontará automáticamente el stock del inventario.',
        confirmLabel: 'Anular Compra',
        isDestructive: true,
      ),
    );
    if (confirm == true) {
      setState(() => _loading = true);
      final success = await SupplierService.cancelPurchase(
        purchaseId: purchaseId,
        tenantId: _tenantId!,
        cancelledBy: Supabase.instance.client.auth.currentUser!.id,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compra anulada con éxito y stock actualizado.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo anular la compra.')));
        }
      }
      _refreshData();
    }
  }

  void _showPurchaseDetails(Map<String, dynamic> purchase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseDetailsSheet(purchase: purchase),
    );
  }

  Future<void> _contactSupplier(String phone, bool useWhatsApp) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = useWhatsApp
        ? Uri.parse('https://wa.me/$clean')
        : Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TenantThemeProvider.of(context).primaryColor;

    if (_loading || _tabController == null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        appBar: AppBar(backgroundColor: AppColors.surfaceGrey, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'Proveedores y Compras',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: primaryColor,
          tabs: [
            const Tab(text: 'Agenda / Directorio'),
            if (!_isWorker) const Tab(text: 'Administrar'),
            const Tab(text: 'Reabastecimientos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPurchaseForm,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.white),
        label: const Text('Ingreso Mercadería', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Agenda / Directorio
              _buildDirectoryTab(),
              // Tab 2: Administrar Proveedores (Solo Manager)
              if (!_isWorker) _buildManagerTab(primaryColor),
              // Tab 3: Reabastecimientos
              _buildPurchasesTab(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryTab() {
    if (_suppliers.isEmpty) {
      return const AppEmptyState(
        icon: Icons.contact_phone_outlined,
        title: 'Agenda de Proveedores vacía',
        subtitle: 'No hay proveedores registrados aún.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = _suppliers[index];
        final phone = s['phone'] as String? ?? '';
        final email = s['email'] as String? ?? '';
        final address = s['address'] as String? ?? '';
        final contact = s['contact_name'] as String? ?? '';

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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.business_rounded, color: AppColors.textSecondary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                    if (contact.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Contacto: $contact', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (phone.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: AppColors.success, size: 22),
                  onPressed: () => _contactSupplier(phone, false),
                  tooltip: 'Llamar',
                ),
                IconButton(
                  icon: const Icon(Icons.chat_rounded, color: AppColors.primary, size: 22),
                  onPressed: () => _contactSupplier(phone, true),
                  tooltip: 'WhatsApp',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildManagerTab(Color primaryColor) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showSupplierForm(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
      body: _suppliers.isEmpty
          ? const AppEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Administrar Proveedores',
              subtitle: 'Agrega y gestiona tus distribuidores de mercadería.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _suppliers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = _suppliers[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Tlf: ${s['phone'] ?? 'Sin teléfono'} • email: ${s['email'] ?? 'Sin correo'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                        onPressed: () => _showSupplierForm(s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () => _deleteSupplier(s['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPurchasesTab(Color primaryColor) {
    if (_purchases.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: 'Historial de compras vacío',
        subtitle: 'Aún no se han registrado ingresos de mercadería.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _purchases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = _purchases[index];
        final amount = (p['total_amount'] as num).toDouble();
        final isCancelled = p['status'] == 'cancelled';
        final supplierName = p['suppliers']?['name'] as String? ?? 'Proveedor Eliminado';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCancelled ? AppColors.error.withOpacity(0.3) : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCancelled ? AppColors.error.withOpacity(0.08) : AppColors.success.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                  color: isCancelled ? AppColors.error : AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: ${_formatDate(p['purchase_date'])}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (p['notes'] != null && (p['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(p['notes'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: isCancelled ? AppColors.textSecondary : primaryColor,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _showPurchaseDetails(p),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Detalles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      if (!_isWorker && !isCancelled) ...[
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () => _annulPurchase(p['id']),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Anular', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

class _SupplierFormSheet extends StatefulWidget {
  final String tenantId;
  final Map<String, dynamic>? supplier;
  final VoidCallback onSaved;

  const _SupplierFormSheet({required this.tenantId, this.supplier, required this.onSaved});

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameCtrl.text = widget.supplier!['name'] ?? '';
      _contactCtrl.text = widget.supplier!['contact_name'] ?? '';
      _phoneCtrl.text = widget.supplier!['phone'] ?? '';
      _emailCtrl.text = widget.supplier!['email'] ?? '';
      _addressCtrl.text = widget.supplier!['address'] ?? '';
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);

    bool ok = false;
    if (widget.supplier == null) {
      ok = await SupplierService.createSupplier(
        tenantId: widget.tenantId,
        name: name,
        contactName: _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
    } else {
      ok = await SupplierService.updateSupplier(widget.supplier!['id'], {
        'name': name,
        'contact_name': _contactCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
    }

    if (ok) {
      widget.onSaved();
    } else {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar el proveedor')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.supplier == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  const AppLabel('Nombre del Proveedor / Razón Social'), const SizedBox(height: 6),
                  AppTextField(controller: _nameCtrl, hint: 'Ej. Distribuidora XYZ', icon: Icons.business_rounded),
                  const SizedBox(height: 12),
                  const AppLabel('Persona de Contacto'), const SizedBox(height: 6),
                  AppTextField(controller: _contactCtrl, hint: 'Ej. Carlos López', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  const AppLabel('Teléfono Celular'), const SizedBox(height: 6),
                  AppTextField(controller: _phoneCtrl, hint: 'Ej. +593999999999', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  const AppLabel('Correo Electrónico'), const SizedBox(height: 6),
                  AppTextField(controller: _emailCtrl, hint: 'Ej. contacto@xyz.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  const AppLabel('Dirección Física'), const SizedBox(height: 6),
                  AppTextField(controller: _addressCtrl, hint: 'Ej. Av. de los Granados 123 y El Sol', icon: Icons.map_outlined),
                  const SizedBox(height: 24),
                  AppButton(label: 'Guardar Proveedor', onPressed: _save, isLoading: _loading, color: TenantThemeProvider.of(context).primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseFormSheet extends StatefulWidget {
  final String tenantId;
  final List<Map<String, dynamic>> suppliers;
  final VoidCallback onSaved;

  const _PurchaseFormSheet({required this.tenantId, required this.suppliers, required this.onSaved});

  @override
  State<_PurchaseFormSheet> createState() => _PurchaseFormSheetState();
}

class _PurchaseFormSheetState extends State<_PurchaseFormSheet> {
  String? _selectedSupplierId;
  final _notesCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _costCtrl = TextEditingController(text: '0.00');

  List<Map<String, dynamic>> _catalogProducts = [];
  Map<String, dynamic>? _selectedProduct;
  final List<Map<String, dynamic>> _purchaseItems = []; // {product_id, name, quantity, cost_price}
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    final prods = await ProductService.getAllProductsForManager(widget.tenantId);
    if (mounted) {
      setState(() {
        _catalogProducts = prods;
        _loading = false;
      });
    }
  }

  void _addItem() {
    if (_selectedProduct == null) return;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0.00;

    if (qty <= 0) return;

    setState(() {
      final index = _purchaseItems.indexWhere((item) => item['product_id'] == _selectedProduct!['id']);
      if (index != -1) {
        _purchaseItems[index]['quantity'] += qty;
        _purchaseItems[index]['cost_price'] = cost;
      } else {
        _purchaseItems.add({
          'product_id': _selectedProduct!['id'],
          'name': _selectedProduct!['name'],
          'quantity': qty,
          'cost_price': cost,
        });
      }
      _qtyCtrl.text = '1';
      _costCtrl.text = '0.00';
      _selectedProduct = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
  }

  double get _totalAmount => _purchaseItems.fold(0.0, (sum, item) => sum + (item['quantity'] as int) * (item['cost_price'] as double));

  Future<void> _submitPurchase() async {
    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto a la compra.')));
      return;
    }
    setState(() => _saving = true);

    final success = await SupplierService.registerPurchase(
      tenantId: widget.tenantId,
      supplierId: _selectedSupplierId,
      totalAmount: _totalAmount,
      notes: _notesCtrl.text.trim(),
      registeredBy: Supabase.instance.client.auth.currentUser!.id,
      items: _purchaseItems,
    );

    if (success) {
      widget.onSaved();
    } else {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al registrar la compra.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TenantThemeProvider.of(context).primaryColor;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registrar Ingreso de Mercadería', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  
                  // Supplier Selector
                  const AppLabel('Proveedor'), const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedSupplierId,
                    hint: const Text('Seleccionar proveedor'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.local_shipping_outlined, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                      filled: true, fillColor: AppColors.surfaceGrey,
                    ),
                    items: widget.suppliers.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name'] as String))).toList(),
                    onChanged: (val) => setState(() => _selectedSupplierId = val),
                  ),
                  const SizedBox(height: 16),

                  // Product Adder Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AGREGAR ÍTEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedProduct,
                          hint: const Text('Seleccionar producto de catálogo'),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.fastfood_outlined, color: AppColors.textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                            filled: true, fillColor: AppColors.white,
                          ),
                          items: _catalogProducts.map((p) => DropdownMenuItem(value: p, child: Text(p['name'] as String))).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedProduct = val;
                              if (val != null) {
                                _costCtrl.text = (val['cost_price'] ?? 0.0).toString();
                              }
                            });
                          },
                        ),
                        if (_selectedProduct != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppLabel('Cantidad recibida'), const SizedBox(height: 6),
                                    AppTextField(controller: _qtyCtrl, hint: '1', icon: Icons.numbers_rounded, keyboardType: TextInputType.number),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppLabel('Costo Unitario compra'), const SizedBox(height: 6),
                                    AppTextField(controller: _costCtrl, hint: '0.00', icon: Icons.attach_money_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppButton(label: 'Agregar al lote', onPressed: _addItem, color: primaryColor),
                        ],
                      ],
                    ),
                  ),

                  // Staged Items list
                  if (_purchaseItems.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('LOTES LISTOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _purchaseItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = _purchaseItems[i];
                        final qty = item['quantity'] as int;
                        final cost = item['cost_price'] as double;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('Cantidad: $qty • Costo Unitario: \$${cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text('\$${(qty * cost).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
                                onPressed: () => _removeItem(i),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 20),
                  const AppLabel('Notas / Detalles de factura física'), const SizedBox(height: 6),
                  AppTextField(controller: _notesCtrl, hint: 'Ej. Factura N° 1234, mercancía en buen estado...', icon: Icons.comment_outlined),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Compra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${_totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(label: 'Guardar Lote y Aumentar Inventario', onPressed: _submitPurchase, isLoading: _saving, color: primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> purchase;

  const _PurchaseDetailsSheet({required this.purchase});

  @override
  State<_PurchaseDetailsSheet> createState() => _PurchaseDetailsSheetState();
}

class _PurchaseDetailsSheetState extends State<_PurchaseDetailsSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final list = await SupplierService.getPurchaseItems(widget.purchase['id']);
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Detalle de Reabastecimiento',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = _items[i];
                final p = item['products'] ?? {};
                final qty = item['quantity'] as int;
                final cost = (item['cost_price'] as num).toDouble();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] ?? 'Producto Eliminado', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Cantidad: $qty • Costo Unitario: \$${cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      Text('\$${(qty * cost).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Compra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${(widget.purchase['total_amount'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
