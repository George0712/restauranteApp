import 'package:cloud_firestore/cloud_firestore.dart';
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> cargarDashboard() async {
    try {
      final docSnapshot = await _firestore
          .collection('dashboard_data')
          .doc('resumen')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        state = AdminDashboardState(
          totalVentas: data?['totalVentas'] ?? 0,
          ordenes: data?['ordenes'] ?? 0,
          clientes: data?['clientes'] ?? 0,
          productos: data?['productos'] ?? 0,
        );
      } else {
        // Documento no existe, puedes manejarlo como un error o dejar valores en cero
        state = AdminDashboardState();
      }
    } catch (e) {
      // Opcional: mostrar un estado de error
      state = AdminDashboardState(); // o mantén el anterior
    }
  }
}