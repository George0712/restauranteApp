import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/dashboard_admin_model.dart';

class AdminController extends StateNotifier<AdminDashboardModel> {
  AdminController() : super(AdminDashboardModel());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> cargarDashboard() async {
    try {
      final docSnapshot = await _firestore
          .collection('dashboard_admin')
          .doc('resumen')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        state = AdminDashboardModel(
          totalVentas: data?['totalVentas'] ?? 0,
          ordenes: data?['ordenes'] ?? 0,
          usuarios: data?['usuarios'] ?? 0,
          productos: data?['productos'] ?? 0,
        );
      } else {
        // Documento no existe, puedes manejarlo como un error o dejar valores en cero
        state = AdminDashboardModel();
      }
    } catch (e) {
      state = AdminDashboardModel(); // o mantén el anterior
    }
  }
}