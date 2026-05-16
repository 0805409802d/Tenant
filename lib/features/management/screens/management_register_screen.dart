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
    _animCtrl.dispose();
    for (final c in [_emailCtrl, _passCtrl, _phoneCtrl, _businessNameCtrl, _ownerNameCtrl, _countryCtrl, _cityCtrl, _addressCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final missing = <String>[];
    if (_emailCtrl.text.trim().isEmpty)       missing.add('correo');
    if (_passCtrl.text.isEmpty)               missing.add('contraseña');
    if (_phoneCtrl.text.trim().isEmpty)       missing.add('teléfono');
    if (_businessNameCtrl.text.trim().isEmpty) missing.add('nombre del negocio');
    if (_ownerNameCtrl.text.trim().isEmpty)   missing.add('nombre del propietario');
    if (_cityCtrl.text.trim().isEmpty)        missing.add('ciudad');
    if (_selectedTypeId == null)              missing.add('tipo de negocio');
    if (!_acceptedTerms)                      missing.add('aceptar términos y condiciones');

    if (missing.isNotEmpty) {
      setState(() => _error = 'Campos incompletos: ${missing.join(', ')}.');
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surfaceGrey,
    body: Center(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: 480,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: AppColors.overlay(0.06), blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Container(width: 32, height: 3, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Crea tu sitio', style: TextStyle(fontFamily: 'Georgia', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
              const SizedBox(height: 4),
              Text('Lleva tu negocio al siguiente nivel', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              // Sección: Cuenta
              _sectionHeader('Tu cuenta', Icons.person_outline_rounded, AppColors.primary),
              const SizedBox(height: 14),
              const AppLabel('Correo electrónico'), const SizedBox(height: 6),
              AppTextField(controller: _emailCtrl, hint: 'correo@dominio.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              const AppLabel('Contraseña'), const SizedBox(height: 6),
              AppTextField(controller: _passCtrl, hint: 'Mínimo 6 caracteres', icon: Icons.lock_outline_rounded, obscure: _obscure,
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 18), onPressed: () => setState(() => _obscure = !_obscure))),
              const SizedBox(height: 12),
              const AppLabel('Teléfono'), const SizedBox(height: 6),
              AppTextField(controller: _phoneCtrl, hint: '+593 99 000 0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),

              // Sección: Negocio
              _sectionHeader('Tu negocio', Icons.storefront_outlined, const Color(0xFF00B37E)),
              const SizedBox(height: 14),
              const AppLabel('Nombre del negocio'), const SizedBox(height: 6),
              AppTextField(controller: _businessNameCtrl, hint: 'Ej: Mi Restaurante', icon: Icons.storefront_outlined),
              const SizedBox(height: 12),
              const AppLabel('Nombre del propietario'), const SizedBox(height: 6),
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
              const SizedBox(height: 24),

              // Sección: Tipo de negocio
              _sectionHeader('Tipo de negocio', Icons.category_outlined, const Color(0xFF6C47FF)),
              const SizedBox(height: 14),
              const AppLabel('Selecciona el tipo'), const SizedBox(height: 6),
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
                const SizedBox(height: 12),
                Text('Tags SEO generados automáticamente:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: _seoTags.map((tag) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryBorder)),
                    child: Text(tag, style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  )
                ).toList()),
              ],
              const SizedBox(height: 24),

              // Términos
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
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Acepto los términos y condiciones del servicio y la política de privacidad.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                  )),
                ]),
              ),

              if (_error != null) ...[const SizedBox(height: 12), AppFeedbackBanner(message: _error!)],
              const SizedBox(height: 20),

              AppButton(label: 'Crear sitio', onPressed: _register, isLoading: _loading),
              const SizedBox(height: 12),
              Center(child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Text('¿Ya tienes cuenta? Iniciar sesión', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              )),
            ]),
          ),
        ),
      ),
    ),
  );

  Widget _sectionHeader(String title, IconData icon, Color color) => Row(children: [
    Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.tint(color), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16)),
    const SizedBox(width: 10),
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const SizedBox(width: 10),
    Expanded(child: Divider(color: AppColors.border)),
  ]);

  void _showTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Text('Selecciona tu giro de negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
