import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/client_service.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementClientsScreen extends StatefulWidget {
  const ManagementClientsScreen({super.key});
  @override
  State<ManagementClientsScreen> createState() => _ManagementClientsScreenState();
}

class _ManagementClientsScreenState extends State<ManagementClientsScreen> {
  final _db = Supabase.instance.client;
  final _messageCtrl = TextEditingController();
  
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;
  bool _selectAll = false;
  List<bool> _selectedClients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    
    final tenant = await _db.from('tenants').select('id').eq('owner_id', uid).maybeSingle();
    if (tenant == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    
    final clients = await ClientService.getTenantClients(tenant['id']);
    
    if (!mounted) return;
    setState(() {
      _clients = clients;
      _selectedClients = List<bool>.filled(clients.length, false);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Clientes',
      accentColor: AppColors.accentPurple,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Clientes y Mensajería', icon: Icons.people_alt_outlined, color: AppColors.primary),
                const SizedBox(height: 16),

                // Caja de mensaje masivo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mensajería por WhatsApp (Próximamente)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDeep)),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _messageCtrl,
                        hint: 'Escribe un mensaje para múltiples clientes...',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _selectAll,
                                onChanged: _toggleSelectAll,
                                activeColor: AppColors.primary,
                              ),
                              const Text('Seleccionar todos', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Enviar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de clientes
                if (_clients.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text('Aún no tienes clientes registrados.', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _clients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = _clients[index]['profiles'] ?? {};
                      final name = '${c['first_name'] ?? 'Anónimo'} ${c['last_name'] ?? ''}'.trim();
                      final phone = c['phone'] ?? 'Sin número';

                      return _AdminClientCard(
                        name: name,
                        phone: phone,
                        isSelected: _selectedClients[index],
                        onChanged: (v) => _toggleClient(index, v),
                      );
                    },
                  ),
              ],
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
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
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
    required this.onChanged,
  });

  final String name, phone;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryTint : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primaryBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Checkbox(value: isSelected, onChanged: onChanged, activeColor: AppColors.primary),
          AppAvatar(name: name, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
