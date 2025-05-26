class ItemPedido {
  final String id;
  final String nombre;
  final double precio;
  final int cantidad;
  final String? notas;
  final List<String>? adicionales;

  ItemPedido({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.notas,
    this.adicionales,
  });

  double get subtotal => precio * cantidad;
}

class Pedido {
  final String id;
  final int mesaId;
  final String? cliente;
  final DateTime fecha;
  final List<ItemPedido> items;
  final String estado;
  final double? propina;
  final String? notas;

  Pedido({
    required this.id,
    required this.mesaId,
    this.cliente,
    required this.fecha,
    required this.items,
    required this.estado,
    this.propina,
    this.notas,
  });

  double get total => items.fold(0, (sum, item) => sum + (item.precio * item.cantidad));
  double get totalConPropina => propina != null ? total + propina! : total;
}

enum EstadoPedido {
  pendiente,
  enPreparacion,
  listo,
  entregado,
  cancelado,
} 