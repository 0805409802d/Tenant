import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_components.dart';

class ManagementHomeScreen extends StatefulWidget {
  const ManagementHomeScreen({super.key});
  @override
  State<ManagementHomeScreen> createState() => _ManagementHomeScreenState();
}

class _ManagementHomeScreenState extends State<ManagementHomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _tenant;
  int _totalProducts = 0;
  int _totalWorkers  = 0;
  int _totalOrders   = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db  = Supabase.instance.client;
      final uid = db.auth.currentUser?.id;
      if (uid == null) { if (mounted) setState(() => _loading = false); return; }

      final profile = await db.from('profiles').select().eq('id', uid).maybeSingle();
      final tenant  = await db.from('tenants').select().eq('owner_id', uid).maybeSingle();

      int products = 0, workers = 0, orders = 0;
      if (tenant != null) {
        final tenantId = tenant['id'];
        final pRes = await db.from('products').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('tenant_id', tenantId);
        final wRes = await db.from('workers').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('tenant_id', tenantId);
        final oRes = await db.from('orders').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('tenant_id', tenantId);
        products = pRes.count ?? 0;
        workers  = wRes.count ?? 0;
        orders   = oRes.count ?? 0;
      }

      if (!mounted) return;
      if (tenant != null) {
        TenantThemeProvider.of(context).initialize(tenant['id']);
      }
      
      setState(() { _profile = profile; _tenant = tenant; _totalProducts = products; _totalWorkers = workers; _totalOrders = orders; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final name        = _profile?['owner_name'] as String? ?? _profile?['email'] as String? ?? 'Manager';
    final businessName = _tenant?['name'] as String? ?? _profile?['business_name'] as String? ?? 'Tu negocio';
    final slug        = _tenant?['slug'] as String?;
    final initials    = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    final themeNotifier = TenantThemeProvider.of(context);
    final primaryColor = themeNotifier.primaryColor;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: _loading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── SliverAppBar con branding ─────────────────────────
                  SliverAppBar(
                    expandedHeight: 160,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.surface,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 22),
                        onPressed: () => context.go('/settings'),
                        tooltip: 'Ajustes',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary, size: 20),
                        onPressed: _signOut,
                        tooltip: 'Cerrar sesión',
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                          Row(children: [
                            if (themeNotifier.logoUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(themeNotifier.logoUrl!, width: 44, height: 44, fit: BoxFit.cover),
                              )
                            else
                              CircleAvatar(radius: 22, backgroundColor: AppColors.white.withValues(alpha: 0.2),
                                child: Text(initials, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('$_greeting,', style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8))),
                              Text(name.split(' ').first, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                            ])),
                          ]),
                          const SizedBox(height: 8),
                          Text(businessName, style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.75))),
                        ]),
                      ),
                    ),
                    title: Text(businessName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),

                  // ── Contenido ──────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(delegate: SliverChildListDelegate([

                      // Stats
                      Row(children: [
                        _Stat(label: 'Productos', value: '$_totalProducts', icon: Icons.inventory_2_outlined, color: primaryColor),
                        const SizedBox(width: 12),
                        _Stat(label: 'Trabajadores', value: '$_totalWorkers', icon: Icons.group_outlined, color: AppColors.accentTeal),
                        const SizedBox(width: 12),
                        _Stat(label: 'Pedidos', value: '$_totalOrders', icon: Icons.receipt_outlined, color: AppColors.accentAmber),
                      ]),
                      const SizedBox(height: 20),

                      // Link de mi sitio
                      if (slug != null) ...[
                        _Card(child: Row(children: [
                          Icon(Icons.link_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Tu sitio web', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('$slug.quinindews.com', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ])),
                          TextButton(onPressed: () {}, child: Text('Abrir', style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600))),
                        ])),
                        const SizedBox(height: 16),
                      ],

                      // Acciones rápidas
                      const Text('GESTIONAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      _Card(child: Column(children: [
                        AppListTile(icon: Icons.inventory_2_outlined, title: 'Mis productos', subtitle: '$_totalProducts producto${_totalProducts != 1 ? 's' : ''} publicado${_totalProducts != 1 ? 's' : ''}', iconColor: primaryColor, onTap: () => context.go('/products')),
                        AppListTile(icon: Icons.receipt_long_outlined, title: 'Pedidos', subtitle: '$_totalOrders orden${_totalOrders != 1 ? 'es' : ''} registrada${_totalOrders != 1 ? 's' : ''}', iconColor: AppColors.accentAmber, onTap: () => context.go('/sales')),
                        AppListTile(icon: Icons.group_outlined, title: 'Trabajadores', subtitle: '$_totalWorkers de 2 cuentas usadas', iconColor: AppColors.accentTeal, onTap: () => context.go('/security')),
                        AppListTile(icon: Icons.qr_code_2_rounded, title: 'QR de mi negocio', subtitle: 'Descargar código QR en PDF', iconColor: AppColors.accentGreen, onTap: () => context.go('/settings')),
                      ])),
                      const SizedBox(height: 16),

                      // Cuenta
                      const Text('CUENTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      _Card(child: Column(children: [
                        AppListTile(icon: Icons.tune_outlined, title: 'Ajustes', subtitle: 'Logo, colores, nombre', iconColor: primaryColor, onTap: () => context.go('/settings')),
                        AppListTile(icon: Icons.shield_outlined, title: 'Seguridad', subtitle: 'Contraseña, preguntas, trabajadores', iconColor: AppColors.accentPurple, onTap: () => context.go('/security')),
                        AppListTile(icon: Icons.logout_rounded, title: 'Cerrar sesión', iconColor: AppColors.error, destructive: true, onTap: _signOut),
                      ])),
                      const SizedBox(height: 32),
                    ])),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
    child: child,
  );
}