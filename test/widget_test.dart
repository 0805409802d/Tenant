import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenant/tenant/tenant_resolver.dart';
import 'package:tenant/tenant/tenant_config.dart';

void main() {
  group('TenantResolver Tests', () {
    test('Should resolve to a valid TenantType', () {
      // Por defecto en un entorno de pruebas (no web) debería resolver a management
      final type = TenantResolver.resolve();
      expect(type, isNotNull);
      expect(type, TenantType.management);
    });

    test('Should resolve config without errors', () {
      final config = TenantResolver.resolveConfig();
      expect(config, isNotNull);
      expect(config.name, 'Management');
    });
  });

  testWidgets('App Scaffold smoke test', (WidgetTester tester) async {
    // Prueba básica para asegurar que los componentes visuales de Flutter compilan
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Smoke Test')),
        ),
      ),
    );

    expect(find.text('Smoke Test'), findsOneWidget);
  });
}
