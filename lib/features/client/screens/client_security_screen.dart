import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class ClientSecurityScreen extends StatefulWidget {
  const ClientSecurityScreen({super.key, required this.tenantSlug});
  final String tenantSlug;

  @override
  State<ClientSecurityScreen> createState() => _ClientSecurityScreenState();
}

class _ClientSecurityScreenState extends State<ClientSecurityScreen>
    with SingleTickerProviderStateMixin {
  
  Color _primaryColor = const Color(0xFF0097A7);
  bool _loadingTheme = true;

  // Contraseña
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true, _obscureNew = true, _obscureConfirm = true;
  bool _savingPass = false;
  String? _passFeedback;
  bool _passIsError = true;
  double _passStrength = 0.0;

  // Email
  final _newEmailCtrl     = TextEditingController();
  final _confirmEmailCtrl = TextEditingController();
  bool _savingEmail = false;
  String? _emailFeedback;
  bool _emailIsError = true;

  // Teléfono
  final _newPhoneCtrl     = TextEditingController();
  final _confirmPhoneCtrl = TextEditingController();
  bool _savingPhone = false;
  String? _phoneFeedback;
  bool _phoneIsError = true;

  // Preguntas
  final _q1Ctrl = TextEditingController(); final _a1Ctrl = TextEditingController();
  final _q2Ctrl = TextEditingController(); final _a2Ctrl = TextEditingController();
  final _q3Ctrl = TextEditingController(); final _a3Ctrl = TextEditingController();
  bool _savingQuestions = false;
  String? _questionsFeedback;
  bool _questionsIsError = true;
  bool _questionsConfigured = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    
    _newPassCtrl.addListener(() {
      final text = _newPassCtrl.text;
      double strength = 0;
      if (text.length >= 8) strength += 0.4;
      if (text.contains(RegExp(r'[A-Z]'))) strength += 0.2;
      if (text.contains(RegExp(r'[0-9]'))) strength += 0.2;
      if (text.contains(RegExp(r'[!@#\$&*~]'))) strength += 0.2;
      setState(() => _passStrength = strength);
    });

    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final db = Supabase.instance.client;
      final res = await db
          .from('tenants')
          .select('primary_color')
          .eq('slug', widget.tenantSlug)
          .maybeSingle();

      if (res != null && res['primary_color'] != null) {
        final hex = (res['primary_color'] as String).replaceAll('#', '');
        _primaryColor = Color(int.parse('FF$hex', radix: 16));
      }

      // Check if user has security questions
      final uid = db.auth.currentUser?.id;
      if (uid != null) {
        final qRes = await db.from('security_questions').select('id').eq('profile_id', uid).maybeSingle();
        _questionsConfigured = qRes != null;
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
    for (final c in [_currentPassCtrl,_newPassCtrl,_confirmPassCtrl,_newEmailCtrl,_confirmEmailCtrl,_newPhoneCtrl,_confirmPhoneCtrl,_q1Ctrl,_a1Ctrl,_q2Ctrl,_a2Ctrl,_q3Ctrl,_a3Ctrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() { _passFeedback = 'Las contraseñas no coinciden.'; _passIsError = true; }); return;
    }
    setState(() { _savingPass = true; _passFeedback = null; });
    final r = await AuthService.changePassword(currentPassword: _currentPassCtrl.text.trim(), newPassword: _newPassCtrl.text.trim());
    if (!mounted) return;
    setState(() { _savingPass = false; _passFeedback = r.success ? 'Contraseña actualizada correctamente.' : r.error; _passIsError = !r.success; });
    if (r.success) { _currentPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear(); }
  }

  Future<void> _changeEmail() async {
    if (_newEmailCtrl.text.trim() != _confirmEmailCtrl.text.trim()) {
      setState(() { _emailFeedback = 'Los correos no coinciden.'; _emailIsError = true; }); return;
    }
    setState(() { _savingEmail = true; _emailFeedback = null; });
    final r = await AuthService.changeEmail(newEmail: _newEmailCtrl.text.trim());
    if (!mounted) return;
    setState(() { _savingEmail = false; _emailFeedback = r.success ? 'Correo actualizado. Por favor, confirma en tu bandeja de entrada.' : r.error; _emailIsError = !r.success; });
    if (r.success) { _newEmailCtrl.clear(); _confirmEmailCtrl.clear(); }
  }

  Future<void> _changePhone() async {
    if (_newPhoneCtrl.text.trim() != _confirmPhoneCtrl.text.trim()) {
      setState(() { _phoneFeedback = 'Los números no coinciden.'; _phoneIsError = true; }); return;
    }
    setState(() { _savingPhone = true; _phoneFeedback = null; });
    final r = await AuthService.changePhone(newPhone: _newPhoneCtrl.text.trim());
    if (!mounted) return;
    setState(() { _savingPhone = false; _phoneFeedback = r.success ? 'Teléfono actualizado correctamente.' : r.error; _phoneIsError = !r.success; });
    if (r.success) { _newPhoneCtrl.clear(); _confirmPhoneCtrl.clear(); }
  }

  Future<void> _saveQuestions() async {
    if ([_q1Ctrl,_a1Ctrl,_q2Ctrl,_a2Ctrl,_q3Ctrl,_a3Ctrl].any((c) => c.text.trim().isEmpty)) {
      setState(() { _questionsFeedback = 'Por favor, completa todas las preguntas y respuestas.'; _questionsIsError = true; }); return;
    }
    setState(() { _savingQuestions = true; _questionsFeedback = null; });
    final r = await AuthService.saveSecurityQuestions(
      question1: _q1Ctrl.text.trim(), answer1: _a1Ctrl.text.trim(),
      question2: _q2Ctrl.text.trim(), answer2: _a2Ctrl.text.trim(),
      question3: _q3Ctrl.text.trim(), answer3: _a3Ctrl.text.trim(),
    );
    if (!mounted) return;
    setState(() { 
      _savingQuestions = false; 
      _questionsFeedback = r.success ? 'Preguntas de seguridad guardadas correctamente.' : r.error; 
      _questionsIsError = !r.success; 
      if (r.success) _questionsConfigured = true;
    });
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
        title: const Text('Seguridad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CollapsibleSection(
                title: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                accentColor: _primaryColor,
                initiallyExpanded: true,
                child: _buildPasswordSection(),
              ),
              const SizedBox(height: 16),
              _CollapsibleSection(
                title: 'Correo electrónico',
                icon: Icons.mail_outline_rounded,
                accentColor: AppColors.accentTeal,
                child: _buildEmailSection(),
              ),
              const SizedBox(height: 16),
              _CollapsibleSection(
                title: 'Teléfono',
                icon: Icons.phone_outlined,
                accentColor: AppColors.accentGreen,
                child: _buildPhoneSection(),
              ),
              const SizedBox(height: 16),
              _CollapsibleSection(
                title: 'Preguntas de seguridad',
                icon: Icons.shield_outlined,
                accentColor: AppColors.error,
                statusBadge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _questionsConfigured ? AppColors.accentGreen.withValues(alpha: 0.1) : AppColors.accentAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _questionsConfigured ? 'Configurado' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _questionsConfigured ? AppColors.accentGreen : AppColors.accentAmber,
                    ),
                  ),
                ),
                child: _buildQuestionsSection(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Secciones
  Widget _buildPasswordSection() => Column(
        children: [
          _passField('Contraseña actual', _currentPassCtrl, _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
          const SizedBox(height: 12),
          _passField('Contraseña nueva', _newPassCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 8),
          
          if (_newPassCtrl.text.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _passStrength,
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _passStrength < 0.4 ? AppColors.error :
                        _passStrength < 0.8 ? AppColors.accentAmber :
                        AppColors.success
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _passStrength < 0.4 ? 'Débil' : _passStrength < 0.8 ? 'Media' : 'Fuerte',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _passStrength < 0.4 ? AppColors.error :
                           _passStrength < 0.8 ? AppColors.accentAmber :
                           AppColors.success
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),
          _passField('Confirmar nueva contraseña', _confirmPassCtrl, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
          if (_passFeedback != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _passFeedback!, isError: _passIsError)],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: 'Actualizar contraseña', onPressed: _changePassword, isLoading: _savingPass, color: _primaryColor),
          ),
        ],
      );

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLabel(label),
          const SizedBox(height: 6),
          AppTextField(
            controller: ctrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: obscure,
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18),
              onPressed: toggle,
            ),
          ),
        ],
      );

  Widget _buildEmailSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Correo electrónico nuevo'),
          const SizedBox(height: 6),
          AppTextField(controller: _newEmailCtrl, hint: 'nuevo@correo.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          const AppLabel('Confirmar correo nuevo'),
          const SizedBox(height: 6),
          AppTextField(controller: _confirmEmailCtrl, hint: 'nuevo@correo.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
          if (_emailFeedback != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _emailFeedback!, isError: _emailIsError)],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: 'Actualizar correo', onPressed: _changeEmail, isLoading: _savingEmail, color: _primaryColor),
          ),
        ],
      );

  Widget _buildPhoneSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Número nuevo'),
          const SizedBox(height: 6),
          AppTextField(controller: _newPhoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          const AppLabel('Confirmar número nuevo'),
          const SizedBox(height: 6),
          AppTextField(controller: _confirmPhoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          if (_phoneFeedback != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _phoneFeedback!, isError: _phoneIsError)],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: 'Actualizar teléfono', onPressed: _changePhone, isLoading: _savingPhone, color: _primaryColor),
          ),
        ],
      );

  Widget _buildQuestionsSection() {
    final pairs = [
      (_q1Ctrl, _a1Ctrl, 'Pregunta 1', 'Respuesta 1'),
      (_q2Ctrl, _a2Ctrl, 'Pregunta 2', 'Respuesta 2'),
      (_q3Ctrl, _a3Ctrl, 'Pregunta 3', 'Respuesta 3'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estas respuestas te permitirán recuperar el acceso a tu cuenta si olvidas tu contraseña.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 16),
        ...pairs.expand((p) => [
          AppLabel(p.$3), const SizedBox(height: 6),
          AppTextField(controller: p.$1, hint: '¿Cuál fue tu primera mascota?', icon: Icons.help_outline_rounded),
          const SizedBox(height: 8),
          AppLabel(p.$4), const SizedBox(height: 6),
          AppTextField(controller: p.$2, hint: 'Tu respuesta', icon: Icons.short_text_rounded),
          const SizedBox(height: 16),
        ]),
        if (_questionsFeedback != null) ...[AppFeedbackBanner(message: _questionsFeedback!, isError: _questionsIsError), const SizedBox(height: 16)],
        SizedBox(
          width: double.infinity,
          child: AppButton(label: 'Guardar preguntas', onPressed: _saveQuestions, isLoading: _savingQuestions, color: _primaryColor),
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.child,
    required this.accentColor,
    this.statusBadge,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color accentColor;
  final Widget? statusBadge;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.tint(accentColor, opacity: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              if (statusBadge != null) statusBadge!,
            ],
          ),
          children: [child],
        ),
      ),
    );
  }
}
