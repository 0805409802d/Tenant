import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  static final _supabase = Supabase.instance.client;

  /// Crea una nueva orden desde el flujo del cliente
  static Future<bool> createOrder({
    required String tenantId,
    required String clientId,
    required double totalAmount,
    required List<Map<String, dynamic>> items, // [{'product_id': id, 'quantity': q, 'unit_price': p}]
  }) async {
    try {
      // 1. Crear la orden principal
      final orderRes = await _supabase.from('orders').insert({
        'tenant_id': tenantId,
        'client_id': clientId,
        'total_amount': totalAmount,
        'status': 'pending',
      }).select('id').single();

      final orderId = orderRes['id'];

      // 2. Insertar los items
      final orderItems = items.map((i) => {
        'order_id': orderId,
        'product_id': i['product_id'],
        'quantity': i['quantity'],
        'unit_price': i['unit_price'],
      }).toList();

      await _supabase.from('order_items').insert(orderItems);

      // 3. Vincular al cliente con la tienda (si no estaba ya)
      // Como RLS lo permite (con unique constraint maneja posibles errores)
      try {
        await _supabase.from('tenant_clients').insert({
          'tenant_id': tenantId,
          'profile_id': clientId,
        });
      } catch (_) {
        // Ignorar si ya existía el registro
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los pedidos de una tienda (Para el Manager)
  static Future<List<Map<String, dynamic>>> getOrdersForTenant(String tenantId) async {
    try {
      final res = await _supabase
          .from('orders')
          .select('''
            id, status, total_amount, created_at,
            profiles:client_id (first_name, last_name, phone)
          ''')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene los detalles de los items de un pedido
  static Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final res = await _supabase
          .from('order_items')
          .select('''
            quantity, unit_price,
            products (name)
          ''')
          .eq('order_id', orderId);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Actualiza el estado del pedido (Aprobar/Rechazar por el Manager)
  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase.from('orders').update({'status': status}).eq('id', orderId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene los pedidos de un cliente específico
  static Future<List<Map<String, dynamic>>> getClientOrders(String clientId) async {
    try {
      final res = await _supabase
          .from('orders')
          .select('''
            id, status, total_amount, created_at,
            tenants:tenant_id (business_name)
          ''')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }
}
