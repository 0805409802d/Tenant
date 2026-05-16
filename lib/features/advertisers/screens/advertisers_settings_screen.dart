import 'package:flutter/material.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdvertisersSettingsScreen extends StatefulWidget {
  const AdvertisersSettingsScreen({super.key});

  @override
  State<AdvertisersSettingsScreen> createState() => _AdvertisersSettingsScreenState();
}

class _AdvertisersSettingsScreenState extends State<AdvertisersSettingsScreen>
    with SingleTickerProviderStateMixin {

  final _businessNameController = TextEditingController();
  bool _savingName  = false;
  bool _savingColor = false;
  bool _savingPhoto = false;
  String? _nameFeedback;
  bool    _nameIsError = true;

  Color _selectedColor = const Color(0xFF1E6BFF);

  static const _palette = [
    Color(0xFF1E6BFF), Color(0xFF0A0A0A), Color(0xFF6C47FF),
    Color(0xFF00B37E), Color(0xFFE53935), Color(0xFFFF8C00),
    Color(0xFF0097A7), Color(0xFF8D6E63), Color(0xFF546E7A),
    Color(0xFF1B5E20),
  ];

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
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_businessNameController.text.trim().isEmpty) {
      setState(() { _nameFeedback = 'Ingresa el nuevo nombre de la empresa.'; _nameIsError = true; });
      return;
    }
    setState(() { _savingName = true; _nameFeedback = null; });
    await Future.delayed(const Duration(seconds: 1)); // TODO: llamar a Supabase
    if (!mounted) return;
    setState(() { _savingName = false; _nameFeedback = 'Nombre actualizado correctamente.'; _nameIsError = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Ajustes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.black)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.greyBorder)),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(width: 4, height: 28, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Personalización', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black)),
                  Text('Configura el perfil de tu empresa', style: TextStyle(fontSize: 13, color: AppColors.greyText)),
                ]),
              ]),
              const SizedBox(height: 24),

              // Foto de perfil
              SectionCard(
                title: 'Foto de perfil',
                icon: Icons.person_outline_rounded,
                child: Row(children: [
                  Stack(children: [
                    CircleAvatar(radius: 36, backgroundColor: AppColors.greyBorder, child: const Icon(Icons.person_rounded, size: 36, color: AppColors.greyText)),
                    Positioned(right: 0, bottom: 0, child: GestureDetector(
                      onTap: () {},
                      child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.white)),
                    )),
                  ]),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Sin foto de perfil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                    const SizedBox(height: 2),
                    const Text('JPG o PNG, máximo 2MB', style: TextStyle(fontSize: 12, color: AppColors.greyText)),
                    const SizedBox(height: 10),
                    AppButton(label: 'Cambiar foto', onPressed: () {}, isLoading: _savingPhoto, fullWidth: false),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),

              // Nombre de la empresa
              SectionCard(
                title: 'Nombre de la empresa',
                icon: Icons.business_outlined,
                subtitle: 'Aparece en tu portal de anunciante',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('Nuevo nombre'),
                  const SizedBox(height: 6),
                  AppTextField(controller: _businessNameController, hint: 'Ej: Empresa XYZ', icon: Icons.business_outlined),
                  if (_nameFeedback != null) ...[const SizedBox(height: 10), AppFeedbackBanner(message: _nameFeedback!, isError: _nameIsError)],
                  const SizedBox(height: 14),
                  AppButton(label: 'Guardar nombre', onPressed: _saveName, isLoading: _savingName),
                ]),
              ),
              const SizedBox(height: 16),

              // Color de la interfaz
              SectionCard(
                title: 'Color de la interfaz',
                icon: Icons.palette_outlined,
                subtitle: 'Personaliza el color de tu panel',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('Selecciona un color'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _palette.map((color) {
                      final selected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle,
                            border: Border.all(color: selected ? AppColors.black : Colors.transparent, width: 2.5),
                            boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))] : [],
                          ),
                          child: selected ? const Icon(Icons.check_rounded, color: AppColors.white, size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  AppButton(label: 'Aplicar color', onPressed: () {}, isLoading: _savingColor),
                ]),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
