import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/product_service.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Pantalla de detalle de producto con datos reales desde Supabase.
/// Accesible mediante ruta /product/:id
class ClientProductDetailScreen extends StatefulWidget {
  const ClientProductDetailScreen({
    super.key,
    required this.tenantSlug,
    required this.productId,
  });

  final String tenantSlug;
  final String productId;

  @override
  State<ClientProductDetailScreen> createState() => _ClientProductDetailScreenState();
}

class _ClientProductDetailScreenState extends State<ClientProductDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _product;
  bool _loading = true;
  int _quantity = 1;
  Color _primaryColor = const Color(0xFF0097A7);

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadProduct();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final product = await ProductService.getProductById(widget.productId);

    if (product != null) {
      // Extract tenant color
      final tenant = product['tenants'] as Map<String, dynamic>?;
      if (tenant != null && tenant['primary_color'] != null) {
        try {
          final hex = (tenant['primary_color'] as String).replaceAll('#', '');
          _primaryColor = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _product = product;
      _loading = false;
    });
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.error),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Producto no encontrado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Este producto no existe o ha sido eliminado.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final name     = _product!['name'] as String? ?? 'Producto';
    final price    = (_product!['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = _product!['image_url'] as String?;
    final desc     = _product!['description'] as String?;
    final tenantInfo = _product!['tenants'] as Map<String, dynamic>?;
    final businessName = tenantInfo?['business_name'] as String? ?? widget.tenantSlug;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // Imagen inmersiva edge-to-edge
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.width,
              pinned: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.overlay(0.08), blurRadius: 8)],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholderLarge())
                    : _imgPlaceholderLarge(),
              ),
              title: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
            ),

            // Contenido del producto
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                transform: Matrix4.translationValues(0, -24, 0),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tienda
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tint(_primaryColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.storefront_outlined, size: 14, color: _primaryColor),
                          const SizedBox(width: 4),
                          Text(businessName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryColor)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Nombre y precio
                    Text(name, style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text('\$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryColor)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.accentGreen),
                          SizedBox(width: 4),
                          Text('Disponible', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentGreen)),
                        ]),
                      ),
                    ]),

                    if (desc != null && desc.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Descripción', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                    ],

                    // Selector de cantidad
                    const SizedBox(height: 28),
                    const Text('Cantidad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QtyButton(icon: Icons.remove_rounded, onTap: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          }, color: _primaryColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          ),
                          _QtyButton(icon: Icons.add_rounded, onTap: () => setState(() => _quantity++), color: _primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Total preview
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Text('\$${(price * _quantity).toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primaryColor)),
                    ]),

                    // Padding for bottom bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky footer
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: AppColors.overlay(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Agregar al carrito · \$${(price * _quantity).toStringAsFixed(2)}',
                  onPressed: () {
                    // Go back to home — the product will be available in the catalog
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('$name agregado ($_quantity)', style: const TextStyle(fontWeight: FontWeight.w600))),
                      ]),
                      backgroundColor: _primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      duration: const Duration(seconds: 2),
                    ));
                    // Pop back and let the home screen know
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholderLarge() => Container(
    color: AppColors.surfaceGrey,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 80),
        const SizedBox(height: 8),
        const Text('Sin imagen', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    ),
  );
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, required this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: AppColors.tint(color),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, size: 18, color: color),
    ),
  );
}
