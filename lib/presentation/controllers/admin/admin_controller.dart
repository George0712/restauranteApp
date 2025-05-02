
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardState {
  final int totalVentas;
  final int ordenes;
  final int clientes;
  final int productos;

  AdminDashboardState({
    this.totalVentas = 0,
    this.ordenes = 0,
    this.clientes = 0,
    this.productos = 0,
  });

  AdminDashboardState copyWith({
    int? totalVentas,
    int? ordenes,
    int? clientes,
    int? productos,
  }) {
    return AdminDashboardState(
      totalVentas: totalVentas ?? this.totalVentas,
      ordenes: ordenes ?? this.ordenes,
      clientes: clientes ?? this.clientes,
      productos: productos ?? this.productos,
    );
  }
}

class AdminController extends StateNotifier<AdminDashboardState> {
  AdminController() : super(AdminDashboardState());

  Future<void> cargarDashboard() async {
    // Aquí simulas una carga de datos, podrías conectar a Firestore, Supabase, etc.
    await Future.delayed(const Duration(seconds: 1));

    // Supón que estos datos vienen de una base de datos
    state = AdminDashboardState(
      totalVentas: 200000,
      ordenes: 43,
      clientes: 23,
      productos: 12,
    );
  }
}