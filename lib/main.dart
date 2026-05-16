import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'tenant/tenant_provider.dart';
import 'shared/theme/tenant_theme_notifier.dart';
import 'shared/theme/tenant_theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final themeNotifier = TenantThemeNotifier();

  runApp(
    TenantThemeProvider(
      notifier: themeNotifier,
      child: const TenantScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = TenantThemeProvider.of(context);
    return MaterialApp.router(
      title: 'Quinindews',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(primaryColor: themeNotifier.primaryColor),
      routerConfig: AppRouter.router,
    );
  }
}