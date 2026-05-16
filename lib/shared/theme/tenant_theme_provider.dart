import 'package:flutter/widgets.dart';
import 'tenant_theme_notifier.dart';

class TenantThemeProvider extends InheritedNotifier<TenantThemeNotifier> {
  const TenantThemeProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static TenantThemeNotifier of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TenantThemeProvider>()!.notifier!;
  }
}
