import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/credit_service.dart';
import '../../../shared/widgets/app_widgets.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key, required this.tenantSlug});
  final String tenantSlug;

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen>
    with SingleTickerProviderStateMixin {
  Color _primaryColor = const Color(0xFF0097A7);
  bool _loadingTheme = true;
  bool _savingPhoto = false;

  Map<String, dynamic>? _creditInfo;
  List<Map<String, dynamic>> _creditLedger = [];
  String? _tenantId;
  String _instructions = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final db = Supabase.instance.client;
      final res = await db
          .from('tenants')
          .select('id, primary_color, manual_payment_instructions')
          .eq('slug', widget.tenantSlug)
          .maybeSingle();

      if (res != null) {
        _tenantId = res['id'] as String?;
        _instructions = res['manual_payment_instructions'] as String? ?? '';
        if (res['primary_color'] != null) {
          final hex = (res['primary_color'] as String).replaceAll('#', '');
          _primaryColor = Color(int.parse('FF$hex', radix: 16));
        }
      }

      final uid = db.auth.currentUser?.id;
      if (uid != null && _tenantId != null) {
        _creditInfo = await CreditService.getClientCreditInfo(tenantId: _tenantId!, clientId: uid);
        _creditLedger = await CreditService.getCreditLedger(tenantId: _tenantId!, clientId: uid);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTheme) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        body: Center(child: CircularProgressIndicator(color: AppColors.textSecondary, strokeWidth: 2)),
      );
    }

    final double currentDebt = (_creditInfo?['current_debt'] as num? ?? 0.0).toDouble();
    final double creditLimit = (_creditInfo?['credit_limit'] as num? ?? 0.0).toDouble();
    final bool isApproved = _creditInfo?['is_credit_approved'] ?? false;

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
              context.go('/t/${widget.tenantSlug}');
            }
          },
        ),
        title: const Text('Ajustes de cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                Container(width: 4, height: 28, decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text('Personaliza cómo te ven los negocios', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 24),

              // Foto de perfil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.person_outline_rounded, color: _primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Foto de perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text('Visible en tus pedidos', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Avatar centrado
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: AppColors.surfaceGrey,
                            child: const Icon(Icons.person_rounded, size: 52, color: AppColors.textSecondary),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: GestureDetector(
                              onTap: () {}, // TODO: image picker
                              child: Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.white, width: 3),
                                  boxShadow: [BoxShadow(color: AppColors.overlay(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                                ),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'JPG o PNG, máximo 2MB',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(label: 'Cambiar foto', onPressed: () {}, isLoading: _savingPhoto, color: _primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==========================================
              // SECCIÓN: CUENTA CORRIENTE / LIBRO DE CRÉDITO
              // ==========================================
              Row(children: [
                Container(width: 4, height: 28, decoration: BoxDecoration(color: AppColors.accentPurple, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Mi Cuenta Corriente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text('Estado de crédito de confianza y abonos', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.overlay(0.04), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentPurple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Crédito de Confianza', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text(isApproved ? 'Línea de crédito autorizada' : 'Sin línea de crédito activa', style: TextStyle(fontSize: 13, color: isApproved ? AppColors.success : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Debt vs Limit meters
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SALDO DEUDOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                Text(
                                  '\$${currentDebt.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _primaryColor.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('LÍMITE MÁXIMO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                Text(
                                  '\$${creditLimit.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Instructions Glassmorphism Card
                    if (_instructions.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accentPurple.withOpacity(0.06), AppColors.primary.withOpacity(0.03)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accentPurple.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.info_outline_rounded, color: AppColors.accentPurple, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  '¿Cómo realizar un abono o pago?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Puedes transferir el monto adeudado utilizando las siguientes coordenadas bancarias del negocio. Una vez hecho, envía el comprobante a su WhatsApp comercial.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                              width: double.infinity,
                              child: Text(
                                _instructions,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // History list
                    const Text('Historial de Transacciones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),

                    if (_creditLedger.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: const Text('No registras compras ni abonos aún.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _creditLedger.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final tx = _creditLedger[i];
                          final amount = (tx['amount'] as num).toDouble();
                          final isPayment = amount < 0;
                          final date = DateTime.parse(tx['created_at']).toLocal();
                          final notes = tx['notes'] as String? ?? '';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPayment ? 'Abono / Pago recibido' : 'Compra / Cargo fiado',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isPayment ? AppColors.success : AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(notes, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                                    ],
                                  ],
                                ),
                                Text(
                                  isPayment ? '-\$${amount.abs().toStringAsFixed(2)}' : '+\$${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isPayment ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
