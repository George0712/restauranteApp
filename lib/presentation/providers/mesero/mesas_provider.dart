import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

// StateNotifier mejorado
class MesasNotifier extends StateNotifier<List<MesaModel>> {
  MesasNotifier() : super([]);

  void agregarMesa(MesaModel mesa) {
    state = [...state, mesa];
  }

  void editarMesa(MesaModel mesa) {
    state = [
      for (final m in state)
        if (m.id == mesa.id) mesa else m
    ];
  }

  void eliminarMesa(int id) {
    state = state.where((m) => m.id != id).toList();
  }

  void asignarPedido(int mesaId, String pedidoId) {
    state = [
      for (final m in state)
        if (m.id == mesaId) m.copyWith(pedidoId: pedidoId) else m
    ];
  }

  int get mesasDisponibles => state.where((m) => m.estado == 'Disponible').length;
  int get mesasOcupadas => state.where((m) => m.estado == 'Ocupada').length;
  int get mesasReservadas => state.where((m) => m.estado == 'Reservada').length;
}

final mesasProvider = StateNotifierProvider<MesasNotifier, List<MesaModel>>((ref) {
  return MesasNotifier();
});