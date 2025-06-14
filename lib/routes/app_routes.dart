import 'package:go_router/go_router.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/create_cocinero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/create_credentials_cocinero.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/manage_cocinero_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/historial/historial_mesero_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/additional/create_item_additional_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/additional/manage_additional_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/combo/create_item_combo_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/combo/manage_combo_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/combo/products_item_combo_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/manage/mesero/create_credentials_mesero.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/create_mesero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/manage_mesero_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/category/create_item_category_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/category/manage_category_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/producto/create_item_producto_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/producto/create_producto_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/manage_producto_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/home/home_admin.dart';
import 'package:restaurante_app/presentation/screens/cocina/home_cocinero.dart';
import 'package:restaurante_app/presentation/screens/login/login.dart';
import 'package:restaurante_app/presentation/screens/mesero/home/home_mesero.dart';
import 'package:restaurante_app/presentation/screens/mesero/mesas/mesa_screen.dart';
import 'package:restaurante_app/presentation/screens/settings/not_found_screen.dart';
import 'package:restaurante_app/presentation/screens/settings/settings_user_screen.dart';
import 'package:restaurante_app/presentation/screens/splash/splash_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/pedido_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(path: '/splash-screen',
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/admin/home',
      builder: (context, state) => const HomeAdminScreen(),
    ),
    GoRoute(
      path: '/mesero/home',
      builder: (context, state) => const HomeMeseroScreen(),
    ),
    GoRoute(
      path: '/cocinero/home',
      builder: (context, state) => const HomeCocineroScreen(),
    ),

    GoRoute(path: '/admin/manage/mesero',
      builder: (context, state) => const ManageMeseroScreen(),
    ),
    GoRoute(path: '/admin/manage/cocinero',
      builder: (context, state) => const ManageCocineroScreen(),
    ),
    
    GoRoute(path: '/admin/manage/mesero/create-mesero',
      builder: (context, state) => const CreateMeseroScreen(),
    ),
    GoRoute(path: '/admin/manage/cocinero/create-cocinero',
      builder: (context, state) => const CreateCocineroScreen(),
    ),
    GoRoute(path: '/admin/manage/manage-productos',
      builder: (context, state) => const ManageProductoScreen(),
    ),
    GoRoute(path: '/admin/manage/producto/manage-categorys',
      builder: (context, state) => const ManageCategoryScreen(),
    ),
    GoRoute(path: '/admin/manage/producto/manage-additionals',
      builder: (context, state) => const ManageAdditionalScreen(),
    ),
    GoRoute(path: '/admin/manage/producto/manage-combos',
      builder: (context, state) => const ManageComboScreen(),
    ),
    GoRoute(path: '/admin/settings',
      builder: (context, state) => const SettingsUserScreen(),
    ),

    GoRoute(path: '/admin/manage/mesero/create-credentials',
      builder: (context, state) => const CreateCredentialsMesero(),
    ),
    GoRoute(path: '/admin/manage/cocinero/create-credentials',
      builder: (context, state) => const CreateCredentialsCocinero(),
    ),
    GoRoute(path: '/admin/manage/producto/productos',
    builder: (context, state) => const CreateProductoScreen(),
    ),
    GoRoute(path: '/admin/manage/producto/create-item-productos',
    builder: (context, state) => const CreateItemProductoScreen(),
    ),
    GoRoute(path: '/admin/manage/category/create-item-categorys',
    builder: (context, state) => const CreateItemCategoryScreen(),
    ),
    GoRoute(path: '/admin/manage/additional/create-item-Additionals',
    builder: (context, state) => const CreateItemAdditionalScreen(),
    ),
    GoRoute(path: '/admin/manage/combo/create-item-Combos',
    builder: (context, state) => const CreateItemComboScreen(),
    ),
    GoRoute(path: '/admin/manage/combo/create-item-combo/products-item-combo',
    builder: (context, state) => const ProductsItemComboScreen(),
    ),
    GoRoute(path: '/mesero/pedidos/mesas',
    builder: (context, state) => const MesasScreen(),
    ),
    GoRoute(path: '/mesero/pedidos/detalle/:mesaId/:pedidoId',
      builder: (context, state) => SeleccionProductosScreen(
        pedidoId: state.pathParameters['pedidoId']!,
      ),
    ),
    GoRoute(
      path: '/mesero/historial',
      builder: (context, state) => const HistorialScreen(),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);