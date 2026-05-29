import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/constants_theme_color.dart';
import '../../../core/services/finance_service.dart';
import '../../../core/services/tenant_service.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/theme/tenant_theme_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

class ManagementFinanceScreen extends StatefulWidget {
  const ManagementFinanceScreen({super.key});

  @override
  State<ManagementFinanceScreen> createState() => _ManagementFinanceScreenState();
}

class _ManagementFinanceScreenState extends State<ManagementFinanceScreen> {
  bool _loading = true;
  bool _isWorker = false;
  String? _tenantId;
  String _currencySymbol = '\$';

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  double _totalRevenue = 0.0;
  double _totalCost = 0.0;
  double _netProfit = 0.0;
  double _marginPercentage = 0.0;

  List<Map<String, dynamic>> _orders = [];
  List<_DailyProfitRow> _dailyData = [];
  List<_ProductProfitRow> _productRanking = [];

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    final isWorker = await TenantService.isCurrentUserWorker();
    if (isWorker) {
      if (mounted) {
        setState(() {
          _isWorker = true;
          _loading = false;
        });
      }
      return;
    }

    final tenantId = await TenantService.getCurrentUserTenantId();
    if (tenantId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _tenantId = tenantId;
    
    // Get currency symbol
    final db = Supabase.instance.client;
    final tenantRow = await db.from('tenants').select('currency_symbol').eq('id', tenantId).maybeSingle();
    if (tenantRow != null && tenantRow['currency_symbol'] != null) {
      _currencySymbol = tenantRow['currency_symbol'] as String;
    }

    await _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    final rawOrders = await FinanceService.getApprovedOrdersForAnalytics(
      tenantId: _tenantId!,
      startDate: _startDate,
      endDate: _endDate,
    );

    _orders = rawOrders;

    // Process variables
    double revenue = 0.0;
    double cost = 0.0;

    // Daily aggregations
    final Map<String, _DailyProfitRow> dailyMap = {};
    // Product aggregations
    final Map<String, _ProductProfitRow> productMap = {};

    for (var order in rawOrders) {
      final orderAmount = (order['total_amount'] as num? ?? 0.0).toDouble();
      revenue += orderAmount;

      final createdAtStr = order['created_at'] as String;
      final localDate = DateTime.parse(createdAtStr).toLocal();
      final dateKey = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = _DailyProfitRow(date: localDate, revenue: 0.0, cost: 0.0);
      }
      dailyMap[dateKey]!.revenue += orderAmount;

      final items = order['order_items'] as List? ?? [];
      for (var item in items) {
        final qty = (item['quantity'] as num? ?? 0).toInt();
        final unitCost = (item['unit_cost_price'] as num? ?? 0.0).toDouble();
        final itemCost = qty * unitCost;
        cost += itemCost;
        dailyMap[dateKey]!.cost += itemCost;

        final prod = item['products'] ?? {};
        final prodName = prod['name'] as String? ?? 'Producto Eliminado';
        final price = (item['unit_price'] as num? ?? 0.0).toDouble();

        if (!productMap.containsKey(prodName)) {
          productMap[prodName] = _ProductProfitRow(
            productName: prodName,
            quantitySold: 0,
            totalRevenue: 0.0,
            totalCost: 0.0,
          );
        }
        productMap[prodName]!.quantitySold += qty;
        productMap[prodName]!.totalRevenue += (qty * price);
        productMap[prodName]!.totalCost += itemCost;
      }
    }

    _totalRevenue = revenue;
    _totalCost = cost;
    _netProfit = _totalRevenue - _totalCost;
    _marginPercentage = _totalRevenue > 0 ? (_netProfit / _totalRevenue) * 100 : 0.0;

    // Sort daily data ascending by date
    final sortedDays = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    _dailyData = sortedDays;

    // Sort products by profit margin percentage descending
    final sortedProds = productMap.values.toList()
      ..sort((a, b) => b.netProfit.compareTo(a.netProfit));
    _productRanking = sortedProds;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _setDatePreset(int days) {
    setState(() {
      _startDate = DateTime.now().subtract(Duration(days: days));
      _endDate = DateTime.now();
    });
    _fetchData();
  }

  Future<void> _exportCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Ingresos brutos,Costos de Inversion,Utilidad Neta');
    for (var day in _dailyData) {
      final formattedDate = '${day.date.day}/${day.date.month}/${day.date.year}';
      buffer.writeln('$formattedDate,${day.revenue.toStringAsFixed(2)},${day.cost.toStringAsFixed(2)},${day.netProfit.toStringAsFixed(2)}');
    }

