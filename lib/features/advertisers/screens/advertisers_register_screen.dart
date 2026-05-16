import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdvertisersRegisterScreen extends StatefulWidget {
  const AdvertisersRegisterScreen({super.key});
  @override
  State<AdvertisersRegisterScreen> createState() => _AdvertisersRegisterScreenState();
}

class _AdvertisersRegisterScreenState extends State<AdvertisersRegisterScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF6C47FF);

  final _emailCtrl        = TextEditingController();
  final _passCtrl         = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _companyNameCtrl  = TextEditingController();
  final _ownerNameCtrl    = TextEditingController();
  final _countryCtrl      = TextEditingController(text: 'Ecuador');
  final _cityCtrl         = TextEditingController();
  final _addressCtrl      = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [_emailCtrl, _passCtrl, _phoneCtrl, _companyNameCtrl, _ownerNameCtrl, _countryCtrl, _cityCtrl, _addressCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final missing = <String>[];
    if (_emailCtrl.text.trim().isEmpty)       missing.add('correo');
    if (_passCtrl.text.isEmpty)               missing.add('contraseña');
    if (_phoneCtrl.text.trim().isEmpty)       missing.add('teléfono');
    if (_companyNameCtrl.text.trim().isEmpty) missing.add('nombre de la empresa');
    if (_ownerNameCtrl.text.trim().isEmpty)   missing.add('nombre del responsable');
    if (_cityCtrl.text.trim().isEmpty)        missing.add('ciudad');

    if (missing.isNotEmpty) { setState(() => _error = 'Campos incompletos: ${missing.join(', ')}.'); return; }

    setState(() { _loading = true; _error = null; });
    final r = await AuthService.registerAdvertiser(
      email: _emailCtrl.text.trim(), password: _passCtrl.text, phone: _phoneCtrl.text.trim(),
      businessName: _companyNameCtrl.text.trim(), ownerName: _ownerNameCtrl.text.trim(),
      country: _countryCtrl.text.trim(), city: _cityCtrl.text.trim(), address: _addressCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) { context.go('/'); } else { setState(() => _error = r.error); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surfaceGrey,
    body: Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: 480, margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: AppColors.overlay(0.06), blurRadius: 32, offset: const Offset(0, 8))]),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 32, height: 3, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Crear cuenta', style: TextStyle(fontFamily: 'Georgia', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
              const SizedBox(height: 4),
              Text('Portal de anunciantes', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              _section('Acceso', Icons.person_outline_rounded, _accent),
              const SizedBox(height: 14),
              const AppLabel('Correo electrónico'), const SizedBox(height: 6),
              AppTextField(controller: _emailCtrl, hint: 'correo@empresa.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              const AppLabel('Contraseña'), const SizedBox(height: 6),
              AppTextField(controller: _passCtrl, hint: 'Mínimo 6 caracteres', icon: Icons.lock_outline_rounded, obscure: _obscure,
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18), onPressed: () => setState(() => _obscure = !_obscure))),
              const SizedBox(height: 12),
              const AppLabel('Teléfono'), const SizedBox(height: 6),
              AppTextField(controller: _phoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),

              _section('Empresa', Icons.business_outlined, const Color(0xFF00B37E)),
              const SizedBox(height: 14),
              const AppLabel('Nombre de la empresa'), const SizedBox(height: 6),
              AppTextField(controller: _companyNameCtrl, hint: 'Empresa XYZ', icon: Icons.business_outlined),
              const SizedBox(height: 12),
              const AppLabel('Nombre del responsable'), const SizedBox(height: 6),
              AppTextField(controller: _ownerNameCtrl, hint: 'Nombre completo', icon: Icons.badge_outlined),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('País'), const SizedBox(height: 6),
                  AppTextField(controller: _countryCtrl, hint: 'Ecuador', icon: Icons.flag_outlined),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('Ciudad'), const SizedBox(height: 6),
                  AppTextField(controller: _cityCtrl, hint: 'Tu ciudad', icon: Icons.location_city_outlined),
                ])),
              ]),
              const SizedBox(height: 12),
              const AppLabel('Dirección'), const SizedBox(height: 6),
              AppTextField(controller: _addressCtrl, hint: 'Calle, número, referencia', icon: Icons.location_on_outlined),

              if (_error != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _error!)],
              const SizedBox(height: 24),
              AppButton(label: 'Registrarse', onPressed: _register, isLoading: _loading, color: _accent),
              const SizedBox(height: 12),
              Center(child: GestureDetector(onTap: () => context.go('/login'),
                child: Text('¿Ya tienes cuenta? Iniciar sesión', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))),
            ]),
          ),
        ),
      ),
    ),
  );

  Widget _section(String title, IconData icon, Color color) => Row(children: [
    Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16)),
    const SizedBox(width: 10),
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const SizedBox(width: 10),
    Expanded(child: Divider(color: AppColors.border)),
  ]);
}
