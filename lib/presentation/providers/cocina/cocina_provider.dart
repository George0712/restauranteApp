import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/pedido.dart';

// Provider para filtrar por estado
final pedidoStatusFilterProvider = StateProvider<String>((ref) => 'all');

// Provider para notificaciones de nuevos pedidos
final newOrderNotificationProvider = StateProvider<String?>((ref) => null);

// Provider para notificaciones de pedidos completados
final completedOrderNotificationProvider = StateProvider<String?>((ref) => null);

// Provider para notificaciones de pedidos actualizados/modificados
final updatedOrderNotificationProvider = StateProvider<String?>((ref) => null);

// StreamProvider para obtener pedidos en tiempo real
final pedidosStreamProvider = StreamProvider<List<Pedido>>((ref) {
  developer.log("INICIANDO pedidosStreamProvider");
  
  return FirebaseFirestore.instance
      .collection('pedido')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final pedidos = <Pedido>[];
    final autoCancelFutures = <Future<void>>[];
    final now = DateTime.now();

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pendiente';
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final referenceDate = updatedAt ?? createdAt;
        final shouldAutoCancel = status == 'pendiente' &&
            referenceDate != null &&
            now.difference(referenceDate) >= const Duration(hours: 3);

        if (shouldAutoCancel) {
          developer.log('Pedido ${doc.id} supero las 3 horas pendiente; se cancela automaticamente.');
          autoCancelFutures.add(
            doc.reference.update({
              'status': 'cancelado',
              'cancelledAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }).catchError((error) {
              developer.log('Error al cancelar automaticamente el pedido ${doc.id}: $error', error: error);
            }),
          );
          continue;
        }

        pedidos.add(Pedido.fromJson({...data, 'id': doc.id}));
      } catch (e, stackTrace) {
        developer.log('Error procesando pedido ${doc.id}: $e', error: e, stackTrace: stackTrace);
      }
    }

    if (autoCancelFutures.isNotEmpty) {
      await Future.wait(autoCancelFutures);
    }

    return pedidos;
  }).handleError((error, stackTrace) {
    developer.log('Error en stream de pedidos: $error', error: error, stackTrace: stackTrace);
    throw error;
  });
});


// Provider para pedidos pendientes (usando los status de Firestore)
final pendingPedidosProvider = Provider<AsyncValue<List<Pedido>>>((ref) {
  final pedidosAsync = ref.watch(pedidosStreamProvider);

  return pedidosAsync.when(
    data: (pedidos) {
      developer.log("PENDING PROVIDER: Recibidos ${pedidos.length} pedidos");

      final pendientes = pedidos.where((pedido) {
        final esPendiente = pedido.status == 'pendiente' || pedido.status == 'preparando';
        developer.log("Pedido ${pedido.id} - Status: '${pedido.status}' - Es pendiente: $esPendiente");
        return esPendiente;
      }).toList();

      final ordenados = _sortByRecent(pendientes);

      developer.log("PEDIDOS PENDIENTES FILTRADOS: ${pendientes.length}");
      return AsyncValue.data(ordenados);
    },
    loading: () {
      developer.log("PENDING PROVIDER: Loading...");
      return const AsyncValue.loading();
    },
    error: (error, stack) {
      developer.log("PENDING PROVIDER ERROR: $error", error: error, stackTrace: stack);
      return AsyncValue.error(error, stack);
    },
  );
});

// Provider para pedidos terminados o cancelados
// Provider para pedidos terminados o cancelados
final completedPedidosProvider = Provider<AsyncValue<List<Pedido>>>((ref) {
  final pedidosAsync = ref.watch(pedidosStreamProvider);

  return pedidosAsync.when(
    data: (pedidos) {
      developer.log("COMPLETED PROVIDER: Recibidos ${pedidos.length} pedidos");

      final completados = pedidos.where((pedido) {
        // ✅ Incluir TODOS los estados completados
        final esCompletado = pedido.status == 'terminado' ||
                            pedido.status == 'cancelado' ||
                            pedido.status == 'pagado' ||      // ✅ Añadir 'pagado'
                            pedido.status == 'entregado';     // ✅ Añadir 'entregado' por si acaso

        developer.log("Pedido ${pedido.id} - Status: '${pedido.status}' - Es completado: $esCompletado");
        return esCompletado;
      }).toList();

      // ✅ Usar la nueva función de ordenamiento para mostrar los más recientes primero
      final ordenados = _sortCompletedByMostRecent(completados);

      developer.log("PEDIDOS COMPLETADOS FILTRADOS: ${completados.length}");
      return AsyncValue.data(ordenados);
    },
    loading: () {
      developer.log("COMPLETED PROVIDER: Loading...");
      return const AsyncValue.loading();
    },
    error: (error, stack) {
      developer.log("COMPLETED PROVIDER ERROR: $error", error: error, stackTrace: stack);
      return AsyncValue.error(error, stack);
    },
  );
});


