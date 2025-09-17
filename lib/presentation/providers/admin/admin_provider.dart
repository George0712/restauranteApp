import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
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

final usersProvider =
    FutureProvider.family<List<UserModel>, String>((ref, rol) async {
  final firestore = ref.watch(firestoreProvider);

  final querySnapshot =
      await firestore.collection('usuario').where('rol', isEqualTo: rol).get();

  return querySnapshot.docs
      .map((doc) => UserModel.fromMap(doc.data(), doc.id))
      .toList();
});

//Providers Imagenes
class ProfileImageNotifier extends StateNotifier<File?> {
  ProfileImageNotifier() : super(null);

  final ImagePicker _picker = ImagePicker();

  // Método existente mejorado para galería
  Future<void> pickImage() async {
    await pickImageFromSource(ImageSource.gallery);
  }

  // Nuevo método para cámara
  Future<void> pickImageFromCamera() async {
    await pickImageFromSource(ImageSource.camera);
  }

  // Nuevo método para establecer imagen desde path
  void setImageFromPath(String imagePath) {
    state = File(imagePath);
  }

  // Nuevo método para establecer imagen desde File
  void setImageFromFile(File imageFile) {
    state = imageFile;
  }

  void clear() {
    state = null;
  }

  // Método unificado para ambas fuentes
  Future<void> pickImageFromSource(ImageSource source) async {
    if (kIsWeb) {
      SnackbarHelper.showSnackBar('Función no soportada en web');
      return;
    }

    try {
      // Verificar permisos según la fuente
      bool hasPermission = false;

      if (source == ImageSource.camera) {
        hasPermission = await _requestCameraPermission();
      } else {
        hasPermission = await _requestGalleryPermission();
      }

      if (!hasPermission) {
        return; // Los mensajes de error ya se manejan en los métodos de permisos
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxHeight: 1200,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        state = File(pickedFile.path);

        final sourceText =
            source == ImageSource.camera ? 'tomada' : 'seleccionada';
        SnackbarHelper.showSnackBar('Imagen $sourceText correctamente');
      } else {
        final sourceText = source == ImageSource.camera ? 'tomó' : 'seleccionó';
        SnackbarHelper.showSnackBar('No se $sourceText ninguna imagen');
      }
    } catch (e) {
      final sourceText = source == ImageSource.camera
          ? 'tomar la foto'
          : 'seleccionar la imagen';
      SnackbarHelper.showSnackBar('Error al $sourceText: $e');
    }
  }

  // Método privado para permisos de galería
  Future<bool> _requestGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        // Para Android 13+ usar permission.photos, para versiones anteriores usar storage
        final deviceInfo = await DeviceInfoPlugin().androidInfo;

        if (deviceInfo.version.sdkInt >= 33) {
          // Android 13+
          var photosStatus = await Permission.photos.status;
          if (!photosStatus.isGranted && !photosStatus.isLimited) {
            photosStatus = await Permission.photos.request();
            if (!photosStatus.isGranted && !photosStatus.isLimited) {
              if (photosStatus.isPermanentlyDenied) {
                SnackbarHelper.showSnackBar(
                    'Permiso de galería denegado permanentemente. Ve a Configuración para habilitarlo.');
                await openAppSettings();
              } else {
                SnackbarHelper.showSnackBar(
                    'Se necesita permiso para acceder a las fotos');
              }
              return false;
            }
          }
        } else {
          // Android < 13
          var storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
            if (!storageStatus.isGranted) {
              if (storageStatus.isPermanentlyDenied) {
                SnackbarHelper.showSnackBar(
                    'Permiso de almacenamiento denegado permanentemente. Ve a Configuración para habilitarlo.');
                await openAppSettings();
              } else {
                SnackbarHelper.showSnackBar(
                    'Se necesita permiso para acceder al almacenamiento');
              }
              return false;
            }
          }
        }
      } else if (Platform.isIOS) {
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted && !photosStatus.isLimited) {
          photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted && !photosStatus.isLimited) {
            if (photosStatus.isPermanentlyDenied) {
              SnackbarHelper.showSnackBar(
                  'Permiso de galería denegado permanentemente. Ve a Configuración para habilitarlo.');
              await openAppSettings();
            } else {
              SnackbarHelper.showSnackBar(
                  'Se necesita permiso para acceder a las fotos');
            }
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      SnackbarHelper.showSnackBar('Error al verificar permisos de galería: $e');
      return false;
    }
  }

  // Método privado para permisos de cámara
  Future<bool> _requestCameraPermission() async {
    try {
      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          if (cameraStatus.isPermanentlyDenied) {
            SnackbarHelper.showSnackBar(
                'Permiso de cámara denegado permanentemente. Ve a Configuración para habilitarlo.');
            await openAppSettings();
          } else {
            SnackbarHelper.showSnackBar(
                'Se necesita permiso para acceder a la cámara');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      SnackbarHelper.showSnackBar('Error al verificar permisos de cámara: $e');
      return false;
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

final registerCategoryControllerProvider =
    Provider<RegisterCategoryController>((ref) {
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
    }).toList();
  });
});

//Providers Productos
final registerProductoControllerProvider =
    Provider<RegisterProductoController>((ref) {
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

final productsProviderCategory =
    StreamProvider.family<List<ProductModel>, String>((ref, categoryId) {
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

final productManagementControllerProvider =
    Provider<ProductManagementController>((ref) {
  return ProductManagementController();
});

// Provider para obtener un producto específico por ID
final productByIdProvider =
    StreamProvider.family<ProductModel?, String>((ref, productId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('producto')
      .doc(productId)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return ProductModel.fromMap(snapshot.data()!, snapshot.id);
    }
    return null;
  });
});

// Provider para el controller de edición
final editProductControllerProvider = Provider<EditProductController>((ref) {
  return EditProductController();
});

//Providers Additionals
final registerAdditionalControllerProvider =
    Provider<RegisterAdditionalController>((ref) {
  final controller = RegisterAdditionalController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final additionalProvider = StreamProvider<List<AdditionalModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('adicional').snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => AdditionalModel.fromMap(doc.data(), doc.id))
        .toList();
  });
});

final additionalsProvider = StreamProvider<List<AdditionalModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('adicional').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => AdditionalModel.fromMap(doc.data(), doc.id)).toList();
  });
});

//Providers Combos
final registerComboControllerProvider =
    Provider<RegisterComboController>((ref) {
  final controller = RegisterComboController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final registerComboControllerNotifierProvider =
    StateNotifierProvider<RegisterComboController, void>((ref) {
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
