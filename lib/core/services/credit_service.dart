import 'package:supabase_flutter/supabase_flutter.dart';

class CreditService {
  static final _supabase = Supabase.instance.client;

  /// Obtiene los datos de límite y deuda corriente de un cliente en una tienda
  static Future<Map<String, dynamic>?> getClientCreditInfo({
    required String tenantId,
    required String clientId,
  }) async {
    try {
      final res = await _supabase
          .from('tenant_clients')
          .select('*, profiles:profile_id (first_name, last_name, email, phone)')
          .eq('tenant_id', tenantId)
          .eq('profile_id', clientId)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Permite al dueño (Manager) actualizar la configuración del crédito de un cliente
  static Future<bool> updateClientCreditSettings({
    required String tenantId,
    required String clientId,
    required bool isApproved,
    required double limit,
  }) async {
    try {
      await _supabase
          .from('tenant_clients')
          .update({
            'is_credit_approved': isApproved,
            'credit_limit': limit,
          })
          .eq('tenant_id', tenantId)
          .eq('profile_id', clientId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Obtiene el historial del libro de crédito para un cliente específico
  static Future<List<Map<String, dynamic>>> getCreditLedger({
    required String tenantId,
    required String clientId,
  }) async {
    try {
      final res = await _supabase
          .from('client_credit_ledger')
          .select('*, profiles:created_by (owner_name, first_name)')
          .eq('tenant_id', tenantId)
          .eq('client_id', clientId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Registra una nueva transacción en el libro de créditos (cargo por compra o abono de dinero)
  /// El trigger update_tenant_client_debt() en Supabase actualizará automáticamente la current_debt del cliente.
  static Future<bool> registerCreditTransaction({
    required String tenantId,
    required String clientId,
    required double amount, // Positivo (+) para compras al fiado, Negativo (-) para abonos/pagos
    required String transactionType, // 'charge', 'payment', 'adjustment'
    String? referenceOrderId,
    String? notes,
    required String createdBy,
  }) async {
    try {
      await _supabase.from('client_credit_ledger').insert({
        'tenant_id': tenantId,
        'client_id': clientId,
        'amount': amount,
        'transaction_type': transactionType,
        'reference_order_id': referenceOrderId,
        'notes': notes,
        'created_by': createdBy,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Obtiene la suma total de las cuentas por cobrar actuales del tenant (Para el Dashboard del Manager)
  static Future<double> getTotalAccountsReceivable(String tenantId) async {
    try {
      final res = await _supabase
          .from('tenant_clients')
          .select('current_debt')
          .eq('tenant_id', tenantId);

      double total = 0.0;
      for (var row in res) {
        total += (row['current_debt'] as num? ?? 0).toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  /// Obtiene el listado de todos los clientes con saldo deudor actual ordenados de mayor a menor deuda
  static Future<List<Map<String, dynamic>>> getClientsInDebt(String tenantId) async {
    try {
      final res = await _supabase
          .from('tenant_clients')
          .select('*, profiles:profile_id (first_name, last_name, email, phone)')
          .eq('tenant_id', tenantId)
          .gt('current_debt', 0)
          .order('current_debt', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