// StateNotifier para manejar las acciones de los pedidos
class CocinaNotifier extends StateNotifier<bool> {
  CocinaNotifier() : super(false);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> startPreparation(String pedidoId) async {
    state = true;
    try {
      developer.log("Iniciando preparación del pedido: $pedidoId");
      await _firestore.collection('pedido').doc(pedidoId).update({
        'status': 'preparando', // Usar 'status' y 'preparando' como en Firestore
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log("Pedido $pedidoId marcado como 'preparando'");
    } catch (e) {
      developer.log("ERROR al iniciar preparación del pedido $pedidoId: $e", error: e);
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> finishOrder(String pedidoId, WidgetRef ref) async {
    state = true;
    try {
      developer.log("Terminando pedido: $pedidoId");
      await _firestore.collection('pedido').doc(pedidoId).update({
        'status': 'terminado', // Usar 'terminado' como en Firestore
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log("Pedido $pedidoId marcado como 'terminado'");

      // Activar notificación de pedido completado
      Future.microtask(() {
        ref.read(completedOrderNotificationProvider.notifier).state =
            'Pedido #${pedidoId.substring(0, 8).toUpperCase()}';

        // Auto-limpiar después de 3.5 segundos
        Future.delayed(const Duration(milliseconds: 3500), () {
          ref.read(completedOrderNotificationProvider.notifier).state = null;
        });
      });
    } catch (e) {
      developer.log("ERROR al terminar pedido $pedidoId: $e", error: e);
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> cancelOrder(String pedidoId) async {
    state = true;
    try {
      developer.log("Cancelando pedido desde cocina: $pedidoId");
      await _firestore.collection('pedido').doc(pedidoId).update({
        'status': 'cancelado',
        'cancelledBy': 'cocina', // ✅ Indicar que fue cancelado por cocina
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log("Pedido $pedidoId marcado como 'cancelado' por cocina");
    } catch (e) {
      developer.log("ERROR al cancelar pedido $pedidoId: $e", error: e);
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> reactivateOrder(String pedidoId) async {
    state = true;
    try {
      developer.log("Reactivando pedido: $pedidoId");
      await _firestore.collection('pedido').doc(pedidoId).update({
        'status': 'pendiente',
        'cancelledBy': FieldValue.delete(), // ✅ Limpiar el campo cancelledBy
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log("Pedido $pedidoId reactivado como 'pendiente'");
    } catch (e) {
      developer.log("ERROR al reactivar pedido $pedidoId: $e", error: e);
      rethrow;
    } finally {
      state = false;
    }
  }

  // ✅ NUEVO: Marcar un item individual como preparado
  Future<void> toggleItemPreparation(String pedidoId, int itemIndex) async {
    try {
      developer.log("Cambiando estado de preparación del item $itemIndex en pedido $pedidoId");

      final docRef = _firestore.collection('pedido').doc(pedidoId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Pedido no encontrado');
      }

      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

      if (itemIndex >= items.length) {
        throw Exception('Índice de item inválido');
      }

      // Cambiar el estado de preparación del item
      items[itemIndex]['isPrepared'] = !(items[itemIndex]['isPrepared'] ?? false);

      // ✅ NO actualizar updatedAt para que la hora de llegada no cambie
      await docRef.update({
        'items': items,
      });

      developer.log("Item $itemIndex del pedido $pedidoId actualizado");
    } catch (e) {
      developer.log("ERROR al actualizar item: $e", error: e);
      rethrow;
    }
  }

  // ✅ NUEVO: Preparar todos los items de un pedido
  Future<void> prepareAllItems(String pedidoId, int itemCount) async {
    try {
      developer.log("Preparando todos los items del pedido $pedidoId");

      final docRef = _firestore.collection('pedido').doc(pedidoId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Pedido no encontrado');
      }

      final data = doc.data()!;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

      // Marcar todos los items como preparados
      for (var i = 0; i < items.length; i++) {
        items[i]['isPrepared'] = true;
      }

      // ✅ NO actualizar updatedAt para que la hora de llegada no cambie
      await docRef.update({
        'items': items,
      });

      developer.log("Todos los items del pedido $pedidoId marcados como preparados");
    } catch (e) {
      developer.log("ERROR al preparar todos los items: $e", error: e);
      rethrow;
    }
  }
}

// Provider para el StateNotifier
final cocinaNotifierProvider = StateNotifierProvider<CocinaNotifier, bool>((ref) {
  return CocinaNotifier();
});

// Provider para estadísticas rápidas (usando los status de Firestore)
final pedidoStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final pedidosAsync = ref.watch(pedidosStreamProvider);

  return pedidosAsync.when(
    data: (pedidos) {
      developer.log("STATS PROVIDER: Calculando estadísticas para ${pedidos.length} pedidos");
      
      final stats = <String, int>{
        'pendiente': 0,
        'preparando': 0, // Cambié 'enPreparacion' por 'preparando'
        'terminado': 0,  // Cambié 'listo' por 'terminado'
        'entregado': 0,
        'cancelado': 0,
        'pagado': 0,
      };

      for (final pedido in pedidos) {
        stats[pedido.status] = (stats[pedido.status] ?? 0) + 1;
      }

      developer.log("ESTADÍSTICAS: $stats");
      return AsyncValue.data(stats);
    },
    loading: () {
      developer.log("STATS PROVIDER: Loading...");
      return const AsyncValue.loading();
    },
    error: (e, st) {
      developer.log("STATS PROVIDER ERROR: $e", error: e, stackTrace: st);
      return AsyncValue.error(e, st);
    },
  );
});

List<Pedido> _sortByRecent(List<Pedido> pedidos) {
  final ordered = List<Pedido>.from(pedidos);
  ordered.sort((a, b) {
    // ✅ USAR SOLO createdAt para mantener el orden de llegada original
    // Ignorar updatedAt para evitar que los pedidos se reordenen al actualizarlos
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    // Ordenar de más antiguo a más reciente (FIFO)
    // Los pedidos más antiguos aparecen primero (índice 0)
    return aDate.compareTo(bDate);
  });
  return ordered;
}

List<Pedido> _sortCompletedByMostRecent(List<Pedido> pedidos) {
  final ordered = List<Pedido>.from(pedidos);
  ordered.sort((a, b) {
    // Para pedidos completados, usar updatedAt (cuando se marcó como terminado)
    // Si no existe updatedAt, usar createdAt como fallback
    final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    // Ordenar de más reciente a más antiguo (el más nuevo primero)
    return bDate.compareTo(aDate);
  });
  return ordered;
}