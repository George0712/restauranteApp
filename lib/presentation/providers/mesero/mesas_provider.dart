import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

class MesasNotifier extends StateNotifier<List<MesaModel>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  MesasNotifier() : super([]) {
    _cargarMesas();
  }

  Future<void> _cargarMesas() async {
    try {
      final querySnapshot = await _firestore
          .collection('mesa')
          .orderBy('id')
          .get();

      final mesas = querySnapshot.docs
          .map((doc) => MesaModel.fromMap(doc.data(), doc.id))
          .toList();
      
      state = mesas;
    } catch (e) {
      developer.log('Error al cargar mesas: $e', error: e);
      state = [];
    }
  }

  Future<void> refrescarMesas() async {
    await _cargarMesas();
  }

  void agregarMesa(MesaModel mesa) {
    state = [...state, mesa];
  }

  Future<void> editarMesa(MesaModel mesa) async {
    try {
      // Buscar el documento por el ID de la mesa
      final querySnapshot = await _firestore
          .collection('mesa')
          .where('id', isEqualTo: mesa.id)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final documentId = querySnapshot.docs.first.id;
        await _firestore.collection('mesa').doc(documentId).update(mesa.toMap());
        
        // Actualizar el estado local
        state = [
          for (final m in state)
            if (m.id == mesa.id) mesa else m
        ];
      }
    } catch (e) {
      developer.log('Error al editar mesa: $e', error: e);
    }
  }

  Future<void> eliminarMesa(int id) async {
    try {
      // Buscar el documento por el ID de la mesa
      final querySnapshot = await _firestore
          .collection('mesa')
          .where('id', isEqualTo: id)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final documentId = querySnapshot.docs.first.id;
        await _firestore.collection('mesa').doc(documentId).delete();
        
        // Actualizar el estado local
        state = state.where((m) => m.id != id).toList();
      }
    } catch (e) {
      developer.log('Error al eliminar mesa: $e', error: e);
    }
  }

  void asignarPedido(int mesaId, String pedidoId) {
    state = [
      for (final m in state)
        if (m.id == mesaId) m.copyWith(pedidoId: pedidoId) else m
    ];
  }

  int get mesasDisponibles => state.where((m) => m.estado == 'disponible').length;
  int get mesasOcupadas => state.where((m) => m.estado == 'ocupada').length;
  int get mesasReservadas => state.where((m) => m.estado == 'reservada').length;
}

final mesasMeseroProvider = StateNotifierProvider<MesasNotifier, List<MesaModel>>((ref) {
  return MesasNotifier();
});

// Provider para obtener mesas en tiempo real desde Firestore
final mesasStreamProvider = StreamProvider<List<MesaModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('mesa').snapshots().map((snapshot) {
    final mesas = snapshot.docs.map((doc) {
      return MesaModel.fromMap(doc.data(), doc.id);
    }).toList();
    
    // Ordenar las mesas por ID numérico ascendente
    mesas.sort((a, b) => a.id.compareTo(b.id));
    return mesas;
  });
});
