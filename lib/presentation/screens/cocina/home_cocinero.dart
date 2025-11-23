import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/models/pedido.dart';

import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';
import 'package:restaurante_app/data/models/notification_model.dart';
import 'package:restaurante_app/presentation/providers/notification/notification_provider.dart';
import 'package:restaurante_app/presentation/widgets/notification_bell.dart';
import 'package:restaurante_app/presentation/widgets/pedido_cards.dart';
import 'package:restaurante_app/presentation/widgets/order_notification_banner.dart';
import 'package:restaurante_app/presentation/widgets/tab_label.dart';

class HomeCocineroScreen extends ConsumerStatefulWidget {
  const HomeCocineroScreen({super.key});

  @override
  ConsumerState<HomeCocineroScreen> createState() => _HomeCocineroScreenState();
}

class _HomeCocineroScreenState extends ConsumerState<HomeCocineroScreen> {
  StreamSubscription<AppNotification>? _notificationSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final controller = ref.read(notificationCenterProvider.notifier);
    _notificationSubscription = controller
        .streamForRole(NotificationRole.kitchen)
        .listen((notification) {
      _playNotificationSound();
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (_) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(pedidoStatsProvider);
    final newOrderNotification = ref.watch(newOrderNotificationProvider);
    final completedOrderNotification =
        ref.watch(completedOrderNotificationProvider);
    final updatedOrderNotification =
        ref.watch(updatedOrderNotificationProvider);

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
              appBar: _buildAppBar(context, stats, ref),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Text(
                            'Gestión de Cocina',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _KitchenTabBar(
                            pendingCount: pendingCount,
                            completedCount: completedCount,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Expanded(
                          child: Padding(
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
                  // Notification banners como overlay flotante
                  SafeArea(
                    child: Column(
                      children: [
                        if (newOrderNotification != null)
                          OrderNotificationBanner(
                            key: ValueKey(newOrderNotification.timestamp),
                            type: NotificationType.newOrder,
                            message: newOrderNotification.message,
                            shouldPlaySound:
                                true, // Sonido habilitado en cocina
                            onDismiss: () {
                              ref
                                  .read(newOrderNotificationProvider.notifier)
                                  .state = null;
                            },
                          ),
                        if (completedOrderNotification != null)
                          OrderNotificationBanner(
                            key: ValueKey(completedOrderNotification.timestamp),
                            type: NotificationType.orderCompleted,
                            message: completedOrderNotification.message,
                            shouldPlaySound:
                                true, // Sonido habilitado en cocina
                            onDismiss: () {
                              ref
                                  .read(completedOrderNotificationProvider
                                      .notifier)
                                  .state = null;
                            },
                          ),
                        if (updatedOrderNotification != null)
                          OrderNotificationBanner(
                            key: ValueKey(updatedOrderNotification.timestamp),
                            type: NotificationType.orderUpdated,
                            message: updatedOrderNotification.message,
                            shouldPlaySound:
                                true, // Sonido habilitado en cocina
                            onDismiss: () {
                              ref
                                  .read(
                                      updatedOrderNotificationProvider.notifier)
                                  .state = null;
                            },
                          ),
                      ],
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
      BuildContext context, Map<String, int> stats, WidgetRef ref) {
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
            onTap: () => context.push('/settings'),
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
                    Theme.of(context).primaryColor.withValues(alpha: 0.85),
                child: const Icon(Icons.person, size: 26, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      actions: const [
        NotificationBell(role: NotificationRole.kitchen),
        SizedBox(width: 12),
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
}

// -------------------- Vista de Mazo de Cartas para Móviles --------------------
class _CardStackView extends ConsumerStatefulWidget {
  final List pedidos;
  final Color emptyStateColor;

  const _CardStackView({
    required this.pedidos,
    required this.emptyStateColor,
  });

  @override
  ConsumerState<_CardStackView> createState() => _CardStackViewState();
}

class _CardStackViewState extends ConsumerState<_CardStackView> {
  late PageController _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(_CardStackView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si llegó un nuevo pedido (aumentó la cantidad), volver a la primera carta
    if (widget.pedidos.length > oldWidget.pedidos.length && currentIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
          HapticFeedback.lightImpact();
        }
      });
    }

    // Si estamos en un índice que ya no existe (porque se eliminaron pedidos)
    if (currentIndex >= widget.pedidos.length && widget.pedidos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          final newIndex = widget.pedidos.length - 1;
          _pageController.jumpToPage(newIndex);
          setState(() {
            currentIndex = newIndex;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pedidos.isEmpty) {
      return const Center(
        child: Text(
          'No hay pedidos',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Stack(
      children: [
        // Contador simple de pedidos
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${currentIndex + 1} / ${widget.pedidos.length}',
              style: TextStyle(
                color: widget.emptyStateColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Stack de cartas ocupando todo el espacio disponible
        PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(parent: ClampingScrollPhysics()),
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
            HapticFeedback.lightImpact();
          },
          itemCount: widget.pedidos.length,
          itemBuilder: (context, index) {
            final pedido = widget.pedidos[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Hero(
                tag: 'pedido_${pedido.id}',
                child: PedidoCard(pedido: pedido),
              ),
            );
          },
        ),

        // Botón flotante para regresar a la primera tarjeta
        if (currentIndex > 0)
          Positioned(
            bottom: 24,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: widget.emptyStateColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                  HapticFeedback.mediumImpact();
                },
                backgroundColor: widget.emptyStateColor,
                foregroundColor: Colors.white,
                elevation: 0,
                child: const Icon(Icons.first_page_rounded, size: 24),
              ),
            ),
          ),
      ],
    );
  }
}

class _KitchenTabBar extends ConsumerWidget {
  final int pendingCount;
  final int completedCount;

  const _KitchenTabBar({
    required this.pendingCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unselectedColor = Colors.white.withValues(alpha: 0.65);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.primaryColor.withValues(alpha: 0.12),
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: theme.primaryColor,
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
          TabLabel(
            label: 'Pendientes',
            count: pendingCount,
            color: const Color(0xFFF97316),
          ),
          TabLabel(
            label: 'Terminados',
            count: completedCount,
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

// -------------------- Pestana Pendientes --------------------
class _PendingOrdersTab extends ConsumerStatefulWidget {
  const _PendingOrdersTab();

  @override
  ConsumerState<_PendingOrdersTab> createState() => _PendingOrdersTabState();
}

class _PendingOrdersTabState extends ConsumerState<_PendingOrdersTab> {
  Set<String> _knownOrderIds = {};
  Map<String, int> _orderItemCounts =
      {}; // Rastrear cantidad de items por pedido

  @override
  void initState() {
    super.initState();
    // Inicializar después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingOrders = ref.read(pendingPedidosProvider);
      pendingOrders.whenData((orders) {
        if (mounted) {
          setState(() {
            _knownOrderIds = orders.map((p) => p.id).toSet();
            _orderItemCounts = {
              for (var order in orders) order.id: order.items.length
            };
          });
        }
      });
    });
  }

  void _checkForNewOrders(List<Pedido> currentOrders) {
    if (currentOrders.isEmpty) return;

    final currentIds = currentOrders.map((p) => p.id).toSet();
    final now = DateTime.now();

    // Solo verificar si ya tenemos IDs conocidos (evita notificación en primera carga)
    if (_knownOrderIds.isNotEmpty) {
      // Detectar NUEVOS pedidos
      final newOrderIds = currentIds.difference(_knownOrderIds);

      if (newOrderIds.isNotEmpty) {
        for (final orderId in newOrderIds) {
          final newOrder = currentOrders.firstWhere((p) => p.id == orderId);
          
          // Solo notificar si el pedido fue creado recientemente (últimos 5 minutos)
          // Esto evita notificar pedidos antiguos que aparecen por primera vez
          final createdAt = newOrder.createdAt;
          if (createdAt != null) {
            final timeDiff = now.difference(createdAt);
            if (timeDiff.inMinutes <= 5 && newOrder.status == 'pendiente') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(newOrderNotificationProvider.notifier).state =
                      OrderNotification(
                    message: 'Pedido #${newOrder.id.substring(0, 8).toUpperCase()}',
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                  );

                  // Auto-limpiar después de 3.5 segundos
                  Future.delayed(const Duration(milliseconds: 3500), () {
                    if (mounted) {
                      ref.read(newOrderNotificationProvider.notifier).state = null;
                    }
                  });
                }
              });
            }
          }
        }
      }

      // Detectar pedidos MODIFICADOS (cambió la cantidad de items)
      for (final order in currentOrders) {
        final orderId = order.id;
        final currentItemCount = order.items.length;
        final previousItemCount = _orderItemCounts[orderId];

        // Solo notificar si:
        // 1. El pedido ya existía
        // 2. Cambió la cantidad de items (agregaron o quitaron productos)
        // 3. El pedido sigue en estado pendiente
        if (previousItemCount != null &&
            currentItemCount != previousItemCount &&
            order.status == 'pendiente') {
          String notificationMessage;

          if (currentItemCount > previousItemCount) {
            final itemsAdded = currentItemCount - previousItemCount;
            notificationMessage =
                'Pedido #${orderId.substring(0, 8).toUpperCase()} modificado (+$itemsAdded productos)';
          } else {
            final itemsRemoved = previousItemCount - currentItemCount;
            notificationMessage =
                'Pedido #${orderId.substring(0, 8).toUpperCase()} modificado (-$itemsRemoved productos)';
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(updatedOrderNotificationProvider.notifier).state =
                  OrderNotification(
                message: notificationMessage,
                timestamp: DateTime.now().millisecondsSinceEpoch,
              );

              // Auto-limpiar después de 3.5 segundos
              Future.delayed(const Duration(milliseconds: 3500), () {
                if (mounted) {
                  ref.read(updatedOrderNotificationProvider.notifier).state =
                      null;
                }
              });
            }
          });
        }
      }
    }

    // Actualizar IDs conocidos y conteo de items
    _knownOrderIds = currentIds;
    _orderItemCounts = {
      for (var order in currentOrders) order.id: order.items.length
    };
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrdersAsync = ref.watch(pendingPedidosProvider);

    return pendingOrdersAsync.when(
      data: (pedidos) {
        // Verificar nuevos pedidos
        _checkForNewOrders(pedidos);

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
                child: _CardStackView(
                  pedidos: pedidos,
                  emptyStateColor: const Color(0xFFF97316),
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
class _CompletedOrdersTab extends ConsumerStatefulWidget {
  const _CompletedOrdersTab();

  @override
  ConsumerState<_CompletedOrdersTab> createState() =>
      _CompletedOrdersTabState();
}

class _CompletedOrdersTabState extends ConsumerState<_CompletedOrdersTab> {
  @override
  Widget build(BuildContext context) {
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
            refresh() async => ref.invalidate(pedidosStreamProvider);

            if (!isWide) {
              return RefreshIndicator(
                color: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF0F172A),
                onRefresh: refresh,
                child: _CardStackView(
                  pedidos: pedidos,
                  emptyStateColor: const Color(0xFF10B981),
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
class _EmptyState extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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

class _ErrorState extends ConsumerWidget {
  final Object error;
  const _ErrorState(this.error);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
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
