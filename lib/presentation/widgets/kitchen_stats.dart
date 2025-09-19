import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';

class KitchenStats extends ConsumerWidget {
  const KitchenStats({Key? key}) : super(key: key);

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Preparando',
            stats['preparando'] ?? 0, // Cambié 'enPreparacion' por 'preparando'
            Colors.orange,
            Icons.restaurant,
          ),
          _buildDivider(),
          _buildStatItem(
            'Terminados',
            stats['terminado'] ?? 0, // Cambié 'listo' por 'terminado' 
            Colors.green,
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.orange,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Error al cargar estadísticas',
          style: TextStyle(
            color: Colors.red[300],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                color.red,
                color.green,
                color.blue,
                0.2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[600],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}