import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/widgets/app_widgets.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key, required this.tenantSlug});
  final String tenantSlug;

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen>
    with SingleTickerProviderStateMixin {
  Color _primaryColor = const Color(0xFF0097A7);
  bool _loadingTheme = true;
  bool _savingPhoto = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final res = await Supabase.instance.client
          .from('tenants')
          .select('primary_color')
          .eq('slug', widget.tenantSlug)
          .maybeSingle();

      if (res != null && res['primary_color'] != null) {
        final hex = (res['primary_color'] as String).replaceAll('#', '');
        _primaryColor = Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    
    if (mounted) {
      setState(() => _loadingTheme = false);
      _animCtrl.forward();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTheme) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        body: Center(child: CircularProgressIndicator(color: AppColors.textSecondary, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
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
        title: const Text('Ajustes de cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(width: 4, height: 28, decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text('Personaliza cómo te ven los negocios', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 24),

              // Foto de perfil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.tint(_primaryColor), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.person_outline_rounded, color: _primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Foto de perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text('Visible en tus pedidos', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Avatar centrado
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: AppColors.surfaceGrey,
                            child: const Icon(Icons.person_rounded, size: 52, color: AppColors.textSecondary),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: GestureDetector(
                              onTap: () {}, // TODO: image picker
                              child: Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.white, width: 3),
                                  boxShadow: [BoxShadow(color: AppColors.overlay(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
                                child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin foto de perfil',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'JPG o PNG, máximo 2MB',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(label: 'Cambiar foto', onPressed: () {}, isLoading: _savingPhoto, color: _primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
