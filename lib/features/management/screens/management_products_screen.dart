import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/product_service.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementProductsScreen extends StatefulWidget {
  const ManagementProductsScreen({super.key});

  @override
  State<ManagementProductsScreen> createState() => _ManagementProductsScreenState();
}

class _ManagementProductsScreenState extends State<ManagementProductsScreen> {
  final _db = Supabase.instance.client;
  String? _tenantId;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    
    // Get tenant
    final tenant = await _db.from('tenants').select('id').eq('owner_id', uid).maybeSingle();
    if (tenant == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    
    _tenantId = tenant['id'];
    _products = await ProductService.getAllProductsForManager(_tenantId!);
    
    if (mounted) setState(() => _loading = false);
  }

  void _showProductModal([Map<String, dynamic>? product]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
      builder: (c) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
        ],
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
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Mis Productos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: TenantThemeProvider.of(context).primaryColor),
            onPressed: () => _showProductModal(),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('Aún no tienes productos.', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Crear mi primer producto',
                        onPressed: () => _showProductModal(),
                        color: TenantThemeProvider.of(context).primaryColor,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGrey,
                              borderRadius: BorderRadius.circular(8),
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
                                Text('\$${p['price']}', style: TextStyle(fontSize: 14, color: TenantThemeProvider.of(context).primaryColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                            onPressed: () => _showProductModal(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () => _deleteProduct(p['id']),
                          ),
                        ],
                      ),
                    );
                  },
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
  File? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
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
      if (_selectedImage != null) {
        final db = Supabase.instance.client;
        final ext = _selectedImage!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = '${widget.tenantId}/$fileName';

        await db.storage.from('products').upload(path, _selectedImage!);
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.product == null ? 'Nuevo Producto' : 'Editar Producto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                image: _selectedImage != null
                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                    : _currentImageUrl != null
                        ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                        : null,
              ),
              child: (_selectedImage == null && _currentImageUrl == null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 32),
                        SizedBox(height: 8),
                        Text('Toca para subir imagen', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Guardar producto',
            onPressed: _save,
            isLoading: _loading,
            color: TenantThemeProvider.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
