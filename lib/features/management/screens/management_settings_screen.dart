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
import '../../../core/services/tenant_service.dart';
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

  static const _palette = [
    Color(0xFF1E6BFF), Color(0xFF6C47FF), Color(0xFF00B37E),
    Color(0xFFE53935), Color(0xFFFF8C00), Color(0xFF0097A7),
    Color(0xFF0A0A0A),
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

      final tenant = await TenantService.getCurrentUserTenant();
      if (tenant != null) {
        _tenantId = tenant['id'];
        _businessNameController.text = tenant['business_name'] ?? '';
        _linkController.text = tenant['link_url'] ?? 'https://${tenant['slug']}.quinindews.com';
        
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

  Future<void> _saveColor(Color color) async {
    if (_tenantId == null) return;
    setState(() {
      _selectedColor = color;
      _savingColor = true;
    });
    
    final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    
    try {
      await _db.from('tenants').update({'primary_color': hex}).eq('id', _tenantId!);
      if (mounted) {
        TenantThemeProvider.of(context).updateColor(color);
      }
    } catch (e) {
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
        backgroundColor: AppColors.textPrimary,
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
      final ext = xfile.name.split('.').last.toLowerCase();
      final finalExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'png';
      final contentType = finalExt == 'png' ? 'image/png' : 'image/jpeg';
      final path = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$finalExt';
      
      await _db.storage.from('avatars').uploadBinary(
        path, 
        bytes, 
        fileOptions: FileOptions(contentType: contentType),
      );
      final publicUrl = _db.storage.from('avatars').getPublicUrl(path);
      
      await _db.from('profiles').update({'avatar_url': publicUrl}).eq('id', uid);
      
      if (mounted) {
        setState(() {
          _avatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
          _savingPhoto = false;
        });
      }
    } catch (e) {
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
      final ext = xfile.name.split('.').last.toLowerCase();
      final finalExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'png';
      final contentType = finalExt == 'png' ? 'image/png' : 'image/jpeg';
      final path = '$_tenantId/logo_${DateTime.now().millisecondsSinceEpoch}.$finalExt';
      
      await _db.storage.from('logos').uploadBinary(
        path, 
        bytes, 
        fileOptions: FileOptions(contentType: contentType),
      );
      final publicUrl = _db.storage.from('logos').getPublicUrl(path);
      
      await _db.from('tenants').update({'logo_url': publicUrl}).eq('id', _tenantId!);
      
      if (mounted) {
        setState(() {
          _logoUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
          _savingLogo = false;
        });
        TenantThemeProvider.of(context).updateLogo(_logoUrl!);
      }
    } catch (e) {
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
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Ajustes',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)
        ),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: AppShimmerLoader(height: 120, borderRadius: 16),
              )),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: 24),

                    SectionCard(
                      title: 'Nombre del negocio',
                      icon: Icons.storefront_outlined,
                      subtitle: 'Aparece en tu página pública',
                      child: _buildNameSection(),
                    ),
                    const SizedBox(height: 16),

                    SectionCard(
                      title: 'Color de la interfaz',
                      icon: Icons.palette_outlined,
                      subtitle: 'Personaliza el color de tu página',
                      child: _buildColorSection(),
                    ),
                    const SizedBox(height: 16),

                    SectionCard(
                      title: 'Logo del negocio',
                      icon: Icons.image_outlined,
                      subtitle: 'Aparece en el encabezado de tu página',
                      child: _buildLogoSection(),
                    ),
                    const SizedBox(height: 16),

                    SectionCard(
                      title: 'Link y Código QR',
                      icon: Icons.link_rounded,
                      subtitle: 'Comparte tu página con tus clientes',
                      child: _buildLinkAndQrSection(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildPhotoSection() => Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndUploadPhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                      image: _avatarUrl != null ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover) : null,
                      color: AppColors.surface,
                    ),
                    child: _avatarUrl == null ? const Icon(Icons.person_rounded, size: 40, color: AppColors.textSecondary) : null,
                  ),
                  if (_savingPhoto)
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.overlay(0.5)),
                      child: const Center(child: CircularProgressIndicator(color: AppColors.white)),
                    )
                  else
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.overlay(0.3)),
                      child: const Center(child: Icon(Icons.camera_alt_outlined, color: AppColors.white, size: 28)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Toca para cambiar tu foto de perfil', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _buildNameSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _businessNameController,
            hint: 'Ej: Mi Restaurante',
            icon: Icons.storefront_outlined,
          ),
          if (_nameFeedback != null) ...[
            const SizedBox(height: 10),
            AppFeedbackBanner(message: _nameFeedback!, isError: _nameIsError),
          ],
          const SizedBox(height: 16),
          AppButton(label: 'Guardar nombre', onPressed: _saveName, isLoading: _savingName),
        ],
      );

  Widget _buildColorSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._palette.map((color) => GestureDetector(
                    onTap: () => _saveColor(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor.value == color.value ? AppColors.textPrimary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (_selectedColor.value == color.value)
                            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: _selectedColor.value == color.value
                          ? const Icon(Icons.check_rounded, color: AppColors.white, size: 20)
                          : null,
                    ),
                  )),
              GestureDetector(
                onTap: _showColorPickerDialog,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: const Icon(Icons.colorize_rounded, color: AppColors.textSecondary, size: 20),
                ),
              ),
            ],
          ),
        ],
      );

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          title: const Text('Color personalizado', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (c) => tempColor = c,
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaBorderRadius: BorderRadius.circular(10),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveColor(tempColor);
              },
              style: ElevatedButton.styleFrom(backgroundColor: TenantThemeProvider.of(context).primaryColor, foregroundColor: AppColors.white),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoSection() => Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              image: _logoUrl != null ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.contain) : null,
            ),
            child: _logoUrl == null ? const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 32) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_logoUrl != null ? 'Logo subido' : 'Sin logo', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('PNG transparente recomendado', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Subir logo',
                  onPressed: _pickAndUploadLogo,
                  isLoading: _savingLogo,
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildLinkAndQrSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: TenantThemeProvider.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.copy_rounded, color: TenantThemeProvider.of(context).primaryColor),
                  onPressed: _copyLink,
                  tooltip: 'Copiar link',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_linkController.text.isNotEmpty)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 12)],
                    ),
                    child: QrImageView(
                      data: _linkController.text,
                      version: QrVersions.auto,
                      size: 160.0,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.black),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Descargar QR',
                    onPressed: _generateAndDownloadQr,
                    icon: Icons.download_rounded,
                  ),
                ],
              ),
            ),
        ],
      );
}
