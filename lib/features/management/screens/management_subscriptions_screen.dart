import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../shared/layouts/app_scaffold.dart';

class ManagementSubscriptionsScreen extends StatefulWidget {
  const ManagementSubscriptionsScreen({super.key});

  @override
  State<ManagementSubscriptionsScreen> createState() => _ManagementSubscriptionsScreenState();
}

class _ManagementSubscriptionsScreenState extends State<ManagementSubscriptionsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _upgradePlan(BuildContext context, String planName, String price) async {
    final message = 'Hola, deseo mejorar mi plan a $planName ($price/mes).';
    final url = Uri.parse('https://wa.me/593980991658?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    }
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    // Staggered animation
    final start = (index * 0.15).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    
    final slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Interval(start, end, curve: Curves.easeOutBack)),
    );
    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Interval(start, end, curve: Curves.easeOut)),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Planes y Suscripción',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mejora tu plan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aumenta el límite de productos de tu tienda y ofrece una mejor experiencia a tus clientes. El pago se realiza de manera manual.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            
            _buildAnimatedCard(
              _PlanCard(
                title: 'Freemium',
                price: '\$0',
                period: '/mes',
                features: const ['Hasta 20 productos', 'Soporte estándar'],
                buttonText: 'Plan actual',
                isCurrent: true,
                color: AppColors.textSecondary,
                onTap: () {},
              ),
              0,
            ),
            const SizedBox(height: 16),
            
            _buildAnimatedCard(
              _PlanCard(
                title: 'Low',
                price: '\$5',
                period: '/mes',
                features: const ['Hasta 100 productos', 'Soporte prioritario'],
                buttonText: 'Mejorar a Low',
                isCurrent: false,
                color: AppColors.accentTeal,
                onTap: () => _upgradePlan(context, 'Low', '\$5'),
              ),
              1,
            ),
            const SizedBox(height: 16),
            
            _buildAnimatedCard(
              _PlanCard(
                title: 'Mid',
                price: '\$10',
                period: '/mes',
                features: const ['Hasta 500 productos', 'Soporte prioritario VIP', 'Sello de tienda verificada'],
                buttonText: 'Mejorar a Mid',
                isCurrent: false,
                color: AppColors.primary,
                isRecommended: true,
                onTap: () => _upgradePlan(context, 'Mid', '\$10'),
              ),
              2,
            ),
            const SizedBox(height: 16),
            
            _buildAnimatedCard(
              _PlanCard(
                title: 'High',
                price: '\$20',
                period: '/mes',
                features: const ['Productos ILIMITADOS', 'Soporte 24/7', 'Dominio personalizado'],
                buttonText: 'Mejorar a High',
                isCurrent: false,
                color: AppColors.accentAmber,
                onTap: () => _upgradePlan(context, 'High', '\$20'),
              ),
              3,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.buttonText,
    required this.isCurrent,
    required this.color,
    required this.onTap,
    this.isRecommended = false,
  });

  final String title;
  final String price;
  final String period;
  final List<String> features;
  final String buttonText;
  final bool isCurrent;
  final bool isRecommended;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isRecommended ? AppColors.tint(color, opacity: 0.03) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecommended ? color : (isCurrent ? color.withValues(alpha: 0.3) : AppColors.border), 
          width: isRecommended ? 2 : 1
        ),
        boxShadow: [
          if (isRecommended)
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: AppColors.overlay(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18), // account for border width
        child: Stack(
          children: [
            if (isRecommended)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                  ),
                  child: const Text('RECOMENDADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 1.2)),
                ),
              ),
              
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Actual',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(period, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 20, color: color),
                        const SizedBox(width: 12),
                        Expanded(child: Text(f, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCurrent ? null : onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent ? AppColors.surfaceGrey : color,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? AppColors.textSecondary : AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
