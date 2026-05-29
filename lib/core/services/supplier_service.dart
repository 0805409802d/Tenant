import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierService {
  static final _supabase = Supabase.instance.client;

  /// Obtiene la lista de todos los proveedores activos de un tenant
  static Future<List<Map<String, dynamic>>> getSuppliers(String tenantId) async {
    try {
      final res = await _supabase
          .from('suppliers')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Crea un nuevo proveedor
  static Future<bool> createSupplier({
    required String tenantId,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
  }) async {
    try {
      await _supabase.from('suppliers').insert({
        'tenant_id': tenantId,
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Actualiza los datos de un proveedor
  static Future<bool> updateSupplier(String supplierId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('suppliers').update(updates).eq('id', supplierId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina o desactiva lógicamente un proveedor
  static Future<bool> deleteSupplier(String supplierId) async {
    try {
      await _supabase.from('suppliers').update({'is_active': false}).eq('id', supplierId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Obtiene el historial de compras/reabastecimientos de un tenant
  static Future<List<Map<String, dynamic>>> getPurchases(String tenantId) async {
    try {
      final res = await _supabase
          .from('supplier_purchases')
          .select('*, suppliers:supplier_id (name, phone)')
          .eq('tenant_id', tenantId)
          .order('purchase_date', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Obtiene los detalles y productos asociados a una compra
  static Future<List<Map<String, dynamic>>> getPurchaseItems(String purchaseId) async {
    try {
      final res = await _supabase
          .from('purchase_items')
          .select('*, products:product_id (name, cost_price)')
          .eq('purchase_id', purchaseId);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  /// Registra una compra e incrementa el stock de cada producto usando Costo Promedio Ponderado
  static Future<bool> registerPurchase({
    required String tenantId,
    required String? supplierId,
    required double totalAmount,
    required String? notes,
    required String registeredBy,
    required List<Map<String, dynamic>> items, // {product_id, quantity, cost_price}
  }) async {
    try {
      // 1. Insertar cabecera de la compra
      final purchaseRow = await _supabase.from('supplier_purchases').insert({
        'tenant_id': tenantId,
        'supplier_id': supplierId,
        'total_amount': totalAmount,
        'notes': notes,
        'registered_by': registeredBy,
      }).select('id').single();

      final purchaseId = purchaseRow['id'] as String;

      // 2. Procesar cada ítem comprado
      for (var item in items) {
        final productId = item['product_id'] as String;
        final buyQty = item['quantity'] as int;
        final buyCost = (item['cost_price'] as num).toDouble();

        // A. Insertar en purchase_items
        await _supabase.from('purchase_items').insert({
          'purchase_id': purchaseId,
          'product_id': productId,
          'quantity': buyQty,
          'cost_price': buyCost,
        });

        // B. Obtener datos actuales del producto para calcular el Costo Promedio Ponderado
        final currentProd = await _supabase
            .from('products')
            .select('stock_quantity, cost_price, track_inventory')
            .eq('id', productId)
            .maybeSingle();

        if (currentProd != null) {
          final currentStock = currentProd['stock_quantity'] as int? ?? 0;
          final currentCost = (currentProd['cost_price'] as num? ?? 0.0).toDouble();
          final trackInventory = currentProd['track_inventory'] as bool? ?? true;

          // Calcular Costo Promedio Ponderado
          double newCost = buyCost;
          final totalStock = currentStock + buyQty;
          if (totalStock > 0) {
            newCost = ((currentStock * currentCost) + (buyQty * buyCost)) / totalStock;
          }

          // C. Actualizar producto (incrementar stock y actualizar precio de costo promedio)
          final Map<String, dynamic> updates = {
            'cost_price': newCost,
          };
          if (trackInventory) {
            updates['stock_quantity'] = totalStock;
          }
          await _supabase.from('products').update(updates).eq('id', productId);

          // D. Registrar auditoría de inventario (inventory_transactions)
          if (trackInventory) {
            await _supabase.from('inventory_transactions').insert({
              'tenant_id': tenantId,
              'product_id': productId,
              'quantity_changed': buyQty,
              'transaction_type': 'purchase',
              'reference_id': purchaseId,
              'notes': 'Entrada por reabastecimiento (Factura de Compra)',
              'created_by': registeredBy,
            });
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Anula una compra reversando el stock y registrando la auditoría
  static Future<bool> cancelPurchase({
    required String purchaseId,
    required String tenantId,
    required String cancelledBy,
  }) async {
    try {
      // 1. Obtener la compra y sus ítems
      final purchase = await _supabase.from('supplier_purchases').select().eq('id', purchaseId).single();
      if (purchase['status'] == 'cancelled') return false;

      final items = await _supabase.from('purchase_items').select().eq('purchase_id', purchaseId);

      // 2. Reversar el stock de cada ítem
      for (var item in items) {
        final productId = item['product_id'] as String;
        final buyQty = item['quantity'] as int;

        // Obtener stock actual
        final currentProd = await _supabase
            .from('products')
            .select('stock_quantity, track_inventory')
            .eq('id', productId)
            .maybeSingle();

        if (currentProd != null) {
          final currentStock = currentProd['stock_quantity'] as int? ?? 0;
          final trackInventory = currentProd['track_inventory'] as bool? ?? true;

          if (trackInventory) {
            // Descontar la cantidad que se había comprado
            final newStock = currentStock - buyQty >= 0 ? currentStock - buyQty : 0;
            await _supabase.from('products').update({'stock_quantity': newStock}).eq('id', productId);

            // Registrar auditoría de salida
            await _supabase.from('inventory_transactions').insert({
              'tenant_id': tenantId,
              'product_id': productId,
              'quantity_changed': -buyQty,
              'transaction_type': 'adjustment',
              'reference_id': purchaseId,
              'notes': 'Anulación de compra (Salida por reversión)',
              'created_by': cancelledBy,
            });
          }
        }
      }

      // 3. Cambiar estado de la compra a cancelado
      await _supabase.from('supplier_purchases').update({'status': 'cancelled'}).eq('id', purchaseId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
