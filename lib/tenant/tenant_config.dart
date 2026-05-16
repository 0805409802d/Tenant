/// Tipos de espacio disponibles en el sistema.
/// Cada valor corresponde a uno de los 4 tenants del claude.md.
enum TenantType { admin, management, advertisers, client }

// ─────────────────────────────────────────────────────────────
// FEATURE FLAGS
// Booleanos que controlan qué pantallas y funciones están
// disponibles. El router y los widgets los consumen siempre
// a través de estos flags — nunca con `if (tenant == 'admin')`.
// ─────────────────────────────────────────────────────────────
class TenantFeatureFlags {
  final bool canRegister;
  final bool canViewDashboard;
  final bool canManageProducts;
  final bool canManageWorkers;
  final bool canViewSales;
  final bool canViewClients;
  final bool canCreateCampaigns;
  final bool canViewReports;
  final bool canViewBilling;
  final bool canViewSettings;
  final bool canViewSecurity;
  final bool canBrowseCatalog;
  final bool canPurchase;
  final bool canViewAdminTenants;

  const TenantFeatureFlags({
    this.canRegister = false,
    this.canViewDashboard = false,
    this.canManageProducts = false,
    this.canManageWorkers = false,
    this.canViewSales = false,
    this.canViewClients = false,
    this.canCreateCampaigns = false,
    this.canViewReports = false,
    this.canViewBilling = false,
    this.canViewSettings = false,
    this.canViewSecurity = false,
    this.canBrowseCatalog = false,
    this.canPurchase = false,
    this.canViewAdminTenants = false,
  });
}

// ─────────────────────────────────────────────────────────────
// TENANT CONFIG
// Configuración completa de un espacio. Incluye su tipo,
// nombre legible y los feature flags correspondientes.
// ─────────────────────────────────────────────────────────────
class TenantConfig {
  final TenantType type;
  final String name;
  final TenantFeatureFlags flags;

  const TenantConfig({
    required this.type,
    required this.name,
    required this.flags,
  });

  // ── Configuraciones predefinidas por espacio ──────────────

  /// Panel del super_admin. Acceso oculto por ruta secreta.
  static const TenantConfig admin = TenantConfig(
    type: TenantType.admin,
    name: 'Admin',
    flags: TenantFeatureFlags(
      canViewDashboard: true,
      canViewReports: true,
      canViewBilling: true,
      canViewAdminTenants: true,
    ),
  );

  /// Portal de dueños de negocio (managers y workers).
  static const TenantConfig management = TenantConfig(
    type: TenantType.management,
    name: 'Management',
    flags: TenantFeatureFlags(
      canRegister: true,
      canManageProducts: true,
      canManageWorkers: true,
      canViewSales: true,
      canViewClients: true,
      canViewSettings: true,
      canViewSecurity: true,
    ),
  );

  /// Portal de empresas publicitarias.
  static const TenantConfig advertisers = TenantConfig(
    type: TenantType.advertisers,
    name: 'Advertisers',
    flags: TenantFeatureFlags(
      canRegister: true,
      canViewDashboard: true,
      canCreateCampaigns: true,
      canViewReports: true,
      canViewBilling: true,
      canViewSettings: true,
      canViewSecurity: true,
    ),
  );

  /// Página pública del negocio que ven los clientes.
  static const TenantConfig client = TenantConfig(
    type: TenantType.client,
    name: 'Client',
    flags: TenantFeatureFlags(
      canRegister: true,
      canBrowseCatalog: true,
      canPurchase: true,
      canViewSettings: true,
      canViewSecurity: true,
    ),
  );

  // ─────────────────────────────────────────────
  // FACTORY DESDE TIPO
  // ─────────────────────────────────────────────

  /// Devuelve la [TenantConfig] correspondiente al [TenantType] dado.
  static TenantConfig fromType(TenantType type) {
    switch (type) {
      case TenantType.admin:
        return admin;
      case TenantType.management:
        return management;
      case TenantType.advertisers:
        return advertisers;
      case TenantType.client:
        return client;
    }
  }
}
