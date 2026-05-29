import 'package:flutter/material.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/client_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_components.dart';
import '../../../shared/widgets/app_widgets.dart';

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
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

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

  @override
  Widget build(BuildContext context) {
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
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.chat_rounded, color: AppColors.primary, size: 20),
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
                                activeColor: AppColors.primary,
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
                      final c = _filteredClients[index]['profiles'] ?? {};
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
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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
    required this.onChanged,
  });

  final String name, phone;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        boxShadow: [if (!isSelected) BoxShadow(color: AppColors.overlay(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected, 
            onChanged: onChanged, 
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          AppAvatar(name: name, radius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
