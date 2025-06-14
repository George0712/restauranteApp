import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/order_model.dart';

// Provider para filtrar por estado
final orderStatusFilterProvider = StateProvider<String>((ref) => 'all');

// StreamProvider para obtener órdenes en tiempo real - ASEGÚRATE DE QUE SEA LA COLECCIÓN CORRECTA
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  return FirebaseFirestore.instance
      .collection('pedido') // Cambia esto por la colección correcta: 'pedidos' en lugar de 'pedido'
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) {
    print('Órdenes recibidas: ${snapshot.docs.length}'); // Debug
    return snapshot.docs.map((doc) {
      final data = doc.data();
      print('Datos de orden: $data'); // Debug para ver la estructura
      return Order.fromJson({...data, 'id': doc.id});
    }).toList();
  }).handleError((error) {
    print('Error en ordersStreamProvider: $error');
  });
});

// Provider mejorado para órdenes pendientes
final pendingOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  
  return ordersAsync.when(
    data: (orders) {
      print('Órdenes totales: ${orders.length}'); // Debug
      final pendingOrders = orders.where((order) => 
        order.status == 'pendiente' || order.status == 'preparando'
      ).toList();
      print('Órdenes pendientes: ${pendingOrders.length}'); // Debug
      return AsyncValue.data(pendingOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) {
      print('Error en pendingOrdersProvider: $error');
      return AsyncValue.error(error, stack);
    },
  );
});

// Provider para órdenes terminadas
final completedOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final completedOrders = orders.where((order) => 
        order.status == 'terminado' || order.status == 'cancelado'
      ).toList();
      return AsyncValue.data(completedOrders);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// StateNotifier para manejar las acciones de las órdenes
class OrdersNotifier extends StateNotifier<bool> {
  OrdersNotifier() : super(false);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Iniciar preparación de una orden
  Future<void> startPreparation(String orderId) async {
    state = true;
    try {
      // Cambia 'pedido' por 'pedidos' si es necesario
      await _firestore.collection('pedido').doc(orderId).update({
        'status': 'preparando',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al iniciar preparación: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  // Marcar orden como terminada
  Future<void> finishOrder(String orderId) async {
    state = true;
    try {
      await _firestore.collection('pedido').doc(orderId).update({
        'status': 'terminado',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al terminar orden: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  // Cancelar orden
  Future<void> cancelOrder(String orderId) async {
    state = true;
    try {
      await _firestore.collection('pedido').doc(orderId).update({
        'status': 'cancelado',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al cancelar orden: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  // Reactivar orden (de cancelado a pendiente)
  Future<void> reactivateOrder(String orderId) async {
    state = true;
    try {
      await _firestore.collection('pedido').doc(orderId).update({
        'status': 'pendiente',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al reactivar orden: $e');
      rethrow;
    } finally {
      state = false;
    }
  }
}

// Provider para el StateNotifier
final ordersNotifierProvider = StateNotifierProvider<OrdersNotifier, bool>((ref) {
  return OrdersNotifier();
});

// Provider para estadísticas rápidas
final orderStatsProvider = Provider<Map<String, int>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  
  return ordersAsync.when(
    data: (orders) {
      final stats = <String, int>{
        'pendiente': 0,
        'preparando': 0,
        'terminado': 0,
        'cancelado': 0,
      };
      
      for (final order in orders) {
        stats[order.status] = (stats[order.status] ?? 0) + 1;
      }
      
      return stats;
    },
    loading: () => {'pendiente': 0, 'preparando': 0, 'terminado': 0, 'cancelado': 0},
    error: (_, __) => {'pendiente': 0, 'preparando': 0, 'terminado': 0, 'cancelado': 0},
  );
});