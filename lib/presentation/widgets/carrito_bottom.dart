import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart';
import 'package:restaurante_app/presentation/controllers/mesero/carrito_controller.dart';
import 'package:restaurante_app/presentation/widgets/carrito_item.dart';

class CarritoBottomSheet extends ConsumerWidget {
  final VoidCallback onConfirmarSinPagar;
  final VoidCallback onConfirmarYPagar;
  final VoidCallback onProcederPago;
  final VoidCallback onModificarPedido;
  final VoidCallback onCancelarPedido;
  final String? pedidoId;

  const CarritoBottomSheet({
    super.key,
    required this.onConfirmarSinPagar,
    required this.onConfirmarYPagar,
    required this.onProcederPago,
    required this.onModificarPedido,
    required this.onCancelarPedido,
    this.pedidoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(carritoProvider);
    final adicionalesAsync = ref.watch(additionalProvider);
    final carritoController = ref.watch(carritoControllerProvider);

    // Usar el provider de admin
    final isAdminAsync = ref.watch(isCurrentUserAdminStreamProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título dinámico basado en el estado real del pedido
          _buildTitulo(context, ref),

          const SizedBox(height: 16),
          Expanded(
            child: carrito.isEmpty
                ? const Center(child: Text('Tu carrito está vacío.'))
                : ListView.builder(
                    itemCount: carrito.length,
                    itemBuilder: (context, index) {
                      final item = carrito[index];
                      return adicionalesAsync.when(
                        data: (adicionales) {
                          final nombresAdicionales = item
                              .modificacionesSeleccionadas
                              .map((id) => adicionales
                                  .firstWhere((a) => a.id == id)
                                  .name)
                              .toList();
                          return CarritoItem(
                            item: item,
                            nombresAdicionales: nombresAdicionales,
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text('Error: $error'),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${carritoController.calcularTotal().toStringAsFixed(0).replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botones basados en el estado real del pedido en Firestore
          isAdminAsync.when(
            data: (isAdmin) =>
                _buildBotonesConEstadoReal(context, ref, carrito, isAdmin),
            loading: () =>
                _buildBotonesConEstadoReal(context, ref, carrito, false),
            error: (_, __) =>
                _buildBotonesConEstadoReal(context, ref, carrito, false),
          ),
        ],
      ),
    );
  }

  Widget _buildTitulo(BuildContext context, WidgetRef ref) {
    if (pedidoId == null) {
      return const Text(
        'Tu carrito',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      );
    }

    // Stream del pedido específico para obtener su estado en tiempo real
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pedido')
          .doc(pedidoId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            'Tu carrito',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          );
        }

        final pedidoData = snapshot.data!.data() as Map<String, dynamic>;
        final estado = pedidoData['status'] ?? 'nuevo';
        final pagado = pedidoData['pagado'] ?? false;

        String titulo = _obtenerTituloSegunEstado(estado, pagado);

        return Text(
          titulo,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _buildBotonesConEstadoReal(
      BuildContext context, WidgetRef ref, List carrito, bool isAdmin) {
    if (carrito.isEmpty) {
      return const SizedBox.shrink();
    }

    if (pedidoId == null) {
      return _buildBotonesIniciales(context);
    }

    // Stream del pedido para obtener el estado real
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pedido')
          .doc(pedidoId)
          .snapshots(),
      builder: (context, snapshot) {
        // Si no hay conexión o está cargando, mostrar botones iniciales
        if (!snapshot.hasData) {
          return _buildBotonesIniciales(context);
        }

        // ✅ CLAVE: Si el documento no existe O no tiene items, mostrar botones iniciales
        if (!snapshot.data!.exists) {
          return _buildBotonesIniciales(context);
        }

        final pedidoData = snapshot.data!.data() as Map<String, dynamic>?;

        // ✅ NUEVA VALIDACIÓN: Si no tiene items o está vacío, es un pedido nuevo
        if (pedidoData == null ||
            !pedidoData.containsKey('items') ||
            pedidoData['items'] == null ||
            (pedidoData['items'] as List).isEmpty) {
          return _buildBotonesIniciales(context);
        }

        final estado = pedidoData['status'] ?? 'nuevo';
        final pagado = pedidoData['pagado'] ?? false;

        // ✅ NUEVA VALIDACIÓN: Solo mostrar botones avanzados si el estado indica que fue confirmado
        if (estado == 'nuevo' || estado.isEmpty) {
          return _buildBotonesIniciales(context);
        }

        // Determinar qué botones mostrar según el estado real
        return _buildBotonesSegunEstado(context, estado, pagado, isAdmin);
      },
    );
  }

  Widget _buildBotonesIniciales(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onConfirmarSinPagar,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar sin Pagar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onConfirmarYPagar,
            icon: const Icon(Icons.payment),
            label: const Text('Confirmar y Pagar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonesSegunEstado(
      BuildContext context, String estado, bool pagado, bool isAdmin) {
    List<Widget> botones = [];

    switch (estado.toLowerCase()) {
      case 'pendiente':
        if (!pagado) {
          // Pedido confirmado pero no pagado
          botones.add(
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onProcederPago,
                icon: const Icon(Icons.payment),
                label: const Text('Proceder al Pago'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
          botones.add(const SizedBox(height: 12));
        }

        // Botón modificar (solo si está pendiente)
        botones.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onModificarPedido,
              icon: const Icon(Icons.edit),
              label: const Text('Modificar Pedido'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
        botones.add(const SizedBox(height: 12));

        // Botón cancelar
        botones.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCancelarPedido,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar Pedido'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
        break;

      case 'preparacion':
      case 'en_preparacion':
        // Solo admin puede cancelar en preparación
        if (isAdmin) {
          botones.add(
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCancelarPedido,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar Pedido (Admin)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        } else {
          // Mostrar mensaje informativo
          botones.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'El pedido está en preparación',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        break;

      case 'listo':
        botones.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Text(
              'Pedido listo para entregar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        break;

      case 'pagado':
      case 'entregado':
      case 'terminado':
        botones.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              estado == 'pagado'
                  ? 'Pedido pagado exitosamente'
                  : 'Pedido completado',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        break;

      case 'cancelado':
        botones.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Text(
              'Pedido cancelado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
        break;

      default:
        // Estado desconocido o nuevo, mostrar botones iniciales
        return _buildBotonesIniciales(context);
    }

    return Column(children: botones);
  }

  String _obtenerTituloSegunEstado(String estado, bool pagado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return pagado ? 'Pedido Pagado' : 'Pedido Pendiente de Pago';
      case 'preparacion':
      case 'en_preparacion':
        return 'Pedido en Preparación';
      case 'listo':
        return 'Pedido Listo';
      case 'pagado':
        return 'Pedido Pagado';
      case 'entregado':
      case 'terminado':
        return 'Pedido Entregado';
      case 'cancelado':
        return 'Pedido Cancelado';
      default:
        return 'Tu carrito';
    }
  }
}
