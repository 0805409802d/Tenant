import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../core/services/worker_email_service.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/app_components.dart';

class ManagementSecurityScreen extends StatefulWidget {
  const ManagementSecurityScreen({super.key});

  @override
  State<ManagementSecurityScreen> createState() => _ManagementSecurityScreenState();
}

class _ManagementSecurityScreenState extends State<ManagementSecurityScreen>
    with SingleTickerProviderStateMixin {

  // ── Cambiar contraseña
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _savingPass     = false;
  String? _passFeedback;
  bool _passIsError = true;
  double _passStrength = 0.0;

  // ── Cambiar email
  final _newEmailCtrl     = TextEditingController();
  final _confirmEmailCtrl = TextEditingController();
  bool _savingEmail = false;
  String? _emailFeedback;
  bool _emailIsError = true;

  // ── Cambiar teléfono
  final _newPhoneCtrl     = TextEditingController();
  final _confirmPhoneCtrl = TextEditingController();
  bool _savingPhone = false;
  String? _phoneFeedback;
  bool _phoneIsError = true;

  // ── Preguntas de seguridad
  final _q1Ctrl = TextEditingController();
  final _a1Ctrl = TextEditingController();
  final _q2Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();
  final _q3Ctrl = TextEditingController();
  final _a3Ctrl = TextEditingController();
  bool _savingQuestions   = false;
  String? _questionsFeedback;
  bool _questionsIsError  = true;
  bool _questionsConfigured = false;

  // ── Workers
  List<Map<String, dynamic>> _workers = [];
  bool _isWorker = false;
  String? _workerFeedback;
  bool _workerIsError = true;

  // Datos de Base de Datos
  final _db = Supabase.instance.client;
  String? _tenantId;
  String? _tenantSlug;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    
    _newPassCtrl.addListener(_updatePassStrength);
    _loadData();
  }

  void _updatePassStrength() {
    final pass = _newPassCtrl.text;
    double strength = 0;
    if (pass.length > 5) strength += 0.3;
    if (pass.length > 8) strength += 0.3;
    if (RegExp(r'[A-Z]').hasMatch(pass)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(pass)) strength += 0.2;
    setState(() => _passStrength = strength.clamp(0.0, 1.0));
  }

  Future<void> _loadData() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    final tenant = await TenantService.getCurrentUserTenant();
    if (tenant != null) {
      _tenantId = tenant['id'];
      _tenantSlug = tenant['slug'];
      
      final isWorker = await TenantService.isCurrentUserWorker();
      List<Map<String, dynamic>> workers = [];
      if (!isWorker) {
        workers = await WorkerEmailService.getWorkers(_tenantId!);
      }
      final questions = await _db.from('security_questions').select().eq('profile_id', uid).maybeSingle();

      if (mounted) {
        if (questions != null) {
          _q1Ctrl.text = questions['question_1'] ?? '';
          _a1Ctrl.text = questions['answer_1'] ?? '';
          _q2Ctrl.text = questions['question_2'] ?? '';
          _a2Ctrl.text = questions['answer_2'] ?? '';
          _q3Ctrl.text = questions['question_3'] ?? '';
          _a3Ctrl.text = questions['answer_3'] ?? '';
          _questionsConfigured = _q1Ctrl.text.isNotEmpty;
        }
        setState(() {
          _isWorker = isWorker;
          _workers = workers;
        });
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _newPassCtrl.removeListener(_updatePassStrength);
    for (final c in [
      _currentPassCtrl, _newPassCtrl, _confirmPassCtrl,
      _newEmailCtrl, _confirmEmailCtrl,
      _newPhoneCtrl, _confirmPhoneCtrl,
      _q1Ctrl, _a1Ctrl, _q2Ctrl, _a2Ctrl, _q3Ctrl, _a3Ctrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── HANDLERS ──────────────────────────────────────────────

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() { _passFeedback = 'Las contraseñas nuevas no coinciden.'; _passIsError = true; });
      return;
    }
    setState(() { _savingPass = true; _passFeedback = null; });
    final result = await AuthService.changePassword(
      currentPassword: _currentPassCtrl.text.trim(),
      newPassword: _newPassCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _savingPass   = false;
      _passFeedback = result.success ? 'Contraseña actualizada correctamente.' : result.error;
      _passIsError  = !result.success;
    });
    if (result.success) {
      _currentPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear();
      _passStrength = 0;
    }
  }

  Future<void> _changeEmail() async {
    if (_newEmailCtrl.text.trim() != _confirmEmailCtrl.text.trim()) {
      setState(() { _emailFeedback = 'Los correos no coinciden.'; _emailIsError = true; });
      return;
    }
    setState(() { _savingEmail = true; _emailFeedback = null; });
    final result = await AuthService.changeEmail(newEmail: _newEmailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _savingEmail   = false;
      _emailFeedback = result.success ? 'Correo actualizado. Revisa tu bandeja para confirmar.' : result.error;
      _emailIsError  = !result.success;
    });
    if (result.success) { _newEmailCtrl.clear(); _confirmEmailCtrl.clear(); }
  }

  Future<void> _changePhone() async {
    if (_newPhoneCtrl.text.trim() != _confirmPhoneCtrl.text.trim()) {
      setState(() { _phoneFeedback = 'Los números no coinciden.'; _phoneIsError = true; });
      return;
    }
    setState(() { _savingPhone = true; _phoneFeedback = null; });
    final result = await AuthService.changePhone(newPhone: _newPhoneCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _savingPhone   = false;
      _phoneFeedback = result.success ? 'Teléfono actualizado correctamente.' : result.error;
      _phoneIsError  = !result.success;
    });
    if (result.success) { _newPhoneCtrl.clear(); _confirmPhoneCtrl.clear(); }
  }

  Future<void> _saveQuestions() async {
    if ([_q1Ctrl, _a1Ctrl, _q2Ctrl, _a2Ctrl, _q3Ctrl, _a3Ctrl]
        .any((c) => c.text.trim().isEmpty)) {
      setState(() { _questionsFeedback = 'Completa todas las preguntas y respuestas.'; _questionsIsError = true; });
      return;
    }
    setState(() { _savingQuestions = true; _questionsFeedback = null; });
    final result = await AuthService.saveSecurityQuestions(
      question1: _q1Ctrl.text.trim(), answer1: _a1Ctrl.text.trim(),
      question2: _q2Ctrl.text.trim(), answer2: _a2Ctrl.text.trim(),
      question3: _q3Ctrl.text.trim(), answer3: _a3Ctrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _savingQuestions   = false;
      _questionsFeedback = result.success ? 'Preguntas de seguridad guardadas.' : result.error;
      _questionsIsError  = !result.success;
      if (result.success) _questionsConfigured = true;
    });
  }

  void _showWorkerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WorkerFormSheet(
        tenantId: _tenantId!,
        tenantSlug: _tenantSlug!,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteWorker(int index) async {
    final worker = _workers[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AppConfirmDialog(
        title: 'Eliminar trabajador',
        content: '¿Seguro que deseas eliminar a ${worker['first_name']}?',
        confirmLabel: 'Eliminar',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      await WorkerEmailService.deleteWorker(worker['profile_id']);
      _loadData();
    }
  }

  // ── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.go('/'),
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
              // Worker context card
              if (_isWorker) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: AppColors.accentPurple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tu cuenta personal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            SizedBox(height: 4),
                            Text(
                              'Aquí puedes actualizar tu contraseña, correo, teléfono y preguntas de seguridad. Estos cambios solo afectan a tu cuenta de trabajador.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _CollapsibleSection(
                title: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                accentColor: AppColors.primary,
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
                statusChip: _questionsConfigured 
                  ? const AppChip(label: 'Configurado', color: AppColors.success)
                  : const AppChip(label: 'Pendiente', color: AppColors.accentAmber),
                child: _buildQuestionsSection(),
              ),
              const SizedBox(height: 16),
              if (!_isWorker) ...[
                _CollapsibleSection(
                  title: 'Trabajadores',
                  icon: Icons.group_outlined,
                  accentColor: AppColors.accentAmber,
                  statusChip: AppChip(label: '${_workers.length}/2', color: AppColors.primary),
                  child: _buildWorkersSection(),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Cambiar contraseña
  Widget _buildPasswordSection() => Column(
        children: [
          _passField('Contraseña actual', _currentPassCtrl, _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
          const SizedBox(height: 12),
          _passField('Contraseña nueva', _newPassCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 8),
          
          // Password Strength indicator
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
          AppButton(label: 'Actualizar contraseña', onPressed: _changePassword, isLoading: _savingPass),
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

  // ── Cambiar email
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
          AppButton(label: 'Actualizar correo', onPressed: _changeEmail, isLoading: _savingEmail),
        ],
      );

  // ── Cambiar teléfono
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
          AppButton(label: 'Actualizar teléfono', onPressed: _changePhone, isLoading: _savingPhone),
        ],
      );

  // ── Preguntas de seguridad
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
        AppButton(label: 'Guardar preguntas', onPressed: _saveQuestions, isLoading: _savingQuestions),
      ],
    );
  }

  // ── Workers
  Widget _buildWorkersSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_workers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Aún no tienes trabajadores. Puedes crear hasta 2 cuentas.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            ),

          ..._workers.asMap().entries.map((e) => _workerTile(e.key, e.value)),

          if (_workerFeedback != null) ...[
            const SizedBox(height: 16),
            AppFeedbackBanner(message: _workerFeedback!, isError: _workerIsError),
          ],

          const SizedBox(height: 16),
          if (_workers.length < 2)
            AppButton(
              label: 'Agregar trabajador',
              onPressed: _showWorkerModal,
              color: AppColors.primary,
            ),
        ],
      );

  Widget _workerTile(int index, Map<String, dynamic> worker) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            AppAvatar(name: '${worker['first_name']} ${worker['last_name']}', radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${worker['first_name']} ${worker['last_name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(worker['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const AppChip(label: 'Activo', color: AppColors.success),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              onPressed: () => _deleteWorker(index),
              tooltip: 'Eliminar trabajador',
            ),
          ],
        ),
      );
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.child,
    required this.accentColor,
    this.statusChip,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color accentColor;
  final Widget? statusChip;
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
              if (statusChip != null) statusChip!,
            ],
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _WorkerFormSheet extends StatefulWidget {
  final String tenantId;
  final String tenantSlug;
  final VoidCallback onSaved;

  const _WorkerFormSheet({required this.tenantId, required this.tenantSlug, required this.onSaved});

  @override
  State<_WorkerFormSheet> createState() => _WorkerFormSheetState();
}

