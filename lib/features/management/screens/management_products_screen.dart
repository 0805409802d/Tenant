import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/utils/image_compressor.dart';
import 'management_stock_history_screen.dart';

class ManagementProductsScreen extends StatefulWidget {
  const ManagementProductsScreen({super.key});

  @override
  State<ManagementProductsScreen> createState() => _ManagementProductsScreenState();
}

class _ManagementProductsScreenState extends State<ManagementProductsScreen> {
  String? _tenantId;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  bool _isWorker = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);

    final tenantId = await TenantService.getCurrentUserTenantId();
    final isWorker = await TenantService.isCurrentUserWorker();
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _tenantId = tenantId;
    _products = await ProductService.getAllProductsForManager(_tenantId!);

    if (mounted) {
      setState(() {
        _loading = false;
        _isWorker = isWorker;
      });
    }
  }

  void _showProductModal([Map<String, dynamic>? product]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(
        tenantId: _tenantId!,
        product: product,
        isWorker: _isWorker,
        onSaved: () {
          Navigator.pop(context);
          _loadProducts();
        },
      ),
    );
  }

  void _showAdjustStockModal(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdjustStockSheet(
        tenantId: _tenantId!,
        product: product,
        onSaved: () {
          Navigator.pop(context);
          _loadProducts();
        },
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => const AppConfirmDialog(
        title: 'Eliminar producto',
        content: '¿Estás seguro de que deseas eliminar este producto? Esta acción no se puede deshacer.',
        confirmLabel: 'Eliminar',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      await ProductService.deleteProduct(id);
      _loadProducts();
    }
  }

  Future<void> _toggleProductActive(String productId, bool isActive) async {
    await ProductService.updateProduct(productId, {'is_active': isActive});
    // Actualizar estado local de forma reactiva sin re-escanear todo
    setState(() {
      final index = _products.indexWhere((p) => p['id'] == productId);
      if (index != -1) {
        _products[index]['is_active'] = isActive;
      }
    });
  }

  void _openStockHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagementStockHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TenantThemeProvider.of(context).primaryColor;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _isWorker ? 'Catálogo' : 'Mis Productos',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
            tooltip: 'Historial de Stock',
            onPressed: _openStockHistory,
          ),
          const SizedBox(width: 12),
        ],
      ),
      // Workers can only view — hide the FAB
      floatingActionButton: (_loading || _isWorker) ? null : FloatingActionButton.extended(
        onPressed: () => _showProductModal(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text('Nuevo producto', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _loading
              ? ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const AppShimmerLoader(height: 92, borderRadius: 16),
                )
              : _products.isEmpty
                  ? AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: _isWorker ? 'No hay productos aún' : 'Aún no tienes productos',
                      subtitle: _isWorker
                          ? 'El dueño del negocio aún no ha agregado productos al catálogo.'
                          : 'Agrega tu primer producto para empezar a vender.',
                      actionLabel: _isWorker ? null : 'Crear producto',
                      onAction: _isWorker ? null : () => _showProductModal(),
                      iconColor: primaryColor,
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, _isWorker ? 20 : 100),
                            itemCount: _products.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final p = _products[index];
                              final trackInv = p['track_inventory'] as bool? ?? true;
                              final stock = p['stock_quantity'] as int? ?? 0;
                              final minAlert = p['min_stock_alert'] as int? ?? 5;
                              final cost = (p['cost_price'] as num? ?? 0.0).toDouble();
                              final isActive = p['is_active'] as bool? ?? true;

                              final isLowStock = trackInv && stock <= minAlert;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 76, height: 76,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceGrey,
                                        borderRadius: BorderRadius.circular(12),
                                        image: p['image_url'] != null ? DecorationImage(image: NetworkImage(p['image_url']), fit: BoxFit.cover) : null,
                                      ),
                                      child: p['image_url'] == null ? const Icon(Icons.image_outlined, color: AppColors.textSecondary) : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                '\$${p['price']}',
                                                style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.w600),
                                              ),
                                              if (!_isWorker && cost > 0)
                                                Text(
                                                  '• Costo: \$${cost.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                              if (trackInv)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isLowStock ? AppColors.error.withOpacity(0.08) : AppColors.success.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(100),
                                                  ),
                                                  child: Text(
                                                    'Stock: $stock',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isLowStock ? AppColors.error : AppColors.success,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Switch de activación y botón de ajuste de stock
                                    Switch.adaptive(
                                      value: isActive,
                                      activeColor: primaryColor,
                                      onChanged: (val) => _toggleProductActive(p['id'], val),
                                    ),
                                    const SizedBox(width: 8),
                                    if (trackInv)
                                      IconButton(
                                        icon: const Icon(Icons.build_rounded, color: AppColors.textSecondary, size: 20),
                                        tooltip: 'Ajustar Inventario',
                                        onPressed: () => _showAdjustStockModal(p),
                                      ),
                                    // Edit and delete only for manager
                                    if (!_isWorker) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                        onPressed: () => _showProductModal(p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                        onPressed: () => _deleteProduct(p['id']),
                                      ),
                                    ],
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
}

