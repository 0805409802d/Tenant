import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/constants_theme_color.dart';

class TenantThemeNotifier extends ChangeNotifier {
  Color _primaryColor = AppColors.primary;
  String? _logoUrl;

  Color get primaryColor => _primaryColor;
  String? get logoUrl => _logoUrl;

  Future<void> initialize(String tenantId) async {
    try {
      final db = Supabase.instance.client;
      final tenant = await db.from('tenants').select('primary_color, logo_url').eq('id', tenantId).maybeSingle();
      if (tenant != null) {
        if (tenant['primary_color'] != null) {
          final hex = tenant['primary_color'].toString().replaceFirst('#', '');
          if (hex.length == 6) {
            _primaryColor = Color(int.parse('0xFF$hex'));
          } else if (hex.length == 8) {
            _primaryColor = Color(int.parse('0x$hex'));
          }
        }
        if (tenant['logo_url'] != null) {
          _logoUrl = tenant['logo_url'];
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void updateColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  void updateLogo(String url) {
    _logoUrl = url;
    notifyListeners();
  }
}
