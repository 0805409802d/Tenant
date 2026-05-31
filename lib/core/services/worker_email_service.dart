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
  // El correo debe ser: algo@slug.com
  // El slug debe coincidir con el slug del tenant del manager.
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

    // 3. Obtener el tenant_id para el slug
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
  // Llama a la Edge Function "create-worker" para evitar
  // que el signUp reemplace la sesión activa del manager.
  // ─────────────────────────────────────────────
  static Future<AuthResult> createWorker({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String tenantId,
    required String managerTenantSlug,
  }) async {
    try {
      email = AuthService.normalizeEmail(email);
      // Validar email antes de crear
      final validation = await validateWorkerEmail(
        workerEmail: email,
        managerTenantSlug: managerTenantSlug,
      );

      if (!validation.isValid) {
        return AuthResult.fail(validation.error!);
      }

      // Llamar a la Edge Function para crear el worker sin afectar la sesión
      final response = await _supabase.functions.invoke(
        'create-worker',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'tenantId': tenantId,
        },
      );

      // Manejo seguro: verificamos que la respuesta sea un Map con posible error
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('error')) {
          return AuthResult.fail(responseData['error'].toString());
        }
        return AuthResult.ok({
          'worker_id': responseData['worker_id'],
          'email': email,
        });
      } else {
        // Si la respuesta no es un Map, asumimos éxito pero sin worker_id
        return AuthResult.ok({'email': email});
      }
    } catch (e) {
      return AuthResult.fail('Error al crear el trabajador: $e');
    }
  }

  // ─────────────────────────────────────────────
  // OBTENER TRABAJADORES DE UN TENANT
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getWorkers(String tenantId) async {
    try {
      final result = await _supabase
          .from('workers')
          .select('id, profile_id, first_name, last_name, email, phone, created_at')
          .eq('tenant_id', tenantId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // ACTUALIZAR TRABAJADOR
  // ─────────────────────────────────────────────
  static Future<AuthResult> updateWorker({
    required String profileId,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      // 1. Actualizar profiles
      await _supabase.from('profiles').update({
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      }).eq('id', profileId);

      // 2. Actualizar workers
      await _supabase.from('workers').update({
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      }).eq('profile_id', profileId);

      return AuthResult.ok();
    } catch (e) {
      return AuthResult.fail('Error al actualizar el trabajador: $e');
    }
  }

  // ─────────────────────────────────────────────
  // ELIMINAR TRABAJADOR
  // Llama a la Edge Function "delete-worker" para también
  // eliminar el usuario de auth.users.
  // ─────────────────────────────────────────────
  static Future<AuthResult> deleteWorker(String workerId) async {
    try {
      final response = await _supabase.functions.invoke(
        'delete-worker',
        body: {'workerId': workerId},
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('error')) {
          return AuthResult.fail(responseData['error'].toString());
        }
        return AuthResult.ok();
      } else {
        // Si no es Map, consideramos éxito genérico
        return AuthResult.ok();
      }
    } catch (e) {
      return AuthResult.fail('Error al eliminar el trabajador: $e');
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
