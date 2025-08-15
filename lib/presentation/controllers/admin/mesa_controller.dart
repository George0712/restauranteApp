import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

class MesaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controladores de texto para el formulario
  final TextEditingController numeroMesaController = TextEditingController();
  final TextEditingController capacidadController = TextEditingController();

  void dispose() {
    numeroMesaController.dispose();
    capacidadController.dispose();
  }

  // Validar campos del formulario
  bool areFieldsValid() {
    final numeroMesa = numeroMesaController.text.trim();
    final capacidad = capacidadController.text.trim();
    
    // Validar que el número de mesa sea un número válido
    final numeroMesaRegex = RegExp(r'^[1-9]\d*$');
    // Validar que la capacidad sea un número válido entre 1 y 20
    final capacidadRegex = RegExp(r'^([1-9]|1[0-9]|20)$');
    
    return numeroMesaRegex.hasMatch(numeroMesa) && 
           capacidadRegex.hasMatch(capacidad);
  }

  // Crear una nueva mesa
  Future<String?> crearMesa({
    required int numeroMesa,
    required int capacidad,
  }) async {
    try {
      // Verificar si ya existe una mesa con ese número
      final mesaExistente = await _firestore
          .collection('mesa')
          .where('id', isEqualTo: numeroMesa)
          .get();

      if (mesaExistente.docs.isNotEmpty) {
        return 'Ya existe una mesa con el número $numeroMesa';
      }

      // Crear el modelo de mesa
      final mesa = MesaModel(
        id: numeroMesa,
        estado: 'disponible',
        capacidad: capacidad,
      );

      // Guardar en Firestore
      final docRef = await _firestore.collection('mesa').add(mesa.toMap());
      print('Mesa creada exitosamente con ID: ${docRef.id}');
      
      return null; // Éxito
    } catch (e) {
      print('Error detallado al crear mesa: $e');
      if (e.toString().contains('permission-denied')) {
        return 'Error de permisos: No tienes permisos para crear mesas. Verifica las reglas de Firestore.';
      } else if (e.toString().contains('unavailable')) {
        return 'Error de conexión: No se pudo conectar con la base de datos. Verifica tu conexión a internet.';
      } else {
        return 'Error al crear la mesa: $e';
      }
    }
  }

  // Obtener todas las mesas
  Future<List<MesaModel>> obtenerMesas() async {
    try {
      final querySnapshot = await _firestore
          .collection('mesa')
          .orderBy('id')
          .get();

      return querySnapshot.docs
          .map((doc) => MesaModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las mesas: $e');
    }
  }

  // Actualizar una mesa
  Future<String?> actualizarMesa({
    required String documentId,
    required int numeroMesa,
    required int capacidad,
  }) async {
    try {
      // Verificar si ya existe otra mesa con ese número (excluyendo la actual)
      final mesaExistente = await _firestore
          .collection('mesa')
          .where('id', isEqualTo: numeroMesa)
          .get();

      final mesaConMismoNumero = mesaExistente.docs
          .where((doc) => doc.id != documentId)
          .isNotEmpty;

      if (mesaConMismoNumero) {
        return 'Ya existe una mesa con el número $numeroMesa';
      }

      // Actualizar en Firestore
      await _firestore.collection('mesa').doc(documentId).update({
        'id': numeroMesa,
        'capacidad': capacidad,
      });
      
      return null; // Éxito
    } catch (e) {
      return 'Error al actualizar la mesa: $e';
    }
  }

  // Eliminar una mesa
  Future<String?> eliminarMesa(String documentId) async {
    try {
      // Verificar si la mesa está ocupada
      final mesaDoc = await _firestore.collection('mesa').doc(documentId).get();
      if (!mesaDoc.exists) {
        return 'La mesa no existe';
      }

      final mesa = MesaModel.fromMap(mesaDoc.data()!, documentId);
      if (mesa.estado == 'ocupada') {
        return 'No se puede eliminar una mesa que está ocupada';
      }

      // Eliminar de Firestore
      await _firestore.collection('mesa').doc(documentId).delete();
      
      return null; // Éxito
    } catch (e) {
      return 'Error al eliminar la mesa: $e';
    }
  }

  // Cambiar estado de una mesa
  Future<String?> cambiarEstadoMesa({
    required String documentId,
    required String nuevoEstado,
    String? cliente,
    String? pedidoId,
  }) async {
    try {
      final updateData = {
        'estado': nuevoEstado,
        'cliente': cliente,
        'pedidoId': pedidoId,
      };

      // Si se está ocupando la mesa, agregar hora de ocupación
      if (nuevoEstado == 'ocupada') {
        updateData['horaOcupacion'] = DateTime.now().toIso8601String();
      } else if (nuevoEstado == 'disponible') {
        // Si se libera la mesa, limpiar datos de ocupación
        updateData['cliente'] = null;
        updateData['pedidoId'] = null;
        updateData['horaOcupacion'] = null;
        updateData['tiempo'] = null;
        updateData['total'] = null;
      }

      await _firestore.collection('mesa').doc(documentId).update(updateData);
      
      return null; // Éxito
    } catch (e) {
      return 'Error al cambiar el estado de la mesa: $e';
    }
  }

  // Limpiar formulario
  void limpiarFormulario() {
    numeroMesaController.clear();
    capacidadController.clear();
  }
}
