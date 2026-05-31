import 'package:supabase_flutter/supabase_flutter.dart';

/// Roles disponibles en el sistema
enum UserRole { admin, manager, advertiser, client, worker }

/// Resultado genérico para operaciones de auth
class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  const AuthResult({required this.success, this.error, this.data});

  factory AuthResult.ok([Map<String, dynamic>? data]) =>
      AuthResult(success: true, data: data);

  factory AuthResult.fail(String error) =>
      AuthResult(success: false, error: error);
}

class AuthService {
  static final _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────
  // LOGIN GENERAL
  // Usado por: management, advertisers, cliente, trabajadores
  // ─────────────────────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.fail('Correo o contraseña incorrectos.');
      }

      // Obtener perfil con rol
      final profile = await _supabase
          .from('profiles')
          .select('role, business_name')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile == null) {
        await _supabase.auth.signOut();
        return AuthResult.fail('No se encontró el perfil del usuario.');
      }

      return AuthResult.ok({
        'user': response.user,
        'role': profile['role'],
        'business_name': profile['business_name'],
      });
    } on AuthException catch (e) {
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Error inesperado. Intenta de nuevo.');
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN ADMIN (solo correo + contraseña, sin rol externo)
  // ─────────────────────────────────────────────
  static Future<AuthResult> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.fail('Credenciales incorrectas.');
      }

      // Verificar que realmente sea admin
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile == null || profile['role'] != 'admin') {
        await _supabase.auth.signOut();
        return AuthResult.fail('Acceso denegado.');
      }

      return AuthResult.ok({'user': response.user});
    } on AuthException catch (e) {
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Error inesperado.');
    }
  }

  // ─────────────────────────────────────────────
  // REGISTER MANAGEMENT
  // ─────────────────────────────────────────────
  static Future<AuthResult> registerManagement({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String country,
    required String city,
    required String address,
    required int businessTypeId,
    required bool acceptedTerms,
  }) async {
    try {
      email = normalizeEmail(email);
      final phoneError = await _checkPhoneUniqueness(phone);
      if (phoneError != null) return AuthResult.fail(phoneError);

      // Generar slug desde el nombre del negocio
      final slug = _generateSlug(businessName);

      // Verificar que el slug no exista
      final existingTenant = await _supabase
          .from('tenants')
          .select('id')
          .eq('slug', slug)
          .maybeSingle();

      if (existingTenant != null) {
        return AuthResult.fail(
          'Ya existe un negocio con ese nombre. Prueba con otro.',
        );
      }

      // Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.fail('No se pudo crear la cuenta.');
      }

      final userId = response.user!.id;

      // Insertar perfil
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'role': 'manager',
        'phone': phone,
        'business_name': businessName,
        'owner_name': ownerName,
        'country': country,
        'city': city,
        'address': address,
      });

      // Insertar tenant
      await _supabase.from('tenants').insert({
        'owner_id': userId,
        'business_name': businessName,
        'slug': slug,
        'business_type_id': businessTypeId,
        'accepted_terms': acceptedTerms,
        'terms_accepted_at': acceptedTerms
            ? DateTime.now().toIso8601String()
            : null,
        'link_url': 'https://$slug.quinindews.com',
      });

      return AuthResult.ok({'slug': slug});
    } on AuthException catch (e) {
      if (_supabase.auth.currentUser != null) await _supabase.auth.signOut();
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (e) {
      if (_supabase.auth.currentUser != null) await _supabase.auth.signOut();
      return AuthResult.fail('Error al crear la cuenta: $e');
    }
  }

  // ─────────────────────────────────────────────
  // REGISTER ADVERTISER
  // ─────────────────────────────────────────────
  static Future<AuthResult> registerAdvertiser({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    required String phone,
    required String country,
    required String city,
    required String address,
  }) async {
    try {
      email = normalizeEmail(email);
      final phoneError = await _checkPhoneUniqueness(phone);
      if (phoneError != null) return AuthResult.fail(phoneError);

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.fail('No se pudo crear la cuenta.');
      }

      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'role': 'advertiser',
        'phone': phone,
        'business_name': businessName,
        'owner_name': ownerName,
        'country': country,
        'city': city,
        'address': address,
      });

      return AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Error al crear la cuenta.');
    }
  }

  // ─────────────────────────────────────────────
  // REGISTER CLIENTE
  // ─────────────────────────────────────────────
  static Future<AuthResult> registerClient({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String tenantSlug, // para saber a qué tienda pertenece
  }) async {
    try {
      email = normalizeEmail(email);
      final phoneError = await _checkPhoneUniqueness(phone);
      if (phoneError != null) return AuthResult.fail(phoneError);

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.fail('No se pudo crear la cuenta.');
      }

      // Buscar el tenant por slug
      final tenant = await _supabase
          .from('tenants')
          .select('id')
          .eq('slug', tenantSlug)
          .maybeSingle();

      if (tenant == null) {
        return AuthResult.fail('Tienda no encontrada.');
      }

      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'role': 'client',
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      });

      // Vincular cliente a la tienda inmediatamente al registrarse
      try {
        await _supabase.from('tenant_clients').insert({
          'tenant_id': tenant['id'],
          'profile_id': response.user!.id,
        });
      } catch (_) {
        // Ignorar si ya existe (unique constraint)
      }

      return AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Error al crear la cuenta.');
    }
  }

  // ─────────────────────────────────────────────
  // CERRAR SESIÓN
  // ─────────────────────────────────────────────
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─────────────────────────────────────────────
  // CAMBIAR CONTRASEÑA
  // ─────────────────────────────────────────────
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return AuthResult.fail('No hay sesión activa.');

      // Re-autenticar para verificar contraseña actual
      final reauth = await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      if (reauth.user == null) {
        return AuthResult.fail('La contraseña actual es incorrecta.');
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Error al cambiar la contraseña.');
    }
  }

  // ─────────────────────────────────────────────
  // CAMBIAR EMAIL
  // ─────────────────────────────────────────────
  static Future<AuthResult> changeEmail({required String newEmail}) async {
    try {
      newEmail = normalizeEmail(newEmail);
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));
      await _supabase
          .from('profiles')
          .update({'email': newEmail})
          .eq('id', _supabase.auth.currentUser!.id);
      return AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.fail('Error al cambiar el correo.');
    }
  }

  // ─────────────────────────────────────────────
  // CAMBIAR TELÉFONO
  // ─────────────────────────────────────────────
  static Future<AuthResult> changePhone({required String newPhone}) async {
    try {
      final phoneError = await _checkPhoneUniqueness(newPhone);
      if (phoneError != null) return AuthResult.fail(phoneError);

      await _supabase
          .from('profiles')
          .update({'phone': newPhone})
          .eq('id', _supabase.auth.currentUser!.id);
      return AuthResult.ok();
    } catch (e) {
      return AuthResult.fail('Error al cambiar el teléfono.');
    }
  }

  // ─────────────────────────────────────────────
  // RECUPERACIÓN DE CUENTA - Guardar preguntas
  // ─────────────────────────────────────────────
  static Future<AuthResult> saveSecurityQuestions({
    required String question1,
    required String answer1,
    required String question2,
    required String answer2,
    required String question3,
    required String answer3,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return AuthResult.fail('No hay sesión activa.');

      await _supabase.from('security_questions').upsert({
        'profile_id': userId,
        'question_1': question1,
        'answer_1': answer1.toLowerCase().trim(),
        'question_2': question2,
        'answer_2': answer2.toLowerCase().trim(),
        'question_3': question3,
        'answer_3': answer3.toLowerCase().trim(),
      });

      return AuthResult.ok();
    } catch (e) {
      return AuthResult.fail('Error al guardar las preguntas.');
    }
  }

  // ─────────────────────────────────────────────
  // RECUPERACIÓN DE CUENTA - Validar respuestas
  // ─────────────────────────────────────────────
  static Future<AuthResult> validateSecurityAnswers({
    required String email,
    required String answer1,
    required String answer2,
    required String answer3,
  }) async {
    try {
      // Buscar perfil por email
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (profile == null) {
        return AuthResult.fail('No existe una cuenta con ese correo.');
      }

      // Obtener preguntas de seguridad
      final questions = await _supabase
          .from('security_questions')
          .select()
          .eq('profile_id', profile['id'])
          .maybeSingle();

      if (questions == null) {
        return AuthResult.fail(
          'Esta cuenta no tiene preguntas de seguridad configuradas.',
        );
      }

      final a1Match = questions['answer_1'] == answer1.toLowerCase().trim();
      final a2Match = questions['answer_2'] == answer2.toLowerCase().trim();
      final a3Match = questions['answer_3'] == answer3.toLowerCase().trim();

      if (!a1Match || !a2Match || !a3Match) {
        return AuthResult.fail('Una o más respuestas son incorrectas.');
      }

      return AuthResult.ok({
        'profile_id': profile['id'],
        'questions': {
          'q1': questions['question_1'],
          'q2': questions['question_2'],
          'q3': questions['question_3'],
        },
      });
    } catch (e) {
      return AuthResult.fail('Error al validar las respuestas.');
    }
  }

  // ─────────────────────────────────────────────
  // OBTENER PREGUNTAS DE SEGURIDAD POR EMAIL
  // ─────────────────────────────────────────────
  static Future<AuthResult> getSecurityQuestions({
    required String email,
  }) async {
    try {
      final result =
          await _supabase.rpc(
                'get_security_questions_by_email',
                params: {'user_email': email.toLowerCase().trim()},
              )
              as List<dynamic>;

      if (result.isEmpty) {
        return AuthResult.fail('Esta cuenta no tiene preguntas configuradas.');
      }
      final row = result.first as Map<String, dynamic>;
      return AuthResult.ok({
        'question_1': row['question_1'] as String,
        'question_2': row['question_2'] as String,
        'question_3': row['question_3'] as String,
      });
    } catch (_) {
      return AuthResult.fail('No se encontró una cuenta con ese correo.');
    }
  }

  // ─────────────────────────────────────────────
  // ENVIAR RESET DE CONTRASEÑA POR EMAIL
  // ─────────────────────────────────────────────
  static Future<AuthResult> sendPasswordReset({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(_translateAuthError(e.message));
    } catch (_) {
      return AuthResult.fail('Error al enviar el correo de recuperación.');
    }
  }

  // ─────────────────────────────────────────────
  // TIPOS DE NEGOCIO (para registro de manager)
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getBusinessTypes() async {
    try {
      final result = await _supabase
          .from('business_types')
          .select('id, name, seo_tags')
          .order('name');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ─────────────────────────────────────────────

  /// Normaliza correos (ej. para Gmail elimina puntos y alias con +)
  static String normalizeEmail(String email) {
    String clean = email.trim().toLowerCase();
    if (clean.endsWith('@gmail.com')) {
      final parts = clean.split('@');
      var localPart = parts[0];
      if (localPart.contains('+')) {
        localPart = localPart.substring(0, localPart.indexOf('+'));
      }
      localPart = localPart.replaceAll('.', '');
      return '$localPart@gmail.com';
    }
    return clean;
  }

  /// Verifica si el teléfono ya está registrado (con excepción del admin)
  static Future<String?> _checkPhoneUniqueness(String phone) async {
    final cleanPhone = phone.trim();
    if (cleanPhone == '+593980991658') return null; // Excepción permitida

    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('phone', cleanPhone)
        .maybeSingle();
    if (existing != null) return 'Este número de teléfono ya está registrado.';
    return null;
  }

  /// Convierte el nombre del negocio a slug limpio para URL
  /// "Mi Restaurante!" → "mi-restaurante"
  static String _generateSlug(String businessName) {
    return businessName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  /// Traduce errores de Supabase Auth al español
  static String _translateAuthError(String message) {
    final errors = {
      'Invalid login credentials': 'Correo o contraseña incorrectos.',
      'Email not confirmed': 'Debes confirmar tu correo antes de ingresar.',
      'User already registered': 'Este correo ya está en uso. Prueba con otro.',
      'Password should be at least 6 characters':
          'La contraseña debe tener al menos 6 caracteres.',
      'Unable to validate email address: invalid format':
          'El formato del correo no es válido.',
    };
    return errors[message] ?? message;
  }

  /// Usuario actual
  static User? get currentUser => _supabase.auth.currentUser;

  /// Stream de cambios de sesión
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
}
