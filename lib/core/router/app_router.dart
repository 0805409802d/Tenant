import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Tenant ─────────────────────────────────────
import '../../tenant/tenant_config.dart';
import '../../tenant/tenant_resolver.dart';

// ── Admin ──────────────────────────────────────
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';
import '../../features/admin/screens/admin_tenants_screen.dart';
import '../../features/admin/screens/admin_advertisers_screen.dart';
import '../../features/admin/screens/admin_finances_screen.dart';

// ── Management ────────────────────────────────
import '../../features/management/screens/management_home_screen.dart';
import '../../features/management/screens/management_login_screen.dart';
import '../../features/management/screens/management_register_screen.dart';
import '../../features/management/screens/management_settings_screen.dart';
import '../../features/management/screens/management_security_screen.dart';
import '../../features/management/screens/management_history_screen.dart';
import '../../features/management/screens/management_sales_screen.dart';
import '../../features/management/screens/management_clients_screen.dart';
import '../../features/management/screens/management_products_screen.dart';
import '../../features/management/screens/management_subscriptions_screen.dart';
import '../../features/management/screens/management_suppliers_screen.dart';
import '../../features/management/screens/management_finance_screen.dart';
import '../../features/management/screens/management_shell.dart';

// ── Advertisers ───────────────────────────────
import '../../features/advertisers/screens/advertisers_home_screen.dart';
import '../../features/advertisers/screens/advertisers_login_screen.dart';
import '../../features/advertisers/screens/advertisers_register_screen.dart';
import '../../features/advertisers/screens/advertisers_settings_screen.dart';
import '../../features/advertisers/screens/advertisers_security_screen.dart';
import '../../features/advertisers/screens/advertisers_campaigns_screen.dart';
import '../../features/advertisers/screens/advertisers_reports_screen.dart';
import '../../features/advertisers/screens/advertisers_billing_screen.dart';

// ── Client ────────────────────────────────────
import '../../features/client/screens/client_home_screen.dart';
import '../../features/client/screens/client_login_screen.dart';
import '../../features/client/screens/client_register_screen.dart';
import '../../features/client/screens/client_settings_screen.dart';
import '../../features/client/screens/client_security_screen.dart';
import '../../features/client/screens/client_product_detail_screen.dart';

// ── Shared ────────────────────────────────────
import '../../shared/screens/not_found_screen.dart';

class AppRouter {
  // ─────────────────────────────────────────────
  // VERIFICAR SI HAY SESIÓN ACTIVA
  // ─────────────────────────────────────────────
  static bool get _isLoggedIn =>
      Supabase.instance.client.auth.currentUser != null;

