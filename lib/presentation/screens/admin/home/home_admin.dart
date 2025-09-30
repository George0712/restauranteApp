import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bi.dart';
import 'package:iconify_flutter/icons/ic.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:intl/intl.dart';

import 'package:restaurante_app/core/constants/app_strings.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/widgets/dashboard_card.dart';
import 'package:restaurante_app/presentation/widgets/option_button_card.dart';

class HomeAdminScreen extends ConsumerStatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  ConsumerState<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends ConsumerState<HomeAdminScreen> {
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  static const Map<String, String> _statusLabels = {
    'pendiente': 'Pendiente',
    'preparando': 'Preparando',
    'terminado': 'Finalizado',
    'cancelado': 'Cancelado',
  };

  static const Map<String, Color> _statusColors = {
    'pendiente': Color(0xFFFFB454),
    'preparando': Color(0xFF60A5FA),
    'terminado': Color(0xFF34D399),
    'cancelado': Color(0xFFF87171),
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leadingWidth: 70,
          leading: _buildProfileButton(theme),
          actions: [_buildNotificationButton()],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.white70,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Gestión'),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F0F23),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: TabBarView(
              children: [
                _buildDashboardTab(context, isTablet),
                _buildManagementTab(context, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      child: Hero(
        tag: 'profile_avatar',
        child: GestureDetector(
          onTap: () {
            context.push('/admin/settings');
          },
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Color.fromRGBO(
                theme.primaryColor.red,
                theme.primaryColor.green,
                theme.primaryColor.blue,
                0.8,
              ),
              child: const Icon(
                Icons.person,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: IconButton(
        onPressed: () {
          // Próximamente: notificaciones para el administrador
        },
        icon: Stack(
          children: [
            const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 30,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.dashboard,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickStats(isTablet),
          const SizedBox(height: 28),
          const Text(
            AppStrings.keyStats,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildHighlightMetrics(isTablet),
          const SizedBox(height: 28),
          const Text(
            AppStrings.analitics,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnalyticsSection(isTablet),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildManagementTab(BuildContext context, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CENTRO DE GESTIÓN',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isTablet ? 3 : 2,
            childAspectRatio: isTablet ? 1.2 : 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              OptionButtonCard(
                icon: const Iconify(Bi.box, size: 32),
                text: AppStrings.productsTitle,
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push('/admin/manage/manage-productos'),
              ),
              OptionButtonCard(
                icon: const Iconify(Ri.user_line, size: 32),
                text: AppStrings.waitersTitle,
                color: const Color(0xFF3B82F6),
                onTap: () => context.push('/admin/manage/mesero'),
              ),
              OptionButtonCard(
                icon: const Iconify(Ri.user_line, size: 32),
                text: AppStrings.cooksTitle,
                color: const Color(0xFF10B981),
                onTap: () => context.push('/admin/manage/cocinero'),
              ),
              OptionButtonCard(
                icon: const Iconify(Ic.outline_table_restaurant, size: 32),
                text: 'Mesas',
                color: const Color(0xFFF59E0B),
                onTap: () => context.push('/admin/manage/mesas'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isTablet) {
    final cards = [
      buildNeonStatCard(
        ref,
        'Ventas',
        'Totales',
        totalVentasProvider,
        const Color(0xFF00D4AA),
        Icons.monetization_on,
      ),
      buildNeonStatCard(
        ref,
        'Órdenes',
        'Activas',
        ordenesProvider,
        const Color(0xFF6366F1),
        Icons.receipt_long,
      ),
      buildNeonStatCard(
        ref,
        'Usuarios',
        'Registrados',
        usuariosProvider,
        const Color(0xFFFF6B6B),
        Icons.group,
      ),
      buildNeonStatCard(
        ref,
        'Productos',
        'Disponibles',
        productosProvider,
        const Color(0xFFFFD23F),
        Icons.inventory_2,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isTablet ? 4 : 2;
        const spacing = 12.0;
        final height = isTablet ? 165.0 : 135.0;
        final width =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: width, height: height, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildHighlightMetrics(bool isTablet) {
    final todaySalesAsync = ref.watch(todaySalesProvider);
    final averageTicketAsync = ref.watch(averageTicketProvider);
    final completedTodayAsync = ref.watch(completedTodayProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isTablet ? 3 : 1;
        const spacing = 12.0;
        final width = crossAxisCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        final cards = [
          SizedBox(
            width: width,
            child: _buildAsyncMetricCard<double>(
              asyncValue: todaySalesAsync,
              title: 'Ventas de hoy',
              subtitle: 'Ingresos generados',
              icon: Icons.stacked_line_chart,
              color: const Color(0xFF38BDF8),
              formatter: (value) => _currencyFormat.format(value),
            ),
          ),
          SizedBox(
            width: width,
            child: _buildAsyncMetricCard<double>(
              asyncValue: averageTicketAsync,
              title: 'Ticket promedio',
              subtitle: 'Valor por orden',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF4ADE80),
              formatter: (value) => _currencyFormat.format(value),
            ),
          ),
          SizedBox(
            width: width,
            child: _buildAsyncMetricCard<int>(
              asyncValue: completedTodayAsync,
              title: 'Pedidos completados',
              subtitle: 'En las últimas 24h',
              icon: Icons.check_circle_outline,
              color: const Color(0xFFF97316),
              formatter: (value) => value.toString(),
            ),
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards,
        );
      },
    );
  }

  Widget _buildAnalyticsSection(bool isTablet) {
    final weeklySalesAsync = ref.watch(weeklySalesProvider);
    final statusSummaryAsync = ref.watch(orderStatusSummaryProvider);
    final topProductsAsync = ref.watch(topProductsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = isTablet;
        const spacing = 16.0;
        final width = isWide
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _buildAsyncChartCard<List<SalesPoint>>(
                asyncValue: weeklySalesAsync,
                title: 'Ventas últimos 7 días',
                subtitle: 'Tendencia semanal',
                icon: Icons.trending_up,
                color: const Color(0xFF6366F1),
                builder: (data) => _buildWeeklySalesChart(data),
              ),
            ),
            SizedBox(
              width: width,
              child: _buildAsyncChartCard<List<OrderStatusMetric>>(
                asyncValue: statusSummaryAsync,
                title: 'Estado de órdenes',
                subtitle: 'Distribución actual',
                icon: Icons.bar_chart_rounded,
                color: const Color(0xFF22D3EE),
                builder: (data) => _buildStatusBarChart(data),
              ),
            ),
            SizedBox(
              width: isWide ? constraints.maxWidth : width,
              child: topProductsAsync.when(
                data: (products) => _buildTopProductsCard(products),
                loading: () => _buildLoadingCard(
                  const Color(0xFFFACC15),
                  minHeight: 240,
                ),
                error: (_, __) => _buildErrorCard(minHeight: 240),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAsyncMetricCard<T>({
    required AsyncValue<T> asyncValue,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String Function(T) formatter,
  }) {
    return asyncValue.when(
      data: (value) => _buildMetricCard(
        title: title,
        subtitle: subtitle,
        value: formatter(value),
        icon: icon,
        color: color,
      ),
      loading: () => _buildLoadingCard(color),
      error: (_, __) => _buildErrorCard(),
    );
  }

  Widget _buildAsyncChartCard<T>({
    required AsyncValue<T> asyncValue,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget Function(T) builder,
  }) {
    return asyncValue.when(
      data: (value) => _buildChartCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        child: builder(value),
      ),
      loading: () => _buildLoadingCard(color, minHeight: 260),
      error: (_, __) => _buildErrorCard(minHeight: 260),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minHeight: 150),
      decoration: _glassDecoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(color),
      constraints: const BoxConstraints(minHeight: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget _buildWeeklySalesChart(List<SalesPoint> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Sin ventas registradas en la última semana',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
      );
    }

    final spots = data.asMap()
        .entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.total))
        .toList();

    final maxY = spots.isEmpty
        ? 1.0
        : spots.map((spot) => spot.y).reduce(math.max).clamp(1.0, double.infinity);
    final interval = _calculateInterval(maxY);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 40,
              interval: interval,
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final date = data[index].date;
                final label = DateFormat('dd/MM').format(date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: const Color(0xFF6366F1),
            barWidth: 3,
            spots: spots,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeColor: const Color(0xFF6366F1),
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.35),
                  const Color(0xFF6366F1).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBarChart(List<OrderStatusMetric> metrics) {
    final filtered = metrics
        .where((metric) => _statusLabels.containsKey(metric.status))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No hay órdenes registradas actualmente',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
      );
    }

    final bars = filtered
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.count.toDouble(),
                color: _statusColors[entry.value.status] ?? Colors.white,
                width: 22,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        )
        .toList();

    final maxCount = filtered.map((e) => e.count).reduce(math.max).toDouble();
    final interval = _calculateInterval(maxCount);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: math.max(maxCount, 1),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= filtered.length) {
                  return const SizedBox.shrink();
                }
                final status = filtered[index].status;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _statusLabels[status] ?? status,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: bars,
      ),
    );
  }

  Widget _buildTopProductsCard(List<TopProductMetric> products) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(const Color(0xFFFACC15)),
      constraints: const BoxConstraints(minHeight: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productos más vendidos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Top de unidades vendidas',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (products.isEmpty)
            Text(
              'Aún no hay datos suficientes para mostrar productos destacados.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.white.withOpacity(0.08),
                height: 18,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.quantity} unidades',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(product.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ingreso',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(Color color, {double? minHeight}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(color),
      constraints:
          minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildErrorCard({double? minHeight}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(const Color(0xFFEF4444)),
      constraints:
          minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
      alignment: Alignment.center,
      child: const Text(
        'No se pudo cargar la información',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  BoxDecoration _glassDecoration(Color accent) {
    return BoxDecoration(
      color: const Color(0xFF0D1117),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Color.fromRGBO(accent.red, accent.green, accent.blue, 0.28),
        width: 1,
      ),
    );
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 4) {
      return 1;
    }
    final rawInterval = (maxValue / 4).ceil().toDouble();
    return rawInterval == 0 ? 1 : rawInterval;
  }
}
