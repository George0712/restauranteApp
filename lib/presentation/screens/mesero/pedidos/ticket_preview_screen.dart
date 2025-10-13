import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/presentation/widgets/payment_bottom_sheet.dart';

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
  ConsumerState<TicketPreviewScreen> createState() => _TicketPreviewScreenState();
}

class _TicketPreviewScreenState extends ConsumerState<TicketPreviewScreen> {
  final NumberFormat _currency = NumberFormat.currency(symbol: r'$');

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ticket del pedido')),
            body: const Center(
              child: Text('No encontramos informacion para este pedido.'),
            ),
          );
        }

        final pedidoData = snapshot.data!.data() ?? <String, dynamic>{};
        final items = (pedidoData['items'] as List?) ?? const [];
        final subtotal = _asDouble(pedidoData['subtotal']);
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
            title: const Text('Ticket del pedido'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TicketHeader(
                  pedidoId: widget.pedidoId,
                  mesaId: widget.mesaId,
                  mesaNombre: mesaNombreVisible,
                  clienteNombre: clienteVisible,
                  estado: estado,
                  pagado: pagado,
                  ticketNumero: ticketNumero,
                  subtotal: subtotal,
                  total: total,
                  formatter: _currency,
                ),
                const SizedBox(height: 20),
                _TicketItemsList(items: items, formatter: _currency),
                const SizedBox(height: 20),
                _TicketTotals(subtotal: subtotal, total: total, formatter: _currency),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!pagado)
                  ElevatedButton.icon(
                    onPressed: () => _abrirPasarelaPago(context),
                    icon: const Icon(Icons.payments),
                    label: const Text('Registrar pago'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                if (!pagado) const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ],
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

  Future<void> _abrirPasarelaPago(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentBottomSheet(pedidoId: widget.pedidoId),
    );
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente.')),
        );
      }
    }
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({
    required this.pedidoId,
    required this.mesaId,
    required this.mesaNombre,
    required this.clienteNombre,
    required this.estado,
    required this.pagado,
    required this.ticketNumero,
    required this.subtotal,
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
  final double total;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final shortId = pedidoId.length > 8 ? pedidoId.substring(0, 8) : pedidoId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pedido: $shortId',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ticket: $ticketNumero',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Mesa', value: mesaNombre ?? mesaId ?? 'Sin asignar'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Cliente', value: clienteNombre ?? 'Consumidor final'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Estado', value: _estadoLegible(estado)),
          const SizedBox(height: 6),
          _InfoRow(label: 'Pago', value: pagado ? 'Pagado' : 'Pendiente'),
          const SizedBox(height: 16),
          const Divider(),
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

class _TicketItemsList extends StatelessWidget {
  const _TicketItemsList({required this.items, required this.formatter});

  final List items;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.blueGrey),
            SizedBox(height: 12),
            Text('No hay productos registrados en este ticket.'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                        color: Colors.black87,
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
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (index != items.length - 1) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade200),
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
      (total, adicional) => total + _toDouble((adicional as Map<String, dynamic>)['price']),
    );
    return (price + adicionalesTotal) * quantity;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class _AdicionalesList extends StatelessWidget {
  const _AdicionalesList({required this.adicionales, required this.formatter});

  final List adicionales;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: adicionales.map((adicional) {
        final data = adicional as Map<String, dynamic>;
        final name = (data['name'] ?? data['nombre'] ?? 'Extra').toString();
        final price = formatter.format(_toDouble(data['price']));
        return Text(
          '+ $name ($price)',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
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

class _TicketTotals extends StatelessWidget {
  const _TicketTotals({
    required this.subtotal,
    required this.total,
    required this.formatter,
  });

  final double subtotal;
  final double total;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A44),
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 8),
          _totalsRow('Total', formatter.format(total), highlight: true),
        ],
      ),
    );
  }

  Widget _totalsRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: highlight ? 1 : 0.8),
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: highlight ? 20 : 16,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String? value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
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
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
