import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/data/models/product_model.dart';

final pedidosProvider = StateNotifierProvider<PedidosNotifier, List<Pedido>>((ref) {
  return PedidosNotifier();
});

class PedidosNotifier extends StateNotifier<List<Pedido>> {
  PedidosNotifier() : super([]);

  void agregarPedido(Pedido pedido) {
    state = [...state, pedido];
  }

  void actualizarPedido(Pedido pedido) {
    state = state.map((p) => p.id == pedido.id ? pedido : p).toList();
  }

  void eliminarPedido(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  Pedido? obtenerPedido(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Pedido? obtenerPedidoPorMesa(int mesaId) {
    try {
      return state.firstWhere(
        (p) => p.mesaId == mesaId && p.estado != 'completado' && p.estado != 'cancelado',
      );
    } catch (e) {
      return null;
    }
  }
} 

// Provider para el carrito
class CarritoNotifier extends StateNotifier<List<ItemCarrito>> {
  CarritoNotifier() : super([]);

  // ✅ NUEVO: Cargar carrito desde un pedido en Firestore
  Future<void> cargarDesdeFirestore(String pedidoId, List<ProductModel> productos, List<AdditionalModel> adicionales) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pedido')
          .doc(pedidoId)
          .get();

      if (!doc.exists) {
        state = [];
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'] as List?;
      
      if (items == null || items.isEmpty) {
        state = [];
        return;
      }

      final carritoItems = <ItemCarrito>[];
      
      for (final item in items) {
        try {
          // Buscar el producto
          final producto = productos.firstWhere(
            (p) => p.id == item['productId'],
            orElse: () => throw Exception('Producto no encontrado'),
          );

          // Buscar adicionales
          final adicionalesItem = <AdditionalModel>[];
          final modificacionesIds = <String>[];
          
          if (item['adicionales'] != null) {
            for (final adicional in item['adicionales']) {
              final adicionalObj = adicionales.firstWhere(
                (a) => a.id == adicional['id'],
                orElse: () => throw Exception('Adicional no encontrado'),
              );
              adicionalesItem.add(adicionalObj);
              modificacionesIds.add(adicionalObj.id);
            }
          }

          final carritoItem = ItemCarrito(
            producto: producto,
            cantidad: item['quantity'] ?? 1,
            precioUnitario: (item['price'] ?? producto.price).toDouble(),
            notas: item['notes'] ?? '',
            adicionales: adicionalesItem.isEmpty ? null : adicionalesItem,
            modificacionesSeleccionadas: modificacionesIds,
          );

          carritoItems.add(carritoItem);
        } catch (e) {
          developer.log('Error cargando item del carrito: $e', error: e);
          // Continuar con los demás items
        }
      }

      state = carritoItems;
      developer.log('Carrito cargado desde Firestore: ${carritoItems.length} items');
    } catch (e) {
      developer.log('Error cargando carrito desde Firestore: $e', error: e);
      state = [];
    }
  }

  void agregarItem(ItemCarrito item) {
    final index = state.indexWhere((existingItem) =>
        existingItem.producto.id == item.producto.id &&
        _listasIguales(existingItem.modificacionesSeleccionadas, item.modificacionesSeleccionadas));

    if (index >= 0) {
      final updatedItem = state[index];
      updatedItem.cantidad += item.cantidad;
      state = [...state];
    } else {
      state = [...state, item];
    }
  }

  void actualizarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      eliminarItem(index);
      return;
    }
    
    final updatedItems = [...state];
    updatedItems[index].cantidad = nuevaCantidad;
    state = updatedItems;
  }

  void eliminarItem(int index) {
    state = state.where((item) => state.indexOf(item) != index).toList();
  }

  void limpiarCarrito() {
    state = [];
  }

  double get total => state.fold(0.0, (accumulator, item) => accumulator + item.subtotal);
  int get cantidadTotal => state.fold(0, (total, item) => total + item.cantidad);

  bool _listasIguales(List<String> lista1, List<String> lista2) {
    if (lista1.length != lista2.length) return false;
    for (int i = 0; i < lista1.length; i++) {
      if (lista1[i] != lista2[i]) return false;
    }
    return true;
  }
}

final carritoProvider = StateNotifierProvider<CarritoNotifier, List<ItemCarrito>>((ref) {
  return CarritoNotifier();
});

// ✅ NUEVO: Provider para obtener un pedido específico desde Firestore
final pedidoPorIdProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, pedidoId) {
  return FirebaseFirestore.instance
      .collection('pedido')
      .doc(pedidoId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return doc.data();
      });
});

// ✅ NUEVO: Provider para verificar si un pedido está confirmado
final pedidoConfirmadoProvider = Provider.family<bool, String?>((ref, pedidoId) {
  if (pedidoId == null) return false;
  
  final pedidoAsync = ref.watch(pedidoPorIdProvider(pedidoId));
  return pedidoAsync.when(
    data: (pedido) {
      if (pedido == null) return false;
      final items = pedido['items'] as List?;
      final status = pedido['status'] ?? 'nuevo';
      return items != null && items.isNotEmpty && status != 'nuevo';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});