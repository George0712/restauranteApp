import 'package:restaurante_app/data/models/product_model.dart';

class ItemCarrito {
  final ProductModel producto;
  int cantidad;
  final List<String> modificacionesSeleccionadas;
  final double precioUnitario;
  final String? notas;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.modificacionesSeleccionadas = const [],
    this.precioUnitario = 0.0,
    this.notas,
  });

  double get subtotal {
    double precioBase = producto.price * cantidad;
    // Los precios de los adicionales se manejan en la UI usando el provider de adicionales
    return precioBase;
  }
}