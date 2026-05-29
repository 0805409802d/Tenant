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

    if (mounted) setState(() {
      _loading = false;
      _isWorker = isWorker;
    });
  }

  void _showProductModal([Map<String, dynamic>? product]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)
        ),
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
                  // Workers don't get the create action button
                  actionLabel: _isWorker ? null : 'Crear producto',
                  onAction: _isWorker ? null : () => _showProductModal(),
                  iconColor: primaryColor,
                )
              : Column(
                  children: [
                    // Worker read-only banner
                    if (_isWorker)
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary.withValues(alpha: 0.8)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Estás en modo de consulta. Solo el dueño puede agregar, editar o eliminar productos.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, _isWorker ? 20 : 100),
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = _products[index];
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
                                  width: 68, height: 68,
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
                                      Text(p['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('\$${p['price']}', style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                // Edit and delete only for manager
                                if (!_isWorker) ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _showProductModal(p),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _deleteProduct(p['id']),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      ),
                                    ),
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
  final VoidCallback onSaved;

  const _ProductFormSheet({required this.tenantId, this.product, required this.onSaved});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  
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
      _currentImageUrl = widget.product!['image_url'];
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    
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
        );
      } else {
        await ProductService.updateProduct(widget.product!['id'], {
          'name': name,
          'price': price,
          'description': _descCtrl.text.trim(),
          'image_url': finalImageUrl,
        });
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
          Padding(
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppLabel('Nombre del producto'), const SizedBox(height: 6),
                AppTextField(controller: _nameCtrl, hint: 'Ej. Hamburguesa doble', icon: Icons.fastfood_outlined),
                const SizedBox(height: 16),
                const AppLabel('Precio'), const SizedBox(height: 6),
                AppTextField(controller: _priceCtrl, hint: '0.00', icon: Icons.attach_money_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                const AppLabel('Descripción (Opcional)'), const SizedBox(height: 6),
                AppTextField(controller: _descCtrl, hint: 'Detalles del producto...', icon: Icons.description_outlined),
                const SizedBox(height: 16),
                const AppLabel('Imagen del producto'), const SizedBox(height: 6),
                
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(16),
                      // Dashed border look by keeping border color light and radius large
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
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 8)],
                                ),
                                child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(height: 12),
                              const Text('Toca para subir una imagen', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.overlay(0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(Icons.edit_outlined, color: AppColors.white, size: 32),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Guardar producto',
                  onPressed: _save,
                  isLoading: _loading,
                  color: TenantThemeProvider.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
