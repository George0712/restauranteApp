import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';

class KitchenStats extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;

  const KitchenStats({Key? key, this.margin}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(pedidoStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildStatsContainer(stats),
      loading: () => _buildLoadingContainer(),
      error: (error, _) => _buildErrorContainer(),
    );
  }

  Widget _buildStatsContainer(Map<String, int> stats) {
    return _buildShell(
      Row(
        children: [
          _buildStatItem(
            'Preparando',
            stats['preparando'] ?? 0,
            const Color(0xFFF97316),
            Icons.local_fire_department_rounded,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            'Terminados',
            (stats['terminado'] ?? 0) + (stats['pagado'] ?? 0) + (stats['entregado'] ?? 0),
            const Color(0xFF10B981),
            Icons.flag_circle_rounded,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            'Cancelados',
            stats['cancelado'] ?? 0,
            const Color(0xFF64748B),
            Icons.cancel_schedule_send,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return _buildShell(
      const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF97316),
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    return _buildShell(
      SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'Error al cargar estadísticas',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildShell(Widget child) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F2937),
            Color(0xFF111827),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.45),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
