import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/theme/tenant_theme_provider.dart';

class ManagementShell extends StatelessWidget {
  const ManagementShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TenantThemeProvider.of(context).primaryColor;
    final currentIndex = navigationShell.currentIndex;

    final bottomNav = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Inicio',
                isSelected: currentIndex == 0,
                primaryColor: primaryColor,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Pedidos',
                isSelected: currentIndex == 1,
                primaryColor: primaryColor,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'Catálogo',
                isSelected: currentIndex == 2,
                primaryColor: primaryColor,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Ajustes',
                isSelected: currentIndex == 3,
                primaryColor: primaryColor,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );

    final navRail = NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: _onTap,
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppColors.surface,
      selectedIconTheme: IconThemeData(color: primaryColor, size: 28),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
      selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
      indicatorColor: AppColors.tint(primaryColor),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_rounded),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_rounded),
          label: Text('Pedidos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_rounded),
          label: Text('Catálogo'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_rounded),
          label: Text('Ajustes'),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return Row(
              children: [
                navRail,
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
                Expanded(child: navigationShell),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: navigationShell),
              bottomNav,
            ],
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tint(primaryColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? primaryColor : AppColors.textSecondary,
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? primaryColor : AppColors.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
