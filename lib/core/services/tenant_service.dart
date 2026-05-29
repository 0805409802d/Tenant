import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio compartido para obtener el tenant del usuario actual.
/// Funciona tanto para managers (owner_id) como para workers (tabla workers).
class TenantService {
  static final _db = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // Obtiene el tenant del usuario autenticado.
  // Primero busca como manager; si no, como worker.
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCurrentUserTenant() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;

    // 1. Intentar como manager (owner)
    final asManger = await _db
        .from('tenants')
        .select()
        .eq('owner_id', uid)
        .maybeSingle();

    if (asManger != null) return asManger;

    // 2. Intentar como worker
    final workerRow = await _db
        .from('workers')
        .select('tenant_id')
        .eq('profile_id', uid)
        .maybeSingle();

    if (workerRow == null) return null;

    final asWorker = await _db
        .from('tenants')
        .select()
        .eq('id', workerRow['tenant_id'])
        .maybeSingle();

    return asWorker;
  }

  // ─────────────────────────────────────────────
  // Retorna true si el usuario actual es un worker
  // (no el dueño/manager del negocio).
  // ─────────────────────────────────────────────
  static Future<bool> isCurrentUserWorker() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return false;

    final profile = await _db
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();

    return profile?['role'] == 'worker';
  }

  // ─────────────────────────────────────────────
  // Obtiene solo el tenant_id del usuario actual.
  // Útil para pantallas que solo necesitan el ID.
  // ─────────────────────────────────────────────
  static Future<String?> getCurrentUserTenantId() async {
    final tenant = await getCurrentUserTenant();
    return tenant?['id'] as String?;
  }
}
