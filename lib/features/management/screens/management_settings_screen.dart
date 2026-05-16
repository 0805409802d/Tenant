import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementSettingsScreen extends StatefulWidget {
  const ManagementSettingsScreen({super.key});

  @override
  State<ManagementSettingsScreen> createState() => _ManagementSettingsScreenState();
}

class _ManagementSettingsScreenState extends State<ManagementSettingsScreen>
    with SingleTickerProviderStateMixin {

  final _db = Supabase.instance.client;
  String? _tenantId;
  
  final _businessNameController = TextEditingController();
  final _linkController         = TextEditingController();

  bool _loading     = true;
  bool _savingName  = false;
  bool _savingColor = false;
  bool _savingLogo  = false;
  bool _savingPhoto = false;

  String? _nameFeedback;
  bool    _nameIsError = true;

  Color _selectedColor = const Color(0xFF1E6BFF);
  String? _logoUrl;
  String? _avatarUrl;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  // Paleta de colores predefinidos para la interfaz
  static const _palette = [
    Color(0xFF1E6BFF), Color(0xFF0A0A0A), Color(0xFF6C47FF),
    Color(0xFF00B37E), Color(0xFFE53935), Color(0xFFFF8C00),
    Color(0xFF0097A7), Color(0xFF8D6E63), Color(0xFF546E7A),
    Color(0xFF1B5E20),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;

      final tenant = await _db.from('tenants').select().eq('owner_id', uid).maybeSingle();
      if (tenant != null) {
        _tenantId = tenant['id'];
        _businessNameController.text = tenant['business_name'] ?? '';
        _linkController.text = tenant['link_url'] ?? 'https://${tenant['slug']}.quinindews.com';
        
        // Parse primary_color si existe
        if (tenant['primary_color'] != null) {
          final hex = (tenant['primary_color'] as String).replaceAll('#', '');
          _selectedColor = Color(int.parse('FF$hex', radix: 16));
        }
        _logoUrl = tenant['logo_url'];
      }
      
      final profile = await _db.from('profiles').select().eq('id', uid).maybeSingle();
      if (profile != null) {
        _avatarUrl = profile['avatar_url'];
      }
      
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _businessNameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _businessNameController.text.trim();
    if (newName.isEmpty) {
      setState(() { _nameFeedback = 'Ingresa el nuevo nombre del negocio.'; _nameIsError = true; });
      return;
    }
    if (_tenantId == null) return;

    setState(() { _savingName = true; _nameFeedback = null; });
    try {
      await _db.from('tenants').update({'business_name': newName}).eq('id', _tenantId!);
      if (!mounted) return;
      setState(() {
        _savingName = false;
        _nameFeedback = 'Nombre actualizado correctamente.';
        _nameIsError  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingName = false;
        _nameFeedback = 'Error al guardar el nombre.';
        _nameIsError  = true;
      });
    }
  }

  Future<void> _saveColor() async {
    if (_tenantId == null) return;
    setState(() => _savingColor = true);
    
    // Convertir Color a HEX (#RRGGBB)
    final hex = '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    
    try {
      await _db.from('tenants').update({'primary_color': hex}).eq('id', _tenantId!);
      if (mounted) {
        TenantThemeProvider.of(context).updateColor(_selectedColor);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Color actualizado exitosamente')));
      }
    } catch (e) {
      print('Error en _saveColor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar el color')));
      }
    } finally {
      if (mounted) setState(() => _savingColor = false);
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _linkController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('¡Link copiado al portapapeles!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (xfile == null) return;

    setState(() => _savingPhoto = true);
    try {
      final bytes = await xfile.readAsBytes();
      final ext = xfile.name.split('.').last;
      final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      await _db.storage.from('avatars').uploadBinary(path, bytes);
      final publicUrl = _db.storage.from('avatars').getPublicUrl(path);
      
      await _db.from('profiles').update({'avatar_url': publicUrl}).eq('id', uid);
      
      if (mounted) {
        setState(() {
          _avatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
          _savingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada exitosamente')));
      }
    } catch (e) {
      print('Error en _pickAndUploadPhoto: $e');
      if (mounted) {
        setState(() => _savingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir la foto de perfil')));
      }
    }
  }

  Future<void> _pickAndUploadLogo() async {
    if (_tenantId == null) return;
    
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (xfile == null) return;

    setState(() => _savingLogo = true);
    try {
      final bytes = await xfile.readAsBytes();
      final ext = xfile.name.split('.').last;
      final path = '$_tenantId/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      await _db.storage.from('logos').uploadBinary(path, bytes);
      final publicUrl = _db.storage.from('logos').getPublicUrl(path);
      
      await _db.from('tenants').update({'logo_url': publicUrl}).eq('id', _tenantId!);
      
      if (mounted) {
        setState(() {
          _logoUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
          _savingLogo = false;
        });
        TenantThemeProvider.of(context).updateLogo(_logoUrl!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo actualizado exitosamente')));
      }
    } catch (e) {
      print('Error en _pickAndUploadLogo: $e');
      if (mounted) {
        setState(() => _savingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir el logo del negocio')));
      }
    }
  }

  Future<void> _generateAndDownloadQr() async {
    final url = _linkController.text;
    if (url.isEmpty) return;

    try {
      final doc = pw.Document();
      
      final qrImage = await QrPainter(
        data: url,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ).toImageData(200);

      if (qrImage == null) return;

      final imageProvider = pw.MemoryImage(qrImage.buffer.asUint8List());

      doc.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Escanea para visitar nuestra pagina', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 40),
                  pw.Image(imageProvider, width: 300, height: 300),
                  pw.SizedBox(height: 30),
                  pw.Text(url, style: pw.TextStyle(fontSize: 16, color: PdfColors.blue800)),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await doc.save(), filename: 'codigo_qr_negocio.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al generar el documento QR')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 24),

                    // ── Foto de perfil ──────────────────────
                    SectionCard(
                      title: 'Foto de perfil',
                      icon: Icons.person_outline_rounded,
                      subtitle: 'Visible en tu panel de gestión',
                      child: _buildPhotoSection(),
                    ),
                    const SizedBox(height: 16),

                    // ── Nombre del negocio ──────────────────
                    SectionCard(
                      title: 'Nombre del negocio',
                      icon: Icons.storefront_outlined,
                      subtitle: 'Aparece en tu página pública',
                      child: _buildNameSection(),
                    ),
                    const SizedBox(height: 16),

                    // ── Color de la interfaz ────────────────
                    SectionCard(
                      title: 'Color de la interfaz',
                      icon: Icons.palette_outlined,
                      subtitle: 'Personaliza el color de tu página',
                      child: _buildColorSection(),
                    ),
                    const SizedBox(height: 16),

                    // ── Logo ────────────────────────────────
                    SectionCard(
                      title: 'Logo del negocio',
                      icon: Icons.image_outlined,
                      subtitle: 'Aparece en el encabezado de tu página',
                      child: _buildLogoSection(),
                    ),
                    const SizedBox(height: 16),

                    // ── Link del sitio ──────────────────────
                    SectionCard(
                      title: 'Link de tu sitio',
                      icon: Icons.link_rounded,
                      subtitle: 'Compártelo o úsalo en Google Business',
                      child: _buildLinkSection(),
                    ),
                    const SizedBox(height: 16),

                    // ── QR ─────────────────────────────────
                    SectionCard(
                      title: 'Código QR',
                      icon: Icons.qr_code_2_rounded,
                      subtitle: 'Descarga el QR de tu página en PDF',
                      child: _buildQrSection(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'Ajustes',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.greyBorder),
        ),
      );

  Widget _buildPageHeader() => Row(
        children: [
          Container(width: 4, height: 28, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Personalización', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.black)),
              Text('Configura cómo se ve tu negocio', style: TextStyle(fontSize: 13, color: AppColors.greyText)),
            ],
          ),
        ],
      );

  // ── SECCIONES ──────────────────────────────────────────────

  Widget _buildPhotoSection() => Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.greyBorder,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.person_rounded, size: 36, color: AppColors.greyText) : null,
              ),
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_avatarUrl != null ? 'Foto de perfil subida' : 'Sin foto de perfil', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                const SizedBox(height: 2),
                const Text('JPG o PNG, máximo 2MB', style: TextStyle(fontSize: 12, color: AppColors.greyText)),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Cambiar foto',
                  onPressed: _pickAndUploadPhoto,
                  isLoading: _savingPhoto,
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildNameSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Nuevo nombre'),
          const SizedBox(height: 6),
          AppTextField(
            controller: _businessNameController,
            hint: 'Ej: Mi Restaurante',
            icon: Icons.storefront_outlined,
          ),
          if (_nameFeedback != null) ...[
            const SizedBox(height: 10),
            AppFeedbackBanner(message: _nameFeedback!, isError: _nameIsError),
          ],
          const SizedBox(height: 14),
          AppButton(label: 'Guardar nombre', onPressed: _saveName, isLoading: _savingName),
        ],
      );

  Widget _buildColorSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Color principal de tu página'),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.greyBorder, width: 2),
                  boxShadow: [
                    BoxShadow(color: _selectedColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  label: 'Elegir un color personalizado',
                  onPressed: _showColorPickerDialog,
                  fullWidth: false,
                  color: AppColors.white,
                  textColor: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(label: 'Aplicar color', onPressed: _saveColor, isLoading: _savingColor),
        ],
      );

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() => _selectedColor = color);
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaBorderRadius: BorderRadius.circular(10),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar', style: TextStyle(color: AppColors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoSection() => Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.greyBorder,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyBorder),
            ),
            child: _logoUrl != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_logoUrl!, fit: BoxFit.cover))
              : const Icon(Icons.image_outlined, color: AppColors.greyText, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_logoUrl != null ? 'Logo subido' : 'Sin logo', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black)),
                const SizedBox(height: 2),
                const Text('PNG con fondo transparente recomendado', style: TextStyle(fontSize: 12, color: AppColors.greyText)),
                const SizedBox(height: 10),
                AppButton(label: 'Subir logo', onPressed: _pickAndUploadLogo, isLoading: _savingLogo, fullWidth: false),
              ],
            ),
          ),
        ],
      );

  Widget _buildLinkSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Tu link único'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _linkController,
                  hint: '',
                  icon: Icons.link_rounded,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copiar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Al presionar Copiar, el link se guarda en tu portapapeles listo para compartir.',
            style: TextStyle(fontSize: 12, color: AppColors.greyText),
          ),
        ],
      );

  Widget _buildQrSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descarga el código QR de tu página en formato PDF para imprimirlo y colocarlo en tu local.',
            style: TextStyle(fontSize: 13, color: AppColors.greyText, height: 1.5),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Descargar QR en PDF',
            onPressed: _generateAndDownloadQr,
            color: AppColors.blue,
          ),
        ],
      );
}
