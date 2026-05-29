import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getPlatformPayments({String? profileId}) async {
    try {
      var query = _supabase.from('platform_payments').select('''
        id, concept, amount, status, payment_date, created_at,
        profiles:profile_id (business_name, email, role)
      ''');

      if (profileId != null) {
        query = query.eq('profile_id', profileId);
      }

      final res = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene el MRR (Monthly Recurring Revenue) estimado (Para el Admin)
  /// Suma de los pagos con estado 'paid' en los últimos 30 días
  static Future<double> calculateMRR() async {
    try {
      final res = await _supabase
          .from('platform_payments')
          .select('amount')
          .eq('status', 'paid')
          .gte('payment_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      
      double total = 0;
      for (var row in res) {
        total += (row['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  /// Simula el pago de un servicio (Suscripción o Presupuesto de Ads)
  static Future<bool> createPaymentRecord({
    required String profileId,
    required String concept,
    required double amount,
  }) async {
    try {
      await _supabase.from('platform_payments').insert({
        'profile_id': profileId,
        'concept': concept,
        'amount': amount,
        'status': 'paid', // Simulado
        'payment_date': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Llama a la función RPC get_tenant_profitability_report en Supabase (Solo para el Manager)
  static Future<Map<String, dynamic>?> getProfitabilityReport({
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _supabase.rpc('get_tenant_profitability_report', params: {
        'p_tenant_id': tenantId,
        'p_start_date': startDate.toUtc().toIso8601String(),
        'p_end_date': endDate.toUtc().toIso8601String(),
      });
      if (res != null && res is List && res.isNotEmpty) {
        return Map<String, dynamic>.from(res.first);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene los pedidos aprobados con sus detalles para análisis de rentabilidad (Para el Manager)
  static Future<List<Map<String, dynamic>>> getApprovedOrdersForAnalytics({
    required String tenantId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await _supabase
          .from('orders')
          .select('''
            id, total_amount, created_at, status,
            order_items (quantity, unit_price, unit_cost_price, products (name))
          ''')
          .eq('tenant_id', tenantId)
          .eq('status', 'approved')
          .gte('created_at', startDate.toUtc().toIso8601String())
          .lte('created_at', endDate.toUtc().toIso8601String())
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }
}
