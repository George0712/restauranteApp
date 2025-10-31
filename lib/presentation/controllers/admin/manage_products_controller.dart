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

  late bool _disponible;

  bool get disponible => _disponible;

  RegisterCategoryController() {
    _disponible = true;
  }

  void dispose() {
    nombreController.dispose();
  }

  void initializeForEditing(CategoryModel category) {
    nombreController.text = category.name;
    _disponible = category.disponible;
  }

  void setDisponible(bool value) {
    _disponible = value;
  }

  bool areFieldsValid() {
    final nombre = nombreController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre);
  }

  Future<String?> registrarCategoria(WidgetRef ref, {
    required String nombre,
    required bool disponible,
    String? foto,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('categoria').doc();
      final category = CategoryModel(
        id: docRef.id,
        name: nombre,
        disponible: disponible,
      );
      await docRef.set(category.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> actualizarCategoria(WidgetRef ref, {
    required String id,
    required String nombre,
    required bool disponible,
    String? foto,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('categoria').doc(id);
      await docRef.update({
        'name': nombre,
        'disponible': disponible,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> eliminarCategoria(WidgetRef ref, {
    required String id,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('categoria').doc(id);
      await docRef.delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final registerCategoryControllerProvider = Provider((ref) => RegisterCategoryController());

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

  void clearAllFields() {
    nombreController.clear();
    precioController.clear();
    tiempoPreparacionController.clear();
    ingredientesController.clear();
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
        onUploadProgress?.call(0.9);
      }

      final productoData = {
        'name': nombre,
        'price': precio,
        'time': tiempoPreparacion,
        'ingredients': ingredientes,
        'category': categoria,
        'disponible': disponible,
        'photo': photoUrl, // URL de Cloudinary
        'createdAt': FieldValue.serverTimestamp(),
      };

      final db = FirebaseFirestore.instance;
      await db.collection('producto').add(productoData);

      onUploadProgress?.call(1.0);

      return null; // Éxito
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProduct(
    WidgetRef ref, {
    required String productId,
    required String nombre,
    required double precio,
    required int tiempoPreparacion,
    required String ingredientes,
    required String categoria,
    required bool disponible,
    String? newPhoto,
    Function(double)? onUploadProgress,
  }) async {
    try {
      String? photoUrl = newPhoto; // Mantener la foto actual si no hay nueva

      // Si hay una nueva imagen, subirla a Cloudinary
      if (newPhoto != null &&
          newPhoto.isNotEmpty &&
          !newPhoto.startsWith('http')) {
        onUploadProgress?.call(0.1);

        final file = File(newPhoto);

        if (!await file.exists()) {
          throw Exception('El archivo de imagen no existe');
        }

        // Subir nueva imagen con progreso
        photoUrl = await CloudinaryService.uploadImage(
          file,
          onProgress: (progress) {
            final mappedProgress = 0.1 + (progress * 0.7);
            onUploadProgress?.call(mappedProgress);
          },
        );

        if (photoUrl == null) {
          throw Exception('Error al subir la imagen a Cloudinary');
        }

        onUploadProgress?.call(0.9);
      }

      final productoData = {
        'name': nombre,
        'price': precio,
        'time': tiempoPreparacion,
        'ingredients': ingredientes,
        'category': categoria,
        'disponible': disponible,
        'photo': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final db = FirebaseFirestore.instance;
      await db.collection('producto').doc(productId).update(productoData);

      onUploadProgress?.call(1.0);

      return null; // Éxito
    } catch (e) {
      return e.toString();
    }
  }
}

class RegisterAdditionalController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool _disponible = true;

  bool get disponible => _disponible;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }

  void clear() {
    nameController.clear();
    priceController.clear();
    _disponible = true;
  }

  void setDisponible(bool value) {
    _disponible = value;
  }

  void initializeForEditing(AdditionalModel additional) {
    nameController.text = additional.name;
    priceController.text = additional.price.toString();
    _disponible = additional.disponible;
  }

  bool areFieldsValid() {
    final name = nameController.text.trim();
    final price = priceController.text.trim();
    return name.isNotEmpty && AppConstants.priceRegex.hasMatch(price);
  }

  /// Crea un nuevo adicional en firestore
  Future<String?> registrarAdditional(WidgetRef ref, {
    required String name,
    required bool disponible,
    required double price,
    String? photo,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('adicional').doc();
      final additional = AdditionalModel(
        id: docRef.id,
        name: name,
        price: price,
        disponible: disponible,
        photo: photo,
      );
      await docRef.set(additional.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Actualiza un adicional existente
  Future<String?> actualizarAdditional(WidgetRef ref, {
    required String id,
    required String name,
    required double price,
    required bool disponible,
    String? photo,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('adicional').doc(id);
      await docRef.update({
        'name': name,
        'disponible': disponible,
        'price': price,
        if (photo != null) 'photo': photo,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Elimina un adicional
  Future<String?> eliminarAdditional(WidgetRef ref, {required String id}) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('adicional').doc(id);
      await docRef.delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final registerAdditionalController = Provider((ref) {
  final controller = RegisterAdditionalController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

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

class ProductManagementController {
  Future<String?> toggleProductAvailability(
      String productId, bool currentDisponible) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('producto').doc(productId).update({
        'disponible': !currentDisponible,
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteProduct(String productId) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('producto').doc(productId).delete();
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
}

class ComboManagementController {
  Future<String?> toggleComboAvailability(
      String comboId, bool currentDisponible) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('combo').doc(comboId).update({
        'disponible': !currentDisponible,
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteCombo(String comboId) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('combo').doc(comboId).delete();
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateCombo({
    required String comboId,
    required String nombre,
    required double precio,
    required int tiempoPreparacion,
    required List<ProductModel> productos,
    required bool disponible,
    String? photo,
  }) async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('combo').doc(comboId).update({
        'name': nombre,
        'price': precio,
        'timePreparation': tiempoPreparacion,
        'products': productos.map((p) => p.toMap()).toList(),
        'disponible': disponible,
        if (photo != null) 'photo': photo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
}

class EditProductController {
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

  // Cargar datos del producto en los controladores
  void loadProductData(ProductModel producto) {
    nombreController.text = producto.name;
    precioController.text = producto.price.toString();
    tiempoPreparacionController.text = producto.tiempoPreparacion.toString();
    ingredientesController.text = producto.ingredientes;
  }

  // Limpiar todos los campos
  void clearAllFields() {
    nombreController.clear();
    precioController.clear();
    tiempoPreparacionController.clear();
    ingredientesController.clear();
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

  Future<String?> updateProduct(
    WidgetRef ref, {
    required String productId,
    required String nombre,
    required double precio,
    required int tiempoPreparacion,
    required String ingredientes,
    required String categoria,
    required bool disponible,
    String? newPhoto,
    Function(double)? onUploadProgress,
  }) async {
    try {
      String? photoUrl = newPhoto; // Mantener la foto actual si no hay nueva

      // Si hay una nueva imagen, subirla a Cloudinary
      if (newPhoto != null &&
          newPhoto.isNotEmpty &&
          !newPhoto.startsWith('http')) {
        onUploadProgress?.call(0.1);

        final file = File(newPhoto);

        if (!await file.exists()) {
          throw Exception('El archivo de imagen no existe');
        }

        // Subir nueva imagen con progreso
        photoUrl = await CloudinaryService.uploadImage(
          file,
          onProgress: (progress) {
            final mappedProgress = 0.1 + (progress * 0.7);
            onUploadProgress?.call(mappedProgress);
          },
        );

        if (photoUrl == null) {
          throw Exception('Error al subir la imagen a Cloudinary');
        }
        onUploadProgress?.call(0.9);
      }

      final productoData = {
        'name': nombre,
        'price': precio,
        'time': tiempoPreparacion,
        'ingredients': ingredientes,
        'categoryId': categoria,
        'disponible': disponible,
        'photo': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final db = FirebaseFirestore.instance;
      await db.collection('producto').doc(productId).update(productoData);

      onUploadProgress?.call(1.0);

      return null; // Éxito
    } catch (e) {
      return e.toString();
    }
  }
}

class EditComboController extends StateNotifier<void> {
  EditComboController() : super(null);

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController tiempoPreparacionController = TextEditingController();

  final List<ProductModel> productos = [];

  void addProduct(ProductModel product) {
    if (!productos.any((p) => p.id == product.id)) {
      productos.add(product);
      state = null; // Trigger rebuild
    }
  }

  void removeProduct(ProductModel product) {
    productos.removeWhere((p) => p.id == product.id);
    state = null; // Trigger rebuild
  }

  void clearProducts() {
    productos.clear();
    state = null;
  }

  void setProducts(List<ProductModel> newProducts) {
    productos.clear();
    productos.addAll(newProducts);
    state = null;
  }

  List<ProductModel> get products => productos;

  bool isProductSelected(ProductModel product) {
    return productos.any((p) => p.id == product.id);
  }

  @override
  void dispose() {
    super.dispose();
    nombreController.dispose();
    precioController.dispose();
    tiempoPreparacionController.dispose();
  }

  // Cargar datos del combo en los controladores
  void loadComboData(ComboModel combo) {
    nombreController.text = combo.name;
    precioController.text = combo.price.toString();
    tiempoPreparacionController.text = combo.timePreparation.toString();
    setProducts(combo.products);
  }

  // Limpiar todos los campos
  void clearAllFields() {
    nombreController.clear();
    precioController.clear();
    tiempoPreparacionController.clear();
    clearProducts();
  }

  bool areFieldsValid() {
    final nombre = nombreController.text.trim();
    final precio = precioController.text.trim();
    final tiempoPreparacion = tiempoPreparacionController.text.trim();
    return AppConstants.nameRegex.hasMatch(nombre) &&
        AppConstants.priceRegex.hasMatch(precio) &&
        AppConstants.timePreparationRegex.hasMatch(tiempoPreparacion) &&
        productos.isNotEmpty;
  }

  Future<String?> updateCombo(
    WidgetRef ref, {
    required String comboId,
    required String nombre,
    required double precio,
    required int tiempoPreparacion,
    required List<ProductModel> productos,
    required bool disponible,
    String? newPhoto,
    Function(double)? onUploadProgress,
  }) async {
    try {
      String? photoUrl = newPhoto; // Mantener la foto actual si no hay nueva

      // Si hay una nueva imagen, subirla a Cloudinary
      if (newPhoto != null &&
          newPhoto.isNotEmpty &&
          !newPhoto.startsWith('http')) {
        onUploadProgress?.call(0.1);

        final file = File(newPhoto);

        if (!await file.exists()) {
          throw Exception('El archivo de imagen no existe');
        }

        // Subir nueva imagen con progreso
        photoUrl = await CloudinaryService.uploadImage(
          file,
          onProgress: (progress) {
            final mappedProgress = 0.1 + (progress * 0.7);
            onUploadProgress?.call(mappedProgress);
          },
        );

        if (photoUrl == null) {
          throw Exception('Error al subir la imagen a Cloudinary');
        }
        onUploadProgress?.call(0.9);
      }

      final comboData = {
        'name': nombre,
        'price': precio,
        'timePreparation': tiempoPreparacion,
        'products': productos.map((p) => p.toMap()).toList(),
        'disponible': disponible,
        'photo': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final db = FirebaseFirestore.instance;
      await db.collection('combo').doc(comboId).update(comboData);

      onUploadProgress?.call(1.0);

      return null; // Éxito
    } catch (e) {
      return e.toString();
    }
  }
}
