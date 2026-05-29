import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/app_widgets.dart';

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
  int _productLimit  = 20;
  String _planTier   = 'freemium';
  bool _loading = true;
  bool _isWorker = false;

  // Worker-specific stats
  int _pendingOrders  = 0;
  int _approvedToday  = 0;

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
      final tenant = await TenantService.getCurrentUserTenant();
      final isWorker = await TenantService.isCurrentUserWorker();

      int products = 0, workers = 0, orders = 0, pending = 0, approvedToday = 0;
      if (tenant != null) {
        final tenantId = tenant['id'];
        final pRes = await db.from('products').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('tenant_id', tenantId);
        final wRes = await db.from('workers').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('tenant_id', tenantId);
        final oRes = await db.from('orders').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('tenant_id', tenantId);
        products = pRes.count ?? 0;
        workers  = wRes.count ?? 0;
        orders   = oRes.count ?? 0;

        // Worker-specific: pending and approved today
        final pendingRes = await db
            .from('orders')
            .select('id', const FetchOptions(count: CountOption.exact, head: true))
            .eq('tenant_id', tenantId)
            .eq('status', 'pending');
        pending = pendingRes.count ?? 0;

        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();
        final approvedRes = await db
            .from('orders')
            .select('id', const FetchOptions(count: CountOption.exact, head: true))
            .eq('tenant_id', tenantId)
            .eq('status', 'approved')
            .gte('created_at', todayStart);
        approvedToday = approvedRes.count ?? 0;

        if (!isWorker) {
          try {
            final usageRes = await db.rpc('get_tenant_product_usage', params: {'p_tenant_id': tenantId});
            if (usageRes != null) {
              _productLimit = usageRes['limit'] ?? 20;
              _planTier = usageRes['tier'] ?? 'freemium';
              products = usageRes['used'] ?? products;
            }
          } catch (e) {
            debugPrint('Error loading product usage: $e');
          }
        }
      }

      if (!mounted) return;
      if (tenant != null) {
        TenantThemeProvider.of(context).initialize(tenant['id']);
      }

      setState(() {
        _profile = profile;
        _tenant = tenant;
        _totalProducts = products;
        _totalWorkers = workers;
        _totalOrders = orders;
        _pendingOrders = pending;
        _approvedToday = approvedToday;
        _isWorker = isWorker;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _openWebsite(String slug) async {
    final uri = Uri.parse('https://$slug.quinindews.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final name         = _profile?['owner_name'] as String?
        ?? _profile?['first_name'] as String?
        ?? _profile?['email'] as String?
        ?? Supabase.instance.client.auth.currentUser?.email
        ?? 'Usuario';
    final businessName = _tenant?['business_name'] as String?
        ?? _profile?['business_name'] as String?
        ?? 'Tu negocio';
    final slug         = _tenant?['slug'] as String?;
    final initials     = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    final themeNotifier = TenantThemeProvider.of(context);
    final primaryColor  = themeNotifier.primaryColor;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: _loading
          ? const _HomeSkeleton()
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: _load,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                  // ── SliverAppBar ──────────────────────────────────────
                  // ── SliverAppBar (Hero Header) ────────────────────────
                  SliverAppBar(
                    expandedHeight: Responsive.isMobile(context) ? 200 : 175,
                    floating: false,
                    pinned: true,
                    backgroundColor: primaryColor,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    title: Text(
                      businessName,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: Responsive.isDesktop(context) ? 75 : (Responsive.isTablet(context) ? 55 : 45),
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 0.5,
                        height: 1.25,
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 16, top: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.white, size: 20),
                          onPressed: _signOut,
                          tooltip: 'Cerrar sesión',
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 60, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // ── Avatar & Saludo (Izquierda) ──
                            Expanded(
                              flex: 5,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: themeNotifier.logoUrl != null ? BoxShape.rectangle : BoxShape.circle,
                                      borderRadius: themeNotifier.logoUrl != null ? BorderRadius.circular(12) : null,
                                    ),
                                    child: themeNotifier.logoUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(themeNotifier.logoUrl!, width: 64, height: 64, fit: BoxFit.cover),
                                          )
                                        : CircleAvatar(
                                            radius: 32,
                                            backgroundColor: AppColors.surfaceGrey,
                                            child: Text(initials, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$_greeting,', style: TextStyle(fontSize: 16, color: AppColors.white.withValues(alpha: 0.85))),
                                        Text(
                                          name.split(' ').first,
                                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: -0.5),
                                        ),
                                        if (_isWorker) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.badge_outlined, size: 14, color: AppColors.white.withValues(alpha: 0.95)),
                                                const SizedBox(width: 4),
                                                const Text('Trabajador', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Glass Card: Uso de Productos (Derecha) ──
                            if (!_isWorker) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.overlay(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        runSpacing: 4,
                                        children: [
                                          const Text('Catálogo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.white)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                            child: Text(
                                              'Plan ${_planTier.toUpperCase()}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        runSpacing: 2,
                                        children: [
                                          Text('Uso', style: TextStyle(fontSize: 11, color: AppColors.white.withValues(alpha: 0.8))),
                                          Text(
                                            '$_totalProducts / $_productLimit',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _productLimit > 0 ? (_totalProducts / _productLimit).clamp(0.0, 1.0) : 0,
                                          minHeight: 6,
                                          backgroundColor: AppColors.white.withValues(alpha: 0.2),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _totalProducts >= _productLimit ? const Color(0xFFFF8C00) : AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Contenido ───────────────────────────────────────
                  if (_isWorker)
                    _buildWorkerContent(context, primaryColor)
                  else
                    _buildManagerContent(context, primaryColor, slug),
                ],
              ),
            ),
          ),
        ),
    );
  }

  // ────────────────────────────────────────────────────
  // WORKER LAYOUT
  // ────────────────────────────────────────────────────
  Widget _buildWorkerContent(BuildContext context, Color primaryColor) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(delegate: SliverChildListDelegate([

        // Banner de pedidos pendientes
        if (_pendingOrders > 0) ...[
          _PendingOrdersBanner(
            count: _pendingOrders,
            onTap: () => context.go('/sales'),
          ),
          const SizedBox(height: 20),
        ],

        // Stats operativas
        Row(children: [
          _Stat(
            label: 'Pendientes',
            value: _pendingOrders,
            icon: Icons.hourglass_top_rounded,
            color: _pendingOrders > 0 ? AppColors.accentAmber : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          _Stat(
            label: 'Aprobados hoy',
            value: _approvedToday,
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.accentGreen,
          ),
          const SizedBox(width: 12),
          _Stat(
            label: 'Productos',
            value: _totalProducts,
            icon: Icons.inventory_2_outlined,
            color: primaryColor,
          ),
        ]),
        const SizedBox(height: 24),

        // Acciones rápidas
        const Text('ACCIONES RÁPIDAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(
            child: _WorkerActionCard(
              icon: Icons.receipt_long_outlined,
              label: 'Pedidos',
              description: '$_pendingOrders pendiente${_pendingOrders != 1 ? 's' : ''}',
              color: AppColors.accentAmber,
              hasBadge: _pendingOrders > 0,
              badgeCount: _pendingOrders,
              onTap: () => context.go('/sales'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _WorkerActionCard(
              icon: Icons.inventory_2_outlined,
              label: 'Catálogo',
              description: '$_totalProducts producto${_totalProducts != 1 ? 's' : ''}',
              color: primaryColor,
              onTap: () => context.go('/products'),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // Cuenta
        const Text('MI CUENTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _Card(child: Column(children: [
          AppListTile(
            icon: Icons.shield_outlined,
            title: 'Seguridad',
            subtitle: 'Contraseña y configuración',
            iconColor: AppColors.accentPurple,
            onTap: () => context.go('/security'),
          ),
          AppListTile(
            icon: Icons.logout_rounded,
            title: 'Cerrar sesión',
            iconColor: AppColors.error,
            destructive: true,
            onTap: _signOut,
          ),
        ])),
        const SizedBox(height: 32),
      ])),
    );
  }

  // ────────────────────────────────────────────────────
  // MANAGER LAYOUT (sin cambios respecto al diseño anterior)
  // ────────────────────────────────────────────────────
  Widget _buildManagerContent(BuildContext context, Color primaryColor, String? slug) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(delegate: SliverChildListDelegate([

        // Stats
        Row(children: [
          _Stat(label: 'Productos', value: _totalProducts, icon: Icons.inventory_2_outlined, color: primaryColor),
          const SizedBox(width: 12),
          _Stat(label: 'Trabajadores', value: _totalWorkers, icon: Icons.group_outlined, color: AppColors.accentTeal),
          const SizedBox(width: 12),
          _Stat(label: 'Pedidos', value: _totalOrders, icon: Icons.receipt_outlined, color: AppColors.accentAmber),
        ]),
        const SizedBox(height: 20),

        if (slug != null) ...[
          _Card(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.tint(primaryColor), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.language_rounded, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tu sitio web', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('$slug.quinindews.com', style: TextStyle(fontSize: 13, color: primaryColor, decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Abrir',
                  onPressed: () => _openWebsite(slug),
                  color: primaryColor,
                  fullWidth: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Más Herramientas (secundarias, ya que las principales están en el Navbar)
        const Text('MÁS HERRAMIENTAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _Card(child: Column(children: [
          AppListTile(
            icon: Icons.people_outline_rounded,
            title: 'Clientes',
            subtitle: 'Directorio y fidelización',
            iconColor: AppColors.primary,
            onTap: () => context.go('/clients'),
          ),
          AppListTile(
            icon: Icons.history_rounded,
            title: 'Historial',
            subtitle: 'Movimientos y reportes',
            iconColor: AppColors.accentPurple,
            onTap: () => context.go('/history'),
          ),
          AppListTile(
            icon: Icons.qr_code_2_rounded,
            title: 'Descargar QR',
            subtitle: 'Genera el PDF de tu negocio',
            iconColor: AppColors.accentGreen,
            onTap: () => context.go('/settings'),
          ),
          AppListTile(
            icon: Icons.card_membership_rounded,
            title: 'Suscripción',
            subtitle: 'Plan actual y facturación',
            iconColor: AppColors.accentAmber,
            onTap: () => context.go('/subscriptions'),
          ),
          AppListTile(
            icon: Icons.shield_outlined,
            title: 'Seguridad',
            subtitle: 'Contraseñas y trabajadores',
            iconColor: AppColors.error,
            onTap: () => context.go('/security'),
          ),
          AppListTile(icon: Icons.logout_rounded, title: 'Cerrar sesión', iconColor: AppColors.error, destructive: true, onTap: _signOut),
        ])),
        const SizedBox(height: 32),
      ])),
    );
  }
}

// ────────────────────────────────────────────────────
// WORKER: Banner de pedidos pendientes
// ────────────────────────────────────────────────────
class _PendingOrdersBanner extends StatelessWidget {
  const _PendingOrdersBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentAmber, AppColors.accentAmber.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.accentAmber.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            // Icono con pulso simulado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.notification_important_rounded, color: AppColors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1 ? '1 pedido pendiente' : '$count pedidos pendientes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toca para revisar y atender los pedidos',
                    style: TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────
// WORKER: Tarjeta de acción rápida grande
// ────────────────────────────────────────────────────
class _WorkerActionCard extends StatelessWidget {
  const _WorkerActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
    this.hasBadge = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool hasBadge;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasBadge ? color : AppColors.border, width: hasBadge ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: hasBadge ? color.withValues(alpha: 0.12) : AppColors.overlay(0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.tint(color, opacity: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: hasBadge ? color : AppColors.textSecondary, fontWeight: hasBadge ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
            if (hasBadge)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                  child: Text('$badgeCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────
// SHARED: Stat tile
// ────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.tint(color, opacity: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutCubic,
          builder: (context, val, _) => Text(val.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 10, offset: const Offset(0, 2))]),
    child: child,
  );
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 210,
          color: AppColors.primary,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const AppShimmerLoader(width: 44, height: 44, borderRadius: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppShimmerLoader(width: 80, height: 14, borderRadius: 4),
                          SizedBox(height: 4),
                          AppShimmerLoader(width: 120, height: 20, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AppShimmerLoader(width: 150, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  const AppShimmerLoader(width: double.infinity, height: 6, borderRadius: 3),
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
                Row(
                  children: const [
                    Expanded(child: AppShimmerLoader(height: 110, borderRadius: 16)),
                    SizedBox(width: 12),
                    Expanded(child: AppShimmerLoader(height: 110, borderRadius: 16)),
                    SizedBox(width: 12),
                    Expanded(child: AppShimmerLoader(height: 110, borderRadius: 16)),
                  ],
                ),
                const SizedBox(height: 24),
                const AppShimmerLoader(width: 100, height: 12, borderRadius: 4),
                const SizedBox(height: 12),
                const AppShimmerLoader(height: 160, borderRadius: 16),
                const SizedBox(height: 24),
                const AppShimmerLoader(width: 100, height: 12, borderRadius: 4),
                const SizedBox(height: 12),
                const AppShimmerLoader(height: 200, borderRadius: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}