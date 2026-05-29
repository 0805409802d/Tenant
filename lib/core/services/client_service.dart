import 'package:supabase_flutter/supabase_flutter.dart';

class ClientService {
  static final _supabase = Supabase.instance.client;

  /// Obtiene la lista de clientes vinculados a una tienda (Para el Manager)
  static Future<List<Map<String, dynamic>>> getTenantClients(String tenantId) async {
    try {
      final res = await _supabase
          .from('tenant_clients')
          .select('''
            created_at,
            profile_id,
            is_credit_approved,
            credit_limit,
            current_debt,
            profiles:profile_id (id, first_name, last_name, email, phone)
          ''')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene el perfil de un solo cliente
  static Future<Map<String, dynamic>?> getClientProfile(String clientId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', clientId)
          .maybeSingle();
      return res;
    } catch (e) {
      return null;
    }
  }
}
