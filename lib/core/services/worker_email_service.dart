import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// Resultado de la validación de correo de trabajador
class WorkerEmailResult {
  final bool isValid;
  final String? tenantSlug;
  final String? tenantId;
  final String? error;

  const WorkerEmailResult({
    required this.isValid,
    this.tenantSlug,
    this.tenantId,
    this.error,
  });
}

class WorkerEmailService {
  static final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // VALIDAR FORMATO DE CORREO DE TRABAJADOR
  // El correo debe ser: algo@nombretienda.com
  // Retorna el slug de la tienda si es válido
  // ─────────────────────────────────────────────
  static WorkerEmailResult validateFormat(String email) {
    final parts = email.split('@');

    if (parts.length != 2) {
      return const WorkerEmailResult(
        isValid: false,
        error: 'Formato de correo inválido.',
      );
    }

    final domain = parts[1]; // ej: "mitienda.com"
    final domainParts = domain.split('.');

    if (domainParts.length < 2) {
      return const WorkerEmailResult(
        isValid: false,
        error: 'El dominio del correo no es válido.',
      );
    }

    // El slug es todo antes del último .com/.net/etc
    // ej: "mitienda.com" → slug = "mitienda"
    final slug = domainParts.sublist(0, domainParts.length - 1).join('-');

    return WorkerEmailResult(isValid: true, tenantSlug: slug);
  }

  // ─────────────────────────────────────────────
  // VERIFICAR QUE EL SLUG DEL CORREO COINCIDA
  // CON EL TENANT DEL MANAGER QUE ESTÁ CREANDO
  // ─────────────────────────────────────────────
  static Future<WorkerEmailResult> validateWorkerEmail({
    required String workerEmail,
    required String managerTenantSlug,
  }) async {
    // 1. Validar formato primero
    final formatResult = validateFormat(workerEmail);
    if (!formatResult.isValid) return formatResult;

    // 2. Verificar que el slug del correo coincida con la tienda del manager
    if (formatResult.tenantSlug != managerTenantSlug) {
      return WorkerEmailResult(
        isValid: false,
        error:
            'El correo del trabajador debe usar el dominio de tu tienda: '
            '@$managerTenantSlug.com',
      );
    }

    // 3. Verificar que el correo no esté ya en uso
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', workerEmail)
        .maybeSingle();

    if (existing != null) {
      return const WorkerEmailResult(
        isValid: false,
        error: 'Este correo ya está en uso. Prueba con otro.',
      );
    }

    // 4. Obtener el tenant_id para el slug
    final tenant = await _supabase
        .from('tenants')
        .select('id')
        .eq('slug', managerTenantSlug)
        .maybeSingle();

    if (tenant == null) {
      return const WorkerEmailResult(
        isValid: false,
        error: 'No se encontró la tienda asociada.',
      );
    }

    return WorkerEmailResult(
      isValid: true,
      tenantSlug: managerTenantSlug,
      tenantId: tenant['id'],
    );
  }

  // ─────────────────────────────────────────────
  // CREAR TRABAJADOR COMPLETO
  // Crea usuario en auth + profile + workers table
  // ─────────────────────────────────────────────
  static Future<AuthResult> createWorker({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String tenantId,
    required String managerTenantSlug,
  }) async {
    try {
      // Validar email antes de crear
      final validation = await validateWorkerEmail(
        workerEmail: email,
        managerTenantSlug: managerTenantSlug,
      );

      if (!validation.isValid) {
        return AuthResult.fail(validation.error!);
      }

      // Verificar límite de 2 trabajadores por tenant
      final workerCount = await _supabase
          .from('workers')
          .select('id')
          .eq('tenant_id', tenantId);

      if (workerCount.length >= 2) {
        return AuthResult.fail(
            'Has alcanzado el límite de 2 trabajadores por tienda.');
      }

      // Crear usuario en Supabase Auth
      // Nota: esto usa el Admin API en el service role,
      // en producción esto debe ejecutarse desde un Edge Function
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.fail('No se pudo crear la cuenta del trabajador.');
      }

      final workerId = response.user!.id;

      // Insertar perfil del trabajador
      await _supabase.from('profiles').insert({
        'id': workerId,
        'email': email,
        'role': 'worker',
        'first_name': firstName,
        'last_name': lastName,
      });

      // Registrar en tabla workers
      await _supabase.from('workers').insert({
        'tenant_id': tenantId,
        'profile_id': workerId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });

      return AuthResult.ok({
        'worker_id': workerId,
        'email': email,
      });
    } catch (e) {
      return AuthResult.fail('Error al crear el trabajador: $e');
    }
  }

  // ─────────────────────────────────────────────
  // OBTENER TRABAJADORES DE UN TENANT
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getWorkers(
      String tenantId) async {
    try {
      final result = await _supabase
          .from('workers')
          .select('id, profile_id, first_name, last_name, email, created_at')
          .eq('tenant_id', tenantId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // ELIMINAR TRABAJADOR
  // ─────────────────────────────────────────────
  static Future<AuthResult> deleteWorker(String workerId) async {
    try {
      // Eliminar de workers
      await _supabase.from('workers').delete().eq('profile_id', workerId);

      // Eliminar perfil
      await _supabase.from('profiles').delete().eq('id', workerId);

      // Nota: eliminar de auth.users requiere Admin API / Edge Function
      // Se deja como pendiente para la fase de producción

      return AuthResult.ok();
    } catch (e) {
      return AuthResult.fail('Error al eliminar el trabajador.');
    }
  }

  // ─────────────────────────────────────────────
  // DETECTAR SI UN EMAIL ES DE TRABAJADOR
  // al hacer login, saber si es worker o manager
  // ─────────────────────────────────────────────
  static Future<bool> isWorkerEmail(String email) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('email', email)
          .maybeSingle();

      return profile != null && profile['role'] == 'worker';
    } catch (e) {
      return false;
    }
  }
}