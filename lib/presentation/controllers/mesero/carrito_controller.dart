import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart';

class CarritoController {
  final Ref ref;

  CarritoController(this.ref);

  void agregarItem(ItemCarrito item) {
    ref.read(carritoProvider.notifier).agregarItem(item);
  }

  void limpiarCarrito() {
    ref.read(carritoProvider.notifier).limpiarCarrito();
  }

  List<ItemCarrito> obtenerCarrito() {
    return ref.read(carritoProvider);
  }

  double calcularTotal() {
    final carrito = ref.read(carritoProvider);
    return carrito.fold<double>(0, (sum, item) {
      final precioBase = item.precioUnitario * item.cantidad;
      final precioAdicionales = item.adicionales?.fold<double>(
        0,
        (sum, adicional) => sum + (adicional.price * item.cantidad),
      ) ?? 0;
      return sum + precioBase + precioAdicionales;
    });
  }

  void eliminarItem(int index) {
    ref.read(carritoProvider.notifier).eliminarItem(index);
  }

  void actualizarCantidad(int index, int nuevaCantidad) {
    ref.read(carritoProvider.notifier).actualizarCantidad(index, nuevaCantidad);
  }
}

final carritoControllerProvider = Provider((ref) => CarritoController(ref)); 