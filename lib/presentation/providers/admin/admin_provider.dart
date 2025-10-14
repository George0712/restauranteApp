import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/dashboard_admin_model.dart';
import 'package:restaurante_app/presentation/controllers/admin/manage_products_controller.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/data/models/category_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

import 'package:restaurante_app/data/models/user_model.dart';

import 'package:restaurante_app/presentation/controllers/admin/admin_dashbord_controller.dart';
import 'package:restaurante_app/presentation/controllers/admin/user_controller.dart';
import 'package:restaurante_app/presentation/controllers/admin/mesa_controller.dart';

//Providers Admin
final adminControllerProvider = StateNotifierProvider<AdminController, AdminDashboardModel>((ref) {
  final controller = AdminController();
  controller.cargarDashboard(); // carga datos al iniciar
  return controller;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Extrae cada métrica de AdminDashboardModel - Solo cuenta pedidos PAGADOS
final totalVentasProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
    .collection('pedido')
    .where('status', isEqualTo: 'pagado') // Cambio: solo pedidos pagados
    .snapshots()
    .map((snapshot) {
      int totalVentas = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final venta = data['total']; // Ajusta el nombre del campo si es necesario
        if (venta is int) {
          totalVentas += venta;
        } else if (venta is double) {
          totalVentas += venta.toInt();
        }
      }
      return totalVentas;
    });
});

// Provider para contar pedidos (órdenes)
final ordenesProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
    .collection('pedido')
    .where('status', isEqualTo: 'pendiente')
    .snapshots()
    .map((snapshot) => snapshot.size);
});

// Provider para contar usuarios
final usuariosProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('usuario').snapshots().map((snapshot) => snapshot.size - 1);
});

// Provider para contar productos
final productosProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
    .collection('producto')
    .where('disponible', isEqualTo: true)
    .snapshots()
    .map((snapshot) => snapshot.size);
});

class SalesPoint {
  final DateTime date;
  final double total;

  const SalesPoint({required this.date, required this.total});
}

class OrderStatusMetric {
  final String status;
  final int count;

  const OrderStatusMetric({required this.status, required this.count});
}

class TopProductMetric {
  final String name;
  final int quantity;
  final double total;

  const TopProductMetric({
    required this.name,
    required this.quantity,
    required this.total,
  });
}

final weeklySalesProvider = StreamProvider<List<SalesPoint>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('pedido')
      .where('status', isEqualTo: 'pagado') // Cambio: solo pedidos pagados
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    final Map<DateTime, double> totalsByDay = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _parseTimestamp(data['createdAt']) ??
          _parseTimestamp(data['fechaCreacion']) ??
          _parseTimestamp(data['fecha']);

      if (createdAt == null) continue;

      final dayKey = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (dayKey.isBefore(startDate)) continue;

      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      totalsByDay.update(dayKey, (value) => value + total, ifAbsent: () => total);
    }

    final List<SalesPoint> points = [];
    for (int i = 0; i < 7; i++) {
      final day = startDate.add(Duration(days: i));
      points.add(
        SalesPoint(
          date: day,
          total: totalsByDay[day] ?? 0,
        ),
      );
    }

    return points;
  });
});

final todaySalesProvider = StreamProvider<double>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('pedido')
      .where('status', isEqualTo: 'pagado') // Cambio: solo pedidos pagados
      .snapshots()
      .map((snapshot) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    double totalSales = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _parseTimestamp(data['createdAt']) ??
          _parseTimestamp(data['fechaCreacion']) ??
          _parseTimestamp(data['fecha']);

      if (createdAt == null) continue;

      final orderDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (orderDay != todayKey) continue;

      totalSales += (data['total'] as num?)?.toDouble() ?? 0;
    }
    return totalSales;
  });
});

final completedTodayProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('pedido')
      .where('status', isEqualTo: 'terminado')
      .snapshots()
      .map((snapshot) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    int completed = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = _parseTimestamp(data['createdAt']) ??
          _parseTimestamp(data['fechaCreacion']) ??
          _parseTimestamp(data['fecha']);

      if (createdAt == null) continue;

      final orderDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (orderDay == todayKey) {
        completed++;
      }
    }

    return completed;
  });
});