  // ─────────────────────────────────────────────
  // ROUTER PRINCIPAL
  // ─────────────────────────────────────────────
  static final router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => NotFoundScreen(error: state.error),
    redirect: _globalRedirect,
    routes: _buildRoutes(),
  );

  // ─────────────────────────────────────────────
  // REDIRECT GLOBAL: protege rutas según sesión
  // ─────────────────────────────────────────────
  static String? _globalRedirect(context, state) {
    final space = TenantResolver.resolve();
    final path = state.matchedLocation;

    // Rutas públicas (no requieren sesión)
    // Se añade ruta base de producto para client
    final publicRoutes = [
      '/login',
      '/register',
      '/d8t1-admin-panel/login',
      '/recover',
    ];

    // Para clientes, la raíz (catálogo) y los productos son públicos
    if (space == TenantType.client) {
      if (path == '/' || path.startsWith('/product/')) return null;
    }

    final isPublic = publicRoutes.any((r) => path.startsWith(r));

    // Si no está logueado e intenta ir a ruta privada → login
    if (!_isLoggedIn && !isPublic) {
      return space == TenantType.admin ? '/d8t1-admin-panel/login' : '/login';
    }

    // Si ya está logueado e intenta ir a login/register → home
    if (_isLoggedIn && isPublic && !path.contains('recover')) {
      return space == TenantType.admin ? '/d8t1-admin-panel' : '/';
    }

    return null; // sin redirect
  }

  // ─────────────────────────────────────────────
  // CONSTRUIR RUTAS SEGÚN EL ESPACIO DETECTADO
  // El tenant activo se resuelve una sola vez aquí
  // a través de TenantResolver, que es la fuente de verdad.
  // ─────────────────────────────────────────────
  static List<RouteBase> _buildRoutes() {
    final space = TenantResolver.resolve();
    final slug = TenantResolver.clientSlug();

    return _getRoutesForTenant(space, slug);
  }

  static List<RouteBase> _getRoutesForTenant(TenantType type, String? slug) {
    switch (type) {

      // ── ADMIN ──────────────────────────────
      case TenantType.admin:
        return [
          GoRoute(
            path: '/d8t1-admin-panel',
            builder: (context, state) => const AdminHomeScreen(),
          ),
          GoRoute(
            path: '/d8t1-admin-panel/login',
            builder: (context, state) => const AdminLoginScreen(),
          ),
          GoRoute(
            path: '/d8t1-admin-panel/tenants',
            builder: (context, state) => const AdminTenantsScreen(),
          ),
          GoRoute(
            path: '/d8t1-admin-panel/advertisers',
            builder: (context, state) => const AdminAdvertisersScreen(),
          ),
          GoRoute(
            path: '/d8t1-admin-panel/finances',
            builder: (context, state) => const AdminFinancesScreen(),
          ),
          // Redirige "/" al panel admin
          GoRoute(
            path: '/',
            redirect: (_, __) => '/d8t1-admin-panel',
          ),
        ];

      // ── ADVERTISERS ────────────────────────
      case TenantType.advertisers:
        return [
          GoRoute(
            path: '/',
            builder: (context, state) => const AdvertisersHomeScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const AdvertisersLoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const AdvertisersRegisterScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const AdvertisersSettingsScreen(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => const AdvertisersSecurityScreen(),
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const AdvertisersCampaignsScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const AdvertisersReportsScreen(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const AdvertisersBillingScreen(),
          ),
        ];

      // ── CLIENT ─────────────────────────────
      case TenantType.client:
        final safeSlug = slug ?? '';
        return [
          GoRoute(
            path: '/',
            builder: (context, state) => ClientHomeScreen(tenantSlug: safeSlug),
          ),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) => ClientProductDetailScreen(
              tenantSlug: safeSlug,
              productId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => ClientLoginScreen(tenantSlug: safeSlug),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => ClientRegisterScreen(tenantSlug: safeSlug),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => ClientSettingsScreen(tenantSlug: safeSlug),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => ClientSecurityScreen(tenantSlug: safeSlug),
          ),
        ];

      // ── MANAGEMENT (default) ───────────────
      case TenantType.management:
      default:
        return [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return ManagementShell(navigationShell: navigationShell);
            },
            branches: [
              // Branch 0: Dashboard/Home
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const ManagementHomeScreen(),
                  ),
                ],
              ),
              // Branch 1: Pedidos
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/sales',
                    builder: (context, state) => const ManagementSalesScreen(),
                  ),
                ],
              ),
              // Branch 2: Catálogo
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/products',
                    builder: (context, state) => const ManagementProductsScreen(),
                  ),
                ],
              ),
              // Branch 3: Ajustes
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/settings',
                    builder: (context, state) => const ManagementSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Rutas fuera del Shell
          GoRoute(
            path: '/login',
            builder: (context, state) => const ManagementLoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const ManagementRegisterScreen(),
          ),
          GoRoute(
            path: '/security',
            builder: (context, state) => const ManagementSecurityScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const ManagementHistoryScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ManagementClientsScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const ManagementSuppliersScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const ManagementFinanceScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const ManagementSubscriptionsScreen(),
          ),
        ];
    }
  }
}