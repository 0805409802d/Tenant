import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/widgets/app_components.dart';

class AdvertisersHomeScreen extends StatefulWidget {
  const AdvertisersHomeScreen({super.key});
  @override
  State<AdvertisersHomeScreen> createState() => _AdvertisersHomeScreenState();
}

class _AdvertisersHomeScreenState extends State<AdvertisersHomeScreen> {
  static const _accent = Color(0xFF6C47FF);
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) { if (mounted) setState(() => _loading = false); return; }
      final profile = await Supabase.instance.client.from('profiles').select().eq('id', uid).maybeSingle();
      if (!mounted) return;
      setState(() { _profile = profile; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final name        = _profile?['owner_name'] as String? ?? _profile?['email'] as String? ?? 'Anunciante';
    final companyName = _profile?['business_name'] as String? ?? 'Tu empresa';
    final initials    = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

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
                  // ── SliverAppBar violeta ──────────────────────────────
                  SliverAppBar(
                    expandedHeight: 150,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.surface,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 22), onPressed: () => context.go('/settings'), tooltip: 'Ajustes'),
                      IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary, size: 20), onPressed: _signOut, tooltip: 'Cerrar sesión'),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_accent, Color(0xFF4A2DB8)]),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                          Row(children: [
                            CircleAvatar(radius: 22, backgroundColor: AppColors.white.withValues(alpha: 0.2),
                              child: Text(initials, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name.split(' ').first, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.white)),
                              Text(companyName, style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.75))),
                            ])),
                          ]),
                        ]),
                      ),
                    ),
                    title: Text(companyName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(delegate: SliverChildListDelegate([

                      // Resumen de campañas (placeholder Fase 3)
                      Row(children: [
                        _Stat('Campañas', '—', Icons.campaign_outlined, _accent),
                        const SizedBox(width: 12),
                        _Stat('Impresiones', '—', Icons.visibility_outlined, AppColors.accentTeal),
                        const SizedBox(width: 12),
                        _Stat('Clics', '—', Icons.ads_click_rounded, AppColors.accentAmber),
                      ]),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _accent.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: _accent.withValues(alpha: 0.2))),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded, color: _accent, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Las métricas de campañas estarán disponibles en la próxima versión.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Acciones
                      const Text('PUBLICIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      _Card(children: [
                        AppListTile(icon: Icons.add_circle_outline_rounded, title: 'Nueva campaña', subtitle: 'Crear anuncio para negocios', iconColor: _accent, onTap: () {}),
                        AppListTile(icon: Icons.campaign_outlined, title: 'Mis campañas', subtitle: 'Ver y gestionar anuncios activos', iconColor: AppColors.accentTeal, onTap: () {}),
                        AppListTile(icon: Icons.analytics_outlined, title: 'Estadísticas', subtitle: 'Rendimiento de tus campañas', iconColor: AppColors.accentAmber, onTap: () {}),
                      ]),
                      const SizedBox(height: 16),

                      // Cuenta
                      const Text('CUENTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      _Card(children: [
                        AppListTile(icon: Icons.tune_outlined, title: 'Ajustes', subtitle: 'Perfil y colores de empresa', iconColor: _accent, onTap: () => context.go('/settings')),
                        AppListTile(icon: Icons.shield_outlined, title: 'Seguridad', subtitle: 'Contraseña y preguntas', iconColor: AppColors.accentPurple, onTap: () => context.go('/security')),
                        AppListTile(icon: Icons.logout_rounded, title: 'Cerrar sesión', iconColor: AppColors.error, destructive: true, onTap: _signOut),
                      ]),
                      const SizedBox(height: 32),
                    ])),
                  ),
                ],
              ),
            ),
    );
  }
}

Widget _Stat(String label, String value, IconData icon, Color color) => Expanded(
  child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 10, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  ),
);

Widget _Card({required List<Widget> children}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border),
    boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
  child: Column(children: children),
);