    // Copy to clipboard
    final data = buffer.toString();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Exportar a CSV', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Los datos en formato CSV se han generado con éxito.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceGrey, borderRadius: BorderRadius.circular(10)),
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(data, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              // Copy to Clipboard
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copiado al portapapeles')));
            },
            child: const Text('Copiar'),
          )
        ],
      ),
    );
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Reporte Financiero de Rentabilidad', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Rango: ${_startDate.day}/${_startDate.month}/${_startDate.year} al ${_endDate.day}/${_endDate.month}/${_endDate.year}', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                
                // Indicators
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INGRESOS BRUTOS', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('$_currencySymbol${_totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('COSTOS INVERSION', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('$_currencySymbol${_totalCost.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('UTILIDAD NETA', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('$_currencySymbol${_netProfit.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                
                pw.Text('Historial Diario', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),

                // Table
                pw.TableHelper.fromTextArray(
                  headers: ['Fecha', 'Ingresos', 'Costos', 'Utilidad Neta'],
                  data: _dailyData.map((d) => [
                    '${d.date.day}/${d.date.month}',
                    '$_currencySymbol${d.revenue.toStringAsFixed(2)}',
                    '$_currencySymbol${d.cost.toStringAsFixed(2)}',
                    '$_currencySymbol${d.netProfit.toStringAsFixed(2)}',
                  ]).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_isWorker) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceGrey,
        body: Center(
          child: AppEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Acceso Restringido',
            subtitle: 'Lo sentimos, las analíticas financieras y de rentabilidad real están reservadas exclusivamente para la administración del negocio.',
            iconColor: AppColors.error,
          ),
        ),
      );
    }

    final primaryColor = TenantThemeProvider.of(context).primaryColor;

    return AppScaffold(
      title: 'Finanzas y Rentabilidad',
      accentColor: Colors.deepPurple,
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textPrimary),
          onPressed: _exportPDF,
          tooltip: 'Exportar PDF',
        ),
        IconButton(
          icon: const Icon(Icons.table_rows_outlined, color: AppColors.textPrimary),
          onPressed: _exportCSV,
          tooltip: 'Exportar CSV',
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date range header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Análisis del Negocio',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Periodo: ${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          PopupMenuButton<int>(
                            onSelected: _setDatePreset,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            icon: Icon(Icons.date_range_rounded, color: primaryColor),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 7, child: Text('Últimos 7 días')),
                              const PopupMenuItem(value: 14, child: Text('Últimas 2 semanas')),
                              const PopupMenuItem(value: 30, child: Text('Último mes (30 días)')),
                              const PopupMenuItem(value: 90, child: Text('Último trimestre (90 días)')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Metrics Cards Row
                      _buildFinancialSummaryCards(),
                      const SizedBox(height: 24),

                      // Custom Interactive Chart
                      _buildVisualChart(primaryColor),
                      const SizedBox(height: 24),

                      // Product profitability list
                      _buildRankingSection(primaryColor),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFinancialSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 32) / 3;
        final bool isWrap = constraints.maxWidth < 600;

        final items = [
          _FinancialMetricCard(
            title: 'INGRESOS BRUTOS',
            value: '$_currencySymbol${_totalRevenue.toStringAsFixed(2)}',
            colors: const [Color(0xFF673AB7), Color(0xFF512DA8)],
            icon: Icons.account_balance_wallet_outlined,
          ),
          _FinancialMetricCard(
            title: 'INVERSIÓN EN COSTO',
            value: '$_currencySymbol${_totalCost.toStringAsFixed(2)}',
            colors: const [Color(0xFFFF9800), Color(0xFFF57C00)],
            icon: Icons.trending_up_rounded,
          ),
          _FinancialMetricCard(
            title: 'UTILIDAD NETA REAL',
            value: '$_currencySymbol${_netProfit.toStringAsFixed(2)}',
            colors: const [Color(0xFF00BFA5), Color(0xFF00897B)],
            icon: Icons.emoji_events_outlined,
            subtitle: 'Margen real: ${_marginPercentage.toStringAsFixed(1)}%',
          ),
        ];

        if (isWrap) {
          return Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(width: double.infinity, child: item),
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: items[0]),
            const SizedBox(width: 16),
            Expanded(child: items[1]),
            const SizedBox(width: 16),
            Expanded(child: items[2]),
          ],
        );
      },
    );
  }

  Widget _buildVisualChart(Color primaryColor) {
    if (_dailyData.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('Sin ventas aprobadas en este periodo para graficar.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final double maxVal = _dailyData.fold(0.01, (max, item) {
      final v = item.revenue > item.cost ? item.revenue : item.cost;
      return v > max ? v : max;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.overlay(0.02), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Comparativa Diaria', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Row(
                children: [
                  _LegendIndicator(color: const Color(0xFF673AB7), label: 'Ingresos'),
                  const SizedBox(width: 16),
                  _LegendIndicator(color: const Color(0xFF00BFA5), label: 'Utilidad Neta'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          // Visual bars
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _dailyData.map((d) {
                final double revHeightFactor = (d.revenue / maxVal).clamp(0.04, 1.0);
                final double netHeightFactor = (d.netProfit / maxVal).clamp(0.04, 1.0);
                final String label = '${d.date.day}/${d.date.month}';

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Revenue bar
                            Tooltip(
                              message: 'Ingreso: $_currencySymbol${d.revenue.toStringAsFixed(2)}',
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 8,
                                height: 140 * revHeightFactor,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF673AB7).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Net Profit bar
                            Tooltip(
                              message: 'Ganancia Neta: $_currencySymbol${d.netProfit.toStringAsFixed(2)}',
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 8,
                                height: 140 * (d.netProfit > 0 ? netHeightFactor : 0.04),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BFA5).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rentabilidad por Artículos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          
          if (_productRanking.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Sin ventas de artículos aún.', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _productRanking.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = _productRanking[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unidades vendidas: ${item.quantitySold}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+$_currencySymbol${item.netProfit.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 14),
                          ),
                          Text(
                            'Margen: ${item.marginPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FinancialMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> colors;
  final IconData icon;
  final String? subtitle;

  const _FinancialMetricCard({
    required this.title,
    required this.value,
    required this.colors,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white.withOpacity(0.7),
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, color: AppColors.white.withOpacity(0.7), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendIndicator({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DailyProfitRow {
  final DateTime date;
  double revenue;
  double cost;

  _DailyProfitRow({
    required this.date,
    required this.revenue,
    required this.cost,
  });

  double get netProfit => revenue - cost;
}

class _ProductProfitRow {
  final String productName;
  int quantitySold;
  double totalRevenue;
  double totalCost;

  _ProductProfitRow({
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCost,
  });

  double get netProfit => totalRevenue - totalCost;
  double get marginPercentage => totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;
}
