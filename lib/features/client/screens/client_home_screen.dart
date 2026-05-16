import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/widgets/app_components.dart';

/// Home del espacio Client — es la página pública del negocio.
/// Muestra el catálogo del tenant actual (identificado por su slug).
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.tenantSlug});
  final String tenantSlug;
  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const _accent = Color(0xFF0097A7);
  Map<String, dynamic>? _tenant;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    _load();
  }

  Future<void> _load() async {
    try {
      final db = Supabase.instance.client;

      // Buscar el tenant por slug
      final tenant = await db.from('tenants').select('id, name, slug, owner_id').eq('slug', widget.tenantSlug).maybeSingle();

      List<Map<String, dynamic>> products = [];
      if (tenant != null) {
        final pRes = await db.from('products').select().eq('tenant_id', tenant['id']).eq('is_active', true).order('created_at', ascending: false).limit(20);
        products = List<Map<String, dynamic>>.from(pRes);
      }

      if (!mounted) return;
      setState(() { _tenant = tenant; _products = products; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = _tenant?['name'] as String? ?? widget.tenantSlug;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: _accent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header del negocio ────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 140,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.surface,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    actions: [
                      if (_isLoggedIn) ...[
                        IconButton(icon: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary, size: 22), onPressed: () => context.go('/settings'), tooltip: 'Mi perfil'),
                        IconButton(icon: const Icon(Icons.security_outlined, color: AppColors.textPrimary, size: 20), onPressed: () => context.go('/security'), tooltip: 'Seguridad'),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            style: TextButton.styleFrom(foregroundColor: _accent),
                            child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_accent, Color(0xFF006B7A)]),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text(businessName, style: const TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.storefront_outlined, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text('${widget.tenantSlug}.quinindews.com', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ]),
                        ]),
                      ),
                    ),
                    title: Text(businessName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),

                  // ── Catálogo ──────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(delegate: SliverChildListDelegate([

                      // Negocio no encontrado
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
                            color: _accent,
                          )
                        else ...[
                          const Text('CATÁLOGO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (_, i) => _ProductCard(product: _products[i]),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Cuenta del cliente
                        if (_isLoggedIn) ...[
                          const Text('MI CUENTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                            child: Column(children: [
                              AppListTile(icon: Icons.person_outline_rounded, title: 'Mi perfil', subtitle: 'Foto y datos de cuenta', iconColor: _accent, onTap: () => context.go('/settings')),
                              AppListTile(icon: Icons.shield_outlined, title: 'Seguridad', subtitle: 'Contraseña y preguntas', iconColor: AppColors.accentPurple, onTap: () => context.go('/security')),
                              AppListTile(icon: Icons.logout_rounded, title: 'Cerrar sesión', iconColor: AppColors.error, destructive: true,
                                onTap: () async { await Supabase.instance.client.auth.signOut(); if (context.mounted) context.go('/'); }),
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
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final name     = product['name'] as String? ?? 'Producto';
    final price    = (product['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = product['image_url'] as String?;

    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Imagen
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
          child: AspectRatio(
            aspectRatio: 1,
            child: imageUrl != null
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
        ),
        // Info
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.surfaceGrey,
    child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 32),
  );
}

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