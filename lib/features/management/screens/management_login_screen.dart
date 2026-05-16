import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_widgets.dart';

enum _View { credentials, enterEmail, questions, sent }

class ManagementLoginScreen extends StatefulWidget {
  const ManagementLoginScreen({super.key});
  @override
  State<ManagementLoginScreen> createState() => _ManagementLoginScreenState();
}

class _ManagementLoginScreenState extends State<ManagementLoginScreen>
    with SingleTickerProviderStateMixin {
  _View _view = _View.credentials;

  // Credentials
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  // Recovery
  final _recoverEmailCtrl = TextEditingController();
  String? _q1, _q2, _q3;
  final _a1Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();
  final _a3Ctrl = TextEditingController();
  bool _loadingQuestions = false, _loadingValidate = false;
  String? _recoverError;

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
    for (final c in [_emailCtrl, _passCtrl, _recoverEmailCtrl, _a1Ctrl, _a2Ctrl, _a3Ctrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Completa correo y contraseña.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final r = await AuthService.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) {
      context.go('/');
    } else {
      setState(() => _error = r.error);
    }
  }

  Future<void> _getQuestions() async {
    final email = _recoverEmailCtrl.text.trim();
    if (email.isEmpty) { setState(() => _recoverError = 'Ingresa tu correo.'); return; }
    setState(() { _loadingQuestions = true; _recoverError = null; });
    final r = await AuthService.getSecurityQuestions(email: email);
    if (!mounted) return;
    setState(() => _loadingQuestions = false);
    if (r.success) {
      setState(() {
        _q1 = r.data!['question_1']; _q2 = r.data!['question_2']; _q3 = r.data!['question_3'];
        _view = _View.questions;
      });
    } else {
      setState(() => _recoverError = r.error);
    }
  }

  Future<void> _validateAnswers() async {
    if ([_a1Ctrl, _a2Ctrl, _a3Ctrl].any((c) => c.text.trim().isEmpty)) {
      setState(() => _recoverError = 'Responde las tres preguntas.'); return;
    }
    setState(() { _loadingValidate = true; _recoverError = null; });
    final val = await AuthService.validateSecurityAnswers(
      email: _recoverEmailCtrl.text.trim(),
      answer1: _a1Ctrl.text.trim(), answer2: _a2Ctrl.text.trim(), answer3: _a3Ctrl.text.trim(),
    );
    if (!mounted) return;
    if (!val.success) {
      setState(() { _loadingValidate = false; _recoverError = val.error; }); return;
    }
    final reset = await AuthService.sendPasswordReset(email: _recoverEmailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loadingValidate = false;
      if (reset.success) { _view = _View.sent; } else { _recoverError = reset.error; }
    });
  }

  void _goBack() => setState(() { _view = _View.credentials; _recoverError = null; });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            width: 420,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: AppColors.overlay(0.06), blurRadius: 32, offset: const Offset(0, 8))],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                key: ValueKey(_view),
                padding: const EdgeInsets.all(40),
                child: switch (_view) {
                  _View.credentials => _buildCredentials(),
                  _View.enterEmail  => _buildEnterEmail(),
                  _View.questions   => _buildQuestions(),
                  _View.sent        => _buildSent(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── CREDENTIALS ──────────────────────────────────────────────
  Widget _buildCredentials() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(width: 32, height: 3, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 24),
      Text('Bienvenido', style: TextStyle(fontFamily: 'Georgia', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
      const SizedBox(height: 4),
      Text('Gestión de tu negocio', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 32),
      const AppLabel('Correo electrónico'), const SizedBox(height: 6),
      AppTextField(controller: _emailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      const AppLabel('Contraseña'), const SizedBox(height: 6),
      AppTextField(controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline_rounded, obscure: _obscure,
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18), onPressed: () => setState(() => _obscure = !_obscure))),
      if (_error != null) ...[const SizedBox(height: 12), AppFeedbackBanner(message: _error!)],
      const SizedBox(height: 24),
      AppButton(label: 'Iniciar sesión', onPressed: _login, isLoading: _loading),
      const SizedBox(height: 16),
      Center(child: GestureDetector(
        onTap: () => setState(() { _view = _View.enterEmail; _recoverError = null; }),
        child: Text('¿Olvidaste tu contraseña? Recuperar cuenta', style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline)),
      )),
      const SizedBox(height: 12),
      Center(child: GestureDetector(
        onTap: () => context.go('/register'),
        child: Text('¿No tienes cuenta? Crear sitio', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      )),
    ],
  );

  // ── ENTER EMAIL ──────────────────────────────────────────────
  Widget _buildEnterEmail() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _backButton(),
      const SizedBox(height: 20),
      Text('Recuperar acceso', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text('Ingresa el correo de tu cuenta.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      const AppLabel('Correo electrónico'), const SizedBox(height: 6),
      AppTextField(controller: _recoverEmailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
      if (_recoverError != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _recoverError!)],
      const SizedBox(height: 20),
      AppButton(label: 'Continuar', onPressed: _getQuestions, isLoading: _loadingQuestions, color: AppColors.primary),
    ],
  );

  // ── QUESTIONS ────────────────────────────────────────────────
  Widget _buildQuestions() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _backButton(onTap: () => setState(() { _view = _View.enterEmail; _recoverError = null; })),
      const SizedBox(height: 20),
      Text('Preguntas de seguridad', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text('Responde correctamente para recuperar tu cuenta.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 20),
      ...[(_q1!, _a1Ctrl), (_q2!, _a2Ctrl), (_q3!, _a3Ctrl)].expand((p) => [
        Text(p.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        AppTextField(controller: p.$2, hint: 'Tu respuesta', icon: Icons.short_text_rounded),
        const SizedBox(height: 14),
      ]),
      if (_recoverError != null) ...[AppFeedbackBanner(message: _recoverError!), const SizedBox(height: 10)],
      AppButton(label: 'Validar y recuperar', onPressed: _validateAnswers, isLoading: _loadingValidate, color: AppColors.primary),
    ],
  );

  // ── SENT ─────────────────────────────────────────────────────
  Widget _buildSent() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
        child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 30)),
      const SizedBox(height: 20),
      Text('¡Correo enviado!', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('Revisa tu bandeja de entrada. Te enviamos un link para restablecer tu contraseña.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 24),
      AppButton(label: 'Volver al inicio de sesión', onPressed: _goBack, color: AppColors.textPrimary),
    ],
  );

  Widget _backButton({VoidCallback? onTap}) => GestureDetector(
    onTap: onTap ?? _goBack,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text('Volver', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]),
  );
}
