import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/incidencia_model.dart';

// Provider para obtener todas las incidencias en tiempo real
final incidenciasStreamProvider = StreamProvider<List<Incidencia>>((ref) {
  return FirebaseFirestore.instance
      .collection('incidencias')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return Incidencia.fromJson(doc.data(), docId: doc.id);
    }).toList();
  });
});

// Provider para obtener estadísticas de incidencias
final incidenciasStatsProvider = Provider<Map<String, int>>((ref) {
  final incidenciasAsync = ref.watch(incidenciasStreamProvider);

  return incidenciasAsync.when(
    data: (incidencias) {
      final stats = <String, int>{
        'total': incidencias.length,
        'pendiente': 0,
        'en_revision': 0,
        'resuelta': 0,
        'cerrada': 0,
        'urgente': 0,
        'cocina': 0,
        'administracion': 0,
        'tecnica': 0,
        'otra': 0,
      };

      for (final incidencia in incidencias) {
        // Contar por estado
        final estado = incidencia.estado.toLowerCase();
        stats[estado] = (stats[estado] ?? 0) + 1;

        // Contar urgentes
        if (incidencia.categoria.toLowerCase() == 'urgente') {
          stats['urgente'] = stats['urgente']! + 1;
        }

        // Contar por tipo
        final tipo = incidencia.tipo.toLowerCase();
        stats[tipo] = (stats[tipo] ?? 0) + 1;
      }

      return stats;
    },
    loading: () => {
      'total': 0,
      'pendiente': 0,
      'en_revision': 0,
      'resuelta': 0,
      'cerrada': 0,
      'urgente': 0,
      'cocina': 0,
      'administracion': 0,
      'tecnica': 0,
      'otra': 0,
    },
    error: (_, __) => {
      'total': 0,
      'pendiente': 0,
      'en_revision': 0,
      'resuelta': 0,
      'cerrada': 0,
      'urgente': 0,
      'cocina': 0,
      'administracion': 0,
      'tecnica': 0,
      'otra': 0,
    },
  );
});