class _ProductFormSheet extends StatefulWidget {
  final String tenantId;
  final Map<String, dynamic>? product;
  final bool isWorker;
  final VoidCallback onSaved;

  const _ProductFormSheet({required this.tenantId, this.product, required this.isWorker, required this.onSaved});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '5');
  final _costPriceCtrl = TextEditingController(text: '0.00');

  bool _trackInventory = true;
  String? _currentImageUrl;
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final compressedBytes = await ImageCompressor.compressImageBytes(bytes);

      setState(() {
        _selectedImageFile = picked;
        _selectedImageBytes = compressedBytes ?? bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!['name'];
      _descCtrl.text = widget.product!['description'] ?? '';
      _priceCtrl.text = widget.product!['price'].toString();
      _stockCtrl.text = (widget.product!['stock_quantity'] ?? 0).toString();
      _minStockCtrl.text = (widget.product!['min_stock_alert'] ?? 5).toString();
      _costPriceCtrl.text = (widget.product!['cost_price'] ?? 0.00).toString();
      _trackInventory = widget.product!['track_inventory'] ?? true;
      _currentImageUrl = widget.product!['image_url'];
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final minAlert = int.tryParse(_minStockCtrl.text.trim()) ?? 5;
    final cost = double.tryParse(_costPriceCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty || price == null) return;

    setState(() => _loading = true);

    String? finalImageUrl = _currentImageUrl;

    try {
      if (_selectedImageFile != null && _selectedImageBytes != null) {
        final db = Supabase.instance.client;
        final ext = _selectedImageFile!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = '${widget.tenantId}/$fileName';

        await db.storage.from('products').uploadBinary(path, _selectedImageBytes!);
        finalImageUrl = db.storage.from('products').getPublicUrl(path);
      }

      if (widget.product == null) {
        await ProductService.createProduct(
          tenantId: widget.tenantId,
          name: name,
          price: price,
          description: _descCtrl.text.trim(),
          imageUrl: finalImageUrl,
          stockQuantity: stock,
          minStockAlert: minAlert,
          trackInventory: _trackInventory,
          costPrice: cost,
        );
      } else {
        final Map<String, dynamic> updates = {
          'name': name,
          'price': price,
          'description': _descCtrl.text.trim(),
          'image_url': finalImageUrl,
          'stock_quantity': stock,
          'min_stock_alert': minAlert,
          'track_inventory': _trackInventory,
        };
        if (!widget.isWorker) {
          updates['cost_price'] = cost;
        }

        await ProductService.updateProduct(widget.product!['id'], updates);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar el producto')));
      }
    }

    widget.onSaved();
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
          // Drag handle
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
                  Row(
                    children: [
                      if (widget.product != null && _currentImageUrl != null && _selectedImageBytes == null)
                        Container(
                          width: 40, height: 40,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover),
                          ),
                        ),
                      Text(
                        widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const AppLabel('Nombre del producto'), const SizedBox(height: 6),
                  AppTextField(controller: _nameCtrl, hint: 'Ej. Hamburguesa doble', icon: Icons.fastfood_outlined),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppLabel('Precio de Venta'), const SizedBox(height: 6),
                            AppTextField(controller: _priceCtrl, hint: '0.00', icon: Icons.attach_money_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          ],
                        ),
                      ),
                      if (!widget.isWorker) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppLabel('Costo de Adquisición'), const SizedBox(height: 6),
                              AppTextField(controller: _costPriceCtrl, hint: '0.00', icon: Icons.shopping_bag_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AppLabel('Descripción (Opcional)'), const SizedBox(height: 6),
                  AppTextField(controller: _descCtrl, hint: 'Detalles del producto...', icon: Icons.description_outlined),
                  const SizedBox(height: 20),
                  
                  // Inventory controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.inventory_rounded, color: AppColors.textSecondary, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Controlar Inventario',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: _trackInventory,
                              activeColor: TenantThemeProvider.of(context).primaryColor,
                              onChanged: (val) => setState(() => _trackInventory = val),
                            ),
                          ],
                        ),
                        if (_trackInventory) ...[
                          const Divider(height: 24, color: AppColors.border),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppLabel('Stock Actual'), const SizedBox(height: 6),
                                    AppTextField(
                                      controller: _stockCtrl,
                                      hint: '0',
                                      icon: Icons.numbers_rounded,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AppLabel('Alerta Mínimo'), const SizedBox(height: 6),
                                    AppTextField(
                                      controller: _minStockCtrl,
                                      hint: '5',
                                      icon: Icons.notifications_active_outlined,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const AppLabel('Imagen del producto'), const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 2),
                        image: _selectedImageBytes != null
                            ? DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.cover)
                            : _currentImageUrl != null
                                ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                                : null,
                      ),
                      child: (_selectedImageBytes == null && _currentImageUrl == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(height: 6),
                                const Text('Subir una imagen', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(color: AppColors.overlay(0.3), borderRadius: BorderRadius.circular(14)),
                              child: const Center(child: Icon(Icons.edit_outlined, color: AppColors.white, size: 24)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Guardar producto',
                    onPressed: _save,
                    isLoading: _loading,
                    color: TenantThemeProvider.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustStockSheet extends StatefulWidget {
  final String tenantId;
  final Map<String, dynamic> product;
  final VoidCallback onSaved;

  const _AdjustStockSheet({required this.tenantId, required this.product, required this.onSaved});

  @override
  State<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends State<_AdjustStockSheet> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  bool _isAddition = true; // True (+) o False (-)
  bool _loading = false;

  Future<void> _adjust() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    final notes = _notesCtrl.text.trim();

    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad válida')));
      return;
    }
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El motivo del ajuste es obligatorio')));
      return;
    }

    setState(() => _loading = true);

    try {
      final db = Supabase.instance.client;
      final change = _isAddition ? qty : -qty;

      // 1. Obtener stock actual
      final currentStock = widget.product['stock_quantity'] as int? ?? 0;
      final newStock = currentStock + change >= 0 ? currentStock + change : 0;

      // 2. Actualizar stock
      await db.from('products').update({'stock_quantity': newStock}).eq('id', widget.product['id']);

      // 3. Registrar auditoría
      await db.from('inventory_transactions').insert({
        'tenant_id': widget.tenantId,
        'product_id': widget.product['id'],
        'quantity_changed': change,
        'transaction_type': 'adjustment',
        'notes': notes,
        'created_by': db.auth.currentUser?.id,
      });

      widget.onSaved();
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al ajustar el inventario')));
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 12,
      ),
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
            'Ajustar Stock: ${widget.product['name']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _AdjustmentTypeCard(
                  label: 'Entrada (+)',
                  icon: Icons.add_circle_outline_rounded,
                  isSelected: _isAddition,
                  color: AppColors.success,
                  onTap: () => setState(() => _isAddition = true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AdjustmentTypeCard(
                  label: 'Salida (-)',
                  icon: Icons.remove_circle_outline_rounded,
                  isSelected: !_isAddition,
                  color: AppColors.error,
                  onTap: () => setState(() => _isAddition = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppLabel('Cantidad física'), const SizedBox(height: 6),
          AppTextField(controller: _qtyCtrl, hint: '1', icon: Icons.numbers_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          const AppLabel('Motivo / Notas obligatorias'), const SizedBox(height: 6),
          AppTextField(controller: _notesCtrl, hint: 'Ej. Mercancía rota o inventario inicial...', icon: Icons.comment_outlined),
          const SizedBox(height: 24),
          AppButton(
            label: 'Guardar Ajuste',
            onPressed: _adjust,
            isLoading: _loading,
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}

class _AdjustmentTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AdjustmentTypeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppColors.border, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
