import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/controllers/admin/manage_products_controller.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/data/models/category_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

import 'package:restaurante_app/data/models/user_model.dart';

import 'package:restaurante_app/presentation/controllers/admin/admin_controller.dart';
import 'package:restaurante_app/presentation/controllers/admin/register_user_controller.dart';
import 'package:restaurante_app/presentation/controllers/admin/mesa_controller.dart';

//Providers Admin
final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminDashboardState>((ref) {
  return AdminController();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Extrae cada métrica de AdminDashboardState
final totalVentasProvider = Provider<int>((ref) {
  return ref.watch(adminControllerProvider).totalVentas;
});
final ordenesProvider = Provider<int>((ref) {
  return ref.watch(adminControllerProvider).ordenes;
});
final clientesProvider = Provider<int>((ref) {
  return ref.watch(adminControllerProvider).clientes;
});
final productosProviderCount = Provider<int>((ref) {
  return ref.watch(adminControllerProvider).productos;
});

//Providers Users
final registerUserControllerProvider = Provider<RegisterUserController>((ref) {
  final controller = RegisterUserController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final isContactInfoValidProvider = StateProvider<bool>((ref) => false);
final isCredentialsValidProvider = StateProvider<bool>((ref) => false);
final userTempProvider = StateProvider<UserModel?>((ref) => null);

final usersProvider = FutureProvider.family<List<UserModel>, String>((ref, rol) async {
  final firestore = ref.watch(firestoreProvider);

  final querySnapshot = await firestore
      .collection('usuario')
      .where('rol', isEqualTo: rol)
      .get();

  return querySnapshot.docs
      .map((doc) => UserModel.fromMap(doc.data(), doc.id))
      .toList();
});


//Providers Imagenes
class ProfileImageNotifier extends StateNotifier<File?> {
  ProfileImageNotifier() : super(null);

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    if (kIsWeb) {
      SnackbarHelper.showSnackBar('Función no soportada en web');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Primero verificamos el permiso de fotos
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            SnackbarHelper.showSnackBar('Se necesita permiso para acceder a las fotos');
            return;
          }
        }

        // Luego verificamos el permiso de almacenamiento
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            SnackbarHelper.showSnackBar('Se necesita permiso para acceder al almacenamiento');
            return;
          }
        }
      } else if (Platform.isIOS) {
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            SnackbarHelper.showSnackBar('Se necesita permiso para acceder a las fotos');
            return;
          }
        }
      }

      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        state = File(pickedFile.path);
      } else {
        SnackbarHelper.showSnackBar('No se seleccionó ninguna foto');
      }
    } catch (e) {
      SnackbarHelper.showSnackBar('Error al seleccionar la imagen: $e');
    }
  }

  void clearImage() {
    state = null;
  }
}

final profileImageProvider =
    StateNotifierProvider<ProfileImageNotifier, File?>((ref) {
  return ProfileImageNotifier();
});



//Providers Category
final isValidFieldsProvider = StateProvider<bool>((ref) => false);

final registerCategoryControllerProvider = Provider<RegisterCategoryController>((ref) {
  final controller = RegisterCategoryController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final categoryDisponibleProvider = StreamProvider<List<CategoryModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('categoria').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return CategoryModel.fromMap(doc.data(), doc.id);
    }).where((category) => category.disponible).toList();
  });
});

//Providers Productos
final registerProductoControllerProvider = Provider<RegisterProductoController>((ref) {
  final controller = RegisterProductoController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('producto').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return ProductModel.fromMap(doc.data(), doc.id);
    }).toList();
  });
});

final productsProviderCategory = StreamProvider.family<List<ProductModel>, String>((ref, categoryId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('producto')
      .where('categoryId', isEqualTo: categoryId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ProductModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
});

//Providers Additionals
final registerAdditionalControllerProvider = Provider<RegisterAdditionalController>((ref) {
  final controller = RegisterAdditionalController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final additionalProvider = StreamProvider<List<AdditionalModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('adicional').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return AdditionalModel.fromMap(doc.data(), doc.id);
    }).where((additional) => additional.disponible).toList();
  });
});


//Providers Combos
final registerComboControllerProvider = Provider<RegisterComboController>((ref)  {
  final controller = RegisterComboController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final registerComboControllerNotifierProvider = StateNotifierProvider<RegisterComboController, void>((ref) {
  return RegisterComboController();
});

//Providers Mesas
final mesaControllerProvider = Provider<MesaController>((ref) {
  final controller = MesaController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final isMesaFieldsValidProvider = StateProvider<bool>((ref) => false);

final mesasProvider = StreamProvider<List<MesaModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('mesa').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return MesaModel.fromMap(doc.data(), doc.id);
    }).toList();
  });
});

final mesasDisponiblesProvider = StreamProvider<List<MesaModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('mesa')
      .where('estado', isEqualTo: 'disponible')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MesaModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
});

final mesasOcupadasProvider = StreamProvider<List<MesaModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('mesa')
      .where('estado', isEqualTo: 'ocupada')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MesaModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
});
