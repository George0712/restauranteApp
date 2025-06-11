import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import '../../../data/models/pedido.dart';

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

  void agregarItem(ItemCarrito item) {
    // Buscar si ya existe un item similar
    final index = state.indexWhere((existingItem) =>
        existingItem.producto.id == item.producto.id &&
        _listasIguales(existingItem.modificacionesSeleccionadas, item.modificacionesSeleccionadas));

    if (index >= 0) {
      // Actualizar cantidad
      final updatedItem = state[index];
      updatedItem.cantidad += item.cantidad;
      state = [...state];
    } else {
      // Agregar nuevo item
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

  double get total => state.fold(0.0, (sum, item) => sum + item.subtotal);
  int get cantidadTotal => state.fold(0, (sum, item) => sum + item.cantidad);

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