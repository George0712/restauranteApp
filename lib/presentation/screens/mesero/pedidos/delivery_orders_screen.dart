import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/widgets/search_text.dart';
import 'package:uuid/uuid.dart';

class DeliveryOrdersScreen extends ConsumerStatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  ConsumerState<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends ConsumerState<DeliveryOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _statusFilter = 'all';
  bool _creatingOrder = false;
  final Set<String> _processingOrders = <String>{};

  static const Map<String, Color> _statusColors = {
    'pendiente': Color(0xFFF97316),
    'preparando': Color(0xFFF59E0B),
    'terminado': Color(0xFF22C55E),
    'entregado': Color(0xFF38BDF8),
    'pagado': Color(0xFF8B5CF6),
    'cancelado': Color(0xFFEF4444),
    'nuevo': Color(0xFF6366F1),
  };

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 900;
    final pedidosAsync = ref.watch(pedidosStreamProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Volver',
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _creatingOrder ? null : _openCreateDeliverySheet,
          backgroundColor: const Color(0xFF22D3EE),
          foregroundColor: Colors.white,
          icon: _creatingOrder
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add_rounded),
          label: Text(_creatingOrder ? 'Creando pedido...' : 'Nuevo pedido'),
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
              child: pedidosAsync.when(
                data: (pedidos) {
                  final deliveryOrders = pedidos
                      .where((pedido) => pedido.mode.toLowerCase() == 'domicilio')
                      .toList();
                  final stats = _computeStats(deliveryOrders);
                  final filtered = _applyFilters(deliveryOrders);

                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 36 : 20,
                            vertical: isTablet ? 18 : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pedidos Domiciliarios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 32 : 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gestiona los pedidos domiciliarios desde esta seccion.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: isTablet ? 18 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFilters(
                                isTablet: isTablet,
                                stats: stats,
                                total: deliveryOrders.length,
                              ),
                              const SizedBox(height: 16),
                              SearchBarText(
                                onChanged: (value) => setState(() {}),
                                hintText: 'Buscar por nombre, telefono, direccion o ID',
                                margin: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 16),
                              if (filtered.isEmpty)
                                _EmptyState(
                                  hasOrders: deliveryOrders.isNotEmpty,
                                  onClear: () {
                                    setState(() {
                                      _statusFilter = 'all';
                                      _searchController.clear();
                                    });
                                  },
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final pedido = filtered[index];
                                    final color =
                                        _statusColors[pedido.status.toLowerCase()] ??
                                            const Color(0xFF6366F1);
                                    final lowerStatus = pedido.status.toLowerCase();
                                    final isProcessing = _processingOrders.contains(pedido.id);
                                    final canCancel = lowerStatus == 'nuevo' ||
                                        lowerStatus == 'pendiente' ||
                                        lowerStatus == 'preparando';
                                    final canDelete =
                                        lowerStatus == 'nuevo' && pedido.items.isEmpty;
                                    return _DeliveryOrderCard(
                                      pedido: pedido,
                                      statusColor: color,
                                      onManage: () => _goToDeliveryOrder(pedido),
                                      onCopyPhone: (pedido.clienteTelefono ?? '').isEmpty
                                          ? null
                                          : () => _copyToClipboard(
                                                pedido.clienteTelefono!,
                                                'Telefono copiado',
                                              ),
                                      onCopyAddress: (pedido.clienteDireccion ?? '').isEmpty
                                          ? null
                                          : () => _copyToClipboard(
                                                pedido.clienteDireccion!,
                                                'Direccion copiada',
                                              ),
                                      onCancel: canCancel ? () => _cancelOrder(pedido) : null,
                                      onDelete: canDelete ? () => _deleteOrder(pedido) : null,
                                      isBusy: isProcessing,
                                      canCancel: canCancel,
                                      canDelete: canDelete,
                                    );
                                  },
                                ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
                error: (error, _) => _ErrorState(error: error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _computeStats(List<Pedido> pedidos) {
    final stats = <String, int>{
      'pendiente': 0,
      'preparando': 0,
      'terminado': 0,
      'entregado': 0,
      'pagado': 0,
      'cancelado': 0,
      'nuevo': 0,
    };

    for (final pedido in pedidos) {
      final status = pedido.status.toLowerCase();
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  List<Pedido> _applyFilters(List<Pedido> pedidos) {
    final search = _searchController.text.trim().toLowerCase();

    final filtered = pedidos.where((pedido) {
      final statusMatches =
          _statusFilter == 'all' || pedido.status.toLowerCase() == _statusFilter;
      if (!statusMatches) return false;

      if (search.isEmpty) return true;

      final fields = <String?>[
        pedido.id,
        pedido.tableNumber,
        pedido.cliente,
        pedido.clienteNombre,
        pedido.clienteTelefono,
        pedido.clienteDireccion,
        pedido.clienteReferencia,
      ];

      return fields
          .whereType<String>()
          .map((value) => value.toLowerCase())
          .any((value) => value.contains(search));
    }).toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return filtered;
  }

  Widget _buildFilters({
    required bool isTablet,
    required Map<String, int> stats,
    required int total,
  }) {
    final filters = <_FilterData>[
      _FilterData(
        key: 'all',
        label: 'Todos',
        count: total,
        color: const Color(0xFF6366F1),
        icon: Icons.local_mall_rounded,
      ),
      _FilterData(
        key: 'nuevo',
        label: 'Nuevos',
        count: stats['nuevo'] ?? 0,
        color: const Color(0xFF818CF8),
        icon: Icons.fiber_new_rounded,
      ),
      _FilterData(
        key: 'pendiente',
        label: 'Pendientes',
        count: stats['pendiente'] ?? 0,
        color: const Color(0xFFF97316),
        icon: Icons.pending_actions_outlined,
      ),
      _FilterData(
        key: 'preparando',
        label: 'Preparando',
        count: stats['preparando'] ?? 0,
        color: const Color(0xFFF59E0B),
        icon: Icons.local_fire_department_rounded,
      ),
      _FilterData(
        key: 'terminado',
        label: 'Listos',
        count: stats['terminado'] ?? 0,
        color: const Color(0xFF22C55E),
        icon: Icons.check_circle_outline,
      ),
      _FilterData(
        key: 'entregado',
        label: 'Entregados',
        count: stats['entregado'] ?? 0,
        color: const Color(0xFF38BDF8),
        icon: Icons.outbox_outlined,
      ),
      _FilterData(
        key: 'pagado',
        label: 'Pagados',
        count: stats['pagado'] ?? 0,
        color: const Color(0xFF8B5CF6),
        icon: Icons.attach_money_rounded,
      ),
      _FilterData(
        key: 'cancelado',
        label: 'Cancelados',
        count: stats['cancelado'] ?? 0,
        color: const Color(0xFFEF4444),
        icon: Icons.cancel_outlined,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(
        top: 2,
        bottom: isTablet ? 10 : 8,
      ),
      child: Row(
        children: [
          for (var i = 0; i < filters.length; i++) ...[
            _FilterChip(
              data: filters[i],
              isSelected: _statusFilter == filters[i].key,
              onTap: () => setState(() => _statusFilter = filters[i].key),
            ),
            if (i != filters.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }


  Future<void> _openCreateDeliverySheet() async {
    final data = await showModalBottomSheet<DeliveryCustomerData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const _DeliveryCustomerSheet(),
    );

    if (!mounted || data == null) return;

    // Crear un ID único para el pedido (igual que las órdenes de mesa)
    final pedidoId = const Uuid().v4();

    // Navegar a selección de productos con datos del cliente
    _goToDeliveryProductSelection(pedidoId, data);
  }

  void _goToDeliveryProductSelection(String pedidoId, DeliveryCustomerData data) async {
    // Crear pedido vacío en Firestore
    setState(() => _creatingOrder = true);

    try {
      final user = await ref.read(userModelProvider.future);
      final timestamp = FieldValue.serverTimestamp();

      final payload = <String, dynamic>{
        'id': pedidoId,
        'mode': 'domicilio',
        'status': 'nuevo',
        'subtotal': 0.0,
        'total': 0.0,
        'pagado': false,
        'paymentStatus': 'pending',
        'cliente': data.nombre,
        'clienteNombre': data.nombre,
        'clienteTelefono': data.telefono,
        'clienteDireccion': data.direccion,
        'phone': data.telefono,
        'address': data.direccion,
        if (data.referencia != null && data.referencia!.isNotEmpty)
          'clienteReferencia': data.referencia,
        if (data.referencia != null && data.referencia!.isNotEmpty)
          'reference': data.referencia,
        if (data.notas != null && data.notas!.isNotEmpty) 'notas': data.notas,
        'items': <Map<String, dynamic>>[],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'meseroId': user.uid,
        'meseroNombre': '${user.nombre} ${user.apellidos}'.trim(),
      };

      await FirebaseFirestore.instance.collection('pedido').doc(pedidoId).set(payload);

      if (!mounted) return;

      final query = <String, String>{
        'orderMode': 'domicilio',
        'clienteNombre': Uri.encodeComponent(data.nombre),
        'clienteTelefono': Uri.encodeComponent(data.telefono),
        'clienteDireccion': Uri.encodeComponent(data.direccion),
        if (data.referencia != null && data.referencia!.isNotEmpty)
          'clienteReferencia': Uri.encodeComponent(data.referencia!),
        if (data.notas != null && data.notas!.isNotEmpty)
          'notas': Uri.encodeComponent(data.notas!),
      };

      final uri = Uri(
        path: '/mesero/pedidos/detalle/domicilio/$pedidoId',
        queryParameters: query,
      );
      context.push(uri.toString());
    } catch (error) {
      SnackbarHelper.showError('No se pudo crear el pedido: $error');
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  void _goToDeliveryOrder(Pedido pedido) {
    // Mostrar panel de gestión unificado para todos los estados
    _showOrderManagementSheet(pedido);
  }

  Future<void> _showOrderManagementSheet(Pedido pedido) async {
    final lowerStatus = pedido.status.toLowerCase();
    final isActive = lowerStatus == 'nuevo' || lowerStatus == 'pendiente' || lowerStatus == 'preparando';
    final isCompleted = lowerStatus == 'terminado' || lowerStatus == 'entregado' || lowerStatus == 'pagado';

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Text(
              'Gestionar Pedido #${pedido.id.substring(0, 6).toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusDescription(lowerStatus),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Cliente',
                    value: pedido.clienteNombre ?? pedido.cliente ?? 'Sin nombre',
                  ),
                  if (pedido.clienteTelefono?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: pedido.clienteTelefono!,
                    ),
                  ],
                  if (pedido.clienteDireccion?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Dirección',
                      value: pedido.clienteDireccion!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Artículos',
                    value: '${pedido.items.fold<int>(0, (acc, item) => acc + item.cantidad)} producto${pedido.items.fold<int>(0, (acc, item) => acc + item.cantidad) == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.payments_outlined,
                    label: 'Total',
                    value: NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0)
                        .format(pedido.total),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Management actions
            // Actions for ACTIVE orders (nuevo, pendiente, preparando)
            if (isActive) ...[
              // Process payment
              if (!pedido.pagado) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _processPayment(pedido);
                    },
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Procesar pago'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Mark as ready (only for preparando)
              if (lowerStatus == 'preparando') ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _markAsReady(pedido);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar como listo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Contact customer
              if (pedido.clienteTelefono?.isNotEmpty ?? false) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _contactCustomer(pedido);
                    },
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Contactar cliente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // Actions for COMPLETED orders (terminado, entregado, pagado)
            if (isCompleted) ...[
              // Mark as delivered (only for terminado)
              if (lowerStatus == 'terminado') ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _markAsDelivered(pedido);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar como entregado'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // View order details
              if (lowerStatus == 'entregado' || lowerStatus == 'pagado') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _viewOrderDetails(pedido);
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Ver detalles del pedido'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Contact customer
              if (pedido.clienteTelefono?.isNotEmpty ?? false) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _contactCustomer(pedido);
                    },
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Contactar cliente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // Actions for CANCELLED orders
            if (lowerStatus == 'cancelado') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFEF4444)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pedido cancelado - No hay acciones disponibles',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Center(
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'nuevo':
        return 'Pedido recién creado';
      case 'pendiente':
        return 'En espera de preparación';
      case 'preparando':
        return 'En preparación';
      case 'terminado':
        return 'Listo para entrega';
      case 'entregado':
        return 'Pedido completado y entregado';
      case 'pagado':
        return 'Pedido pagado';
      case 'cancelado':
        return 'Pedido cancelado';
      default:
        return 'Estado: $status';
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _contactCustomer(Pedido pedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contactar cliente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.copy_rounded, color: Color(0xFF22C55E)),
              ),
              title: const Text(
                'Copiar número',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                pedido.clienteTelefono ?? '',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              onTap: () {
                _copyToClipboard(pedido.clienteTelefono!, 'Teléfono copiado');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.message_rounded, color: Color(0xFF25D366)),
              ),
              title: const Text(
                'Abrir WhatsApp',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Enviar mensaje al cliente',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Navigator.pop(context);
                _openWhatsApp(pedido);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openWhatsApp(Pedido pedido) {
    // final phone = pedido.clienteTelefono?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    // final orderNumber = pedido.id.substring(0, 6).toUpperCase();
    // final message = Uri.encodeComponent(
    //   'Hola! Tu pedido #$orderNumber está siendo preparado. Te avisaremos cuando esté en camino.',
    // );
    // final url = 'https://wa.me/57$phone?text=$message';

    SnackbarHelper.showInfo('Función WhatsApp pendiente de implementar');
    // In a real app, you would use url_launcher package here
    // launch(url);
  }

  Future<void> _processPayment(Pedido pedido) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DeliveryPaymentSheet(pedidoId: pedido.id),
    );

    if (result == true && mounted) {
      SnackbarHelper.showSuccess('Pago procesado correctamente');
    }
  }

  Future<void> _markAsReady(Pedido pedido) async {
    if (_processingOrders.contains(pedido.id)) return;

    final confirmed = await _confirmAction(
      title: 'Marcar como listo',
      message: '¿El pedido está completo y listo para ser enviado? Se notificará al cliente.',
      confirmLabel: 'Marcar como listo',
      confirmColor: const Color(0xFF22C55E),
    );

    if (confirmed != true) return;

    setState(() {
      _processingOrders.add(pedido.id);
    });

    try {
      await FirebaseFirestore.instance.collection('pedido').doc(pedido.id).update({
        'status': 'terminado',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      SnackbarHelper.showSuccess('Pedido marcado como listo para envío');
    } catch (error) {
      SnackbarHelper.showError('Error al actualizar estado: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingOrders.remove(pedido.id);
        });
      }
    }
  }

  Future<void> _markAsDelivered(Pedido pedido) async {
    if (_processingOrders.contains(pedido.id)) return;

    setState(() {
      _processingOrders.add(pedido.id);
    });

    try {
      await FirebaseFirestore.instance.collection('pedido').doc(pedido.id).update({
        'status': 'entregado',
        'updatedAt': FieldValue.serverTimestamp(),
        'deliveredAt': FieldValue.serverTimestamp(),
      });
      SnackbarHelper.showSuccess('Pedido marcado como entregado.');
    } catch (error) {
      SnackbarHelper.showError('No se pudo actualizar el estado: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingOrders.remove(pedido.id);
        });
      }
    }
  }

  void _viewOrderDetails(Pedido pedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            const Text(
              'Detalles del Pedido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pedido #${pedido.id.substring(0, 6).toUpperCase()}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            // Items list
            if (pedido.items.isNotEmpty) ...[
              const Text(
                'Productos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...pedido.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item.cantidad}x',
                            style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.adicionales != null && item.adicionales!.isNotEmpty)
                              Text(
                                item.adicionales!
                                    .map((adicional) => adicional['name'] ?? adicional['nombre'] ?? '')
                                    .where((nombre) => nombre.isNotEmpty)
                                    .join(', '),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'es_CO',
                          symbol: r'$',
                          decimalDigits: 0,
                        ).format(item.precio * item.cantidad),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'es_CO',
                        symbol: r'$',
                        decimalDigits: 0,
                      ).format(pedido.total),
                      style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(Pedido pedido) async {
    if (_processingOrders.contains(pedido.id)) return;
    final confirmed = await _confirmAction(
      title: 'Cancelar pedido',
      message:
          'Deseas cancelar el pedido #${pedido.id.substring(0, 6).toUpperCase()}? El equipo de cocina sera notificado.',
      confirmLabel: 'Cancelar pedido',
      confirmColor: const Color(0xFFEF4444),
    );
    if (confirmed != true) return;

    setState(() {
      _processingOrders.add(pedido.id);
    });

    try {
      await FirebaseFirestore.instance.collection('pedido').doc(pedido.id).update({
        'status': 'cancelado',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'mesero',
      });
      SnackbarHelper.showSuccess('Pedido cancelado correctamente.');
    } catch (error) {
      SnackbarHelper.showError('No se pudo cancelar el pedido: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingOrders.remove(pedido.id);
        });
      }
    }
  }

  Future<void> _deleteOrder(Pedido pedido) async {
    if (_processingOrders.contains(pedido.id)) return;

    final confirmed = await _confirmAction(
      title: 'Eliminar pedido',
      message:
          'Eliminar definitivamente el pedido #${pedido.id.substring(0, 6).toUpperCase()}? No podras recuperarlo.',
      confirmLabel: 'Eliminar',
      confirmColor: const Color(0xFFDC2626),
    );
    if (confirmed != true) return;

    setState(() {
      _processingOrders.add(pedido.id);
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('pedido').doc(pedido.id);
      final tickets = await docRef.collection('tickets').get();
      for (final ticket in tickets.docs) {
        await ticket.reference.delete();
      }
      await docRef.delete();
      SnackbarHelper.showSuccess('Pedido eliminado.');
    } catch (error) {
      SnackbarHelper.showError('No se pudo eliminar el pedido: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingOrders.remove(pedido.id);
        });
      }
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    SnackbarHelper.showInfo(message);
  }
}
class _FilterData {
  final String key;
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _FilterData({
    required this.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _FilterData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? data.color.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);
    final borderColor = isSelected
        ? data.color.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.14);
    final valueColor = isSelected ? Colors.white : data.color;
    final iconColor = isSelected ? Colors.white : data.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.28),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? data.color.withValues(alpha: 0.4)
                    : data.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.count.toString(),
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  const _DeliveryOrderCard({
    required this.pedido,
    required this.statusColor,
    required this.onManage,
    this.onCopyPhone,
    this.onCopyAddress,
    this.onCancel,
    this.onDelete,
    this.isBusy = false,
    this.canCancel = false,
    this.canDelete = false,
  });

  final Pedido pedido;
  final Color statusColor;
  final VoidCallback onManage;
  final VoidCallback? onCopyPhone;
  final VoidCallback? onCopyAddress;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final bool isBusy;
  final bool canCancel;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final String name = pedido.clienteNombre ?? pedido.cliente ?? 'Cliente sin nombre';
    final String? telefono = pedido.clienteTelefono;
    final String? direccion = pedido.clienteDireccion;
    // final String? referencia = pedido.clienteReferencia;
    final int itemsCount = pedido.items.fold<int>(0, (acc, item) => acc + item.cantidad);
    final DateTime created = pedido.createdAt ?? pedido.updatedAt ?? DateTime.now();
    final String elapsed = _formatElapsed(created);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.24),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pedido #${pedido.id.substring(0, 6).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(label: pedido.status.toUpperCase(), color: statusColor),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (telefono != null && telefono.isNotEmpty)
                _InfoRow(icon: Icons.phone_rounded, label: telefono, onPressed: onCopyPhone),
              if (direccion != null && direccion.isNotEmpty) ...[
                _InfoRow(icon: Icons.location_on_rounded, label: direccion, onPressed: onCopyAddress),
              ],
              // if (referencia != null && referencia.isNotEmpty) ...[
              //   const SizedBox(height: 8),
              //   _InfoRow(icon: Icons.push_pin_outlined, label: referencia),
              // ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(icon: Icons.receipt_long_outlined, label: '$itemsCount articulo${itemsCount == 1 ? '' : 's'}'),
                    _Tag(
                      icon: Icons.payments_outlined,
                      label: NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0)
                          .format(pedido.total),
                    ),
                    _Tag(icon: Icons.schedule_rounded, label: elapsed),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onManage,
                    icon: const Icon(Icons.edit_note_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    label: const Text('Gestionar pedido'),
                  ),
                ),
              ),
              if (canCancel || canDelete)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (canCancel)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isBusy ? null : onCancel,
                            icon: isBusy && onCancel != null
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 18),
                            label: Text(
                              isBusy && onCancel != null ? 'Procesando...' : 'Cancelar',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      if (canCancel && canDelete) const SizedBox(width: 12),
                      if (canDelete)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: isBusy ? null : onDelete,
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text(
                              'Eliminar',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(alpha: 0.85),
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Hace instantes';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final minutes = diff.inMinutes % 60;
      return 'Hace ${diff.inHours}h ${minutes}m';
    }
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dia${diff.inDays == 1 ? '' : 's'}';
    return DateFormat('dd MMM - HH:mm', 'es').format(date);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ),
        if (onPressed != null)
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.copy_rounded),
            color: Colors.white.withValues(alpha: 0.6),
            iconSize: 18,
            tooltip: 'Copiar',
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasOrders,
    required this.onClear,
  });

  final bool hasOrders;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasOrders ? Icons.filter_alt_off_rounded : Icons.delivery_dining_outlined,
              color: Colors.white.withValues(alpha: 0.35),
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              hasOrders ? 'Sin resultados para la busqueda' : 'Aun no hay pedidos domiciliarios',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasOrders
                  ? 'Ajusta los filtros o busca con otro dato del cliente.'
                  : 'Crea tu primer pedido a domicilio para iniciar el flujo de entrega.',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasOrders) ...[
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                label: const Text('Limpiar filtros', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              'No fue posible cargar los pedidos.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryCustomerData {
  DeliveryCustomerData({
    required this.nombre,
    required this.telefono,
    required this.direccion,
    this.referencia,
    this.notas,
  });

  final String nombre;
  final String telefono;
  final String direccion;
  final String? referencia;
  final String? notas;
}

class _DeliveryCustomerSheet extends ConsumerStatefulWidget {
  const _DeliveryCustomerSheet();

  @override
  ConsumerState<_DeliveryCustomerSheet> createState() => _DeliveryCustomerSheetState();
}

class _DeliveryCustomerSheetState extends ConsumerState<_DeliveryCustomerSheet> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  bool _showOptionalFields = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nuevo Pedido Domiciliario',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'El pago se procesa al confirmar el pedido',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _nombreController,
                          label: 'Nombre del cliente *',
                          hint: 'Ej. Ana Gomez',
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa el nombre del cliente';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _telefonoController,
                          label: 'Telefono de contacto *',
                          hint: 'Ej. 320 123 4567',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Agrega el telefono de contacto';
                            }
                            if (trimmed.length < 7) {
                              return 'El telefono es muy corto';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _direccionController,
                          label: 'Direccion de entrega *',
                          hint: 'Ej. Calle 123 #45-67, Apto 302',
                          keyboardType: TextInputType.streetAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Indica la direccion completa de entrega';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: () => setState(() => _showOptionalFields = !_showOptionalFields),
                          icon: Icon(
                            _showOptionalFields ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: const Color(0xFF22C55E),
                          ),
                          label: Text(
                            _showOptionalFields ? 'Ocultar campos opcionales' : 'Mostrar campos opcionales',
                            style: const TextStyle(color: Color(0xFF22C55E)),
                          ),
                        ),
                        if (_showOptionalFields) ...[
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _referenciaController,
                            label: 'Referencia o indicaciones (Opcional)',
                            hint: 'Punto de referencia, piso, porteria, etc.',
                            maxLines: 2,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _notasController,
                            label: 'Notas (Opcional)',
                            hint: 'Informacion adicional para el equipo',
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.navigate_next_rounded),
                            label: Text(_submitting ? 'Creando...' : 'Continuar con productos'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: _submitting ? null : _handleSubmit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF22C55E)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() => _submitting = true);

    Navigator.of(context).pop(
      DeliveryCustomerData(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        referencia: _referenciaController.text.trim().isEmpty ? null : _referenciaController.text.trim(),
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      ),
    );
  }
}

