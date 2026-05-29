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
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -100, right: -100,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50, left: -50,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTeal.withValues(alpha: 0.05),
                ),
              ),
            ),
            
            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 420,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      boxShadow: [BoxShadow(color: AppColors.overlay(0.08), blurRadius: 40, offset: const Offset(0, 16))],
                    ),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                              child: child,
                            ),
                          );
                        },
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CREDENTIALS ──────────────────────────────────────────────
  Widget _buildCredentials() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.tint(AppColors.primary, opacity: 0.8)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.storefront_rounded, color: AppColors.white, size: 28),
        ),
      ),
      const SizedBox(height: 24),
      const Center(child: Text('Bienvenido', style: TextStyle(fontFamily: 'Georgia', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2))),
      const SizedBox(height: 8),
      const Center(child: Text('Accede para gestionar tu negocio', style: TextStyle(fontSize: 14, color: AppColors.textSecondary))),
      const SizedBox(height: 32),
      const AppLabel('Correo electrónico'), const SizedBox(height: 6),
      AppTextField(controller: _emailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      const AppLabel('Contraseña'), const SizedBox(height: 6),
      AppTextField(controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline_rounded, obscure: _obscure,
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18), onPressed: () => setState(() => _obscure = !_obscure))),
      if (_error != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _error!)],
      const SizedBox(height: 24),
      AppButton(label: 'Iniciar sesión', onPressed: _login, isLoading: _loading),
      const SizedBox(height: 24),
      Center(child: GestureDetector(
        onTap: () => setState(() { _view = _View.enterEmail; _recoverError = null; }),
        child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
      )),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('¿No tienes cuenta? ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          GestureDetector(
            onTap: () => context.go('/register'),
            child: const Text('Crear negocio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ],
      ),
    ],
  );

  // ── ENTER EMAIL ──────────────────────────────────────────────
  Widget _buildEnterEmail() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _backButton(),
      const SizedBox(height: 24),
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
      ),
      const SizedBox(height: 16),
      const Text('Recuperar acceso', style: TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Ingresa el correo de tu cuenta para buscar tus preguntas de seguridad.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
      const SizedBox(height: 24),
      const AppLabel('Correo electrónico'), const SizedBox(height: 6),
      AppTextField(controller: _recoverEmailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
      if (_recoverError != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _recoverError!)],
      const SizedBox(height: 24),
      AppButton(label: 'Continuar', onPressed: _getQuestions, isLoading: _loadingQuestions, color: AppColors.primary),
    ],
  );

  // ── QUESTIONS ────────────────────────────────────────────────
  Widget _buildQuestions() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _backButton(onTap: () => setState(() { _view = _View.enterEmail; _recoverError = null; })),
      const SizedBox(height: 24),
      const Text('Preguntas de seguridad', style: TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Responde correctamente para verificar que eres el dueño de la cuenta.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
      const SizedBox(height: 24),
      ...[(_q1!, _a1Ctrl), (_q2!, _a2Ctrl), (_q3!, _a3Ctrl)].expand((p) => [
        Text(p.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        AppTextField(controller: p.$2, hint: 'Tu respuesta', icon: Icons.short_text_rounded),
        const SizedBox(height: 16),
      ]),
      if (_recoverError != null) ...[AppFeedbackBanner(message: _recoverError!), const SizedBox(height: 16)],
      const SizedBox(height: 8),
      AppButton(label: 'Validar y recuperar', onPressed: _validateAnswers, isLoading: _loadingValidate, color: AppColors.primary),
    ],
  );

  // ── SENT ─────────────────────────────────────────────────────
  Widget _buildSent() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 80, height: 80, 
        decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
        child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 40)
      ),
      const SizedBox(height: 24),
      const Text('¡Correo enviado!', style: TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      const Text(
        'Revisa tu bandeja de entrada o spam. Te enviamos un link para restablecer tu contraseña y recuperar tu acceso.',
        textAlign: TextAlign.center, 
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)
      ),
      const SizedBox(height: 32),
      AppButton(label: 'Volver al inicio de sesión', onPressed: _goBack, color: AppColors.textPrimary),
    ],
  );

  Widget _backButton({VoidCallback? onTap}) => GestureDetector(
    onTap: onTap ?? _goBack,
    child: Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 8),
        const Text('Volver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]
    ),
  );
}
