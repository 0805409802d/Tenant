import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/order_service.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/app_widgets.dart';

// ─────────────────────────────────────────────
// Modelo interno para el carrito
// ─────────────────────────────────────────────
class _CartItem {
  final Map<String, dynamic> product;
  int quantity;
  _CartItem({required this.product, int initialQuantity = 1}) : quantity = initialQuantity;
}

/// Home del espacio Client — es la página pública del negocio.
/// Muestra el catálogo del tenant actual (identificado por su slug),
/// aplica el color y logo personalizado del negocio, y provee
/// flujo completo de carrito + checkout.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.tenantSlug});
  final String tenantSlug;
  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _tenant;
  Map<String, dynamic>? _clientProfile;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  bool _isLoggedIn = false;

  // Tema dinámico del negocio
  Color _primaryColor = const Color(0xFF0097A7);
  Color _primaryDark  = const Color(0xFF006B7A);
  String? _logoUrl;
  String? _catalogCoverUrl;

  // Carrito
  final List<_CartItem> _cart = [];

  // Animaciones
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _load();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final db = Supabase.instance.client;

      final tenant = await db
          .from('tenants')
          .select('''
            id, business_name, slug, owner_id, primary_color, logo_url,
            whatsapp_number, whatsapp_enabled, currency_symbol, catalog_cover_url,
            shipping_cost, manual_payment_instructions
          ''')
          .eq('slug', widget.tenantSlug)
          .maybeSingle();

      // Aplicar tema del negocio si existe
      if (tenant != null) {
        if (tenant['primary_color'] != null) {
          try {
            final hex = (tenant['primary_color'] as String).replaceAll('#', '');
            final color = Color(int.parse('FF$hex', radix: 16));
            _primaryColor = color;
            _primaryDark  = Color.fromARGB(
              255,
              (color.r * 255.0 * 0.7).round().clamp(0, 255),
              (color.g * 255.0 * 0.7).round().clamp(0, 255),
              (color.b * 255.0 * 0.7).round().clamp(0, 255),
            );
          } catch (_) {}
        }
        _logoUrl = tenant['logo_url'] as String?;
        _catalogCoverUrl = tenant['catalog_cover_url'] as String?;
      }

      // Obtener datos del perfil del cliente conectado
      final uid = db.auth.currentUser?.id;
      if (uid != null) {
        _clientProfile = await db.from('profiles').select().eq('id', uid).maybeSingle();
      }

      List<Map<String, dynamic>> products = [];
      if (tenant != null) {
        final pRes = await db
            .from('products')
            .select()
            .eq('tenant_id', tenant['id'])
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(50);
        products = List<Map<String, dynamic>>.from(pRes);
      }

      if (!mounted) return;
      setState(() {
        _tenant = tenant;
        _products = products;
        _loading = false;
      });
      _staggerCtrl.forward();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Carrito ────────────────────────────────────────────────────────────────

  void _addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    setState(() {
      final existing = _cart.where((i) => i.product['id'] == product['id']).toList();
      if (existing.isNotEmpty) {
        existing.first.quantity += quantity;
      } else {
        _cart.add(_CartItem(product: product, initialQuantity: quantity));
      }
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: AppColors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('${product['name']} agregado al carrito', style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      duration: const Duration(seconds: 2),
      backgroundColor: _primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    ));
  }

  void _updateQuantity(String productId, int delta) {
    setState(() {
      final item = _cart.where((i) => i.product['id'] == productId).toList();
      if (item.isNotEmpty) {
        item.first.quantity += delta;
        if (item.first.quantity <= 0) {
          _cart.removeWhere((i) => i.product['id'] == productId);
        }
      }
    });
  }

  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);
  double get _cartTotal => _cart.fold(0.0, (s, i) => s + (i.product['price'] as num).toDouble() * i.quantity);

  void _showCart() {
    final double shippingCost = (_tenant?['shipping_cost'] as num? ?? 0.0).toDouble();
    final String instructions = _tenant?['manual_payment_instructions'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        cart: _cart,
        primaryColor: _primaryColor,
        cartTotal: _cartTotal,
        cartCount: _cartCount,
        clientProfile: _clientProfile,
        shippingCost: shippingCost,
        manualPaymentInstructions: instructions,
        onUpdateQuantity: (id, delta) {
          _updateQuantity(id, delta);
        },
        onCheckout: (name, phone, address, deliveryOpt, paymentMethod, finalTotal) {
          _checkout(name, phone, address, deliveryOpt, paymentMethod, finalTotal);
        },
      ),
    );
  }

  Future<void> _checkout(
    String clientName,
    String clientPhone,
    String deliveryAddress,
    String deliveryOption,
    String paymentMethod,
    double finalTotal,
  ) async {
    Navigator.of(context).pop(); // cerrar carrito

    final db  = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;

    // Si no está logueado, redirigir al login
    if (uid == null) {
      context.go('/login');
      return;
    }

    final tenantId = _tenant?['id'] as String?;
    if (tenantId == null) return;

    final items = _cart.map((i) => {
      'product_id': i.product['id'],
      'quantity': i.quantity,
      'unit_price': (i.product['price'] as num).toDouble(),
    }).toList();

    // 1. Guardar orden en Supabase
    final success = await OrderService.createOrder(
      tenantId: tenantId,
      clientId: uid,
      totalAmount: finalTotal,
      items: items,
    );

    if (!mounted) return;

    if (success) {
      // 2. Si WhatsApp está habilitado y configurado, generar el link universal wa.me
      final waEnabled = _tenant?['whatsapp_enabled'] as bool? ?? true;
      final waNumber = _tenant?['whatsapp_number'] as String?;

      if (waEnabled && waNumber != null && waNumber.isNotEmpty) {
        final businessName = _tenant?['business_name'] ?? 'Tienda';
        final symbol = _tenant?['currency_symbol'] ?? '\$';
        final shipping = (_tenant?['shipping_cost'] as num? ?? 0.0).toDouble();

        // Estructurar el mensaje de compra
        final buffer = StringBuffer();
        buffer.writeln('🛒 *NUEVO PEDIDO - $businessName*');
        buffer.writeln();
        buffer.writeln('Hola, me gustaría comprar:');
        for (var item in _cart) {
          final pName = item.product['name'];
          final pPrice = (item.product['price'] as num).toDouble();
          buffer.writeln('• ${item.quantity}x $pName ($symbol${pPrice.toStringAsFixed(2)})');
        }
        buffer.writeln('------------------------------------------');
        if (deliveryOption == 'delivery') {
          buffer.writeln('🚚 Entrega: A Domicilio ($symbol${shipping.toStringAsFixed(2)})');
        } else {
          buffer.writeln('🏬 Entrega: Retiro en Local (\$0.00)');
        }
        buffer.writeln('💰 *TOTAL: $symbol${finalTotal.toStringAsFixed(2)}*');
        buffer.writeln();
        buffer.writeln('📍 *Datos de Entrega:*');
        buffer.writeln('• Cliente: $clientName');
        buffer.writeln('• Celular: $clientPhone');
        if (deliveryOption == 'delivery') {
          buffer.writeln('• Dirección: $deliveryAddress');
        }
        buffer.writeln('• Método de Pago: ${paymentMethod == 'transfer' ? 'Transferencia Bancaria' : 'Efectivo contra entrega'}');
        buffer.writeln();
        buffer.writeln('Pulse para procesar mi compra. ¡Muchas gracias!');

        final textEncoded = Uri.encodeComponent(buffer.toString());
        final cleanNumber = waNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final waUri = Uri.parse('https://wa.me/$cleanNumber?text=$textEncoded');

        try {
          if (await canLaunchUrl(waUri)) {
            await launchUrl(waUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }

      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.celebration_rounded, color: AppColors.white, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('¡Pedido realizado! Se ha enviado el mensaje al negocio.', style: TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        duration: const Duration(seconds: 5),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Error al realizar el pedido. Inténtalo de nuevo.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ));
    }
  }

  // Navigate to product detail and handle add-to-cart result
  Future<void> _openProductDetail(Map<String, dynamic> product) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _ProductDetailInline(
          product: product,
          tenantSlug: widget.tenantSlug,
          primaryColor: _primaryColor,
        ),
      ),
    );
    if (result != null && mounted) {
      _addToCart(result['product'], quantity: result['quantity'] ?? 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = _tenant?['business_name'] as String? ?? widget.tenantSlug;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: _loading
          ? _CatalogSkeleton(color: _primaryColor)
          : RefreshIndicator(
              onRefresh: _load,
              color: _primaryColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                  // ── Header del negocio (Glassmorphism & Hero) ──────────
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.surface.withValues(alpha: 0.95),
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    actions: [
                      // Botón carrito
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: AnimatedScale(
                          scale: _cartCount > 0 ? 1.0 : 0.9,
                          duration: const Duration(milliseconds: 200),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _cartCount > 0 ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
                                  color: _cartCount > 0 ? _primaryColor : AppColors.textPrimary,
                                  size: 20,
                                ),
                                onPressed: _cartCount > 0 ? _showCart : null,
                                tooltip: _cartCount > 0 ? 'Ver carrito' : 'Carrito vacío',
                              ),
                              if (_cartCount > 0)
                                Positioned(
                                  top: -2, right: -2,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.elasticOut,
                                    builder: (_, val, child) => Transform.scale(scale: val, child: child),
                                    child: Container(
                                      width: 18, height: 18,
                                      decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle),
                                      child: Center(child: Text('$_cartCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.white))),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Botón Login / Perfil
                      Container(
                        margin: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: _isLoggedIn
                            ? IconButton(icon: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 20), onPressed: () => context.go('/settings'), tooltip: 'Mi perfil')
                            : TextButton.icon(
                                onPressed: () => context.go('/login'),
                                icon: Icon(Icons.login_rounded, size: 16, color: _primaryColor),
                                label: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                style: TextButton.styleFrom(foregroundColor: _primaryColor, padding: const EdgeInsets.symmetric(horizontal: 16)),
                              ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          image: _catalogCoverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_catalogCoverUrl!),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.srcOver),
                                )
                              : null,
                          gradient: _catalogCoverUrl == null
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_primaryColor, _primaryColor.withValues(alpha: 0.85)],
                                )
                              : null,
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                          Row(children: [
                            if (_logoUrl != null) ...[
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(_logoUrl!, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: -0.5)),
                              const SizedBox(height: 2),
                              Text('Catálogo en línea', style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                            ])),
                          ]),
                        ]),
                      ),
                    ),
                  ),

                  // ── Contenido ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      if (_tenant == null) ...[
                        _EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Negocio no encontrado',
                          subtitle: 'No encontramos el negocio "${widget.tenantSlug}".',
                          color: AppColors.error,
                        ),
                      ] else ...[
                        // Sin productos
                        if (_products.isEmpty)
                          _EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'Catálogo en preparación',
                            subtitle: '$businessName aún no ha publicado productos.',
                            color: _primaryColor,
                          )
                        else ...[
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('CATÁLOGO · ${_products.length} producto${_products.length != 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                            if (_cartCount > 0)
                              GestureDetector(
                                onTap: _showCart,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.tint(_primaryColor),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.shopping_cart_outlined, size: 14, color: _primaryColor),
                                    const SizedBox(width: 4),
                                    Text('$_cartCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryColor)),
                                  ]),
                                ),
                              ),
                          ]),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Responsive.isDesktop(context) ? 4 : (Responsive.isTablet(context) ? 3 : 2),
                              mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (_, i) {
                              final delay = (i * 0.08).clamp(0.0, 0.8);
                              final end = (delay + 0.4).clamp(0.0, 1.0);
                              final itemAnim = CurvedAnimation(
                                parent: _staggerCtrl,
                                curve: Interval(delay, end, curve: Curves.easeOutCubic),
                              );

                              return AnimatedBuilder(
                                animation: itemAnim,
                                builder: (ctx, child) => Opacity(
                                  opacity: itemAnim.value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - itemAnim.value)),
                                    child: child,
                                  ),
                                ),
                                child: _ProductCard(
                                  product: _products[i],
                                  accentColor: _primaryColor,
                                  onAddToCart: _addToCart,
                                  onTap: () => _openProductDetail(_products[i]),
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Cuenta del cliente
                        if (_isLoggedIn) ...[
                          const Text('MI CUENTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
                              boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 10, offset: const Offset(0, 2))]),
                            child: Column(children: [
                              AppListTile(icon: Icons.person_outline_rounded, title: 'Mi perfil', subtitle: 'Foto y datos de cuenta', iconColor: _primaryColor, onTap: () => context.go('/settings')),
                              AppListTile(icon: Icons.shield_outlined, title: 'Seguridad', subtitle: 'Contraseña y preguntas', iconColor: AppColors.accentPurple, onTap: () => context.go('/security')),
                              AppListTile(icon: Icons.logout_rounded, title: 'Cerrar sesión', iconColor: AppColors.error, destructive: true,
                                onTap: () async {
                                  await Supabase.instance.client.auth.signOut();
                                  if (context.mounted) setState(() => _isLoggedIn = false);
                                }),
                            ]),
                          ),
                        ] else ...[
                          // Invitación a registrarse
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.tint(_primaryColor),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.login_rounded, color: _primaryColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('¿Quieres hacer un pedido?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _primaryColor)),
                                const SizedBox(height: 2),
                                const Text('Inicia sesión o crea una cuenta para continuar.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ])),
                              IconButton(
                                onPressed: () => context.go('/login'),
                                icon: Icon(Icons.arrow_forward_ios_rounded, color: _primaryColor, size: 18),
                              ),
                            ]),
                          ),
                        ],
                      ],

                      const SizedBox(height: 32),
                    ])),
                  ),
                  ],
                ),
              ),
            ),
          ),
      // FAB del carrito con animación
      floatingActionButton: AnimatedScale(
        scale: _cartCount > 0 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: FloatingActionButton.extended(
          onPressed: _showCart,
          backgroundColor: _primaryColor,
          elevation: 6,
          icon: const Icon(Icons.shopping_cart_rounded, color: AppColors.white, size: 20),
          label: Text('\$${_cartTotal.toStringAsFixed(2)} · $_cartCount item${_cartCount != 1 ? 's' : ''}',
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Inline Product Detail
// ─────────────────────────────────────────────
class _ProductDetailInline extends StatefulWidget {
  const _ProductDetailInline({
    required this.product,
    required this.tenantSlug,
    required this.primaryColor,
  });
  final Map<String, dynamic> product;
  final String tenantSlug;
  final Color primaryColor;

  @override
  State<_ProductDetailInline> createState() => _ProductDetailInlineState();
}

class _ProductDetailInlineState extends State<_ProductDetailInline> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final name     = widget.product['name'] as String? ?? 'Producto';
    final price    = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = widget.product['image_url'] as String?;
    final desc     = widget.product['description'] as String?;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: CustomScrollView(
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholderLarge())
                  : _imgPlaceholderLarge(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('\$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, color: widget.primaryColor, fontWeight: FontWeight.w800)),
                  if (desc != null && desc.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Descripción', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
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
                        }, color: widget.primaryColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ),
                        _QtyButton(icon: Icons.add_rounded, onTap: () => setState(() => _quantity++), color: widget.primaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Total preview
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    Text('\$${(price * _quantity).toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: widget.primaryColor)),
                  ]),

                  // Padding for bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Agregar al carrito · \$${(price * _quantity).toStringAsFixed(2)}',
              onPressed: () {
                Navigator.of(context).pop({
                  'product': widget.product,
                  'quantity': _quantity,
                });
              },
              color: widget.primaryColor,
            ),
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

// ─────────────────────────────────────────────
// Carrito BottomSheet rediseñado con Checkout Manual
// ─────────────────────────────────────────────
class _CartSheet extends StatefulWidget {
  const _CartSheet({
    required this.cart,
    required this.primaryColor,
    required this.cartTotal,
    required this.cartCount,
    required this.clientProfile,
    required this.shippingCost,
    required this.manualPaymentInstructions,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  final List<_CartItem> cart;
  final Color primaryColor;
  final double cartTotal;
  final int cartCount;
  final Map<String, dynamic>? clientProfile;
  final double shippingCost;
  final String manualPaymentInstructions;
  final void Function(String productId, int delta) onUpdateQuantity;
  final void Function(
    String clientName,
    String clientPhone,
    String deliveryAddress,
    String deliveryOption,
    String paymentMethod,
    double finalTotal,
  ) onCheckout;

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _deliveryOption = 'pickup'; // 'pickup' o 'delivery'
  String _paymentMethod = 'cash'; // 'cash' o 'transfer'

  @override
  void initState() {
    super.initState();
    if (widget.clientProfile != null) {
      _nameCtrl.text = '${widget.clientProfile!['first_name'] ?? ''} ${widget.clientProfile!['last_name'] ?? ''}'.trim();
      _phoneCtrl.text = widget.clientProfile!['phone'] ?? '';
      _addressCtrl.text = widget.clientProfile!['address'] ?? '';
    }
  }

  void _update(String productId, int delta) {
    widget.onUpdateQuantity(productId, delta);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double finalTotal = widget.cartTotal + (_deliveryOption == 'delivery' ? widget.shippingCost : 0.0);

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
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.shopping_cart_rounded, color: widget.primaryColor, size: 22),
                const SizedBox(width: 10),
                Text('Mi carrito', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.tint(widget.primaryColor), borderRadius: BorderRadius.circular(20)),
                  child: Text('${widget.cartCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: widget.primaryColor)),
                ),
              ]),
              IconButton(icon: const Icon(Icons.close_rounded, size: 22), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
          
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(children: [
                        Icon(Icons.shopping_cart_outlined, color: AppColors.textSecondary, size: 48),
                        SizedBox(height: 12),
                        Text('El carrito está vacío.', style: TextStyle(color: AppColors.textSecondary)),
                      ]),
                    )
                  else ...[
                    // List of items
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: widget.cart.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = widget.cart[i];
                        final price = (item.product['price'] as num).toDouble();
                        final imageUrl = item.product['image_url'] as String?;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 56, height: 56,
                                child: imageUrl != null
                                    ? Image.network(imageUrl, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _imgPlaceholder())
                                    : _imgPlaceholder(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.product['name'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text('\$${(price * item.quantity).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: widget.primaryColor, fontWeight: FontWeight.w700)),
                            ])),
                            Row(children: [
                              _QtyButton(icon: Icons.remove_rounded, onTap: () => _update(item.product['id'], -1), color: widget.primaryColor),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('${item.quantity}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              ),
                              _QtyButton(icon: Icons.add_rounded, onTap: () => _update(item.product['id'], 1), color: widget.primaryColor),
                            ]),
                          ]),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider()),
                    const SizedBox(height: 8),

                    // Checkout Form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATOS DE ENTREGA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          const AppLabel('Nombre completo'), const SizedBox(height: 6),
                          AppTextField(controller: _nameCtrl, hint: 'Ej. Juan Pérez', icon: Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          const AppLabel('Teléfono Celular'), const SizedBox(height: 6),
                          AppTextField(controller: _phoneCtrl, hint: 'Ej. +593 99 999 9999', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          
                          // Delivery options
                          Row(
                            children: [
                              Expanded(
                                child: _RadioOptionCard(
                                  label: 'Retiro en Local',
                                  icon: Icons.storefront_rounded,
                                  isSelected: _deliveryOption == 'pickup',
                                  primaryColor: widget.primaryColor,
                                  onTap: () => setState(() => _deliveryOption = 'pickup'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _RadioOptionCard(
                                  label: 'A Domicilio',
                                  icon: Icons.local_shipping_outlined,
                                  isSelected: _deliveryOption == 'delivery',
                                  primaryColor: widget.primaryColor,
                                  onTap: () => setState(() => _deliveryOption = 'delivery'),
                                ),
                              ),
                            ],
                          ),
                          
                          if (_deliveryOption == 'delivery') ...[
                            const SizedBox(height: 16),
                            const AppLabel('Dirección exacta de entrega'), const SizedBox(height: 6),
                            AppTextField(controller: _addressCtrl, hint: 'Ej. Calle Falsa 123 y Av. Principal', icon: Icons.map_outlined),
                          ],
                          
                          const SizedBox(height: 24),
                          const Text('MÉTODO DE PAGO MANUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          
                          // Payment Options
                          Row(
                            children: [
                              Expanded(
                                child: _RadioOptionCard(
                                  label: 'Efectivo',
                                  icon: Icons.payments_outlined,
                                  isSelected: _paymentMethod == 'cash',
                                  primaryColor: widget.primaryColor,
                                  onTap: () => setState(() => _paymentMethod = 'cash'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _RadioOptionCard(
                                  label: 'Transferencia',
                                  icon: Icons.account_balance_rounded,
                                  isSelected: _paymentMethod == 'transfer',
                                  primaryColor: widget.primaryColor,
                                  onTap: () => setState(() => _paymentMethod = 'transfer'),
                                ),
                              ),
                            ],
                          ),
                          
                          if (_paymentMethod == 'transfer' && widget.manualPaymentInstructions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: widget.primaryColor.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, color: widget.primaryColor, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Instrucciones de Pago',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.primaryColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.manualPaymentInstructions,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Totals summaries
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text('\$${widget.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          ]),
                          if (_deliveryOption == 'delivery') ...[
                            const SizedBox(height: 6),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Envío a domicilio', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('\$${widget.shippingCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            ]),
                          ],
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Total a pagar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('\$${finalTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: widget.primaryColor)),
                          ]),
                          
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: 'Confirmar por WhatsApp',
                              onPressed: () {
                                final name = _nameCtrl.text.trim();
                                final phone = _phoneCtrl.text.trim();
                                final address = _addressCtrl.text.trim();
                                
                                if (name.isEmpty || phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa tu Nombre y Teléfono')));
                                  return;
                                }
                                if (_deliveryOption == 'delivery' && address.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa la Dirección de entrega')));
                                  return;
                                }
                                
                                widget.onCheckout(name, phone, address, _deliveryOption, _paymentMethod, finalTotal);
                              },
                              color: widget.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: AppColors.border.withValues(alpha: 0.3),
    child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 22),
  );
}

class _RadioOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _RadioOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryColor : AppColors.border, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? primaryColor : AppColors.textSecondary, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? primaryColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tarjeta de producto con animación de escala
// ─────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.accentColor,
    required this.onAddToCart,
    required this.onTap,
  });
  final Map<String, dynamic> product;
  final Color accentColor;
  final ValueChanged<Map<String, dynamic>> onAddToCart;
  final VoidCallback onTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final name     = widget.product['name'] as String? ?? 'Producto';
    final price    = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = widget.product['image_url'] as String?;
    final desc     = widget.product['description'] as String?;

    final trackInv = widget.product['track_inventory'] as bool? ?? true;
    final stock = widget.product['stock_quantity'] as int? ?? 0;
    final minAlert = widget.product['min_stock_alert'] as int? ?? 5;
    
    final isLowStock = trackInv && stock <= minAlert;
    final isOutOfStock = trackInv && stock <= 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                    if (trackInv && stock > 0 && isLowStock)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '¡Pocas unidades!',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info + botón
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    if (desc != null && desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('\$${price.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: widget.accentColor)),
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Agotado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      )
                    else
                      GestureDetector(
                        onTap: () => widget.onAddToCart(widget.product),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(color: widget.accentColor, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_rounded, color: AppColors.white, size: 20),
                        ),
                      ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.surfaceGrey,
    child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 32),
  );
}

// ─────────────────────────────────────────────
// Botón de cantidad +/-
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// Estado vacío
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle, required this.color});
  final IconData icon;
  final String title, subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: color, size: 30)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
// Skeleton de carga para el catálogo
// ─────────────────────────────────────────────
class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        ),
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppShimmerLoader(width: 44, height: 44, borderRadius: 10),
                SizedBox(height: 12),
                AppShimmerLoader(width: 180, height: 22, borderRadius: 4),
                SizedBox(height: 6),
                AppShimmerLoader(width: 140, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppShimmerLoader(width: 120, height: 12, borderRadius: 4),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                  children: List.generate(4, (_) => const AppShimmerLoader(borderRadius: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}