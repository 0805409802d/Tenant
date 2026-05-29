import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/client_service.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/theme/tenant_theme_provider.dart';

class ManagementClientsScreen extends StatefulWidget {
  const ManagementClientsScreen({super.key});
  @override
  State<ManagementClientsScreen> createState() => _ManagementClientsScreenState();
}

class _ManagementClientsScreenState extends State<ManagementClientsScreen> {
  final _messageCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  bool _loading = true;
  bool _isWorker = false;
  String? _tenantId;
  bool _selectAll = false;
  List<bool> _selectedClients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredClients = _clients.where((c) {
        final profile = c['profiles'] ?? {};
        final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.toLowerCase();
        return name.contains(query);
      }).toList();
      _selectedClients = List<bool>.filled(_filteredClients.length, false);
      _selectAll = false;
    });
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);

    final tenantId = await TenantService.getCurrentUserTenantId();
    final isWorker = await TenantService.isCurrentUserWorker();
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _tenantId = tenantId;
    _isWorker = isWorker;

    final clients = await ClientService.getTenantClients(tenantId);

    if (!mounted) return;
    setState(() {
      _clients = clients;
      _filteredClients = clients;
      _selectedClients = List<bool>.filled(clients.length, false);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;
    setState(() {
      _selectAll = value;
      for (int i = 0; i < _selectedClients.length; i++) {
        _selectedClients[i] = value;
      }
    });
  }

  void _toggleClient(int index, bool? value) {
    if (value == null) return;
    setState(() {
      _selectedClients[index] = value;
      _selectAll = !_selectedClients.contains(false);
    });
  }

  void _showClientDetails(Map<String, dynamic> clientRow) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientDetailsSheet(
        clientRow: clientRow,
        tenantId: _tenantId!,
        isWorker: _isWorker,
        onSaved: _loadClients,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = TenantThemeProvider.of(context).primaryColor;
    return AppScaffold(
      title: 'Clientes',
      accentColor: AppColors.accentPurple,
      body: _loading
          ? const Center(child: AppShimmerLoader(height: 100, borderRadius: 16))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: 'Clientes y Mensajería', icon: Icons.people_alt_outlined, color: AppColors.primary),
                    const SizedBox(height: 16),

                    // Caja de mensaje masivo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: themeColor.withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: themeColor.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(Icons.chat_rounded, color: themeColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Mensajería Masiva (Próximamente)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _messageCtrl,
                            hint: 'Escribe un mensaje para los clientes seleccionados...',
                            icon: Icons.chat_bubble_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 12,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _selectAll,
                                    onChanged: _toggleSelectAll,
                                    activeColor: themeColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const Text('Seleccionar todos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                ],
                              ),
                              AppButton(
                                label: 'Enviar',
                                onPressed: () {},
                                icon: Icons.send_rounded,
                                fullWidth: false,
                                color: themeColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Barra de Búsqueda
                    AppTextField(
                      controller: _searchCtrl,
                      hint: 'Buscar cliente...',
                      icon: Icons.search_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Lista de clientes
                    if (_filteredClients.isEmpty)
                      AppEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: _clients.isEmpty ? 'Aún no tienes clientes' : 'No se encontraron resultados',
                        subtitle: _clients.isEmpty ? 'Tus clientes aparecerán aquí cuando se registren.' : 'Intenta con otro nombre de búsqueda.',
                        iconColor: AppColors.accentPurple,
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredClients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final clientRow = _filteredClients[index];
                          final c = clientRow['profiles'] ?? {};
                          final name = '${c['first_name'] ?? 'Anónimo'} ${c['last_name'] ?? ''}'.trim();
                          final phone = c['phone'] ?? 'Sin número';
                          final isCreditApproved = clientRow['is_credit_approved'] ?? false;
                          final currentDebt = (clientRow['current_debt'] as num? ?? 0.0).toDouble();

                          return _AdminClientCard(
                            name: name,
                            phone: phone,
                            isSelected: _selectedClients[index],
                            isCreditApproved: isCreditApproved,
                            currentDebt: currentDebt,
                            onChanged: (v) => _toggleClient(index, v),
                            onTap: () => _showClientDetails(clientRow),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _AdminClientCard extends StatelessWidget {
  const _AdminClientCard({
    required this.name,
    required this.phone,
    required this.isSelected,
    required this.isCreditApproved,
    required this.currentDebt,
    required this.onChanged,
    required this.onTap,
  });

  final String name, phone;
  final bool isSelected;
  final bool isCreditApproved;
  final double currentDebt;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeColor = TenantThemeProvider.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? themeColor : AppColors.border),
          boxShadow: [if (!isSelected) BoxShadow(color: AppColors.overlay(0.01), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected, 
              onChanged: onChanged, 
              activeColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            AppAvatar(name: name, radius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name, 
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCreditApproved)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Fiado Activo', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Spacer(),
                      if (currentDebt > 0)
                        Text(
                          'Debe: \$${currentDebt.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.error),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ficha de Detalle de Cliente y Libro de Crédito
class _ClientDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> clientRow;
  final String tenantId;
  final bool isWorker;
  final VoidCallback onSaved;

  const _ClientDetailsSheet({
    required this.clientRow,
    required this.tenantId,
    required this.isWorker,
    required this.onSaved,
  });

  @override
  State<_ClientDetailsSheet> createState() => _ClientDetailsSheetState();
}

class _ClientDetailsSheetState extends State<_ClientDetailsSheet> {
  bool _isApproved = false;
  final _limitCtrl = TextEditingController();
  List<Map<String, dynamic>> _ledger = [];
  bool _loadingLedger = true;
  bool _savingSettings = false;
  double _currentDebt = 0.0;
  double _creditLimit = 0.0;

  @override
  void initState() {
    super.initState();
    _isApproved = widget.clientRow['is_credit_approved'] ?? false;
    _currentDebt = (widget.clientRow['current_debt'] as num? ?? 0.0).toDouble();
    _creditLimit = (widget.clientRow['credit_limit'] as num? ?? 0.0).toDouble();
    _limitCtrl.text = _creditLimit.toStringAsFixed(2);
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    setState(() => _loadingLedger = true);
    final clientId = widget.clientRow['profile_id'];
    final list = await CreditService.getCreditLedger(tenantId: widget.tenantId, clientId: clientId);
    if (mounted) {
      setState(() {
        _ledger = list;
        _loadingLedger = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final limit = double.tryParse(_limitCtrl.text.trim()) ?? 0.0;
    setState(() => _savingSettings = true);
    final ok = await CreditService.updateClientCreditSettings(
      tenantId: widget.tenantId,
      clientId: widget.clientRow['profile_id'],
      isApproved: _isApproved,
      limit: limit,
    );
    if (mounted) {
      setState(() => _savingSettings = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración de crédito guardada con éxito.')),
        );
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar configuración de crédito.')),
        );
      }
    }
  }

  void _showAbonoDialog() {
    showDialog(
      context: context,
      builder: (c) => _AbonoDialog(
        tenantId: widget.tenantId,
        clientId: widget.clientRow['profile_id'],
        onSuccess: () {
          _loadLedger();
          // Actualizar deuda actual de forma reactiva
          CreditService.getClientCreditInfo(
            tenantId: widget.tenantId,
            clientId: widget.clientRow['profile_id'],
          ).then((info) {
            if (info != null && mounted) {
              setState(() {
                _currentDebt = (info['current_debt'] as num? ?? 0.0).toDouble();
              });
              widget.onSaved();
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TenantThemeProvider.of(context).primaryColor;
    final c = widget.clientRow['profiles'] ?? {};
    final name = '${c['first_name'] ?? 'Anónimo'} ${c['last_name'] ?? ''}'.trim();
    final phone = c['phone'] ?? 'Sin teléfono';
    final email = c['email'] ?? 'Sin correo';

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
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client info card (Header)
                  Row(
                    children: [
                      AppAvatar(name: name, radius: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Tlf: $phone • $email', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Credit metrics
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.error.withOpacity(0.08), AppColors.error.withOpacity(0.12)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.error.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DEUDA ACTUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Text(
                                '\$${_currentDebt.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor.withOpacity(0.08), primaryColor.withOpacity(0.12)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LÍMITE MÁXIMO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Text(
                                '\$${_creditLimit.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Credit config section (Only visible for Manager)
                  if (!widget.isWorker) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AJUSTES DE CRÉDITO (MANAGER)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Habilitar crédito de confianza', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Switch.adaptive(
                                value: _isApproved,
                                onChanged: (val) => setState(() => _isApproved = val),
                                activeColor: AppColors.success,
                              ),
                            ],
                          ),
                          if (_isApproved) ...[
                            const SizedBox(height: 12),
                            const AppLabel('Límite de crédito autorizado (\$)'),
                            const SizedBox(height: 6),
                            AppTextField(
                              controller: _limitCtrl,
                              hint: '0.00',
                              icon: Icons.attach_money_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Guardar Ajustes',
                            onPressed: _saveSettings,
                            isLoading: _savingSettings,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Registrar Abono button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Historial de Créditos',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAbonoDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.payment_rounded, size: 18),
                        label: const Text('Registrar Abono', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ledger / Audit log
                  if (_loadingLedger)
                    const Center(child: CircularProgressIndicator())
                  else if (_ledger.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: const Text('Sin transacciones en la cuenta corriente.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ledger.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final tx = _ledger[i];
                        final amount = (tx['amount'] as num).toDouble();
                        final isAbono = amount < 0; // Abono is negative
                        final notes = tx['notes'] as String? ?? '';
                        final date = DateTime.parse(tx['created_at']).toLocal();
                        final userProfile = tx['profiles'] ?? {};
                        final userName = userProfile['owner_name'] ?? userProfile['first_name'] ?? 'Sistema';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isAbono ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isAbono ? 'Abono / Pago' : 'Cargo / Fiado',
                                            style: TextStyle(
                                              color: isAbono ? AppColors.success : AppColors.error,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(notes, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                    ],
                                    const SizedBox(height: 4),
                                    Text('Reg. por: $userName', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              Text(
                                isAbono 
                                  ? '+\$${amount.abs().toStringAsFixed(2)}' 
                                  : '-\$${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: isAbono ? AppColors.success : AppColors.error,
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
          ),
        ],
      ),
    );
  }
}

// Diálogo para registrar Abono
class _AbonoDialog extends StatefulWidget {
  final String tenantId;
  final String clientId;
  final VoidCallback onSuccess;

  const _AbonoDialog({required this.tenantId, required this.clientId, required this.onSuccess});

  @override
  State<_AbonoDialog> createState() => _AbonoDialogState();
}

class _AbonoDialogState extends State<_AbonoDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido mayor a 0.')));
      return;
    }

    setState(() => _submitting = true);
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    // Un abono/pago va en negativo (-) para disminuir la deuda.
    final ok = await CreditService.registerCreditTransaction(
      tenantId: widget.tenantId,
      clientId: widget.clientId,
      amount: -amount,
      transactionType: 'payment',
      notes: _notesCtrl.text.trim().isEmpty ? 'Abono a cuenta corriente' : _notesCtrl.text.trim(),
      createdBy: currentUserId,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abono registrado con éxito.')));
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al registrar el abono.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Registrar Abono', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Monto abonado en efectivo o transferencia (\$)'),
          const SizedBox(height: 6),
          AppTextField(
            controller: _amountCtrl,
            hint: 'Ej. 50.00',
            icon: Icons.attach_money_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          const AppLabel('Comentarios / Nro de Transferencia'),
          const SizedBox(height: 6),
          AppTextField(
            controller: _notesCtrl,
            hint: 'Ej. Transferencia N Banco Pichincha 881',
            icon: Icons.comment_outlined,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _submitting 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
            : const Text('Guardar Abono', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

