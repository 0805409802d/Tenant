import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;

  /// Obtiene todos los productos activos de un tenant (Para el cliente público)
  static Future<List<Map<String, dynamic>>> getProductsByTenant(String tenantId) async {
    try {
      final res = await _supabase
          .from('products')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene un producto individual por su ID
  static Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final res = await _supabase
          .from('products')
          .select('*, tenants:tenant_id (business_name, slug, primary_color, logo_url)')
          .eq('id', productId)
          .maybeSingle();
      return res;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todos los productos de un tenant (Para el Manager, incluye inactivos)
  static Future<List<Map<String, dynamic>>> getAllProductsForManager(String tenantId) async {
    try {
      final res = await _supabase
          .from('products')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Crea un nuevo producto
  static Future<bool> createProduct({
    required String tenantId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    int stockQuantity = 0,
    int minStockAlert = 5,
    bool trackInventory = true,
    double costPrice = 0.0,
  }) async {
    try {
      await _supabase.from('products').insert({
        'tenant_id': tenantId,
        'name': name,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'stock_quantity': stockQuantity,
        'min_stock_alert': minStockAlert,
        'track_inventory': trackInventory,
        'cost_price': costPrice,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza un producto existente
  static Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('products').update(updates).eq('id', productId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Elimina un producto lógicamente (o físicamente si prefieres)
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
