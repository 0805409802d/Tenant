import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Ingresa tus credenciales completas.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: pass,
      );
      
      if (res.session != null) {
        // Verificar si es admin realmente (el router igual lo validará, pero por seguridad)
        if (mounted) context.go('/d8t1-admin-panel');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error de conexión.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      maxWidth: 380,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.textPrimary, // Panel oscuro para Admin
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.overlay(0.1), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.shield_outlined, color: AppColors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Admin',
                  style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Inputs (Variantes oscuras customizadas localmente)
            const Text('Correo electrónico', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.1),
                hintText: 'admin@dominio.com',
                hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.white.withValues(alpha: 0.5), size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Contraseña secreta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
            const SizedBox(height: 6),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.1),
                hintText: '••••••••',
                hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.white.withValues(alpha: 0.5), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.white.withValues(alpha: 0.5), size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('Autenticar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
