// lib/presentation/screens/cocina/home_cocinero.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:restaurante_app/presentation/providers/cocina/order_provider.dart';
import 'package:restaurante_app/presentation/widgets/order_cards.dart';
import 'package:restaurante_app/presentation/widgets/kitchen_stats.dart';

class HomeCocineroScreen extends ConsumerWidget {
  const HomeCocineroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leemos el mapa de estadísticas directamente
    final stats = ref.watch(orderStatsProvider);
    final pendingCount = (stats['pendiente'] ?? 0) + (stats['preparando'] ?? 0);
    final completedCount = (stats['terminado'] ?? 0) + (stats['cancelado'] ?? 0);

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
              onTap: () {
                context.push('/admin/settings');
              },
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:Color.fromRGBO(0, 0, 0, 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Color.fromRGBO(
                    Theme.of(context).primaryColor.red,
                    Theme.of(context).primaryColor.green,
                    Theme.of(context).primaryColor.blue,
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

        // ¡Sacamos KitchenStats y TabBar del AppBar, y lo ponemos en el body!
        body: Column(
          children: [
            // 1) Estadísticas en la parte superior (puede tener altura variable)
            Container(
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const KitchenStats(),
            ),

            // 2) TabBar con sus dos pestañas (Pendientes / Terminados)
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$completedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3) El único elemento Expanded: TabBarView tomará el espacio restante
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
  }

  void _showStatsDialog(BuildContext context, Map<String, int> stats) {
    final totalCount = (stats['pendiente'] ?? 0) +
        (stats['preparando'] ?? 0) +
        (stats['terminado'] ?? 0) +
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
            _buildStatRow('Pendientes', stats['pendiente'] ?? 0, Colors.red),
            _buildStatRow('Preparando', stats['preparando'] ?? 0, Colors.orange),
            _buildStatRow('Terminados', stats['terminado'] ?? 0, Colors.green),
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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


class _PendingOrdersTab extends ConsumerWidget {
  const _PendingOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrdersAsync = ref.watch(pendingOrdersProvider);

    return pendingOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const _EmptyState(
            icon: Icons.restaurant_menu,
            title: '¡Todo al día!',
            subtitle: 'No hay órdenes pendientes',
            color: Colors.green,
          );
        }

        // Si hay órdenes, mostramos la lista o la grilla con padding inferior
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (!isWide) {
              // Vista móvil: ListView con padding inferior extra
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersStreamProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                ),
              );
            } else {
              // Vista tablet/desktop: GridView con padding inferior extra
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersStreamProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order, isCompact: true);
                  },
                ),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      error: (error, _) => _ErrorState(error),
    );
  }
}

class _CompletedOrdersTab extends ConsumerWidget {
  const _CompletedOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOrdersAsync = ref.watch(completedOrdersProvider);

    return completedOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const _EmptyState(
            icon: Icons.history,
            title: 'Sin órdenes completadas',
            subtitle: 'Las órdenes terminadas aparecerán aquí',
            color: Colors.blue,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (!isWide) {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersStreamProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order);
                  },
                ),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersStreamProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(order: order, isCompact: true);
                  },
                ),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
      error: (error, _) => _ErrorState(error),
    );
  }
}

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
          Icon(icon, size: 80, color: Color.fromRGBO(
            color.red,
            color.green,
            color.blue,
            0.5,
          )),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
            'Error al cargar órdenes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Error: $error',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ProviderScope.containerOf(context).refresh(orderStatsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
