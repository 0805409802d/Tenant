import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/worker_email_service.dart';
import '../../../shared/widgets/app_widgets.dart';

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

  // ── Workers
  bool _showWorkerModal = false;
  final _wFirstCtrl    = TextEditingController();
  final _wLastCtrl     = TextEditingController();
  final _wEmailCtrl    = TextEditingController();
  final _wPassCtrl     = TextEditingController();
  bool _obscureWorkerPass = true;
  bool _savingWorker   = false;
  String? _workerFeedback;
  bool _workerIsError  = true;

  // Datos de Base de Datos
  final _db = Supabase.instance.client;
  String? _tenantId;
  String? _tenantSlug;
  List<Map<String, dynamic>> _workers = [];

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    final tenant = await _db.from('tenants').select('id, slug').eq('owner_id', uid).maybeSingle();
    if (tenant != null) {
      _tenantId = tenant['id'];
      _tenantSlug = tenant['slug'];
      
      final workers = await WorkerEmailService.getWorkers(_tenantId!);
      final questions = await _db.from('security_questions').select().eq('profile_id', uid).maybeSingle();

      if (mounted) {
        if (questions != null) {
          _q1Ctrl.text = questions['question_1'] ?? '';
          _a1Ctrl.text = questions['answer_1'] ?? '';
          _q2Ctrl.text = questions['question_2'] ?? '';
          _a2Ctrl.text = questions['answer_2'] ?? '';
          _q3Ctrl.text = questions['question_3'] ?? '';
          _a3Ctrl.text = questions['answer_3'] ?? '';
        }
        setState(() => _workers = workers);
      }
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _currentPassCtrl, _newPassCtrl, _confirmPassCtrl,
      _newEmailCtrl, _confirmEmailCtrl,
      _newPhoneCtrl, _confirmPhoneCtrl,
      _q1Ctrl, _a1Ctrl, _q2Ctrl, _a2Ctrl, _q3Ctrl, _a3Ctrl,
      _wFirstCtrl, _wLastCtrl, _wEmailCtrl, _wPassCtrl,
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
    });
  }

  Future<void> _createWorker() async {
    if ([_wFirstCtrl, _wLastCtrl, _wEmailCtrl, _wPassCtrl]
        .any((c) => c.text.trim().isEmpty)) {
      setState(() { _workerFeedback = 'Completa todos los campos del trabajador.'; _workerIsError = true; });
      return;
    }
    if (_workers.length >= 2) {
      setState(() { _workerFeedback = 'Ya tienes el máximo de 2 trabajadores.'; _workerIsError = true; });
      return;
    }
    if (_tenantId == null || _tenantSlug == null) {
      setState(() { _workerFeedback = 'No se encontró la información del negocio.'; _workerIsError = true; });
      return;
    }
    
    setState(() { _savingWorker = true; _workerFeedback = null; });
    
    final result = await WorkerEmailService.createWorker(
      firstName: _wFirstCtrl.text.trim(),
      lastName: _wLastCtrl.text.trim(),
      email: _wEmailCtrl.text.trim(),
      password: _wPassCtrl.text.trim(),
      tenantId: _tenantId!,
      managerTenantSlug: _tenantSlug!,
    );
    
    if (!mounted) return;
    
    setState(() {
      _savingWorker = false;
      _workerFeedback = result.success ? 'Trabajador creado correctamente.' : result.error;
      _workerIsError  = !result.success;
    });

    if (result.success) {
      _showWorkerModal = false;
      _wFirstCtrl.clear(); _wLastCtrl.clear(); _wEmailCtrl.clear(); _wPassCtrl.clear();
      _loadData();
    }
  }

  Future<void> _deleteWorker(int index) async {
    final worker = _workers[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar trabajador'),
        content: Text('¿Seguro que deseas eliminar a ${worker['first_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
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
      backgroundColor: AppColors.greyLight,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 24),

                  // Contraseña
                  SectionCard(
                    title: 'Cambiar contraseña',
                    icon: Icons.lock_outline_rounded,
                    accentColor: const Color(0xFF6C47FF),
                    child: _buildPasswordSection(),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  SectionCard(
                    title: 'Cambiar correo electrónico',
                    icon: Icons.mail_outline_rounded,
                    child: _buildEmailSection(),
                  ),
                  const SizedBox(height: 16),

                  // Teléfono
                  SectionCard(
                    title: 'Cambiar número de teléfono',
                    icon: Icons.phone_outlined,
                    accentColor: const Color(0xFF00B37E),
                    child: _buildPhoneSection(),
                  ),
                  const SizedBox(height: 16),

                  // Preguntas de seguridad
                  SectionCard(
                    title: 'Recuperación de cuenta',
                    icon: Icons.shield_outlined,
                    subtitle: '3 preguntas de seguridad',
                    accentColor: const Color(0xFFE53935),
                    child: _buildQuestionsSection(),
                  ),
                  const SizedBox(height: 16),

                  // Workers
                  SectionCard(
                    title: 'Trabajadores',
                    icon: Icons.group_outlined,
                    subtitle: 'Máximo 2 cuentas',
                    accentColor: const Color(0xFF0097A7),
                    child: _buildWorkersSection(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Modal de nuevo trabajador
          if (_showWorkerModal) _buildWorkerModal(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Seguridad', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.black)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.greyBorder),
        ),
      );

  Widget _buildPageHeader() => Row(
        children: [
          Container(width: 4, height: 28, decoration: BoxDecoration(color: const Color(0xFF6C47FF), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Seguridad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black)),
              Text('Protege y actualiza los datos de tu cuenta', style: TextStyle(fontSize: 13, color: AppColors.greyText)),
            ],
          ),
        ],
      );

  // ── Cambiar contraseña
  Widget _buildPasswordSection() => Column(
        children: [
          _passField('Contraseña actual', _currentPassCtrl, _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
          const SizedBox(height: 12),
          _passField('Contraseña nueva', _newPassCtrl, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 12),
          _passField('Confirmar nueva contraseña', _confirmPassCtrl, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
          if (_passFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _passFeedback!, isError: _passIsError)],
          const SizedBox(height: 14),
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
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.greyText, size: 18),
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
          if (_emailFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _emailFeedback!, isError: _emailIsError)],
          const SizedBox(height: 14),
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
          if (_phoneFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _phoneFeedback!, isError: _phoneIsError)],
          const SizedBox(height: 14),
          AppButton(label: 'Actualizar teléfono', onPressed: _changePhone, isLoading: _savingPhone, color: const Color(0xFF00B37E)),
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
          style: TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.5),
        ),
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
      ],
    );
  }

  // ── Workers
  Widget _buildWorkersSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_workers.isEmpty)
            const Text('Aún no tienes trabajadores. Puedes crear hasta 2 cuentas.',
                style: TextStyle(fontSize: 13, color: AppColors.greyText, height: 1.5)),

          ..._workers.asMap().entries.map((e) => _workerTile(e.key, e.value)),

          if (_workerFeedback != null && !_showWorkerModal) ...[
            const SizedBox(height: 10),
            AppFeedbackBanner(message: _workerFeedback!, isError: _workerIsError),
          ],

          const SizedBox(height: 14),
          if (_workers.length < 2)
            AppButton(
              label: 'Agregar trabajador',
              onPressed: () => setState(() { _showWorkerModal = true; _workerFeedback = null; }),
              color: const Color(0xFF0097A7),
            ),
        ],
      );

  Widget _workerTile(int index, Map<String, dynamic> worker) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: const Color(0xFF0097A7).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_rounded, color: Color(0xFF0097A7), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${worker['first_name']} ${worker['last_name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                  Text(worker['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.greyText)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 20),
              onPressed: () => _deleteWorker(index),
              tooltip: 'Eliminar trabajador',
            ),
          ],
        ),
      );

  // ── Modal de nuevo trabajador
  Widget _buildWorkerModal() => GestureDetector(
        onTap: () => setState(() => _showWorkerModal = false),
        child: Container(
          color: AppColors.black.withValues(alpha: 0.45),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // evitar que el tap cierre el modal
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nuevo trabajador', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.black)),
                        IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.greyText), onPressed: () => setState(() => _showWorkerModal = false)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('El e-mail debe usar el dominio de tu tienda: nombre@tutienda.com',
                        style: TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.5)),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 12),
                    const AppLabel('Correo'), const SizedBox(height: 6),
                    AppTextField(controller: _wEmailCtrl, hint: 'maria@tutienda.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    const AppLabel('Contraseña'), const SizedBox(height: 6),
                    AppTextField(
                      controller: _wPassCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscureWorkerPass,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureWorkerPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.greyText, size: 18),
                        onPressed: () => setState(() => _obscureWorkerPass = !_obscureWorkerPass),
                      ),
                    ),
                    if (_workerFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _workerFeedback!, isError: _workerIsError)],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: AppButton(label: 'Cancelar', onPressed: () => setState(() => _showWorkerModal = false), color: AppColors.greyBorder, textColor: AppColors.black)),
                        const SizedBox(width: 12),
                        Expanded(child: AppButton(label: 'Crear', onPressed: _createWorker, isLoading: _savingWorker, color: const Color(0xFF0097A7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
