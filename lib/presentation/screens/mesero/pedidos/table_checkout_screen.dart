import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';
import 'package:restaurante_app/presentation/providers/mesero/mesas_provider.dart';
import 'package:restaurante_app/presentation/widgets/payment_bottom_sheet.dart';
import 'package:restaurante_app/presentation/widgets/search_text.dart';

class TableCheckoutScreen extends ConsumerStatefulWidget {
  const TableCheckoutScreen({super.key});

  @override
  ConsumerState<TableCheckoutScreen> createState() => _TableCheckoutScreenState();
}

class _TableCheckoutScreenState extends ConsumerState<TableCheckoutScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _modeFilter = 'all';
  String _paymentFilter = 'pending';

  static const Map<String, Color> _statusColors = {
    'pendiente': Color(0xFFF97316),
    'preparando': Color(0xFFF59E0B),
    'terminado': Color(0xFF22C55E),
    'entregado': Color(0xFF38BDF8),
    'pagado': Color(0xFF8B5CF6),
    'cancelado': Color(0xFFEF4444),
  };

  static final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'es_CO', symbol: r'$');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedidosAsync = ref.watch(pedidosStreamProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: pedidosAsync.when(
        data: (pedidos) {
          final last7DaysOrders = _ordersLast7Days(pedidos);
          final filtered = _applyFilters(last7DaysOrders);
          final stats = _computeStats(last7DaysOrders);

          return Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Volver',
              ),
            ),
            body: Stack(
              children: [
                Container(
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
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 20,
                      vertical: isTablet ? 24 : 16,
                    ),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(
                            isTablet: isTablet,
                            stats: stats,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        SliverToBoxAdapter(
                          child: _buildFilters(isTablet),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final pedido = filtered[index];
                                final statusColor =
                                    _statusColors[pedido.status.toLowerCase()] ??
                                        const Color(0xFF6366F1);
                                final isPriority = _isPriority(pedido);
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == filtered.length - 1 ? 28 : 18,
                                  ),
                                  child: _CheckoutCard(
                                    pedido: pedido,
                                    isTablet: isTablet,
                                    statusColor: statusColor,
                                    isPriority: isPriority,
                                    currencyFormatter: _currencyFormatter,
                                    onCharge: () => _handleCharge(pedido),
                                    onViewTicket: () => _openTicket(pedido.id, pedido),
                                  ),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: _ScrollToTopButton(controller: _scrollController),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          ),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Volver',
            ),
          ),
          body: Stack(
            children: [
              Container(
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
              ),
              Center(child: _buildErrorState(error)),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeader({
    required bool isTablet,
    required _CheckoutStats stats,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cobrar Pedidos',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestiona el cobro de pedidos de los últimos 7 días.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _SummaryStat(
                title: 'Pendientes',
                value: stats.pendingCount.toString(),
                color: _statusColors['terminado']!,
                icon: Icons.timer_outlined,
              ),
              const SizedBox(width: 12),
              _SummaryStat(
                title: 'Total pendiente',
                value: _currencyFormatter.format(stats.pendingTotal),
                color: const Color(0xFF34D399),
                icon: Icons.attach_money_rounded,
              ),
              const SizedBox(width: 12),
              _SummaryStat(
                title: 'Pagados',
                value: stats.paidCount.toString(),
                color: _statusColors['pagado']!,
                icon: Icons.verified_rounded,
              ),
              const SizedBox(width: 12),
              _SummaryStat(
                title: 'Total pagado',
                value: _currencyFormatter.format(stats.paidTotal),
                color: const Color(0xFF60A5FA),
                icon: Icons.receipt_long_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildFilters(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBarText(
          onChanged: (value) {
            _searchController.text = value;
            setState(() {});
          },
          hintText: 'Buscar por mesa, cliente o código',
          margin: const EdgeInsets.only(bottom: 12),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              _buildPaymentChip(
                label: 'Pendientes',
                value: 'pending',
                selectedValue: _paymentFilter,
                color: _statusColors['terminado']!,
              ),
              _buildPaymentChip(
                label: 'Pagados',
                value: 'paid',
                selectedValue: _paymentFilter,
                color: _statusColors['pagado']!,
              ),
              _buildPaymentChip(
                label: 'Todos',
                value: 'all',
                selectedValue: _paymentFilter,
                color: const Color(0xFF71717A),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildModeChip(
                label: 'Todos',
                value: 'all',
                selectedValue: _modeFilter,
                color: const Color(0xFF38BDF8),
              ),
              _buildModeChip(
                label: 'Mesas',
                value: 'mesa',
                selectedValue: _modeFilter,
                color: const Color(0xFF8B5CF6),
              ),
              _buildModeChip(
                label: 'Domicilio',
                value: 'domicilio',
                selectedValue: _modeFilter,
                color: const Color(0xFF22D3EE),
              ),
              _buildModeChip(
                label: 'Para llevar',
                value: 'para_llevar',
                selectedValue: _modeFilter,
                color: const Color(0xFF34D399),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChip({
    required String label,
    required String value,
    required String selectedValue,
    required Color color,
  }) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _paymentFilter = value),
        selectedColor: color.withValues(alpha: 0.7),
        backgroundColor: const Color(0xFF1F233A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required String value,
    required String selectedValue,
    required Color color,
  }) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _modeFilter = value),
        selectedColor: color.withValues(alpha: 0.7),
        backgroundColor: const Color(0xFF1F233A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }

  List<Pedido> _ordersLast7Days(List<Pedido> pedidos) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return pedidos.where((pedido) {
      final reference = pedido.createdAt ?? pedido.updatedAt;
      if (reference == null) return false;
      return reference.isAfter(sevenDaysAgo);
    }).toList();
  }

  List<Pedido> _applyFilters(List<Pedido> pedidos) {
    final query = _searchController.text.trim().toLowerCase();
    const readyStatuses = {'terminado', 'entregado', 'completado', 'listo', 'pagado'};

    final result = pedidos.where((pedido) {
      final status = pedido.status.toLowerCase();
      final isPaid = pedido.pagado;

      if (_modeFilter != 'all' && pedido.mode.toLowerCase() != _modeFilter) {
        return false;
      }

      if (!isPaid && !readyStatuses.contains(status)) {
        return false;
      }

      switch (_paymentFilter) {
        case 'pending':
          if (isPaid) return false;
          break;
        case 'paid':
          if (!isPaid) return false;
          break;
      }

      if (query.isEmpty) {
        return true;
      }

      final mesa = (pedido.mesaNombre ?? '').toLowerCase();
      final cliente = (pedido.clienteNombre ?? pedido.cliente ?? '').toLowerCase();
      final telefono = (pedido.clienteTelefono ?? '').toLowerCase();
      final direccion = (pedido.clienteDireccion ?? '').toLowerCase();
      final identifier = pedido.id.toLowerCase();

      return mesa.contains(query) ||
             cliente.contains(query) ||
             telefono.contains(query) ||
             direccion.contains(query) ||
             identifier.contains(query);
    }).toList();

    result.sort((a, b) {
      final dateA = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return result;
  }

  _CheckoutStats _computeStats(List<Pedido> pedidos) {
    double pendingTotal = 0;
    double paidTotal = 0;
    int pendingCount = 0;
    int paidCount = 0;

    for (final pedido in pedidos) {
      if (pedido.pagado) {
        paidTotal += pedido.total;
        paidCount++;
      } else {
        pendingTotal += pedido.total;
        pendingCount++;
      }
    }

    return _CheckoutStats(
      pendingTotal: pendingTotal,
      pendingCount: pendingCount,
      paidTotal: paidTotal,
      paidCount: paidCount,
    );
  }

  bool _isPriority(Pedido pedido) {
    final notas = (pedido.notas ?? '').toLowerCase();
    if (notas.contains('[prioridad]')) {
      return true;
    }
    if (pedido.extras.isNotEmpty) {
      final lastItems = pedido.extras.last.items;
      if (lastItems.any((item) => (item.notas ?? '').toLowerCase().contains('prioridad'))) {
        return true;
      }
    }
    final priorityLevel = (pedido.toJson()['priorityLevel'] ?? '').toString().toLowerCase();
    return priorityLevel == 'alta';
  }

  Future<void> _handleCharge(Pedido pedido) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentBottomSheet(
        pedidoId: pedido.id,
        onPaid: () => SnackbarHelper.showSuccess('Pago registrado correctamente'),
      ),
    );

    if (result == true && mounted) {
      // Liberar la mesa si es un pedido de mesa
      if (pedido.mode.toLowerCase() == 'mesa' && pedido.mesaId != null) {
        await _liberarMesaTrasPago(pedido);
      }

      // Navegar al ticket para mostrar el comprobante
      if (mounted) {
        _openTicket(pedido.id, pedido);
      }
    }
  }

  /// Libera la mesa después de completar el pago
  Future<void> _liberarMesaTrasPago(Pedido pedido) async {
    try {
      final mesaIdInt = pedido.mesaId is String
          ? int.tryParse(pedido.mesaId.toString())
          : (pedido.mesaId is int ? pedido.mesaId as int : null);

      if (mesaIdInt == null) return;

      // Buscar la mesa en el provider
      final mesas = ref.read(mesasStreamProvider).value ?? [];
      final mesa = mesas.firstWhere(
        (m) => m.id == mesaIdInt,
        orElse: () => throw Exception('Mesa no encontrada'),
      );

      // Actualizar la mesa a disponible
      final mesaActualizada = mesa.copyWith(
        estado: 'disponible',
        cliente: null,
        tiempo: null,
        pedidoId: null,
        horaOcupacion: null,
        total: null,
        fechaReserva: null,
      );

      await ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);
    } catch (e) {
      // Silenciosamente fallar si no se puede liberar la mesa
      debugPrint('Error al liberar mesa tras pago: $e');
    }
  }

  void _openTicket(String pedidoId, Pedido pedido) {
    final mesaNombre = (pedido.mesaNombre ?? '').trim();
    final clienteNombre = (pedido.clienteNombre ?? '').trim();
    final query = <String, String>{};
    if (pedido.mesaId != null) {
      query['mesaId'] = pedido.mesaId.toString();
    }
    if (mesaNombre.isNotEmpty) {
      query['mesaNombre'] = mesaNombre;
    }
    if (clienteNombre.isNotEmpty) {
      query['clienteNombre'] = clienteNombre;
    }

    context.push(
      Uri(path: '/mesero/pedidos/ticket/$pedidoId', queryParameters: query).toString(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 46, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay pedidos para cobrar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona otro día o ajusta los filtros de búsqueda.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Error al cargar pedidos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

}
class _CheckoutStats {
  const _CheckoutStats({
    required this.pendingTotal,
    required this.pendingCount,
    required this.paidTotal,
    required this.paidCount,
  });

  final double pendingTotal;
  final int pendingCount;
  final double paidTotal;
  final int paidCount;
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.pedido,
    required this.isTablet,
    required this.statusColor,
    required this.isPriority,
    required this.currencyFormatter,
    required this.onCharge,
    required this.onViewTicket,
  });

  final Pedido pedido;
  final bool isTablet;
  final Color statusColor;
  final bool isPriority;
  final NumberFormat currencyFormatter;
  final VoidCallback onCharge;
  final VoidCallback onViewTicket;

  @override
  Widget build(BuildContext context) {
    final itemsCount = pedido.items.fold<int>(0, (total, item) => total + item.cantidad);
    final priorityLabel = isPriority ? 'Prioridad' : 'Normal';
    final priorityColor = isPriority ? const Color(0xFFEF4444) : const Color(0xFF38BDF8);
    final isPaid = pedido.pagado;
    final totalFormatted = currencyFormatter.format(pedido.total);
    final pendingLabel = isPaid ? 'Pagado' : 'Pendiente por cobrar';
    final statusLabel = _statusText(pedido.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF121429),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locationLabel(pedido),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _ChipInfo(
                          icon: Icons.payments_rounded,
                          color: statusColor,
                          label: pendingLabel,
                        ),
                        _ChipInfo(
                          icon: Icons.priority_high_rounded,
                          color: priorityColor,
                          label: priorityLabel,
                        ),
                        if ((pedido.meseroNombre ?? '').trim().isNotEmpty)
                          _ChipInfo(
                            icon: Icons.person_outline,
                            color: Colors.white.withValues(alpha: 0.7),
                            label: (pedido.meseroNombre ?? '').trim(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: statusColor.withValues(alpha: 0.18),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _MetaItem(
                icon: Icons.inventory_2_outlined,
                label: '$itemsCount ${itemsCount == 1 ? 'ítem' : 'ítems'}',
              ),
              _MetaItem(
                icon: Icons.schedule_rounded,
                label: _timeAgo(pedido.updatedAt ?? pedido.createdAt),
              ),
              _MetaItem(
                icon: Icons.attach_money,
                label: totalFormatted,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isPaid)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewTicket,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Ver ticket'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCharge,
                    icon: const Icon(Icons.attach_money_rounded),
                    label: const Text('Registrar pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewTicket,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Ver ticket'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _locationLabel(Pedido pedido) {
    final mesaNombre = (pedido.mesaNombre ?? '').trim();
    if (mesaNombre.isNotEmpty) {
      return mesaNombre;
    }
    final clienteNombre = (pedido.clienteNombre ?? '').trim();
    if (clienteNombre.isNotEmpty) {
      return clienteNombre;
    }
    final tableNumber = (pedido.tableNumber ?? '').trim();
    if (tableNumber.isNotEmpty) {
      return 'Mesa $tableNumber';
    }
    return 'Mesa sin nombre';
  }

  static String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Sin registro';
    }
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Hace instantes';
    }
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      final minutes = difference.inMinutes % 60;
      return 'Hace ${difference.inHours}h ${minutes}m';
    }
    if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    }
    return DateFormat('dd MMM • HH:mm', 'es').format(dateTime);
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return content;
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121429),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollToTopButton extends StatefulWidget {
  const _ScrollToTopButton({required this.controller});

  final ScrollController controller;

  @override
  State<_ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<_ScrollToTopButton> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    final shouldBeVisible = widget.controller.offset > 400;
    if (shouldBeVisible != _isVisible) {
      setState(() {
        _isVisible = shouldBeVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: _isVisible ? Offset.zero : const Offset(0, 1.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isVisible ? 1 : 0,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () {
            widget.controller.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: const Icon(Icons.arrow_upward_rounded),
        ),
      ),
    );
  }
}
  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
        return 'En cocina';
      case 'terminado':
        return 'Listo para pago';
      case 'entregado':
        return 'Entregado';
      case 'pagado':
        return 'Pagado';
      default:
        return status;
    }
  }
