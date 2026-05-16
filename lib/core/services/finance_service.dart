import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceService {
  static final _supabase = Supabase.instance.client;

  /// Obtiene los pagos realizados a la plataforma (Para el Admin o Usuario)
  /// Si se pasa profileId, obtiene los de ese usuario. Si es Admin, puede mandar null.
  static Future<List<Map<String, dynamic>>> getPlatformPayments({String? profileId}) async {
    try {
      var query = _supabase.from('platform_payments').select('''
        id, concept, amount, status, payment_date, created_at,
        profiles:profile_id (business_name, email, role)
      ''').order('created_at', ascending: false);

      if (profileId != null) {
        query = query.eq('profile_id', profileId);
      }

      final res = await query;
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
}
