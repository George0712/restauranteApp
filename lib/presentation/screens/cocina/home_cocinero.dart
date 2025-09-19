import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';
import 'package:restaurante_app/presentation/widgets/pedido_cards.dart';
import 'package:restaurante_app/presentation/widgets/kitchen_stats.dart';
import 'package:restaurante_app/data/models/pedido.dart';

class HomeCocineroScreen extends ConsumerWidget {
  const HomeCocineroScreen({Key? key}) : super(key: key);

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final statsAsync = ref.watch(pedidoStatsProvider);

  return statsAsync.when(
    data: (stats) {
      final pendingCount = (stats['pendiente'] ?? 0) + (stats['preparando'] ?? 0);    // ✅ 'preparando'
      final completedCount = (stats['terminado'] ?? 0) + (stats['cancelado'] ?? 0);  // ✅ 'terminado' y 'pagado'

      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2D2D2D),
            elevation: 0,
            title: const Text(
              'Cocina',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Hero(
                tag: 'profile_avatar',
                child: GestureDetector(
                  onTap: () => context.push('/admin/settings'),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                    child: const Icon(Icons.person, size: 28, color: Colors.white),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _showStatsDialog(context, stats),
                icon: const Icon(Icons.analytics, color: Colors.white),
                tooltip: 'Estadísticas',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: const Color(0xFF2D2D2D),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const KitchenStats(),
              ),
              Container(
                color: const Color(0xFF3D3D3D),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.orange,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Pendientes'),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildBadge(pendingCount, Colors.red),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Terminados'),
                          if (completedCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildBadge(completedCount, Colors.green),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _PendingOrdersTab(),
                    _CompletedOrdersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
    loading: () => const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Center(child: CircularProgressIndicator(color: Colors.orange)),
    ),
    error: (e, st) => Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Text(
          'Error al cargar estadísticas: $e',
          style: TextStyle(color: Colors.red[300]),
        ),
      ),
    ),
  );
}
Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context, Map<String, int> stats) {
    final totalCount = (stats['pendiente'] ?? 0) +
        (stats['preparando'] ?? 0) +
        (stats['listo'] ?? 0) +
        (stats['cancelado'] ?? 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Estadísticas de Cocina',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('En preparación', stats['preparando'] ?? 0, Colors.orange),     // ✅ 'preparando'
            _buildStatRow('Terminados', stats['terminado'] ?? 0, Colors.green),           // ✅ 'terminado'                // ✅ Añadir 'pagado'
            _buildStatRow('Terminados', stats['listo'] ?? 0, Colors.green),
            _buildStatRow('Cancelados', stats['cancelado'] ?? 0, Colors.grey),
            const Divider(color: Colors.grey),
            _buildStatRow('Total', totalCount, Colors.blue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// -------------------- Pestaña Pendientes --------------------
class _PendingOrdersTab extends ConsumerWidget {
  const _PendingOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrdersAsync = ref.watch(pendingPedidosProvider);

    return pendingOrdersAsync.when(
      data: (pedidos) {
        if (pedidos.isEmpty) {
          return const _EmptyState(
            icon: Icons.restaurant_menu,
            title: '¡Todo al día!',
            subtitle: 'No hay pedidos pendientes',
            color: Colors.green,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (!isWide) {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(pedidosStreamProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return PedidoCard(pedido: pedido);
                  },
                ),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(pedidosStreamProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return PedidoCard(pedido: pedido, isCompact: true);
                  },
                ),
              );
            }
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
      error: (error, _) => _ErrorState(error),
    );
  }
}

// -------------------- Pestaña Completados --------------------
class _CompletedOrdersTab extends ConsumerWidget {
  const _CompletedOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOrdersAsync = ref.watch(completedPedidosProvider);

    return completedOrdersAsync.when(
      data: (pedidos) {
        if (pedidos.isEmpty) {
          return const _EmptyState(
            icon: Icons.history,
            title: 'Sin pedidos completados',
            subtitle: 'Los pedidos terminados aparecerán aquí',
            color: Colors.blue,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (!isWide) {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(pedidosStreamProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return PedidoCard(pedido: pedido);
                  },
                ),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(pedidosStreamProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return PedidoCard(pedido: pedido, isCompact: true);
                  },
                ),
              );
            }
          },
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
      error: (error, _) => _ErrorState(error),
    );
  }
}

// -------------------- Estados Vacío y Error --------------------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  const _ErrorState(this.error, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar pedidos',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Error: $error',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                ProviderScope.containerOf(context).refresh(pedidoStatsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
