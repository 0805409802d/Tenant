import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementRegisterScreen extends StatefulWidget {
  const ManagementRegisterScreen({super.key});
  @override
  State<ManagementRegisterScreen> createState() => _ManagementRegisterScreenState();
}

class _ManagementRegisterScreenState extends State<ManagementRegisterScreen>
    with SingleTickerProviderStateMixin {

  final _pageController = PageController();
  int _currentStep = 0;

  // Cuenta
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  bool _obscure = true;

  // Negocio
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl    = TextEditingController();
  final _countryCtrl      = TextEditingController(text: 'Ecuador');
  final _cityCtrl         = TextEditingController();
  final _addressCtrl      = TextEditingController();

  // Tipo de negocio
  List<Map<String, dynamic>> _businessTypes = [];
  int? _selectedTypeId;
  List<String> _seoTags = [];
  bool _loadingTypes = true;

  // Términos
  bool _acceptedTerms = false;

  bool _loading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final types = await AuthService.getBusinessTypes();
    if (mounted) setState(() { _businessTypes = types; _loadingTypes = false; });
  }

  void _onTypeChanged(int? id) {
    if (id == null) return;
    final type = _businessTypes.firstWhere((t) => t['id'] == id, orElse: () => {});
    final rawTags = type['seo_tags'];
    setState(() {
      _selectedTypeId = id;
      _seoTags = rawTags is List ? List<String>.from(rawTags) : [];
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    for (final c in [_emailCtrl, _passCtrl, _phoneCtrl, _businessNameCtrl, _ownerNameCtrl, _countryCtrl, _cityCtrl, _addressCtrl]) c.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _error = null);
    if (_currentStep == 0) {
      if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty || _phoneCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Completa todos los campos de la cuenta.');
        return;
      }
    } else if (_currentStep == 1) {
      if (_businessNameCtrl.text.trim().isEmpty || _ownerNameCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Completa los campos obligatorios del negocio.');
        return;
      }
    }
    
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _error = null);
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep--);
  }

  Future<void> _register() async {
    final missing = <String>[];
    if (_selectedTypeId == null) missing.add('tipo de negocio');
    if (!_acceptedTerms) missing.add('aceptar términos y condiciones');

    if (missing.isNotEmpty) {
      setState(() => _error = 'Falta: ${missing.join(', ')}.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final r = await AuthService.registerManagement(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
      businessName: _businessNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      businessTypeId: _selectedTypeId!,
      acceptedTerms: _acceptedTerms,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (r.success) { context.go('/'); } else { setState(() => _error = r.error); }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 24 : 12,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Paso 1: Tu cuenta', Icons.person_outline_rounded, AppColors.primary),
          const SizedBox(height: 24),
          const AppLabel('Correo electrónico'), const SizedBox(height: 6),
          AppTextField(controller: _emailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          const AppLabel('Contraseña'), const SizedBox(height: 6),
          AppTextField(controller: _passCtrl, hint: 'Mínimo 6 caracteres', icon: Icons.lock_outline_rounded, obscure: _obscure,
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18), onPressed: () => setState(() => _obscure = !_obscure))),
          const SizedBox(height: 16),
          const AppLabel('Teléfono'), const SizedBox(height: 6),
          AppTextField(controller: _phoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          if (_error != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _error!)],
          const SizedBox(height: 32),
          AppButton(label: 'Siguiente paso', onPressed: _nextStep),
          const SizedBox(height: 24),
          Center(child: GestureDetector(
            onTap: () => context.go('/login'),
            child: const Text('¿Ya tienes cuenta? Iniciar sesión', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, decoration: TextDecoration.underline)),
          )),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Paso 2: Tu negocio', Icons.storefront_outlined, const Color(0xFF00B37E)),
          const SizedBox(height: 24),
          const AppLabel('Nombre del negocio'), const SizedBox(height: 6),
          AppTextField(controller: _businessNameCtrl, hint: 'Ej: Mi Restaurante', icon: Icons.storefront_outlined),
          const SizedBox(height: 16),
          const AppLabel('Nombre del propietario'), const SizedBox(height: 6),
          AppTextField(controller: _ownerNameCtrl, hint: 'Nombre completo', icon: Icons.badge_outlined),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          const AppLabel('Dirección'), const SizedBox(height: 6),
          AppTextField(controller: _addressCtrl, hint: 'Calle, número, referencia', icon: Icons.location_on_outlined),
          if (_error != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _error!)],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: AppButton(label: 'Atrás', onPressed: _prevStep, color: AppColors.surfaceGrey, textColor: AppColors.textPrimary)),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: 'Siguiente', onPressed: _nextStep, color: const Color(0xFF00B37E))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Paso 3: Detalles finales', Icons.category_outlined, const Color(0xFF6C47FF)),
          const SizedBox(height: 24),
          const AppLabel('Selecciona el tipo de negocio'), const SizedBox(height: 6),
          _loadingTypes
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : GestureDetector(
                  onTap: _showTypeSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTypeId == null 
                              ? 'Elige el giro de tu negocio' 
                              : _businessTypes.firstWhere((t) => t['id'] == _selectedTypeId, orElse: () => {'name': ''})['name'] as String,
                          style: TextStyle(
                            fontSize: 14, 
                            color: _selectedTypeId == null ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),

          if (_seoTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Tags SEO generados automáticamente:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8, 
              children: _seoTags.asMap().entries.map((entry) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (entry.key * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFBFD7FF))),
                    child: Text(entry.value, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 32),

          GestureDetector(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Acepto los términos y condiciones del servicio y la política de privacidad.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              )),
            ]),
          ),

          if (_error != null) ...[const SizedBox(height: 16), AppFeedbackBanner(message: _error!)],
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: AppButton(label: 'Atrás', onPressed: _prevStep, color: AppColors.surfaceGrey, textColor: AppColors.textPrimary)),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: 'Crear sitio 🚀', onPressed: _register, isLoading: _loading, color: const Color(0xFF6C47FF))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surfaceGrey,
    body: Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: 500,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: AppColors.overlay(0.06), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
                child: Column(
                  children: [
                    Text('Crea tu sitio', style: TextStyle(fontFamily: 'Georgia', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Lleva tu negocio al siguiente nivel', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    _buildStepIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _sectionHeader(String title, IconData icon, Color color) => Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20)),
    const SizedBox(width: 12),
    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const SizedBox(width: 12),
    const Expanded(child: Divider(color: AppColors.borderLight)),
  ]);

  void _showTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return _BusinessTypeSelector(
          types: _businessTypes,
          onSelected: (id) {
            _onTypeChanged(id);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _BusinessTypeSelector extends StatefulWidget {
  const _BusinessTypeSelector({required this.types, required this.onSelected});
  final List<Map<String, dynamic>> types;
  final ValueChanged<int> onSelected;

  @override
  State<_BusinessTypeSelector> createState() => _BusinessTypeSelectorState();
}

class _BusinessTypeSelectorState extends State<_BusinessTypeSelector> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.types;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.types.where((t) {
        final name = (t['name'] as String).toLowerCase();
        final tags = (t['seo_tags'] as List).join(' ').toLowerCase();
        return name.contains(query) || tags.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Selecciona tu giro de negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _searchCtrl,
                hint: 'Buscar por nombre o palabra clave...',
                icon: Icons.search_rounded,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = _filtered[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        (t['seo_tags'] as List).take(5).join(', '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => widget.onSelected(t['id'] as int),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
