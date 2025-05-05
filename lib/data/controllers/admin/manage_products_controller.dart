import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/data/models/category_model.dart';

class RegisterCategoryController {
  final TextEditingController nombreController = TextEditingController();

  void dispose() {
    nombreController.dispose();
  }

  bool areFieldsValid() {
    final nombre = nombreController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre);
  }

  Future<String?> registrarCategoria(
    WidgetRef ref, {
    required String nombre,
    required bool disponible,
    required String? foto,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('categoria').doc();

      final categoria = CategoryModel(
        id: docRef.id,
        name: nombre,
        photo: foto,
        disponible: disponible,
      );

      await docRef.set(categoria.toMap());

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

class RegisterProductoController {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController tiempoPreparacionController =
      TextEditingController();
  final TextEditingController ingredientesController = TextEditingController();

  void dispose() {
    nombreController.dispose();
    precioController.dispose();
    tiempoPreparacionController.dispose();
    ingredientesController.dispose();
  }

  bool areFieldsValid() {
    final nombre = nombreController.text.trim();
    final precio = precioController.text.trim();
    final tiempoPreparacion = tiempoPreparacionController.text.trim();
    final ingredientes = ingredientesController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre) &&
        AppConstants.priceRegex.hasMatch(precio) &&
        AppConstants.timePreparationRegex.hasMatch(tiempoPreparacion) &&
        AppConstants.ingredientesRegex.hasMatch(ingredientes);
  }

  Future<String?> registrarProducto(
    WidgetRef ref, {
    required String nombre,
    required double precio,
    required int tiempoPreparacion,
    required String ingredientes,
    required String categoria,
    required bool disponible,
    required String foto,
  }) async {
    try {
      final productoData = {
        'name': nombre,
        'price': precio,
        'time': tiempoPreparacion,
        'ingredients': ingredientes,
        'category': categoria,
        'disponible': disponible = true,
        'photo': foto,
      };

      final db = FirebaseFirestore.instance;

      await db.collection('producto').add(productoData);

      return null; // Éxito
    } catch (e) {
      return e.toString();
    }
  }
}

class RegisterAdditionalController {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();

  void dispose() {
    nombreController.dispose();
    precioController.dispose();
  }

  bool areFieldsValid() {
    final nombre = nombreController.text.trim();
    final precio = precioController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre) &&
        AppConstants.priceRegex.hasMatch(precio);
  }

  Future<String?> registrarAdditional(
    WidgetRef ref, {
    required String nombre,
    required String precio,
    required bool disponible,
    required String foto,
  }) async {
    try {} catch (e) {
      return e.toString();
    }
    return null;
  }
}

class RegisterComboController {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController tiempoPreparacionController =
      TextEditingController();
  final TextEditingController ingredientesController = TextEditingController();

  void dispose() {
    nombreController.dispose();
    precioController.dispose();
    tiempoPreparacionController.dispose();
    ingredientesController.dispose();
  }

  bool areFieldsValid() {
    final nombre = nombreController.text.trim();
    final precio = precioController.text.trim();
    final tiempoPreparacion = tiempoPreparacionController.text.trim();
    final ingredientes = ingredientesController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre) &&
        AppConstants.priceRegex.hasMatch(precio) &&
        AppConstants.timePreparationRegex.hasMatch(tiempoPreparacion) &&
        AppConstants.ingredientesRegex.hasMatch(ingredientes);
  }

  Future<String?> registrarProducto(
    WidgetRef ref, {
    required String nombre,
    required String precio,
    required String tiempoPreparacion,
    required String productos,
    required String categoria,
    required String disponible,
    required String foto,
  }) async {
    try {} catch (e) {
      return e.toString();
    }
    return null;
  }
}
