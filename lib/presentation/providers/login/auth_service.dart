import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/mesero/mesas_provider.dart'
    as mesero_mesas;
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart'
    as mesero_pedidos;
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart'
    as cocina;
import 'package:restaurante_app/presentation/providers/cocina/order_provider.dart'
    as cocina_orders;
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart'
    as admin_providers;

final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

final signInProvider =
    FutureProvider.family<void, (String email, String password)>(
        (ref, credentials) async {
  final auth = ref.watch(authProvider);
  final (email, password) = credentials;
  await auth.signInWithEmailAndPassword(email: email, password: password);
});

final signUpProvider =
    FutureProvider.family<void, (String email, String password)>(
        (ref, credentials) async {
  final auth = ref.watch(authProvider);
  final (email, password) = credentials;

  await auth.createUserWithEmailAndPassword(email: email, password: password);
});

final userModelProvider = FutureProvider<UserModel>((ref) async {
  final userAsync = await ref.watch(authStateChangesProvider.future);
  if (userAsync == null) throw Exception("Usuario no autenticado");

  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('usuario').doc(userAsync.uid).get();
  if (!doc.exists) throw Exception("Usuario no encontrado en Firestore");

  return UserModel.fromMap(doc.data()!, userAsync.uid);
});

final isCurrentUserAdminProvider = FutureProvider<bool>((ref) async {
  try {
    final userModel = await ref.watch(userModelProvider.future);
    return userModel.rol.toLowerCase() == 'admin';
  } catch (e) {
    return false; // Si hay error o no está autenticado, no es admin
  }
});

// Versión StreamProvider para reactividad en tiempo real (recomendada)
final isCurrentUserAdminStreamProvider = StreamProvider<bool>((ref) {
  final authStateAsync = ref.watch(authStateChangesProvider);

  return authStateAsync.when(
    data: (user) {
      if (user == null) {
        return Stream.value(false);
      }

      final firestore = ref.watch(firestoreProvider);
      return firestore
          .collection('usuario')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return false;
        final userData = doc.data()!;
        return userData['rol']?.toLowerCase() == 'admin';
      });
    },
    loading: () => Stream.value(false),
    error: (_, __) => Stream.value(false),
  );
});

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<void> signOut() async {
    await _ref.read(authProvider).signOut();

    _ref.invalidate(authStateChangesProvider);
    _ref.invalidate(userModelProvider);
    _ref.invalidate(isCurrentUserAdminProvider);
    _ref.invalidate(isCurrentUserAdminStreamProvider);

    _ref.invalidate(mesero_mesas.mesasMeseroProvider);
    _ref.invalidate(mesero_mesas.mesasStreamProvider);

    _ref.invalidate(mesero_pedidos.pedidosProvider);
    _ref.invalidate(mesero_pedidos.carritoProvider);

    _ref.invalidate(cocina.pedidosStreamProvider);
    _ref.invalidate(cocina.pendingPedidosProvider);
    _ref.invalidate(cocina.completedPedidosProvider);
    _ref.invalidate(cocina.cocinaNotifierProvider);
    _ref.invalidate(cocina.pedidoStatsProvider);
    _ref.invalidate(cocina.pedidoStatusFilterProvider);

    _ref.invalidate(cocina_orders.ordersStreamProvider);
    _ref.invalidate(cocina_orders.pendingOrdersProvider);
    _ref.invalidate(cocina_orders.completedOrdersProvider);
    _ref.invalidate(cocina_orders.ordersNotifierProvider);
    _ref.invalidate(cocina_orders.orderStatsProvider);
    _ref.invalidate(cocina_orders.orderStatusFilterProvider);

    _ref.invalidate(admin_providers.adminControllerProvider);
    _ref.invalidate(admin_providers.productsProvider);
    _ref.invalidate(admin_providers.productsProviderCategory);
    _ref.invalidate(admin_providers.totalVentasProvider);
    _ref.invalidate(admin_providers.ordenesProvider);
    _ref.invalidate(admin_providers.usuariosProvider);
    _ref.invalidate(admin_providers.productosProvider);
    _ref.invalidate(admin_providers.weeklySalesProvider);
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});
