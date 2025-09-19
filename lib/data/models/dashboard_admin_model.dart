class AdminDashboardModel {
  final int totalVentas;
  final int ordenes;
  final int usuarios;
  final int productos;

  AdminDashboardModel({
    this.totalVentas = 0,
    this.ordenes = 0,
    this.usuarios = 0,
    this.productos = 0,
  });

  AdminDashboardModel copyWith({
    int? totalVentas,
    int? ordenes,
    int? usuarios,
    int? productos,
  }) {
    return AdminDashboardModel(
      totalVentas: totalVentas ?? this.totalVentas,
      ordenes: ordenes ?? this.ordenes,
      usuarios: usuarios ?? this.usuarios,
      productos: productos ?? this.productos,
    );
  }
}