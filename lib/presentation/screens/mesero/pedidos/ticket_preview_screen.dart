import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/mesero/print_ticket.dart';
import 'package:share_plus/share_plus.dart';

class TicketPreviewScreen extends ConsumerStatefulWidget {
  const TicketPreviewScreen({
    super.key,
    required this.pedidoId,
    this.ticketId,
    this.mesaId,
    this.mesaNombre,
    this.clienteNombre,
  });

  final String pedidoId;
  final String? ticketId;
  final String? mesaId;
  final String? mesaNombre;
  final String? clienteNombre;

  @override
  ConsumerState<TicketPreviewScreen> createState() =>
      _TicketPreviewScreenState();
}

class _TicketPreviewScreenState extends ConsumerState<TicketPreviewScreen> {
  final NumberFormat _currency = NumberFormat.currency(symbol: r'$');

  Future<void> _printTicket(Map<String, dynamic> pedidoData) async {
    await PrintTicketService.printTicket(
      pedidoData: pedidoData,
      pedidoId: widget.pedidoId,
      ticketId: widget.ticketId,
      mesaId: widget.mesaId,
      mesaNombre: widget.mesaNombre,
      clienteNombre: widget.clienteNombre,
    );
  }

  Future<void> _shareTicket(Map<String, dynamic> pedidoData) async {
    try {
      // Generar imagen del ticket
      final imageBytes = await PrintTicketService.generateTicketImage(
        pedidoData: pedidoData,
        pedidoId: widget.pedidoId,
        ticketId: widget.ticketId,
        mesaNombre: widget.mesaNombre,
        clienteNombre: widget.clienteNombre,
      );

      // Guardar imagen temporal
      final tempDir = await getTemporaryDirectory();
      final shortId = widget.pedidoId.length > 8
          ? widget.pedidoId.substring(0, 8)
          : widget.pedidoId;
      final file = File('${tempDir.path}/ticket_$shortId.png');
      await file.writeAsBytes(imageBytes);

      // Compartir usando el selector nativo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Ticket del Pedido $shortId',
        subject: 'Ticket - LA CENTRAL',
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError('Error al compartir ticket: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidoStream = FirebaseFirestore.instance
        .collection('pedido')
        .doc(widget.pedidoId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: pedidoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            extendBodyBehindAppBar: true,
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
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            extendBodyBehindAppBar: true,
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
              child: const SafeArea(
                child: Center(
                  child: Text(
                    'No encontramos información para este pedido.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          );
        }

        final pedidoData = snapshot.data!.data() ?? <String, dynamic>{};
        final items = (pedidoData['items'] as List?) ?? const [];
        final subtotal = _asDouble(pedidoData['subtotal']);
        final descuento = _asDouble(pedidoData['descuento']);
        final total = _asDouble(pedidoData['total']);
        final pagado = pedidoData['pagado'] == true;
        final estado = (pedidoData['status'] ?? 'pendiente').toString();
        final mesaNombreVisible = _decodeIfNeeded(widget.mesaNombre) ??
            (pedidoData['mesaNombre']?.toString());
        final clienteVisible = _decodeIfNeeded(widget.clienteNombre) ??
            (pedidoData['clienteNombre']?.toString());
        final ticketNumero = widget.ticketId ??
            (pedidoData['ultimoTicket']?.toString() ?? 'Ticket provisional');

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
              tooltip: 'Volver',
            ),
          ),
          extendBodyBehindAppBar: true,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título en el cuerpo
                    const Text(
                      'Ticket del Pedido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Resumen completo de la orden',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _TicketHeader(
                      pedidoId: widget.pedidoId,
                      mesaId: widget.mesaId,
                      mesaNombre: mesaNombreVisible,
                      clienteNombre: clienteVisible,
                      estado: estado,
                      pagado: pagado,
                      ticketNumero: ticketNumero,
                      subtotal: subtotal,
                      descuento: descuento,
                      total: total,
                      formatter: _currency,
                    ),
                    const SizedBox(height: 16),
                    _TicketItemsList(items: items, formatter: _currency),
                    const SizedBox(height: 16),
                    _TicketTotals(
                        subtotal: subtotal, descuento: descuento, total: total, formatter: _currency),
                    const SizedBox(height: 24),
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _printTicket(pedidoData),
                            icon: const Icon(Icons.print),
                            label: const Text('Imprimir'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                              ),
                              foregroundColor: const Color(0xFF8B5CF6),
                              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _shareTicket(pedidoData),
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                              ),
                              foregroundColor: const Color(0xFF8B5CF6),
                              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final router = GoRouter.of(context);
                          const fallbackRoute = '/mesero/pedidos/mesas';
                          if (router.canPop()) {
                            router.pop();
                          } else {
                            router.go(fallbackRoute);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String? _decodeIfNeeded(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }
}

class _TicketHeader extends ConsumerWidget {
  const _TicketHeader({
    required this.pedidoId,
    required this.mesaId,
    required this.mesaNombre,
    required this.clienteNombre,
    required this.estado,
    required this.pagado,
    required this.ticketNumero,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.formatter,
  });

  final String pedidoId;
  final String? mesaId;
  final String? mesaNombre;
  final String? clienteNombre;
  final String estado;
  final bool pagado;
  final String ticketNumero;
  final double subtotal;
  final double descuento;
  final double total;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortId = pedidoId.length > 8 ? pedidoId.substring(0, 8) : pedidoId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pedido: $shortId',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ticket: $ticketNumero',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Mesa', value: mesaNombre ?? mesaId ?? 'Sin asignar'),
          const SizedBox(height: 6),
          _InfoRow(
              label: 'Cliente', value: clienteNombre ?? 'Consumidor final'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Estado', value: _estadoLegible(estado)),
          const SizedBox(height: 6),
          _InfoRow(label: 'Pago', value: pagado ? 'Pagado' : 'Pendiente'),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          _InfoRow(label: 'Subtotal', value: formatter.format(subtotal)),
          const SizedBox(height: 6),
          _InfoRow(
            label: pagado ? 'Total cobrado' : 'Total a cobrar',
            value: formatter.format(total),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

String _estadoLegible(String estado) {
  switch (estado.toLowerCase()) {
    case 'pendiente':
      return 'Pendiente';
    case 'preparacion':
    case 'preparando':
    case 'en_preparacion':
      return 'En preparacion';
    case 'terminado':
      return 'Terminado';
    case 'listo':
      return 'Listo';
    case 'cancelado':
      return 'Cancelado';
    case 'entregado':
      return 'Entregado';
    default:
      return estado.isEmpty ? 'Pendiente' : estado;
  }
}

class _TicketItemsList extends ConsumerWidget {
  const _TicketItemsList({required this.items, required this.formatter});

  final List items;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay productos registrados en este ticket.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index] as Map<String, dynamic>;
            final quantity = item['quantity'] ?? 1;
            final name = (item['name'] ?? 'Producto').toString();
            final price = _itemTotal(item);
            final notas = (item['notes'] ?? '').toString();
            final adicionales = (item['adicionales'] as List?) ?? const [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quantity}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (adicionales.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _AdicionalesList(
                              adicionales: adicionales,
                              formatter: formatter,
                            ),
                          ],
                          if (notas.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Nota: $notas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatter.format(price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (index != items.length - 1) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  double _itemTotal(Map<String, dynamic> item) {
    final quantity = (item['quantity'] ?? 1) as int;
    final price = _toDouble(item['price']);
    final adicionales = (item['adicionales'] as List?) ?? const [];
    final adicionalesTotal = adicionales.fold<double>(
      0,
      (total, adicional) =>
          total + _toDouble((adicional as Map<String, dynamic>)['price']),
    );
    return (price + adicionalesTotal) * quantity;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class _AdicionalesList extends ConsumerWidget {
  const _AdicionalesList({required this.adicionales, required this.formatter});

  final List adicionales;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: adicionales.map((adicional) {
        final data = adicional as Map<String, dynamic>;
        final name = (data['name'] ?? data['nombre'] ?? 'Extra').toString();
        final price = _toDouble(data['price']);
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '+ $name (${formatter.format(price)})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        );
      }).toList(),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class _TicketTotals extends ConsumerWidget {
  const _TicketTotals({
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.formatter,
  });

  final double subtotal;
  final double descuento;
  final double total;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6D28D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de pago',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _totalsRow('Subtotal', formatter.format(subtotal)),
          if (descuento > 0) ...[
            const SizedBox(height: 8),
            _totalsRow('Descuento', '- ${formatter.format(descuento)}', isDiscount: true),
          ],
          const SizedBox(height: 8),
          _totalsRow('Total', formatter.format(total), highlight: true),
        ],
      ),
    );
  }

  Widget _totalsRow(String label, String value, {bool highlight = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount
                ? const Color(0xFF34D399)
                : Colors.white.withValues(alpha: highlight ? 1 : 0.8),
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount
                ? const Color(0xFF34D399)
                : Colors.white,
            fontSize: highlight ? 20 : 16,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends ConsumerWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String? value;
  final bool emphasize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value?.isNotEmpty == true ? value! : 'Sin dato',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: emphasize ? 16 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize ? Colors.white : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
