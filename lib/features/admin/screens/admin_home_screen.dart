import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/widgets/app_components.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // En Fase 3 se cargarán desde Supabase
  int _totalNegocios    = 0;
  int _totalAnunciantes = 0;
  int _totalClientes    = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = Supabase.instance.client;
      final negocios    = await db.from('tenants').select('id', const FetchOptions(count: CountOption.exact, head: true));
      final anunciantes = await db.from('profiles').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('role', 'advertiser');
      final clientes    = await db.from('profiles').select('id', const FetchOptions(count: CountOption.exact, head: true)).eq('role', 'client');
      if (!mounted) return;
      setState(() {
        _totalNegocios    = negocios.count ?? 0;
        _totalAnunciantes = anunciantes.count ?? 0;
        _totalClientes    = clientes.count ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/d8t1-admin-panel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.shield_outlined, color: AppColors.white, size: 16)),
          const SizedBox(width: 10),
          const Text('Admin Panel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.white, size: 20),
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A0A0A), Color(0xFF1E1E2E)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Panel de Administración', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text('Quinindews — Superadministrador', style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.6))),
                ]),
              ),
              const SizedBox(height: 20),

              // Stats
              const Text('RESUMEN GLOBAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2)))
              else
                Row(children: [
                  Expanded(child: _StatCard(label: 'Negocios', value: '$_totalNegocios', icon: Icons.storefront_outlined, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Anunciantes', value: '$_totalAnunciantes', icon: Icons.campaign_outlined, color: AppColors.accentPurple)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Clientes', value: '$_totalClientes', icon: Icons.people_outline_rounded, color: AppColors.accentTeal)),
                ]),
              const SizedBox(height: 24),

              // Acciones rápidas
              const Text('ACCIONES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              _ActionCard(children: [
                AppListTile(icon: Icons.storefront_outlined, title: 'Ver todos los negocios', subtitle: 'Gestionar tenants activos', iconColor: AppColors.primary, onTap: () {}),
                AppListTile(icon: Icons.campaign_outlined, title: 'Ver anunciantes', subtitle: 'Revisar cuentas de publicidad', iconColor: AppColors.accentPurple, onTap: () {}),
                AppListTile(icon: Icons.category_outlined, title: 'Tipos de negocio', subtitle: 'Administrar categorías y SEO tags', iconColor: AppColors.accentGreen, onTap: () {}),
                AppListTile(icon: Icons.bar_chart_rounded, title: 'Estadísticas', subtitle: 'Métricas de la plataforma', iconColor: AppColors.accentAmber, onTap: () {}),
              ]),
              const SizedBox(height: 16),

              // Zona peligrosa
              const Text('SISTEMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              _ActionCard(children: [
                AppListTile(icon: Icons.logout_rounded, title: 'Cerrar sesión', iconColor: AppColors.error, destructive: true, onTap: _signOut),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
    child: Column(children: children),
  );
}