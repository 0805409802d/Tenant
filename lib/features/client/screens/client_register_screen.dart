import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class ClientRegisterScreen extends StatefulWidget {
  const ClientRegisterScreen({super.key, required this.tenantSlug});
  final String tenantSlug;
  @override
  State<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF0097A7);

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _phoneCtrl     = TextEditingController();
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
    for (final c in [_firstNameCtrl, _lastNameCtrl, _emailCtrl, _passCtrl, _phoneCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final missing = <String>[];
    if (_firstNameCtrl.text.trim().isEmpty) missing.add('nombre');
    if (_lastNameCtrl.text.trim().isEmpty)  missing.add('apellido');
    if (_emailCtrl.text.trim().isEmpty)     missing.add('correo');
    if (_passCtrl.text.isEmpty)             missing.add('contraseña');
    if (_phoneCtrl.text.trim().isEmpty)     missing.add('teléfono');

    if (missing.isNotEmpty) { setState(() => _error = 'Campos incompletos: ${missing.join(', ')}.'); return; }

    setState(() { _loading = true; _error = null; });
    final r = await AuthService.registerClient(
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(), lastName: _lastNameCtrl.text.trim(),
      tenantSlug: widget.tenantSlug,
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
          width: 440, margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: AppColors.overlay(0.06), blurRadius: 32, offset: const Offset(0, 8))]),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 32, height: 3, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Crear cuenta', style: TextStyle(fontFamily: 'Georgia', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
              const SizedBox(height: 4),
              Text('Regístrate en ${widget.tenantSlug}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              // Nombre
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('Nombre'), const SizedBox(height: 6),
                  AppTextField(controller: _firstNameCtrl, hint: 'Tu nombre', icon: Icons.person_outline_rounded),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('Apellido'), const SizedBox(height: 6),
                  AppTextField(controller: _lastNameCtrl, hint: 'Tu apellido', icon: Icons.person_outline_rounded),
                ])),
              ]),
              const SizedBox(height: 12),
              const AppLabel('Correo electrónico'), const SizedBox(height: 6),
              AppTextField(controller: _emailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              const AppLabel('Contraseña'), const SizedBox(height: 6),
              AppTextField(controller: _passCtrl, hint: 'Mínimo 6 caracteres', icon: Icons.lock_outline_rounded, obscure: _obscure,
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18), onPressed: () => setState(() => _obscure = !_obscure))),
              const SizedBox(height: 12),
              const AppLabel('Teléfono'), const SizedBox(height: 6),
              AppTextField(controller: _phoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),

              if (_error != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _error!)],
              const SizedBox(height: 24),
              AppButton(label: 'Crear cuenta', onPressed: _register, isLoading: _loading, color: _accent),
              const SizedBox(height: 12),
              Center(child: GestureDetector(onTap: () => context.go('/login'),
                child: Text('¿Ya tienes cuenta? Iniciar sesión', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))),
            ]),
          ),
        ),
      ),
    ),
  );
}