class _WorkerFormSheetState extends State<_WorkerFormSheet> {
  final _wFirstCtrl    = TextEditingController();
  final _wLastCtrl     = TextEditingController();
  final _wEmailCtrl    = TextEditingController();
  final _wPassCtrl     = TextEditingController();
  bool _obscureWorkerPass = true;
  bool _savingWorker   = false;
  String? _workerFeedback;
  bool _workerIsError  = true;

  Future<void> _createWorker() async {
    if ([_wFirstCtrl, _wLastCtrl, _wEmailCtrl, _wPassCtrl]
        .any((c) => c.text.trim().isEmpty)) {
      setState(() { _workerFeedback = 'Completa todos los campos del trabajador.'; _workerIsError = true; });
      return;
    }
    
    setState(() { _savingWorker = true; _workerFeedback = null; });
    
    final result = await WorkerEmailService.createWorker(
      firstName: _wFirstCtrl.text.trim(),
      lastName: _wLastCtrl.text.trim(),
      email: _wEmailCtrl.text.trim(),
      password: _wPassCtrl.text.trim(),
      tenantId: widget.tenantId,
      managerTenantSlug: widget.tenantSlug,
    );
    
    if (!mounted) return;
    
    setState(() {
      _savingWorker = false;
      _workerFeedback = result.success ? 'Trabajador creado correctamente.' : result.error;
      _workerIsError  = !result.success;
    });

    if (result.success) {
      widget.onSaved();
    }
  }

