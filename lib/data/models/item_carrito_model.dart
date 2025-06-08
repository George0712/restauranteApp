import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';

class ItemCarrito {
  final ProductModel producto;
  int cantidad;
  final List<String> modificacionesSeleccionadas;
  final double precioUnitario;
  final String? notas;
  final List<AdditionalModel>? adicionales;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
    this.modificacionesSeleccionadas = const [],
    this.precioUnitario = 0.0,
    this.notas,
    this.adicionales,
  });

  double get subtotal {
    double precioBase = precioUnitario * cantidad;
    double precioAdicionales = 0.0;
    
    if (adicionales != null) {
      precioAdicionales = adicionales!.fold(0.0, (sum, adicional) => sum + adicional.price) * cantidad;
    }
    
    return precioBase + precioAdicionales;
  }
}