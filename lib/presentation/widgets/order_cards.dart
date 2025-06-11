// presentation/screens/cocina/widgets/order_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/data/models/order_model.dart';
import 'package:restaurante_app/presentation/providers/cocina/order_provider.dart';

class OrderCard extends ConsumerWidget {
  final Order order;
  final bool isCompact;

  const OrderCard({
    Key? key,
    required this.order,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(ordersNotifierProvider);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(order.status),
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
            _buildCustomerInfo(),
            const SizedBox(height: 12),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildActionButtons(context, ref, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '#${order.id?.substring(0, 6).toUpperCase() ?? 'N/A'}',
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
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
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
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(order.status),
                style: TextStyle(
                  color: _getStatusColor(order.status),
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

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getModeIcon(order.mode),
            color: Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getModeText(order.mode),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getCustomerDisplay(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                  'Productos (${order.items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...order.items.map((item) => _buildItemRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item) {
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
              color: _getStatusColor(order.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
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
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Text(
                    'Nota: ${item.notes}',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (order.status == 'terminado')
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (order.status) {
      case 'pendiente':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startPreparation(ref),
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
                onPressed: () => _finishOrder(ref),
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
          onPressed: () => _reactivateOrder(ref),
          icon: const Icon(Icons.refresh),
          label: const Text('Reactivar Orden'),
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
                'Orden Completada',
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

  void _startPreparation(WidgetRef ref) {
    ref.read(ordersNotifierProvider.notifier).startPreparation(order.id!);
  }

  void _finishOrder(WidgetRef ref) {
    ref.read(ordersNotifierProvider.notifier).finishOrder(order.id!);
  }

  void _reactivateOrder(WidgetRef ref) {
    ref.read(ordersNotifierProvider.notifier).reactivateOrder(order.id!);
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Orden'),
        content: Text('¿Estás seguro de que quieres cancelar la orden #${order.id?.substring(0, 6).toUpperCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(ordersNotifierProvider.notifier).cancelOrder(order.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
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

  String _getCustomerDisplay() {
    switch (order.mode) {
      case 'mesa':
        return 'Mesa ${order.tableNumber ?? 'N/A'}';
      case 'domicilio':
        return order.customerName ?? 'Cliente sin nombre';
      case 'paraLlevar':
        return order.customerName ?? 'Cliente sin nombre';
      default:
        return 'N/A';
    }
  }

  String _getTimeDisplay() {
    final now = DateTime.now();
    final orderTime = order.createdAt.toDate();
    final difference = now.difference(orderTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return DateFormat('HH:mm').format(orderTime);
    }
  }
}