  @override
  void dispose() {
    _wFirstCtrl.dispose();
    _wLastCtrl.dispose();
    _wEmailCtrl.dispose();
    _wPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24, right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nuevo trabajador', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('El e-mail debe usar el dominio de tu tienda: nombre@tutienda.com',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const AppLabel('Nombre'), const SizedBox(height: 6),
                      AppTextField(controller: _wFirstCtrl, hint: 'María', icon: Icons.person_outline_rounded),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const AppLabel('Apellido'), const SizedBox(height: 6),
                      AppTextField(controller: _wLastCtrl, hint: 'García', icon: Icons.person_outline_rounded),
                    ])),
                  ],
                ),
                const SizedBox(height: 16),
                const AppLabel('Correo'), const SizedBox(height: 6),
                AppTextField(controller: _wEmailCtrl, hint: 'maria@tutienda.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                const AppLabel('Contraseña temporal'), const SizedBox(height: 6),
                AppTextField(
                  controller: _wPassCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureWorkerPass,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureWorkerPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18),
                    onPressed: () => setState(() => _obscureWorkerPass = !_obscureWorkerPass),
                  ),
                ),
                if (_workerFeedback != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _workerFeedback!, isError: _workerIsError)],
                const SizedBox(height: 32),
                AppButton(label: 'Crear trabajador', onPressed: _createWorker, isLoading: _savingWorker),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
