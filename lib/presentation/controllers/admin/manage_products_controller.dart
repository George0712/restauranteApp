import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/constants/app_constants.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/data/models/category_model.dart';
import 'package:restaurante_app/data/models/combo_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'dart:io';
import 'package:restaurante_app/presentation/providers/images/cloudinary_service.dart';

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
    required String? foto,
    Function(double)? onUploadProgress,
  }) async {
    try {
      String? photoUrl;
      
      // Si hay una imagen, subirla a Cloudinary
      if (foto != null && foto.isNotEmpty) {
        print('Subiendo imagen a Cloudinary: $foto');
        onUploadProgress?.call(0.1);
        
        final file = File(foto);
        
        if (!await file.exists()) {
          throw Exception('El archivo de imagen no existe');
        }
        
        // Subir imagen con progreso
        photoUrl = await CloudinaryService.uploadImage(
          file,
          onProgress: (progress) {
            // Mapear progreso de subida (0.1 a 0.8)
            final mappedProgress = 0.1 + (progress * 0.7);
            onUploadProgress?.call(mappedProgress);
          },
        );
        
        if (photoUrl == null) {
          throw Exception('Error al subir la imagen a Cloudinary');
        }
        
        print('Imagen subida exitosamente: $photoUrl');
        onUploadProgress?.call(0.9);
      }

      final productoData = {
        'name': nombre,
        'price': precio,
        'time': tiempoPreparacion,
        'ingredients': ingredientes,
        'categoryId': categoria,
        'disponible': disponible,
        'photo': photoUrl, // URL de Cloudinary
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Guardando producto: $productoData');

      final db = FirebaseFirestore.instance;
      final docRef = await db.collection('producto').add(productoData);
      
      onUploadProgress?.call(1.0);
      print('Producto guardado con ID: ${docRef.id}');

      return null; // Éxito
    } catch (e) {
      print('Error al registrar producto: $e');
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
    required double precio,
    required bool disponible,
    required String foto,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('adicional').doc();

      final adicional = AdditionalModel(
        id: docRef.id,
        name: nombre,
        price: precio,
        disponible: disponible,
        photo: foto,
      );

      await docRef.set(adicional.toMap());

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

class RegisterComboController extends StateNotifier<void> {
  RegisterComboController() : super(null);

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController tiempoPreparacionController =
      TextEditingController();

  final List<ProductModel> productos = [];

  void addProduct(ProductModel product) {
    productos.add(product);
  }

  void removeProduct(ProductModel product) {
    productos.remove(product);
  }

  void clearProducts() {
    productos.clear();
  }

  List<ProductModel> get products => productos;

  bool isProductSelected(ProductModel product) {
    return productos.contains(product);
  }

  void update() {
    state = null;
  }

  @override
  void dispose() {
    super.dispose();
    nombreController.dispose();
    precioController.dispose();
    tiempoPreparacionController.dispose();
  }

  bool areFieldsValid() {
    final nombre = nombreController.text.trim();
    final precio = precioController.text.trim();
    final tiempoPreparacion = tiempoPreparacionController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre) &&
        AppConstants.priceRegex.hasMatch(precio) &&
        AppConstants.timePreparationRegex.hasMatch(tiempoPreparacion);
  }

  Future<String?> registrarCombo(
    WidgetRef ref, {
    required String nombre,
    required double precio,
    required int tiempoPreparacion,
    required List<ProductModel> productos,
    required String? disponible,
    required String? foto,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('combo').doc();

      final combo = ComboModel(
        id: docRef.id,
        name: nombre,
        price: precio,
        timePreparation: tiempoPreparacion,
        products: productos,
        disponible: disponible == 'true',
        photo: foto,
      );

      await docRef.set(combo.toMap());

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