// Custom payment sheet for delivery orders with "paga al recibir" option
class _DeliveryPaymentSheet extends ConsumerStatefulWidget {
  final String pedidoId;

  const _DeliveryPaymentSheet({required this.pedidoId});

  @override
  ConsumerState<_DeliveryPaymentSheet> createState() => _DeliveryPaymentSheetState();
}

class _DeliveryPaymentSheetState extends ConsumerState<_DeliveryPaymentSheet> {
  String _selectedMethod = 'cash';
  bool _processing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1B23),
            Color(0xFF2D2E37),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('pedido')
              .doc(widget.pedidoId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 260,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              );
            }

            final pedidoSnapshot = snapshot.data!;
            if (!pedidoSnapshot.exists) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No encontramos este pedido.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            final data = pedidoSnapshot.data() ?? {};
            final total = (data['total'] as num?)?.toDouble() ?? 0.0;
            final subtotal = (data['subtotal'] as num?)?.toDouble() ?? total;
            final extras = (total - subtotal).clamp(0.0, double.infinity);
            final pagado = data['pagado'] == true;
            final paymentInfo = data['payment'] as Map<String, dynamic>?;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Registrar pago',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confirma el método de pago para el pedido domiciliario.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildResumenCard(
                    subtotal: subtotal,
                    extras: extras,
                    total: total,
                    pagado: pagado,
                    paymentInfo: paymentInfo,
                  ),
                  const SizedBox(height: 20),
                  _buildMetodoPagoSelector(pagado: pagado),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade700),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _processing
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: pagado || _processing
                              ? null
                              : () => _registrarPago(total),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _processing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(_selectedMethod == 'pay_on_delivery'
                                  ? 'Confirmar pedido'
                                  : 'Confirmar pago'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumenCard({
    required double subtotal,
    required double extras,
    required double total,
    required bool pagado,
    Map<String, dynamic>? paymentInfo,
  }) {
    final metodo = (paymentInfo?['method'] ?? '').toString();
    final procesadoPor = (paymentInfo?['processedByName'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF363740).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle del cobro',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildResumenRow('Subtotal', _formatCurrency(subtotal)),
          if (extras > 0) ...[
            const SizedBox(height: 6),
            _buildResumenRow('Extras agregados', _formatCurrency(extras)),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          _buildResumenRow(
            pagado ? 'Total cobrado' : 'Total a cobrar',
            _formatCurrency(total),
            highlight: true,
          ),
          if (pagado) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Este pedido ya fue pagado.',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (metodo.isNotEmpty)
                    Text(
                      'Método: ${_getMethodLabel(metodo)}',
                      style: TextStyle(color: Colors.green.shade300),
                    ),
                  if (procesadoPor.isNotEmpty)
                    Text(
                      'Registrado por: $procesadoPor',
                      style: TextStyle(color: Colors.green.shade300),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            color: highlight ? Colors.white : Colors.grey.shade400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? Colors.white : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildMetodoPagoSelector({required bool pagado}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Metodo de pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Theme(
          data: ThemeData(
            unselectedWidgetColor: Colors.grey.shade600,
          ),
          child: RadioListTile<String>(
            value: 'cash',
            groupValue: _selectedMethod,
            onChanged: pagado || _processing
                ? null
                : (value) {
                    setState(() {
                      _selectedMethod = value ?? 'cash';
                      _errorMessage = null;
                    });
                  },
            title: const Text(
              'Efectivo',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Pago en efectivo al momento del pedido',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            activeColor: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 8),
        Theme(
          data: ThemeData(
            unselectedWidgetColor: Colors.grey.shade600,
          ),
          child: RadioListTile<String>(
            value: 'pay_on_delivery',
            groupValue: _selectedMethod,
            onChanged: pagado || _processing
                ? null
                : (value) {
                    setState(() {
                      _selectedMethod = value ?? 'pay_on_delivery';
                      _errorMessage = null;
                    });
                  },
            title: const Text(
              'Paga al recibir',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'El cliente pagará cuando reciba el pedido',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            activeColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 8),
        Theme(
          data: ThemeData(
            unselectedWidgetColor: Colors.grey.shade600,
          ),
          child: RadioListTile<String>(
            value: 'card',
            groupValue: _selectedMethod,
            onChanged: null,
            title: Text(
              'Tarjeta',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            subtitle: Text(
              'Disponible próximamente',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            secondary: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade700),
              ),
              child: const Text(
                'Pronto',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<void> _registrarPago(double total) async {
    if (_selectedMethod != 'cash' && _selectedMethod != 'pay_on_delivery') {
      setState(() {
        _errorMessage = 'Por ahora solo es posible cobrar en efectivo o paga al recibir.';
      });
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(userModelProvider.future);

      final processedByName = '${user.nombre} ${user.apellidos}'.trim();

      // If "paga al recibir" is selected, we don't mark as paid but update payment method
      if (_selectedMethod == 'pay_on_delivery') {
        final paymentData = <String, dynamic>{
          'method': 'pay_on_delivery',
          'status': 'pending',
          'amount': total,
          'processedAt': FieldValue.serverTimestamp(),
        };

        paymentData['processedBy'] = user.uid;
        paymentData['processedByName'] = processedByName;
      
        await FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId)
            .update({
          'pagado': false,
          'paymentStatus': 'pending',
          'payment': paymentData,
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'pendiente',
        });
      } else {
        // Cash payment - mark as paid immediately
        final paymentData = <String, dynamic>{
          'method': 'cash',
          'status': 'completed',
          'amount': total,
          'processedAt': FieldValue.serverTimestamp(),
        };

        paymentData['processedBy'] = user.uid;
        paymentData['processedByName'] = processedByName;
      
        await FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId)
            .update({
          'pagado': true,
          'paymentStatus': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
          'payment': paymentData,
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'pendiente',
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No pudimos registrar el pago. Intenta nuevamente.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar pago: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    return r'$' + NumberFormat('#,##0', 'es_CO').format(value);
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'pay_on_delivery':
        return 'Paga al recibir';
      case 'card':
        return 'Tarjeta';
      default:
        return method;
    }
  }
}
