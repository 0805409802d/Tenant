import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_widgets.dart';

enum _View { credentials, enterEmail, questions, sent }

class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key, required this.tenantSlug});
  final String tenantSlug;
  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen>
    with SingleTickerProviderStateMixin {
  _View _view = _View.credentials;
  
  // Tema dinámico
  Color _primaryColor = const Color(0xFF0097A7);
  bool _loadingTheme = true;
  String _tenantName = '';

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  final _recoverEmailCtrl = TextEditingController();
  String? _q1, _q2, _q3;
  final _a1Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();
  final _a3Ctrl = TextEditingController();
  bool _loadingQ = false, _loadingV = false;
  String? _recoverError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _tenantName = widget.tenantSlug;
    try {
      final res = await Supabase.instance.client
          .from('tenants')
          .select('primary_color, name')
          .eq('slug', widget.tenantSlug)
          .maybeSingle();

      if (res != null) {
        if (res['primary_color'] != null) {
          final hex = (res['primary_color'] as String).replaceAll('#', '');
          _primaryColor = Color(int.parse('FF$hex', radix: 16));
        }
        if (res['name'] != null && res['name'].toString().isNotEmpty) {
          _tenantName = res['name'];
        }
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
    for (final c in [_emailCtrl, _passCtrl, _recoverEmailCtrl, _a1Ctrl, _a2Ctrl, _a3Ctrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Completa correo y contraseña.'); return;
    }
    setState(() { _loading = true; _error = null; });
    final r = await AuthService.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) { context.go('/'); } else { setState(() => _error = r.error); }
  }

  Future<void> _getQuestions() async {
    if (_recoverEmailCtrl.text.trim().isEmpty) { setState(() => _recoverError = 'Ingresa tu correo.'); return; }
    setState(() { _loadingQ = true; _recoverError = null; });
    final r = await AuthService.getSecurityQuestions(email: _recoverEmailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loadingQ = false);
    if (r.success) {
      setState(() { _q1 = r.data!['question_1']; _q2 = r.data!['question_2']; _q3 = r.data!['question_3']; _view = _View.questions; });
    } else { setState(() => _recoverError = r.error); }
  }

  Future<void> _validateAnswers() async {
    if ([_a1Ctrl, _a2Ctrl, _a3Ctrl].any((c) => c.text.trim().isEmpty)) {
      setState(() => _recoverError = 'Responde las tres preguntas.'); return;
    }
    setState(() { _loadingV = true; _recoverError = null; });
    final val = await AuthService.validateSecurityAnswers(
      email: _recoverEmailCtrl.text.trim(),
      answer1: _a1Ctrl.text.trim(), answer2: _a2Ctrl.text.trim(), answer3: _a3Ctrl.text.trim(),
    );
    if (!mounted) return;
    if (!val.success) { setState(() { _loadingV = false; _recoverError = val.error; }); return; }
    final reset = await AuthService.sendPasswordReset(email: _recoverEmailCtrl.text.trim());
    if (!mounted) return;
    setState(() { _loadingV = false; if (reset.success) { _view = _View.sent; } else { _recoverError = reset.error; } });
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    key: ValueKey(_view),
                    padding: const EdgeInsets.all(32),
                    child: switch (_view) {
                      _View.credentials => _creds(),
                      _View.enterEmail  => _enterEmail(),
                      _View.questions   => _questions(),
                      _View.sent        => _sent(),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _creds() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 40, height: 4, decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(2))),
    const SizedBox(height: 24),
    Text('Bienvenido a $_tenantName', style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
    const SizedBox(height: 6),
    const Text('Inicia sesión para continuar comprando.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    const SizedBox(height: 32),
    const AppLabel('Correo electrónico'), const SizedBox(height: 6),
    AppTextField(controller: _emailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
    const SizedBox(height: 16),
    const AppLabel('Contraseña'), const SizedBox(height: 6),
    AppTextField(controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline_rounded, obscure: _obscure,
      suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18), onPressed: () => setState(() => _obscure = !_obscure))),
    if (_error != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _error!)],
    const SizedBox(height: 24),
    SizedBox(
      width: double.infinity,
      child: AppButton(label: 'Entrar', onPressed: _login, isLoading: _loading, color: _primaryColor),
    ),
    const SizedBox(height: 24),
    Center(
      child: GestureDetector(
        onTap: () => setState(() { _view = _View.enterEmail; _recoverError = null; }),
        child: Text('Olvidé mi contraseña', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryColor)),
      ),
    ),
    const SizedBox(height: 16),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('¿No tienes cuenta?', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: () => context.go('/register'),
        child: Text('Regístrate aquí', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryColor)),
      ),
    ]),
  ]);

  Widget _enterEmail() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _back(), const SizedBox(height: 24),
    const Text('Recuperar acceso', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    const SizedBox(height: 6), const Text('Ingresa el correo de tu cuenta. Te pediremos responder tus preguntas de seguridad.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
    const SizedBox(height: 24), const AppLabel('Correo electrónico'), const SizedBox(height: 6),
    AppTextField(controller: _recoverEmailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
    if (_recoverError != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _recoverError!)],
    const SizedBox(height: 24),
    SizedBox(
      width: double.infinity,
      child: AppButton(label: 'Continuar', onPressed: _getQuestions, isLoading: _loadingQ, color: _primaryColor),
    ),
  ]);

  Widget _questions() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _back(onTap: () => setState(() { _view = _View.enterEmail; _recoverError = null; })), const SizedBox(height: 24),
    const Text('Preguntas de seguridad', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    const SizedBox(height: 6), const Text('Responde las siguientes preguntas para verificar tu identidad.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
    const SizedBox(height: 24),
    ...[(_q1!, _a1Ctrl), (_q2!, _a2Ctrl), (_q3!, _a3Ctrl)].expand((p) => [
      Text(p.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), const SizedBox(height: 6),
      AppTextField(controller: p.$2, hint: 'Tu respuesta', icon: Icons.short_text_rounded), const SizedBox(height: 16),
    ]),
    if (_recoverError != null) ...[AppFeedbackBanner(message: _recoverError!), const SizedBox(height: 16)],
    SizedBox(
      width: double.infinity,
      child: AppButton(label: 'Validar y recuperar', onPressed: _validateAnswers, isLoading: _loadingV, color: _primaryColor),
    ),
  ]);

  Widget _sent() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
    Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.tint(AppColors.success), shape: BoxShape.circle),
      child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 30)),
    const SizedBox(height: 20),
    const Text('¡Correo enviado!', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    const SizedBox(height: 8),
    const Text('Revisa tu bandeja de entrada o spam. Te hemos enviado un enlace para restablecer tu contraseña.',
      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
    const SizedBox(height: 32),
    SizedBox(
      width: double.infinity,
      child: AppButton(label: 'Volver al login', onPressed: () => setState(() { _view = _View.credentials; _recoverError = null; }), color: _primaryColor),
    ),
  ]);

  Widget _back({VoidCallback? onTap}) => GestureDetector(
    onTap: onTap ?? () => setState(() { _view = _View.credentials; _recoverError = null; }),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textSecondary),
      ),
      const SizedBox(width: 8),
      const Text('Volver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    ]),
  );
}
