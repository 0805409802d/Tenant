import 'package:flutter/material.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Ajustes del cliente: solo foto de perfil.
/// El cliente no gestiona empresa, link, QR ni colores.
class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen>
    with SingleTickerProviderStateMixin {

  bool _savingPhoto = false;

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
    super.dispose();
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
                  Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black)),
                  Text('Personaliza cómo te ven los negocios', style: TextStyle(fontSize: 13, color: AppColors.greyText)),
                ]),
              ]),
              const SizedBox(height: 24),

              // Foto de perfil
              SectionCard(
                title: 'Foto de perfil',
                icon: Icons.person_outline_rounded,
                subtitle: 'Visible en tus pedidos y perfil',
                child: Column(
                  children: [
                    // Avatar centrado
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: AppColors.greyBorder,
                            child: const Icon(Icons.person_rounded, size: 52, color: AppColors.greyText),
                          ),
                          Positioned(
                            right: 2, bottom: 2,
                            child: GestureDetector(
                              onTap: () {}, // TODO: image picker
                              child: Container(
                                width: 30, height: 30,
                                decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sin foto de perfil',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'JPG o PNG, máximo 2MB',
                      style: TextStyle(fontSize: 13, color: AppColors.greyText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppButton(label: 'Cambiar foto', onPressed: () {}, isLoading: _savingPhoto),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
