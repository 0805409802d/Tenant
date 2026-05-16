import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdvertisersSecurityScreen extends StatefulWidget {
  const AdvertisersSecurityScreen({super.key});

  @override
  State<AdvertisersSecurityScreen> createState() => _AdvertisersSecurityScreenState();
}

class _AdvertisersSecurityScreenState extends State<AdvertisersSecurityScreen>
    with SingleTickerProviderStateMixin {

  // Contraseña
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true, _obscureNew = true, _obscureConfirm = true;
  bool _savingPass = false;
  String? _passFeedback;
  bool _passIsError = true;

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

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [_currentPassCtrl, _newPassCtrl, _confirmPassCtrl, _newEmailCtrl, _confirmEmailCtrl, _newPhoneCtrl, _confirmPhoneCtrl, _q1Ctrl, _a1Ctrl, _q2Ctrl, _a2Ctrl, _q3Ctrl, _a3Ctrl]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() { _passFeedback = 'Las contraseñas no coinciden.'; _passIsError = true; }); return;
    }
    setState(() { _savingPass = true; _passFeedback = null; });
    final r = await AuthService.changePassword(currentPassword: _currentPassCtrl.text.trim(), newPassword: _newPassCtrl.text.trim());
    if (!mounted) return;
    setState(() { _savingPass = false; _passFeedback = r.success ? 'Contraseña actualizada.' : r.error; _passIsError = !r.success; });
    if (r.success) { _currentPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear(); }
  }

  Future<void> _changeEmail() async {
    if (_newEmailCtrl.text.trim() != _confirmEmailCtrl.text.trim()) {
      setState(() { _emailFeedback = 'Los correos no coinciden.'; _emailIsError = true; }); return;
    }
    setState(() { _savingEmail = true; _emailFeedback = null; });
    final r = await AuthService.changeEmail(newEmail: _newEmailCtrl.text.trim());
    if (!mounted) return;
    setState(() { _savingEmail = false; _emailFeedback = r.success ? 'Correo actualizado. Confirma en tu bandeja.' : r.error; _emailIsError = !r.success; });
    if (r.success) { _newEmailCtrl.clear(); _confirmEmailCtrl.clear(); }
  }

  Future<void> _changePhone() async {
    if (_newPhoneCtrl.text.trim() != _confirmPhoneCtrl.text.trim()) {
      setState(() { _phoneFeedback = 'Los números no coinciden.'; _phoneIsError = true; }); return;
    }
    setState(() { _savingPhone = true; _phoneFeedback = null; });
    final r = await AuthService.changePhone(newPhone: _newPhoneCtrl.text.trim());
    if (!mounted) return;
    setState(() { _savingPhone = false; _phoneFeedback = r.success ? 'Teléfono actualizado.' : r.error; _phoneIsError = !r.success; });
    if (r.success) { _newPhoneCtrl.clear(); _confirmPhoneCtrl.clear(); }
  }

  Future<void> _saveQuestions() async {
    if ([_q1Ctrl,_a1Ctrl,_q2Ctrl,_a2Ctrl,_q3Ctrl,_a3Ctrl].any((c) => c.text.trim().isEmpty)) {
      setState(() { _questionsFeedback = 'Completa todas las preguntas y respuestas.'; _questionsIsError = true; }); return;
    }
    setState(() { _savingQuestions = true; _questionsFeedback = null; });
    final r = await AuthService.saveSecurityQuestions(
      question1: _q1Ctrl.text.trim(), answer1: _a1Ctrl.text.trim(),
      question2: _q2Ctrl.text.trim(), answer2: _a2Ctrl.text.trim(),
      question3: _q3Ctrl.text.trim(), answer3: _a3Ctrl.text.trim(),
    );
    if (!mounted) return;
    setState(() { _savingQuestions = false; _questionsFeedback = r.success ? 'Preguntas guardadas.' : r.error; _questionsIsError = !r.success; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.white, elevation: 0, centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.black), onPressed: () => Navigator.of(context).maybePop()),
        title: const Text('Seguridad', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.black)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.greyBorder)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 4, height: 28, decoration: BoxDecoration(color: const Color(0xFF6C47FF), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Seguridad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black)),
                  Text('Protege los datos de tu empresa', style: TextStyle(fontSize: 13, color: AppColors.greyText)),
                ]),
              ]),
              const SizedBox(height: 24),

              SectionCard(title: 'Cambiar contraseña', icon: Icons.lock_outline_rounded, accentColor: const Color(0xFF6C47FF), child: _buildPasswordSection()),
              const SizedBox(height: 16),
              SectionCard(title: 'Cambiar correo electrónico', icon: Icons.mail_outline_rounded, child: _buildEmailSection()),
              const SizedBox(height: 16),
              SectionCard(title: 'Cambiar número de teléfono', icon: Icons.phone_outlined, accentColor: const Color(0xFF00B37E), child: _buildPhoneSection()),
              const SizedBox(height: 16),
              SectionCard(title: 'Recuperación de cuenta', icon: Icons.shield_outlined, subtitle: '3 preguntas de seguridad', accentColor: const Color(0xFFE53935), child: _buildQuestionsSection()),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection() => Column(children: [
    _passRow('Contraseña actual', _currentPassCtrl, _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
    const SizedBox(height: 12),
    _passRow('Contraseña nueva', _newPassCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
    const SizedBox(height: 12),
    _passRow('Confirmar nueva', _confirmPassCtrl, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
    if (_passFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _passFeedback!, isError: _passIsError)],
    const SizedBox(height: 14),
    AppButton(label: 'Actualizar contraseña', onPressed: _changePassword, isLoading: _savingPass),
  ]);

  Widget _passRow(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [AppLabel(label), const SizedBox(height: 6),
      AppTextField(controller: ctrl, hint: '••••••••', icon: Icons.lock_outline_rounded, obscure: obscure,
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.greyText, size: 18), onPressed: toggle)),
    ]);

  Widget _buildEmailSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const AppLabel('Correo nuevo'), const SizedBox(height: 6),
    AppTextField(controller: _newEmailCtrl, hint: 'nuevo@correo.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
    const SizedBox(height: 12),
    const AppLabel('Confirmar correo nuevo'), const SizedBox(height: 6),
    AppTextField(controller: _confirmEmailCtrl, hint: 'nuevo@correo.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
    if (_emailFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _emailFeedback!, isError: _emailIsError)],
    const SizedBox(height: 14),
    AppButton(label: 'Actualizar correo', onPressed: _changeEmail, isLoading: _savingEmail),
  ]);

  Widget _buildPhoneSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const AppLabel('Número nuevo'), const SizedBox(height: 6),
    AppTextField(controller: _newPhoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
    const SizedBox(height: 12),
    const AppLabel('Confirmar número nuevo'), const SizedBox(height: 6),
    AppTextField(controller: _confirmPhoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
    if (_phoneFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _phoneFeedback!, isError: _phoneIsError)],
    const SizedBox(height: 14),
    AppButton(label: 'Actualizar teléfono', onPressed: _changePhone, isLoading: _savingPhone, color: const Color(0xFF00B37E)),
  ]);

  Widget _buildQuestionsSection() {
    final pairs = [(_q1Ctrl,_a1Ctrl,'Pregunta 1','Respuesta 1'),(_q2Ctrl,_a2Ctrl,'Pregunta 2','Respuesta 2'),(_q3Ctrl,_a3Ctrl,'Pregunta 3','Respuesta 3')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Estas respuestas te permitirán recuperar el acceso a tu cuenta.', style: TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.5)),
      const SizedBox(height: 16),
      ...pairs.expand((p) => [
        AppLabel(p.$3), const SizedBox(height: 6),
        AppTextField(controller: p.$1, hint: '¿Cuál fue tu primera mascota?', icon: Icons.help_outline_rounded),
        const SizedBox(height: 8),
        AppLabel(p.$4), const SizedBox(height: 6),
        AppTextField(controller: p.$2, hint: 'Tu respuesta', icon: Icons.short_text_rounded),
        const SizedBox(height: 14),
      ]),
      if (_questionsFeedback != null) ...[AppFeedbackBanner(message: _questionsFeedback!, isError: _questionsIsError), const SizedBox(height: 10)],
      AppButton(label: 'Guardar preguntas', onPressed: _saveQuestions, isLoading: _savingQuestions, color: const Color(0xFFE53935)),
    ]);
  }
}
