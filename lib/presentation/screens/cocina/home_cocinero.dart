import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';
import 'package:restaurante_app/data/models/notification_model.dart';
import 'package:restaurante_app/presentation/widgets/notification_bell.dart';
import 'package:restaurante_app/presentation/widgets/kitchen_stats.dart';
import 'package:restaurante_app/presentation/widgets/pedido_cards.dart';

class HomeCocineroScreen extends ConsumerWidget {
  const HomeCocineroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(pedidoStatsProvider);

    return statsAsync.when(
      data: (stats) {
        final pendingCount =
            (stats['pendiente'] ?? 0) + (stats['preparando'] ?? 0);
        final completedCount = (stats['terminado'] ?? 0) +
            (stats['pagado'] ?? 0) +
            (stats['entregado'] ?? 0) +
            (stats['cancelado'] ?? 0);

        return DefaultTabController(
          length: 2,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: Colors.black,
              extendBodyBehindAppBar: true,
              appBar: _buildAppBar(context, stats),
              body: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF111827),
                          Color(0xFF0B1120),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _buildIntroHeader(context),
                          const KitchenStats(
                            margin: EdgeInsets.fromLTRB(20, 16, 20, 0),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _KitchenTabBar(
                              pendingCount: pendingCount,
                              completedCount: completedCount,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: TabBarView(
                                physics: BouncingScrollPhysics(),
                                children: [
                                  _PendingOrdersTab(),
                                  _CompletedOrdersTab(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF97316)),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error al cargar estadisticas: $error',
            style: const TextStyle(
              color: Color(0xFFCBD5F5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, Map<String, int> stats) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
        child: Hero(
          tag: 'profile_avatar',
          child: GestureDetector(
            onTap: () => context.push('/admin/settings'),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(15, 23, 42, 0.45),
                    blurRadius: 16,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.85),
                child: const Icon(Icons.person, size: 26, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      actions: [
        const NotificationBell(role: NotificationRole.kitchen),
        const SizedBox(width: 12),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1F2937),
              Color(0xFF111827),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildIntroHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTROL DE COCINA',
            style: TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenTabBar extends StatelessWidget {
  final int pendingCount;
  final int completedCount;

  const _KitchenTabBar({
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedColor = Colors.white.withOpacity(0.65);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.primaryColor.withOpacity(0.12),
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: unselectedColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
        tabs: [
          _TabLabel(
            label: 'Pendientes',
            count: pendingCount,
            color: const Color(0xFFF97316),
          ),
          _TabLabel(
            label: 'Terminados',
            count: completedCount,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TabLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = count > 0;

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (showBadge) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------- Pestana Pendientes --------------------
class _PendingOrdersTab extends ConsumerWidget {
  const _PendingOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrdersAsync = ref.watch(pendingPedidosProvider);

    return pendingOrdersAsync.when(
      data: (pedidos) {
        if (pedidos.isEmpty) {
          return const _EmptyState(
            icon: Icons.emoji_food_beverage,
            title: 'Todo al dia!',
            subtitle: 'No hay pedidos pendientes',
            color: Color(0xFF10B981),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 820;
            refresh() async => ref.invalidate(pedidosStreamProvider);

            if (!isWide) {
              return RefreshIndicator(
                color: const Color(0xFFF97316),
                backgroundColor: const Color(0xFF0F172A),
                onRefresh: refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 120),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return PedidoCard(pedido: pedido);
                  },
                ),
              );
            } else {
              return RefreshIndicator(
                color: const Color(0xFFF97316),
                backgroundColor: const Color(0xFF0F172A),
                onRefresh: refresh,
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
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
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFF97316)),
      ),
      error: (error, _) => _ErrorState(error),
    );
  }
}

// -------------------- Pestana Completados --------------------
class _CompletedOrdersTab extends ConsumerWidget {
  const _CompletedOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOrdersAsync = ref.watch(completedPedidosProvider);

    return completedOrdersAsync.when(
      data: (pedidos) {
        if (pedidos.isEmpty) {
          return const _EmptyState(
            icon: Icons.history_toggle_off,
            title: 'Sin pedidos completados',
            subtitle: 'Los pedidos terminados apareceran aqui',
            color: Color(0xFF38BDF8),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 820;
            final refresh = () async => ref.invalidate(pedidosStreamProvider);

            if (!isWide) {
              return RefreshIndicator(
                color: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF0F172A),
                onRefresh: refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 120),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    return PedidoCard(pedido: pedido);
                  },
                ),
              );
            } else {
              return RefreshIndicator(
                color: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF0F172A),
                onRefresh: refresh,
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
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
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
      error: (error, _) => _ErrorState(error),
    );
  }
}

// -------------------- Estados Vacio y Error --------------------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 54, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  const _ErrorState(this.error);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline,
                size: 54, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error al cargar pedidos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Error: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                ProviderScope.containerOf(context).refresh(pedidoStatsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
