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
          backgroundColor: const Color(0xFF22C55E),
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
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'lib/core/assets/bg-mesero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
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
                              // _buildSearchField(),
                              // const SizedBox(height: 16),
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

  // Widget _buildSearchField() {
  //   return TextField(
  //     controller: _searchController,
  //     style: const TextStyle(color: Colors.white, fontSize: 14.5),
  //     decoration: InputDecoration(
  //       hintText: 'Buscar por nombre, telefono, direccion o ID',
  //       hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
  //       filled: true,
  //       fillColor: Colors.white.withValues(alpha: 0.06),
  //       prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
  //       suffixIcon: _searchController.text.isEmpty
  //           ? null
  //           : IconButton(
  //               icon: const Icon(Icons.close_rounded, color: Colors.white70),
  //               onPressed: () {
  //                 _searchController.clear();
  //                 setState(() {});
  //               },
  //             ),
  //       contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(18),
  //         borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(18),
  //         borderSide: const BorderSide(color: Color(0xFF6366F1)),
  //       ),
  //     ),
  //     onChanged: (_) => setState(() {}),
  //     textInputAction: TextInputAction.search,
  //   );
  // }

  Future<void> _openCreateDeliverySheet() async {
    final data = await showModalBottomSheet<DeliveryCustomerData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: _DeliveryCustomerSheet(
            onSubmit: (data) => Navigator.of(context).pop(data),
          ),
        );
      },
    );

    if (!mounted || data == null) return;

    setState(() => _creatingOrder = true);
    try {
      final user = await ref.read(userModelProvider.future);
      final pedidoId = const Uuid().v4();
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
        'clienteReferencia': data.referencia,
        'phone': data.telefono,
        'address': data.direccion,
        if (data.referencia != null && data.referencia!.isNotEmpty) 'reference': data.referencia,
        if (data.notas != null && data.notas!.isNotEmpty) 'notas': data.notas,
        'items': <Map<String, dynamic>>[],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'meseroId': user.uid,
        'meseroNombre': '${user.nombre} ${user.apellidos}'.trim(),
      };

      await FirebaseFirestore.instance.collection('pedido').doc(pedidoId).set(payload);

      if (!mounted) return;

      SnackbarHelper.showSuccess(
        'Pedido domiciliario creado. Agrega productos y confirma el pedido.',
      );

      _goToDeliveryOrder(
        Pedido(
          id: pedidoId,
          status: 'nuevo',
          mode: 'domicilio',
          subtotal: 0,
          total: 0,
          items: const [],
          initialItems: const [],
          cliente: data.nombre,
          clienteNombre: data.nombre,
          clienteTelefono: data.telefono,
          clienteDireccion: data.direccion,
          clienteReferencia: data.referencia,
          notas: data.notas,
          meseroId: user.uid,
          meseroNombre: '${user.nombre} ${user.apellidos}'.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      SnackbarHelper.showError('No se pudo crear el pedido: $error');
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  void _goToDeliveryOrder(Pedido pedido) {
    final query = <String, String>{
      'orderMode': 'domicilio',
      if ((pedido.clienteNombre ?? pedido.cliente ?? '').isNotEmpty)
        'clienteNombre': Uri.encodeComponent(pedido.clienteNombre ?? pedido.cliente ?? ''),
      if ((pedido.clienteTelefono ?? '').isNotEmpty)
        'clienteTelefono': Uri.encodeComponent(pedido.clienteTelefono!),
      if ((pedido.clienteDireccion ?? '').isNotEmpty)
        'clienteDireccion': Uri.encodeComponent(pedido.clienteDireccion!),
      if ((pedido.clienteReferencia ?? '').isNotEmpty)
        'clienteReferencia': Uri.encodeComponent(pedido.clienteReferencia!),
      if ((pedido.notas ?? '').isNotEmpty)
        'notas': Uri.encodeComponent(pedido.notas!),
    };

    final uri = Uri(
      path: '/mesero/pedidos/detalle/domicilio/${pedido.id}',
      queryParameters: query.isEmpty ? null : query,
    );
    context.push(uri.toString());
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
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
  const _DeliveryCustomerSheet({required this.onSubmit});

  final ValueChanged<DeliveryCustomerData> onSubmit;

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

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Datos del cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Completa la informacion para agilizar la entrega y mantener contacto con el cliente.',
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
                      return 'Agrega el telefono para la entrega';
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
                _buildField(
                  controller: _referenciaController,
                  label: 'Referencia o indicaciones',
                  hint: 'Punto de referencia, piso, porteria, etc.',
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _notasController,
                  label: 'Notas internas',
                  hint: 'Informacion adicional para el equipo',
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
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
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
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

    widget.onSubmit(
      DeliveryCustomerData(
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        referencia: _referenciaController.text.trim().isEmpty
            ? null
            : _referenciaController.text.trim(),
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      ),
    );
  }
}