final averageTicketProvider = StreamProvider<double>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('pedido')
      .where('status', isEqualTo: 'pagado') // Cambio: solo pedidos pagados
      .snapshots()
      .map((snapshot) {
    if (snapshot.size == 0) return 0.0;

    double totalSales = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      totalSales += (data['total'] as num?)?.toDouble() ?? 0;
    }

    return snapshot.size == 0 ? 0.0 : totalSales / snapshot.size;
  });
});

final orderStatusSummaryProvider = StreamProvider<List<OrderStatusMetric>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore.collection('pedido').snapshots().map((snapshot) {
    final Map<String, int> counts = {
      'pendiente': 0,
      'preparando': 0,
      'terminado': 0,
      'cancelado': 0,
    };

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? data['estado'] ?? '').toString().toLowerCase();
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts.entries
        .map((entry) => OrderStatusMetric(status: entry.key, count: entry.value))
        .toList();
  });
});

final topProductsProvider = StreamProvider<List<TopProductMetric>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('pedido')
      .where('status', isEqualTo: 'pagado') // Cambio: solo pedidos pagados
      .snapshots()
      .map((snapshot) {
    final Map<String, _ProductAccumulator> aggregated = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final items = data['items'] ?? data['productos'];

      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final name = (item['name'] ?? item['nombre'] ?? 'Producto').toString();
            final quantity = (item['quantity'] ?? item['cantidad'] ?? 0) as num?;
            final price = (item['price'] ?? item['precio'] ?? 0) as num?;

            final safeQuantity = quantity?.toInt() ?? 0;
            final safeTotal = (price?.toDouble() ?? 0) * safeQuantity;

            final accumulator = aggregated.putIfAbsent(
              name,
              () => _ProductAccumulator(name: name),
            );

            accumulator.quantity += safeQuantity;
            accumulator.total += safeTotal;
          }
        }
      }
    }

    final List<TopProductMetric> products = aggregated.values
        .map((value) => TopProductMetric(
              name: value.name,
              quantity: value.quantity,
              total: value.total,
            ))
        .toList();

    products.sort((a, b) => b.quantity.compareTo(a.quantity));
    return products.take(5).toList();
  });
});

DateTime? _parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class _ProductAccumulator {
  final String name;
  int quantity;
  double total;

  _ProductAccumulator({required this.name}) : quantity = 0, total = 0.0;
}

//Providers Users
final registerUserControllerProvider = Provider<UserController>((ref) {
  final controller = UserController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final isContactInfoValidProvider = StateProvider<bool>((ref) => false);
final isCredentialsValidProvider = StateProvider<bool>((ref) => false);
final userTempProvider = StateProvider<UserModel?>((ref) => null);

final usersProvider = StreamProvider.family<List<UserModel>, String>((ref, rol) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('usuario')
      .where('rol', isEqualTo: rol)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
});

final userManagementControllerProvider =
    Provider<ProductManagementController>((ref) {
  return ProductManagementController();
});

final userByIdProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('usuario').doc(userId).snapshots().map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  });
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
    final mesas = snapshot.docs.map((doc) => MesaModel.fromMap(doc.data(), doc.id)).toList();
    // Ordenar las mesas por ID numérico ascendente
    mesas.sort((a, b) => a.id.compareTo(b.id));
    return mesas;
  });
});

final mesasDisponiblesProvider = StreamProvider<List<MesaModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('mesa')
      .where('estado', isEqualTo: 'disponible')
      .snapshots()
      .map((snapshot) {
    final mesas = snapshot.docs.map((doc) {
      return MesaModel.fromMap(doc.data(), doc.id);
    }).toList();
    // Ordenar las mesas por ID numérico ascendente
    mesas.sort((a, b) => a.id.compareTo(b.id));
    return mesas;
  });
});

final mesasOcupadasProvider = StreamProvider<List<MesaModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('mesa')
      .where('estado', isEqualTo: 'ocupada')
      .snapshots()
      .map((snapshot) {
    final mesas = snapshot.docs.map((doc) {
      return MesaModel.fromMap(doc.data(), doc.id);
    }).toList();
    // Ordenar las mesas por ID numérico ascendente
    mesas.sort((a, b) => a.id.compareTo(b.id));
    return mesas;
  });
});
