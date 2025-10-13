import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/presentation/controllers/mesero/carrito_controller.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart';
import 'package:restaurante_app/presentation/widgets/carrito_item.dart';

class CarritoBottomSheet extends ConsumerWidget {
  final VoidCallback onConfirmarSinPagar;
  final VoidCallback onConfirmarYPagar;
  final VoidCallback onRegistrarPago;
  final VoidCallback onModificarPedido;
  final VoidCallback onCancelarPedido;
  final VoidCallback onActualizarPedido;
  final VoidCallback onReportIssue;
  final VoidCallback onGenerarTicket;
  final String? pedidoId;
  const CarritoBottomSheet({
    super.key,
    required this.onConfirmarSinPagar,
    required this.onConfirmarYPagar,
    required this.onRegistrarPago,
    required this.onModificarPedido,
    required this.onCancelarPedido,
    required this.onActualizarPedido,
    required this.onReportIssue,
    required this.onGenerarTicket,
    this.pedidoId,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(carritoProvider);
    final adicionalesAsync = ref.watch(additionalProvider);
    final carritoController = ref.watch(carritoControllerProvider);
    final isAdminAsync = ref.watch(isCurrentUserAdminStreamProvider);
    final totalItems = carrito.fold<int>(0, (sum, item) => sum + item.cantidad);
    final heightFactor = totalItems >= 4 ? 0.96 : 0.82;
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTitulo(context),
              const SizedBox(height: 12),
              Expanded(
                child: adicionalesAsync.when(
                  data: (adicionales) {
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _ResumenCarritoCard(
                          total: carritoController.calcularTotal(),
                          cantidadTotal: carrito.fold<int>(
                              0, (sum, item) => sum + item.cantidad),
                        ),
                        const SizedBox(height: 16),
                        if (carrito.isEmpty)
                          _buildCarritoVacio(context)
                        else
                          ...carrito.map((item) {
                            final nombresAdicionales =
                                item.modificacionesSeleccionadas.map((id) {
                              final adicional = adicionales.firstWhere(
                                (a) => a.id == id,
                                orElse: () =>
                                    AdditionalModel(id: id, name: id, price: 0),
                              );
                              return adicional.name;
                            }).toList();
                            return CarritoItem(
                              item: item,
                              nombresAdicionales: nombresAdicionales,
                            );
                          }).toList(),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text('Error al cargar adicionales: $error'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              isAdminAsync.when(
                data: (isAdmin) =>
                    _buildAcciones(context, ref, carrito, isAdmin),
                loading: () => _buildAcciones(context, ref, carrito, false),
                error: (_, __) => _buildAcciones(context, ref, carrito, false),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTitulo(BuildContext context) {
    const titleStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
    if (pedidoId == null) {
      return const Text(
        'Carrito del pedido',
        style: titleStyle,
      );
    }
    final shortId = pedidoId!.length > 8 ? pedidoId!.substring(0, 8) : pedidoId!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resumen del pedido', style: titleStyle),
        const SizedBox(height: 4),
        Text(
          'ID: $shortId',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAcciones(BuildContext context, WidgetRef ref,
      List<ItemCarrito> carrito, bool isAdmin) {
    if (pedidoId == null) {
      if (carrito.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryButton(
            icon: Icons.local_fire_department,
            label: 'Enviar pedido a cocina',
            onPressed: onConfirmarSinPagar,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            icon: Icons.receipt_long,
            label: 'Enviar y generar ticket',
            onPressed: onConfirmarYPagar,
            backgroundColor: Colors.green,
          ),
        ],
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pedido')
          .doc(pedidoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          if (carrito.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PrimaryButton(
                icon: Icons.local_fire_department,
                label: 'Enviar pedido a cocina',
                onPressed: onConfirmarSinPagar,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                icon: Icons.receipt_long,
                label: 'Enviar y generar ticket',
                onPressed: onConfirmarYPagar,
                backgroundColor: Colors.green,
              ),
              const SizedBox(height: 6),
              const Text(
                'Generar el ticket no marca el pedido como pagado.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        }
        final pedidoData = snapshot.data!.data() as Map<String, dynamic>;
        final estado =
            (pedidoData['status'] ?? 'pendiente').toString().toLowerCase();
        final estadoNormalizado = estado.replaceAll(' ', '_');
        final pagado = pedidoData['pagado'] == true;
        final pedidoItems = (pedidoData['items'] as List?) ?? [];
        final bool pedidoSinItems = pedidoItems.isEmpty;
        if (pedidoSinItems && estadoNormalizado == 'nuevo') {
          if (carrito.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PrimaryButton(
                icon: Icons.local_fire_department,
                label: 'Enviar pedido a cocina',
                onPressed: onConfirmarSinPagar,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                icon: Icons.receipt_long,
                label: 'Enviar y generar ticket',
                onPressed: onConfirmarYPagar,
                backgroundColor: Colors.green,
              ),
              const SizedBox(height: 6),
              const Text(
                'Generar el ticket no marca el pedido como pagado.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        }
        final hayCambios = _tieneCambiosEnCarrito(carrito, pedidoItems);
        const estadosActualizacion = {'pendiente'};
        const estadosEdicion = {'nuevo', 'pendiente'};
        const estadosCancelacion = {
          'nuevo',
          'pendiente',
          'preparando',
          'preparacion',
          'en_preparacion',
        };
        const estadosFinalizados = {
          'terminado',
          'entregado',
          'completado',
          'pagado',
          'finalizado',
          'cerrado',
        };
        final estadoPermiteActualizacion =
            estadosActualizacion.contains(estadoNormalizado);
        final estadoPermiteEdicion =
            estadosEdicion.contains(estadoNormalizado);
        final estadoPermiteCancelacion =
            estadosCancelacion.contains(estadoNormalizado);
        final estadoFinalizado = estadosFinalizados.contains(estadoNormalizado);
        final acciones = <Widget>[];
        if (hayCambios && estadoPermiteActualizacion) {
          acciones.add(
            _PrimaryButton(
              icon: Icons.local_fire_department,
              label: 'Enviar actualizacion a cocina',
              onPressed: onActualizarPedido,
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
          acciones.add(const SizedBox(height: 12));
        }
        acciones.add(
          const _SectionTitle(
            icon: Icons.attach_money,
            title: 'Cobro y comprobantes',
          ),
        );
        acciones.add(const SizedBox(height: 8));
        acciones.add(
          _SecondaryButton(
            icon: Icons.receipt_long,
            label: pagado
                ? 'Generar nuevamente ticket'
                : 'Generar ticket / factura',
            onPressed: onGenerarTicket,
          ),
        );
        acciones.add(const SizedBox(height: 6));
        acciones.add(const Text(
          'Generar el ticket no marca el pedido como pagado.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ));
        acciones.add(const SizedBox(height: 16));
        if (!pagado && estadoFinalizado) {
          acciones.add(
            _PrimaryButton(
              icon: Icons.payments,
              label: 'Registrar pago del pedido',
              onPressed: onRegistrarPago,
              backgroundColor: Colors.green,
            ),
          );
          acciones.add(const SizedBox(height: 16));
        }
        if (pagado) {
          acciones.add(
            const _InfoBox(
              icon: Icons.verified_outlined,
              message:
                  'El pedido ya esta pagado. Puedes volver a generar el ticket si lo necesitas.',
              color: Colors.green,
            ),
          );
          acciones.add(const SizedBox(height: 16));
        }
        if (!pagado && estadoPermiteEdicion) {
          acciones.add(
            _SecondaryButton(
              icon: Icons.edit_outlined,
              label: 'Seguir modificando el pedido',
              onPressed: onModificarPedido,
            ),
          );
          acciones.add(const SizedBox(height: 12));
        }
        if (isAdmin && !pagado && estadoPermiteCancelacion) {
          acciones.add(
            _DangerButton(
              icon: Icons.cancel_outlined,
              label: 'Cancelar pedido',
              onPressed: onCancelarPedido,
            ),
          );
          acciones.add(const SizedBox(height: 12));
        }
        if (estadoFinalizado) {
          acciones.add(
            _DangerButton(
              icon: Icons.report_problem_outlined,
              label: 'Notificar problema',
              onPressed: onReportIssue,
            ),
          );
        }
        if (acciones.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: acciones,
        );
      },
    );
  }

  Widget _buildCarritoVacio(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.blueGrey),
          SizedBox(height: 12),
          Text(
            'Aun no has agregado productos',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Selecciona articulos para poder enviar el pedido a cocina o generar un ticket.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _tieneCambiosEnCarrito(
      List<ItemCarrito> carrito, List<dynamic> pedidoItems) {
    if (pedidoItems.isEmpty) {
      return carrito.isNotEmpty;
    }
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }
    final carritoCanonico = carrito.map((item) {
      final adicionales = [...item.modificacionesSeleccionadas]..sort();
      final nota = item.notas ?? '';
      return '${item.producto.id}|${item.cantidad}|${item.precioUnitario.toStringAsFixed(2)}|$nota|${adicionales.join(',')}';
    }).toList()
      ..sort();
    final pedidoCanonico = pedidoItems.map((item) {
      final data = item as Map<String, dynamic>;
      final adicionales = (data['adicionales'] as List?)
              ?.map((a) => (a['id'] ?? '').toString())
              .toList() ??
          [];
      adicionales.sort();
      final nota = (data['notes'] ?? '').toString();
      final price = asDouble(data['price']);
      return '${data['productId']}|${data['quantity']}|${price.toStringAsFixed(2)}|$nota|${adicionales.join(',')}';
    }).toList()
      ..sort();
    if (carritoCanonico.length != pedidoCanonico.length) {
      return true;
    }
    for (var i = 0; i < carritoCanonico.length; i++) {
      if (carritoCanonico[i] != pedidoCanonico[i]) {
        return true;
      }
    }
    return false;
  }
}

class _ResumenCarritoCard extends StatelessWidget {
  final double total;
  final int cantidadTotal;
  const _ResumenCarritoCard({
    required this.total,
    required this.cantidadTotal,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A44),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$cantidadTotal ${cantidadTotal == 1 ? 'articulo' : 'articulos'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(label),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Theme.of(context).primaryColor),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(label),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).primaryColor, width: 1.4),
          foregroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _DangerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(label),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String message;
  final MaterialColor color;
  const _InfoBox({
    required this.icon,
    required this.message,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({
    required this.icon,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

String _formatCurrency(double value) {
  final formatted = value.toStringAsFixed(0);
  return '\$${formatted.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  )}';
}
