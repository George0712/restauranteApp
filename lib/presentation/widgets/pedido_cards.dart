import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';
import 'package:restaurante_app/presentation/providers/mesero/mesas_provider.dart';

class PedidoCard extends ConsumerWidget {
  final Pedido pedido;
  final bool isCompact;

  const PedidoCard({
    Key? key,
    required this.pedido,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(cocinaNotifierProvider);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(pedido.status), // ✅ Cambiado a 'status'
          width: 3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildCustomerInfo(ref),
            const SizedBox(height: 12),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildActionButtons(context, ref, isLoading),
          ],
        ),
      ),
    );
  }

  // ========== HEADER ==========
  Widget _buildHeader() {
    final statusColor = _getStatusColor(pedido.status); // ✅ Cambiado a 'status'

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '#${_generateFriendlyId(pedido.id)}', // ✅ ID más amigable
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getTimeDisplay(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(pedido.status), // ✅ Cambiado a 'status'
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========== INFO CLIENTE ==========
  // ========== INFO CLIENTE ==========
Widget _buildCustomerInfo(WidgetRef ref) {
  final mesasAsync = ref.watch(mesasStreamProvider);
  
  return mesasAsync.when(
    data: (mesas) {
      String display;
      if (pedido.mode == 'mesa') {
        final mesasConPedido = mesas.where((m) => m.pedidoId == pedido.id);
        final mesa = mesasConPedido.isNotEmpty ? mesasConPedido.first : null;

        if (mesa != null) {
          display = mesa.cliente != null && mesa.cliente!.isNotEmpty
              ? 'Mesa ${mesa.id} - ${mesa.cliente}'
              : 'Mesa ${mesa.id}';
        } else {
          final tableRef = pedido.tableNumber?.substring(0, 8) ?? 'Unknown';
          display = 'Mesa ($tableRef)';
        }
      } else {
        display = pedido.cliente ?? 'Cliente sin nombre';
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _getModeIcon(pedido.mode ?? ''),
              color: Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getModeText(pedido.mode ?? ''),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    display,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // ✅ AÑADIR ESTA SECCIÓN (que faltaba):
                  if (pedido.meseroNombre != null && pedido.meseroNombre!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pedido.meseroNombre!.trim(), // ✅ Usar trim() para quitar espacios
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
    loading: () => _buildCustomerInfoLoading(),
    error: (error, stack) => _buildCustomerInfoError(),
  );
}



  // Widget helper para estado de loading
  Widget _buildCustomerInfoLoading() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant, color: Colors.grey[700], size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mesa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Cargando...', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para estado de error
  Widget _buildCustomerInfoError() {
    final tableRef = pedido.tableNumber?.substring(0, 8) ?? 'Unknown';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.table_restaurant, color: Colors.grey[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mesa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Mesa ($tableRef)', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== ITEMS ==========
  Widget _buildItemsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Productos (${pedido.items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tiempo: ${_getTotalPreparationTime()} min',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          ...pedido.items.map((item) => _buildItemRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildItemRow(ItemPedido item) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.grey[200]!),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _getStatusColor(pedido.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${item.cantidad}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              // ✅ MOSTRAR ADICIONALES (CORREGIDO)
              if (item.adicionales != null && item.adicionales!.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...item.adicionales!.map((adicional) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 12,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        adicional['name'] ?? adicional['nombre'] ?? 'Adicional', // ✅ Correcto
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+\$${(adicional['price'] ?? adicional['precio'] ?? 0).toStringAsFixed(0)}', // ✅ Correcto
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              // Tiempo de preparación
              if (item.tiempoPreparacion != null && item.tiempoPreparacion! > 0) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.tiempoPreparacion} min',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // Notas
              if (item.notas != null && item.notas!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Nota: ${item.notas}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (pedido.status == 'terminado')
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    ),
  );
}



  // ========== ACCIONES ==========
  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (pedido.status) { // ✅ Cambiado a 'status'
      case 'pendiente':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(cocinaNotifierProvider.notifier).startPreparation(pedido.id!),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Preparación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showCancelDialog(context, ref),
              icon: const Icon(Icons.cancel),
              color: Colors.red,
              tooltip: 'Cancelar',
            ),
          ],
        );

      case 'preparando':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(cocinaNotifierProvider.notifier).finishOrder(pedido.id!),
                icon: const Icon(Icons.check),
                label: const Text('Marcar Terminado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showCancelDialog(context, ref),
              icon: const Icon(Icons.cancel),
              color: Colors.red,
              tooltip: 'Cancelar',
            ),
          ],
        );

      case 'cancelado':
        return ElevatedButton.icon(
          onPressed: () =>
              ref.read(cocinaNotifierProvider.notifier).reactivateOrder(pedido.id!),
          icon: const Icon(Icons.refresh),
          label: const Text('Reactivar Pedido'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Pedido Completado',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  // ========== HELPERS ==========
  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: Text(
            '¿Estás seguro de que quieres cancelar el pedido #${_generateFriendlyId(pedido.id)}?'), // ✅ ID amigable
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(cocinaNotifierProvider.notifier).cancelOrder(pedido.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  // ✅ Función para generar ID amigable
  String _generateFriendlyId(String? fullId) {
    if (fullId == null || fullId.isEmpty) return 'N/A';
    
    // Generar un ID más amigable basado en el hash
    final hash = fullId.hashCode.abs();
    final friendlyId = (hash % 10000).toString().padLeft(4, '0');
    return friendlyId;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.red;
      case 'preparando':
        return Colors.orange;
      case 'terminado':
        return Colors.green;
      case 'cancelado':
        return Colors.grey;
      case 'pagado': // ✅ Añadido estado 'pagado'
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
        return 'Preparando';
      case 'terminado':
        return 'Terminado';
      case 'cancelado':
        return 'Cancelado';
      case 'pagado': // ✅ Añadido estado 'pagado'
        return 'Pagado';
      default:
        return 'Desconocido';
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'mesa':
        return Icons.table_restaurant;
      case 'domicilio':
        return Icons.delivery_dining;
      case 'paraLlevar':
        return Icons.takeout_dining;
      default:
        return Icons.restaurant;
    }
  }

  String _getModeText(String mode) {
    switch (mode) {
      case 'mesa':
        return 'Mesa';
      case 'domicilio':
        return 'Domicilio';
      case 'paraLlevar':
        return 'Para Llevar';
      default:
        return 'Desconocido';
    }
  }

  String _getTimeDisplay() {
    final now = DateTime.now();
    final orderTime = pedido.updatedAt ?? pedido.createdAt ?? DateTime.now(); // ✅ Usar nuevos campos de fecha
    final difference = now.difference(orderTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return DateFormat('HH:mm').format(orderTime);
    }
  }

  int _getTotalPreparationTime() {
    int totalTime = 0;
    for (final item in pedido.items) {
      if (item.tiempoPreparacion != null) {
        totalTime += (item.tiempoPreparacion! * item.cantidad).toInt();
      } else {
        // Si no tiene tiempo de preparación, usar 15 min por defecto
        totalTime += (15 * item.cantidad).toInt();
      }
    }
    return totalTime;
  }
}
