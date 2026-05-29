import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // Small screens, like phones
  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

  // Medium screens, like tablets
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 && MediaQuery.sizeOf(context).width < 1000;

  // Large screens, like laptops and desktops
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 1000;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return desktop;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
